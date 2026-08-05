import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser?> getCurrentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
  });

  Future<AppUser> updateProfile(AppUser user);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
