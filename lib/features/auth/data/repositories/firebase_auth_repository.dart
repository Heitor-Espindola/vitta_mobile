import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitta_mobile/core/constants/app_roles.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    return _getOrCreateUserProfile(firebaseUser);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Usuario nao encontrado.',
      );
    }

    return _getOrCreateUserProfile(firebaseUser);
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Nao foi possivel criar o usuario.',
      );
    }

    await firebaseUser.updateDisplayName(name.trim());

    final now = DateTime.now();
    final appUser = AppUser(
      uid: firebaseUser.uid,
      name: name.trim(),
      email: firebaseUser.email ?? email.trim(),
      role: AppRoles.responsible,
      createdAt: now,
      updatedAt: now,
    );

    await _users.doc(firebaseUser.uid).set(appUser.toMap());
    return appUser;
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<AppUser> _getOrCreateUserProfile(User firebaseUser) async {
    final userDocument = _users.doc(firebaseUser.uid);
    final snapshot = await userDocument.get();
    if (snapshot.exists && snapshot.data() != null) {
      return AppUser.fromMap({...snapshot.data()!, 'uid': firebaseUser.uid});
    }

    final now = DateTime.now();
    final appUser = AppUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      role: AppRoles.responsible,
      createdAt: now,
      updatedAt: now,
    );

    await userDocument.set(appUser.toMap());
    return appUser;
  }
}
