import 'package:firebase_core/firebase_core.dart';
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

  testWidgets(
    'AuthGate exposes Firestore permission-denied instead of hiding it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            authRepository: FakeAuthRepository(
              null,
              streamError: FirebaseException(
                plugin: 'cloud_firestore',
                code: 'permission-denied',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('permission-denied'), findsOneWidget);
    },
  );
}

final testUser = AppUser(
  uid: 'uid',
  name: 'Eduardo',
  email: 'eduardo@gmail.com',
  role: AppRoles.responsible,
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.user, {this.streamError});

  final AppUser? user;
  final Object? streamError;

  @override
  Stream<AppUser?> authStateChanges() => streamError == null
      ? Stream.value(user)
      : Stream<AppUser?>.error(streamError!);

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
