import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';
import 'package:vitta_mobile/core/validators/cpf_validator.dart';
import 'package:vitta_mobile/core/validators/full_name_validator.dart';
import 'package:vitta_mobile/features/auth/data/cpf_registry_key.dart'
    as cpf_registry;
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/people/data/repositories/firebase_person_identity_repository.dart';
import 'package:vitta_mobile/features/people/domain/models/family_member.dart';
import 'package:vitta_mobile/features/people/domain/models/relationship.dart';
import 'package:vitta_mobile/features/people/domain/repositories/person_identity_repository.dart';

class FirebasePeopleRepository implements PeopleRepository {
  FirebasePeopleRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    PersonIdentityRepository? identityRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _identityRepository =
           identityRepository ??
           FirebasePersonIdentityRepository(
             firestore: firestore ?? FirebaseFirestore.instance,
           );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final PersonIdentityRepository _identityRepository;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<List<AppUser>> getAvailablePeople(String guardianId) async {
    final members = await getFamilyMembers(guardianId);
    return members.map((member) => member.person).toList(growable: false);
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers(String currentPersonId) async {
    await _assertGuardian(currentPersonId);
    final currentSnapshot = await _users.doc(currentPersonId).get();
    final currentData = currentSnapshot.data();
    if (!currentSnapshot.exists || currentData == null) return const [];

    final current = AppUser.fromMap({
      ...currentData,
      'uid': currentPersonId,
      'personId': currentPersonId,
    });
    final members = <FamilyMember>[
      FamilyMember(person: current, isCurrent: true),
    ];
    for (final dependentId in current.dependentIds.toSet()) {
      final dependentSnapshot = await _users.doc(dependentId).get();
      final dependentData = dependentSnapshot.data();
      if (!dependentSnapshot.exists || dependentData == null) continue;
      final person = AppUser.fromMap({
        ...dependentData,
        'uid': dependentId,
        'personId': dependentId,
      });
      final directId = PersonRelationship.deterministicId(
        currentPersonId,
        dependentId,
      );
      var relationshipData = await _optionalDocument(
        collection: 'relationships',
        documentId: directId,
      );
      var grantData = await _optionalDocument(
        collection: 'access_grants',
        documentId: directId,
      );
      if (relationshipData == null && grantData == null) {
        final repaired = await _repairLegacyAccessPair(
          guardian: current,
          dependent: person,
          pairId: directId,
        );
        relationshipData = repaired.relationship;
        grantData = repaired.grant;
      }
      members.add(
        FamilyMember(
          person: person,
          relationship: relationshipData == null
              ? null
              : PersonRelationship.fromMap(directId, relationshipData),
          accessGrant: grantData == null
              ? null
              : VaccinationAccessGrant.fromMap(directId, grantData),
        ),
      );
    }
    return members;
  }

  /// Completa, uma única vez, o par de autorização ausente em dependentes
  /// criados antes da adoção de `relationships` e `access_grants`.
  ///
  /// O reparo só é tentado para um vínculo legado já comprovado nos dois
  /// perfis e no registro exato do CPF. Vínculos revogados, pendentes ou
  /// parcialmente existentes nunca são reativados automaticamente.
  Future<_AccessPair> _repairLegacyAccessPair({
    required AppUser guardian,
    required AppUser dependent,
    required String pairId,
  }) async {
    final guardianId = guardian.effectivePersonId;
    final dependentId = dependent.effectivePersonId;
    final isManagedDirectly =
        guardian.dependentIds.contains(dependentId) &&
        dependent.guardianIds.contains(guardianId) &&
        dependent.managedByUserIds.contains(guardianId);
    final cpfDigits = cpfDigitsOnly(dependent.cpf ?? '');
    if (!isManagedDirectly || cpfDigits.length != 11) {
      return const _AccessPair();
    }

    try {
      final cpfHash = cpf_registry.cpfRegistryKey(cpfDigits);
      final registry = await _firestore
          .collection('cpf_registry')
          .doc(cpfHash)
          .get();
      final registryData = registry.data();
      final registryPersonId = registryData == null
          ? null
          : _registryPersonId(registryData);
      if (!registry.exists || registryPersonId != dependentId) {
        return const _AccessPair();
      }

      final relationship = _firestore.collection('relationships').doc(pairId);
      final grant = _firestore.collection('access_grants').doc(pairId);
      final batch = _firestore.batch();
      batch.set(relationship, {
        'fromPersonId': guardianId,
        'toPersonId': dependentId,
        'type': _relationshipType(
          dependent.relationshipToGuardian ?? 'Responsável legal',
        ),
        'status': 'verified',
        'permissions': {'viewVaccination': true, 'receiveNotifications': true},
        'consentStatus': 'granted',
        'verificationSource': 'academic_tcc',
        'cpfHash': cpfHash,
        'verifiedAt': FieldValue.serverTimestamp(),
        'validUntil': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(grant, {
        'granteePersonId': guardianId,
        'subjectPersonId': dependentId,
        'viewVaccination': true,
        'receiveNotifications': true,
        'consentStatus': 'granted',
        'source': 'academic_tcc',
        'cpfHash': cpfHash,
        'validUntil': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException {
      // Uma corrida de gravação ou uma regra mais restritiva não deve impedir
      // a listagem da família; as leituras abaixo refletem o estado definitivo.
    }

    return _AccessPair(
      relationship: await _optionalDocument(
        collection: 'relationships',
        documentId: pairId,
      ),
      grant: await _optionalDocument(
        collection: 'access_grants',
        documentId: pairId,
      ),
    );
  }

  @override
  Future<AppUser> createDependent({
    required String guardianId,
    required String name,
    required DateTime birthDate,
    required String relationship,
    required String cpf,
  }) async {
    await _assertGuardian(guardianId);
    final formattedName = formatPersonName(name);
    final nameError = validateFullName(formattedName);
    if (nameError != null) throw StateError(nameError);
    final cpfError = validateCpf(cpf);
    if (cpfError != null) throw StateError(cpfError);

    final guardianDocument = _users.doc(guardianId);
    final cpfDigits = cpfDigitsOnly(cpf);
    final cpfHash = cpf_registry.cpfRegistryKey(cpfDigits);
    final registryDocument = _firestore.collection('cpf_registry').doc(cpfHash);
    final now = DateTime.now();
    final majorityAt = calculateMajorityAt(birthDate);
    final generatedPersonDocument = _users.doc();
    final initialRegistrySnapshot = await registryDocument.get();
    final initialPersonId = initialRegistrySnapshot.data() == null
        ? null
        : _registryPersonId(initialRegistrySnapshot.data()!);
    final initialRelationshipId = initialPersonId == null
        ? null
        : PersonRelationship.deterministicId(guardianId, initialPersonId);
    final initialRelationship = initialRelationshipId == null
        ? null
        : await _optionalDocument(
            collection: 'relationships',
            documentId: initialRelationshipId,
          );
    final initialGrant = initialRelationshipId == null
        ? null
        : await _optionalDocument(
            collection: 'access_grants',
            documentId: initialRelationshipId,
          );
    final initialGrantValidUntil = dateTimeFromMap(initialGrant?['validUntil']);
    final initialLinkIsActive =
        initialRelationship?['status'] == 'verified' &&
        (initialRelationship?['permissions'] as Map?)?['viewVaccination'] ==
            true &&
        initialGrant?['granteePersonId'] == guardianId &&
        initialGrant?['subjectPersonId'] == initialPersonId &&
        initialGrant?['viewVaccination'] == true &&
        initialGrant?['consentStatus'] == 'granted' &&
        (initialGrantValidUntil == null ||
            now.isBefore(initialGrantValidUntil));
    late String linkedPersonId;
    late bool createdNewPerson;

    await _firestore.runTransaction((transaction) async {
      final guardianSnapshot = await transaction.get(guardianDocument);
      final guardianData = guardianSnapshot.data();
      if (!guardianSnapshot.exists || guardianData == null) {
        throw StateError('Perfil do responsável não encontrado.');
      }

      final registrySnapshot = await transaction.get(registryDocument);
      final registryData = registrySnapshot.data();
      final existingPersonId = registryData == null
          ? null
          : _registryPersonId(registryData);
      if (registrySnapshot.exists && existingPersonId == null) {
        throw StateError('O registro deste CPF está inconsistente.');
      }
      linkedPersonId = existingPersonId ?? generatedPersonDocument.id;
      createdNewPerson = existingPersonId == null;
      if (linkedPersonId == guardianId) {
        throw StateError('Este CPF pertence à sua própria carteira.');
      }

      final dependentIds = List<String>.from(
        guardianData['dependentIds'] as List? ?? const [],
      );
      if (dependentIds.contains(linkedPersonId) && initialLinkIsActive) {
        throw StateError('Este familiar já está vinculado à sua conta.');
      }
      final addsDependent = !dependentIds.contains(linkedPersonId);
      if (addsDependent) {
        dependentIds.add(linkedPersonId);
      }

      if (createdNewPerson) {
        final dependent = AppUser(
          uid: linkedPersonId,
          personId: linkedPersonId,
          authUid: null,
          canAuthenticate: false,
          name: formattedName,
          email: '',
          role: 'dependent',
          roles: const ['dependent'],
          accountStatus: 'active',
          cpf: cpfDigits,
          birthDate: birthDate,
          majorityAt: majorityAt,
          guardianIds: [guardianId],
          managedByUserIds: [guardianId],
          relationshipToGuardian: relationship.trim(),
          createdAt: now,
          updatedAt: now,
        );
        transaction.set(generatedPersonDocument, {
          ...dependent.toMap(),
          'createdAt':
              initialRelationship?['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': null,
        });
        transaction.set(registryDocument, {
          'ownerUid': linkedPersonId,
          'personId': linkedPersonId,
          'guardianUid': guardianId,
          'createdAt':
              initialGrant?['createdAt'] ?? FieldValue.serverTimestamp(),
        });
      }
      if (addsDependent) {
        transaction.update(guardianDocument, {
          'dependentIds': dependentIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      final relationshipId = PersonRelationship.deterministicId(
        guardianId,
        linkedPersonId,
      );
      transaction.set(
        _firestore.collection('relationships').doc(relationshipId),
        {
          'fromPersonId': guardianId,
          'toPersonId': linkedPersonId,
          'type': _relationshipType(relationship),
          'status': 'verified',
          'permissions': {
            'viewVaccination': true,
            'receiveNotifications': true,
          },
          'consentStatus': 'granted',
          'verificationSource': 'academic_tcc',
          'cpfHash': cpfHash,
          'verifiedAt': FieldValue.serverTimestamp(),
          'validUntil': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      transaction
          .set(_firestore.collection('access_grants').doc(relationshipId), {
            'granteePersonId': guardianId,
            'subjectPersonId': linkedPersonId,
            'viewVaccination': true,
            'receiveNotifications': true,
            'consentStatus': 'granted',
            'source': 'academic_tcc',
            'cpfHash': cpfHash,
            'validUntil': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    });
    final linkedSnapshot = await _users.doc(linkedPersonId).get();
    final linkedData = linkedSnapshot.data();
    if (!linkedSnapshot.exists || linkedData == null) {
      throw StateError('O familiar foi vinculado, mas não pôde ser carregado.');
    }
    return AppUser.fromMap({
      ...linkedData,
      'uid': linkedPersonId,
      'personId': linkedPersonId,
      'relationshipToGuardian': relationship.trim(),
    });
  }

  Future<void> _assertGuardian(String guardianId) async {
    final authUid = _firebaseAuth.currentUser?.uid;
    final currentPersonId = authUid == null
        ? null
        : await _identityRepository.resolvePersonId(authUid);
    if (currentPersonId != guardianId) {
      throw StateError('Sessão inválida para gerenciar dependentes.');
    }
  }

  Future<Map<String, dynamic>?> _optionalDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .doc(documentId)
          .get();
      return snapshot.data();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' || error.code == 'not-found') {
        return null;
      }
      rethrow;
    }
  }
}

class _AccessPair {
  const _AccessPair({this.relationship, this.grant});

  final Map<String, dynamic>? relationship;
  final Map<String, dynamic>? grant;
}

String? _registryPersonId(Map<String, dynamic> data) {
  final personId = data['personId'];
  if (personId is String && personId.isNotEmpty) return personId;
  final ownerUid = data['ownerUid'];
  if (ownerUid is String && ownerUid.isNotEmpty) return ownerUid;
  return null;
}

String _relationshipType(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('mãe') || normalized.contains('mae')) return 'mother';
  if (normalized.contains('pai')) return 'father';
  if (normalized.contains('respons') || normalized.contains('tutor')) {
    return 'tutor';
  }
  if (normalized.contains('filh') || normalized.contains('guard')) {
    return 'legal_guardian';
  }
  return 'caregiver';
}
