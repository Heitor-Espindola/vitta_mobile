import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/validators/cpf_validator.dart';
import 'package:vitta_mobile/core/validators/full_name_validator.dart';
import 'package:vitta_mobile/features/auth/data/cpf_registry_key.dart'
    as cpf_registry;
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/people/data/repositories/firebase_person_identity_repository.dart';
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
    await _assertGuardian(guardianId);
    final guardianSnapshot = await _users.doc(guardianId).get();
    final guardianData = guardianSnapshot.data();
    if (!guardianSnapshot.exists || guardianData == null) return const [];

    final guardian = AppUser.fromMap({...guardianData, 'uid': guardianId});
    final people = <AppUser>[guardian];
    if (guardian.dependentIds.isEmpty) return people;

    final snapshots = await Future.wait(
      guardian.dependentIds.map((id) => _users.doc(id).get()),
    );
    for (final snapshot in snapshots) {
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        people.add(AppUser.fromMap({...data, 'uid': snapshot.id}));
      }
    }
    return people;
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

    final dependentDocument = _users.doc();
    final guardianDocument = _users.doc(guardianId);
    final cpfDigits = cpfDigitsOnly(cpf);
    final registryDocument = _firestore
        .collection('cpf_registry')
        .doc(cpf_registry.cpfRegistryKey(cpfDigits));
    final now = DateTime.now();
    final dependent = AppUser(
      uid: dependentDocument.id,
      personId: dependentDocument.id,
      authUid: null,
      canAuthenticate: false,
      name: formattedName,
      email: '',
      role: 'dependent',
      roles: const ['dependent'],
      accountStatus: 'active',
      cpf: cpfDigits,
      birthDate: birthDate,
      majorityAt: calculateMajorityAt(birthDate),
      guardianIds: [guardianId],
      managedByUserIds: [guardianId],
      relationshipToGuardian: relationship.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.runTransaction((transaction) async {
      final guardianSnapshot = await transaction.get(guardianDocument);
      final guardianData = guardianSnapshot.data();
      if (!guardianSnapshot.exists || guardianData == null) {
        throw StateError('Perfil do responsável não encontrado.');
      }

      final registrySnapshot = await transaction.get(registryDocument);
      if (registrySnapshot.exists) {
        throw StateError('Este CPF já está cadastrado.');
      }

      final dependentIds = List<String>.from(
        guardianData['dependentIds'] as List? ?? const [],
      );
      dependentIds.add(dependent.uid);

      transaction.set(dependentDocument, {
        ...dependent.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
      });
      transaction.update(guardianDocument, {
        'dependentIds': dependentIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(registryDocument, {
        'ownerUid': dependent.uid,
        'guardianUid': guardianId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final relationshipId = PersonRelationship.deterministicId(
        guardianId,
        dependent.uid,
      );
      transaction.set(
        _firestore.collection('relationships').doc(relationshipId),
        {
          'fromPersonId': guardianId,
          'toPersonId': dependent.uid,
          'type': _relationshipType(relationship),
          'status': 'pending',
          'permissions': {
            'viewVaccination': false,
            'receiveNotifications': false,
          },
          'consentStatus': 'not_required_minor',
          'verificationSource': 'manual_pending',
          'verifiedAt': null,
          'validUntil': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });
    return dependent;
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
}

String _relationshipType(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('mãe') || normalized.contains('mae')) return 'mother';
  if (normalized.contains('pai')) return 'father';
  if (normalized.contains('tutor')) return 'tutor';
  if (normalized.contains('respons') || normalized.contains('guard')) {
    return 'legal_guardian';
  }
  return 'caregiver';
}
