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

class FirebasePeopleRepository implements PeopleRepository {
  FirebasePeopleRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<List<AppUser>> getAvailablePeople(String guardianId) async {
    _assertGuardian(guardianId);
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
    _assertGuardian(guardianId);
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
      authUid: '',
      canAuthenticate: false,
      name: formattedName,
      email: '',
      role: 'dependent',
      roles: const ['dependent'],
      accountStatus: 'active',
      cpf: cpfDigits,
      birthDate: birthDate,
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
    });
    return dependent;
  }

  void _assertGuardian(String guardianId) {
    if (_firebaseAuth.currentUser?.uid != guardianId) {
      throw StateError('Sessão inválida para gerenciar dependentes.');
    }
  }
}
