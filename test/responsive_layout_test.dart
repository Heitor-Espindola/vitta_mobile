import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/core/constants/app_roles.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/presentation/login_screen.dart';
import 'package:vitta_mobile/features/auth/presentation/register_screen.dart';
import 'package:vitta_mobile/features/home/presentation/home_screen.dart';
import 'package:vitta_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:vitta_mobile/features/people/domain/models/family_member.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/profile/presentation/profile_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccines/presentation/vaccines_screen.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';
import 'package:vitta_mobile/shared/widgets/vitta_logo.dart';

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

  testWidgets(
    'Home uses the official logo, full-width header and native share callback',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? sharedText;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authRepository: _FakeAuthRepository(),
            peopleRepository: _FakePeopleRepository(),
            vaccinationRepository: _FakeVaccinationRepository(),
            shareText: (text) async => sharedText = text,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VittaLogo), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('home-header-band'))).width,
        412,
      );
      await tester.tap(find.byKey(const Key('share-wallet-button')));
      await tester.pump();
      expect(sharedText, 'Minha carteira de vacinação está no Vitta.');
    },
  );

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

  testWidgets('Vacinas places category filters above the left search', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VaccinesScreen(
          authRepository: _FakeAuthRepository(),
          vaccinationRepository: _FakeVaccinationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final filters = find.byKey(const Key('vaccine-category-filters'));
    final search = find.byKey(const ValueKey('collapsed-search'));
    expect(
      tester.getTopLeft(filters).dy,
      lessThan(tester.getTopLeft(search).dy),
    );
    expect(
      tester.getTopLeft(search).dx,
      closeTo(tester.getTopLeft(filters).dx, 1),
    );
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

    expect(find.byKey(const Key('notification-badge')), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Nenhuma próxima dose cadastrada'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nenhuma próxima dose cadastrada'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nenhuma aplicação registrada ainda'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma aplicação registrada ainda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home shows the badge when the shared feed has notifications', (
    tester,
  ) async {
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

    expect(find.byKey(const Key('notification-badge')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home summary warns when a dose is overdue', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authRepository: _FakeAuthRepository(),
          peopleRepository: _FakePeopleRepository(),
          vaccinationRepository: _FakeVaccinationRepository(
            records: [
              VaccinationRecord(
                id: 'overdue',
                patientId: 'uid',
                vaccineName: 'Influenza',
                doseLabel: 'Dose anual',
                nextDoseAt: DateTime.now().subtract(const Duration(days: 2)),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Você possui uma dose que precisa de atenção.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('notification-badge')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notifications shows a compact empty state', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          authRepository: _FakeAuthRepository(),
          vaccinationRepository: _FakeVaccinationRepository(empty: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tudo certo por aqui'), findsOneWidget);
    expect(
      find.text('Você não possui notificações no momento.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('notifications-empty-state')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile exposes functional settings and support pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final pageTitle in [
      'Configurações',
      'Segurança da conta',
      'Central de ajuda',
      'Termos e privacidade',
    ]) {
      await tester.pumpWidget(
        MaterialApp(home: ProfileScreen(authRepository: _FakeAuthRepository())),
      );
      await tester.pumpAndSettle();

      final item = find.textContaining(pageTitle, findRichText: true);
      await tester.dragUntilVisible(
        item,
        find.byType(ListView).first,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.tap(item);
      await tester.pumpAndSettle();
      expect(find.text(pageTitle), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Perfil'), findsOneWidget);
    }
  });

  testWidgets('profile editor stays scrollable above keyboard and system bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(authRepository: _FakeAuthRepository())),
    );
    await tester.pumpAndSettle();
    final contactEntry = find.textContaining('Contato', findRichText: true);
    await tester.dragUntilVisible(
      contactEntry,
      find.byType(ListView).first,
      const Offset(0, -120),
    );
    await tester.tap(contactEntry);
    await tester.pumpAndSettle();

    final phoneField = find.byKey(const Key('profile-phone-field'));
    await tester.ensureVisible(phoneField);
    await tester.tap(phoneField);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Salvar dados');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    expect(saveButton, findsOneWidget);
    expect(tester.getBottomRight(saveButton).dy, lessThanOrEqualTo(544));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contact saves phone and private emergency contact immediately', (
    tester,
  ) async {
    final repository = _TrackingAuthRepository();
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(authRepository: repository)),
    );
    await tester.pumpAndSettle();
    final contactEntry = find.textContaining('Contato', findRichText: true);
    await tester.dragUntilVisible(
      contactEntry,
      find.byType(ListView).first,
      const Offset(0, -120),
    );
    await tester.tap(contactEntry);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile-phone-field')),
      '(16) 98888-7777',
    );
    await tester.enterText(
      find.byKey(const Key('emergency-contact-name-field')),
      'Maria Souza',
    );
    await tester.enterText(
      find.byKey(const Key('emergency-contact-phone-field')),
      '(16) 99999-9999',
    );
    await tester.enterText(
      find.byKey(const Key('emergency-contact-relationship-field')),
      'Mãe',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar dados'));
    await tester.pumpAndSettle();

    expect(repository.saved?.phone, '(16) 98888-7777');
    expect(repository.saved?.emergencyContact?.name, 'Maria Souza');
    expect(repository.saved?.emergencyContact?.relationship, 'Mãe');
    expect(find.text('Dados atualizados com sucesso.'), findsOneWidget);
  });

  testWidgets('profile keeps typed fields open when persistence fails', (
    tester,
  ) async {
    final repository = _TrackingAuthRepository(fail: true);
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(authRepository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    final nameField = find.widgetWithText(TextFormField, 'Nome completo');
    await tester.enterText(nameField, 'Maria Souza');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar dados'));
    await tester.pumpAndSettle();

    expect(find.text('Maria Souza'), findsOneWidget);
    expect(
      find.text('Não foi possível salvar. Revise os dados e tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Dados pessoais'), findsOneWidget);
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

  @override
  Future<List<FamilyMember>> getFamilyMembers(String currentPersonId) async =>
      const [
        FamilyMember(
          person: AppUser(
            uid: 'uid',
            name: 'Maria Silva',
            email: 'maria@gmail.com',
            role: AppRoles.responsible,
          ),
          isCurrent: true,
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

class _TrackingAuthRepository extends _FakeAuthRepository {
  _TrackingAuthRepository({this.fail = false});

  final bool fail;
  AppUser? saved;

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    if (fail) throw StateError('Falha simulada');
    saved = user;
    return user;
  }
}

class _FakeVaccinationRepository implements VaccinationRepository {
  _FakeVaccinationRepository({this.empty = false, this.records});

  final bool empty;
  final List<VaccinationRecord>? records;

  @override
  Future<List<VaccinationRecord>> getRecordsByResponsible(String id) async {
    if (records != null) return records!;
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
