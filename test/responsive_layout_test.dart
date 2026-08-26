import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/core/constants/app_roles.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/presentation/login_screen.dart';
import 'package:vitta_mobile/features/auth/presentation/register_screen.dart';
import 'package:vitta_mobile/features/home/presentation/home_screen.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/profile/presentation/profile_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccines/presentation/vaccines_screen.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

void main() {
  const homeViewports = <String, Size>{
    'small': Size(320, 568),
    'medium': Size(768, 1024),
    'common Android': Size(412, 915),
    'Edge/Web': Size(1280, 720),
  };

  for (final viewport in homeViewports.entries) {
    testWidgets('Home fits the ${viewport.key} viewport', (tester) async {
      tester.view.physicalSize = viewport.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authRepository: _FakeAuthRepository(),
            peopleRepository: _FakePeopleRepository(),
            vaccinationRepository: _FakeVaccinationRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minha Carteira'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
      await tester.pumpAndSettle();
      expect(find.text('Próximas doses'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Login, registration and profile fit a small viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(authRepository: _FakeAuthRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Perfil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vaccine cards do not overflow on a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: VaccinesScreen(
          authRepository: _FakeAuthRepository(),
          vaccinationRepository: _FakeVaccinationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vacinas recomendadas'), findsOneWidget);
    expect(find.text('BCG'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final bcgCard = find.byKey(const Key('vaccine-card-BCG'));
    await tester.ensureVisible(bcgCard);
    await tester.pumpAndSettle();
    await tester.tap(bcgCard);
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da vacina'), findsOneWidget);
    expect(find.text('O que ela previne'), findsOneWidget);
    expect(find.text('Esquema de doses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shows the vaccination empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authRepository: _FakeAuthRepository(),
          peopleRepository: _FakePeopleRepository(),
          vaccinationRepository: _FakeVaccinationRepository(empty: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhuma vacina registrada ainda.'), findsOne);
  });

  testWidgets(
    'profile has one entry point and returns to the previous screen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.profile: (context) => Scaffold(
              body: TextButton(
                key: const Key('profile-back-test'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Voltar'),
              ),
            ),
          },
          home: const VittaMobileShell(
            title: 'Início',
            currentTab: VittaTab.home,
            body: Center(child: Text('Tela anterior')),
          ),
        ),
      );

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.byTooltip('Perfil'), findsNothing);
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-back-test')), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile-back-test')));
      await tester.pumpAndSettle();
      expect(find.text('Tela anterior'), findsOneWidget);
    },
  );
}

class _FakePeopleRepository implements PeopleRepository {
  @override
  Future<AppUser> createDependent({
    required String guardianId,
    required String name,
    required DateTime birthDate,
    required String relationship,
    required String cpf,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<AppUser>> getAvailablePeople(String guardianId) async => const [
    AppUser(
      uid: 'uid',
      name: 'Maria Silva',
      email: 'maria@gmail.com',
      role: AppRoles.responsible,
    ),
  ];
}

class _FakeAuthRepository implements AuthRepository {
  final user = const AppUser(
    uid: 'uid',
    name: 'Maria Silva',
    email: 'maria@gmail.com',
    role: AppRoles.responsible,
  );

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(user);

  @override
  Future<AppUser?> getCurrentUser() async => user;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    return user;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
  }) async => user;

  @override
  Future<AppUser> updateProfile(AppUser user) async => user;
}

class _FakeVaccinationRepository implements VaccinationRepository {
  _FakeVaccinationRepository({this.empty = false});

  final bool empty;

  @override
  Future<List<VaccinationRecord>> getRecordsByResponsible(String id) async {
    if (empty) return [];
    return [
      VaccinationRecord(
        id: 'next',
        childId: 'uid',
        responsibleId: 'uid',
        vaccineName: 'Influenza',
        dose: 'Dose anual',
        status: 'pending',
        nextDoseDate: DateTime.now().add(const Duration(days: 30)),
      ),
      VaccinationRecord(
        id: 'last',
        childId: 'uid',
        responsibleId: 'uid',
        vaccineName: 'Hepatite B',
        dose: '3ª dose',
        status: 'applied',
        applicationDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  @override
  Future<List<VaccinationRecord>> getRecordsByChild(String childId) async => [];

  @override
  Future<List<VaccinationRecord>> getRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) => getRecordsByResponsible(responsibleId);

  @override
  Future<List<Vaccine>> getVaccines() async => [];

  @override
  Stream<List<VaccinationRecord>> watchRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) async* {
    yield await getRecordsByPerson(
      personId: personId,
      responsibleId: responsibleId,
    );
  }

  @override
  Stream<List<VaccinationRecord>> watchPatientRecords(String patientUid) =>
      watchRecordsByPerson(personId: patientUid, responsibleId: patientUid);
}
