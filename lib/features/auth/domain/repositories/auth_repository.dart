import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser?> getCurrentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
