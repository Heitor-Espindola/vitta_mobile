import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vitta_mobile/core/constants/app_roles.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/validators/password_validator.dart';
import 'package:vitta_mobile/features/auth/data/cpf_registry_key.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/validators/gmail_validator.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static Future<void> configurePersistence() async {
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
  }

  @override
  Stream<AppUser?> authStateChanges() =>
      _firebaseAuth.authStateChanges().asyncExpand((firebaseUser) {
        if (firebaseUser == null) return Stream.value(null);
        return _users.doc(firebaseUser.uid).snapshots().map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return AppUser.fromMap({
            ...snapshot.data()!,
            'uid': firebaseUser.uid,
          });
        });
      });

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

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

    final appUser = await _getUserProfile(firebaseUser);
    final now = DateTime.now();
    await _users.doc(firebaseUser.uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return appUser.copyWith(lastLoginAt: now, updatedAt: now);
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
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: normalizeEmail(email),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Nao foi possivel criar o usuario.',
      );
    }

    final formattedName = formatPersonName(name);
    await firebaseUser.updateDisplayName(formattedName);
    await firebaseUser.sendEmailVerification();

    final now = DateTime.now();
    final appUser = AppUser(
      uid: firebaseUser.uid,
      name: formattedName,
      email: firebaseUser.email ?? normalizeEmail(email),
      role: AppRoles.responsible,
      cpf: cpf.trim(),
      birthDate: birthDate,
      createdAt: now,
      updatedAt: now,
    );

    final cpfHash = cpfRegistryKey(cpf);
    final registryDocument = _firestore.collection('cpf_registry').doc(cpfHash);

    try {
      await _firestore.runTransaction((transaction) async {
        final registrySnapshot = await transaction.get(registryDocument);
        if (registrySnapshot.exists) {
          throw FirebaseAuthException(
            code: 'cpf-already-in-use',
            message: 'Este CPF já está cadastrado.',
          );
        }

        transaction.set(_users.doc(firebaseUser.uid), {
          ...appUser.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': null,
        });
        transaction.set(registryDocument, {
          'ownerUid': firebaseUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return appUser;
    } catch (_) {
      // Evita deixar uma conta de Authentication sem perfil após falha atômica.
      await firebaseUser.delete();
      rethrow;
    }
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final updatedUser = user.copyWith(
      name: formatPersonName(user.name),
      updatedAt: DateTime.now(),
    );
    await _users
        .doc(user.uid)
        .set(updatedUser.toMap(), SetOptions(merge: true));
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null && firebaseUser.displayName != updatedUser.name) {
      await firebaseUser.updateDisplayName(updatedUser.name);
    }
    return updatedUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: normalizeEmail(email));
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<AppUser> _getUserProfile(User firebaseUser) async {
    final userDocument = _users.doc(firebaseUser.uid);
    final snapshot = await userDocument.get();
    if (snapshot.exists && snapshot.data() != null) {
      return AppUser.fromMap({...snapshot.data()!, 'uid': firebaseUser.uid});
    }

    throw FirebaseAuthException(
      code: 'profile-not-found',
      message: 'Perfil do usuário não encontrado.',
    );
  }
}
