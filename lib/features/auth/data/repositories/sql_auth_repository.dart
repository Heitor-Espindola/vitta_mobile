import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:vitta_mobile/core/constants/app_roles.dart';
import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/validators/password_validator.dart';
import 'package:vitta_mobile/dataconnect_generated/mobile_connector.dart';
import 'package:vitta_mobile/features/auth/data/registration_compensator.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/validators/gmail_validator.dart';

class SqlAuthRepository implements AuthRepository {
  SqlAuthRepository({
    FirebaseAuth? firebaseAuth,
    MobileConnectorConnector? connector,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _connector = connector ?? MobileConnectorConnector.instance;

  final FirebaseAuth _firebaseAuth;
  final MobileConnectorConnector _connector;

  @override
  Stream<AppUser?> authStateChanges() =>
      _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;
        return _getUserProfile(firebaseUser);
      });

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _getUserProfile(firebaseUser);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: normalizeEmail(email),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Usuario nao encontrado.',
      );
    }
    await firebaseUser.getIdToken(true);
    return _getUserProfile(firebaseUser);
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
  }) async {
    final passwordError = validateStrongPassword(password);
    if (passwordError != null) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: passwordError,
      );
    }

    final normalizedEmail = normalizeEmail(email);
    final formattedName = formatPersonName(name);
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Nao foi possivel criar o usuario.',
      );
    }

    return RegistrationCompensator.run(
      operation: () async {
        await firebaseUser.updateDisplayName(formattedName);
        await firebaseUser.sendEmailVerification();
        await firebaseUser.getIdToken(true);
        await _connector
            .completeMobileRegistration(
              name: formattedName,
              birthDate: birthDate,
              email: normalizedEmail,
              cpf: cpfDigitsOnly(cpf),
            )
            .execute();
        return _getUserProfile(firebaseUser);
      },
      compensate: firebaseUser.delete,
    );
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final formattedName = formatPersonName(user.name);
    await _connector
        .updateMobileProfile(name: formattedName)
        .phone(_nullableTrimmed(user.phone))
        .execute();

    final contact = user.emergencyContact;
    if (contact != null) {
      await _connector
          .upsertAccessibleEmergencyContact(
            patientId: user.effectivePersonId,
            name: contact.name.trim(),
            phone: contact.phone.trim(),
            relationship: contact.relationship.trim(),
          )
          .execute();
    }

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null && firebaseUser.displayName != formattedName) {
      try {
        await firebaseUser.updateDisplayName(formattedName);
      } on FirebaseAuthException {
        // SQL e a fonte autoritativa do nome. O displayName e apenas auxiliar.
      }
    }
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Sessao expirada.',
      );
    }
    return _getUserProfile(firebaseUser);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _firebaseAuth.sendPasswordResetEmail(email: normalizeEmail(email));

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  Future<AppUser> _getUserProfile(User firebaseUser) async {
    final result = await _connector.getMobileCurrentPerson().execute(
      fetchPolicy: QueryFetchPolicy.serverOnly,
    );
    if (result.data.users.length != 1) {
      throw FirebaseAuthException(
        code: 'profile-not-found',
        message: 'Perfil do usuario nao encontrado.',
      );
    }
    final row = result.data.users.single;
    final patient = row.patient_on_user;
    if (patient == null) {
      throw FirebaseAuthException(
        code: 'profile-not-found',
        message: 'Carteira do usuario nao encontrada.',
      );
    }

    EmergencyContact? emergencyContact;
    try {
      final emergencyResult = await _connector
          .getAccessibleEmergencyContact(patientId: patient.id)
          .execute(fetchPolicy: QueryFetchPolicy.serverOnly);
      final contact =
          emergencyResult.data.patient?.user.emergencyContact_on_user;
      if (contact != null) {
        emergencyContact = EmergencyContact(
          name: contact.name,
          phone: contact.phone,
          relationship: contact.relationship,
        );
      }
    } catch (_) {
      // O contato e opcional e nao deve impedir a abertura da carteira.
    }

    return AppUser(
      uid: patient.id,
      personId: patient.id,
      authUid: firebaseUser.uid,
      name: row.name,
      email: row.email ?? firebaseUser.email ?? '',
      role: AppRoles.responsible,
      roles: const ['user'],
      accountStatus: row.status.stringValue.toLowerCase(),
      cpf: row.cpf,
      birthDate: row.birthDate,
      majorityAt: calculateMajorityAt(row.birthDate),
      phone: row.phone,
      emergencyContact: emergencyContact,
      photoUrl: row.photoUrl,
      createdAt: row.createdAt?.toDateTime(),
      updatedAt: row.updatedAt?.toDateTime(),
      lastLoginAt: row.lastLoginAt?.toDateTime(),
    );
  }
}

String? _nullableTrimmed(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
