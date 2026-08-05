import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/core/constants/app_roles.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/presentation/login_screen.dart';
import 'package:vitta_mobile/features/auth/presentation/splash_screen.dart';
import 'package:vitta_mobile/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('AuthGate renders login without a user', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(authRepository: FakeAuthRepository(null))),
    );
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('AuthGate renders home for an authenticated user', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(authRepository: FakeAuthRepository(testUser)),
      ),
    );
    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

final testUser = AppUser(
  uid: 'uid',
  name: 'Eduardo',
  email: 'eduardo@gmail.com',
  role: AppRoles.responsible,
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.user);

  final AppUser? user;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(user);

  @override
  Future<AppUser?> getCurrentUser() async => user;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
  }) => throw UnimplementedError();

  @override
  Future<AppUser> updateProfile(AppUser user) async => user;
}
