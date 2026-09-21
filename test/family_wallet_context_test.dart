import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/home/presentation/home_screen.dart';
import 'package:vitta_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/people/domain/models/family_member.dart';
import 'package:vitta_mobile/features/people/domain/models/relationship.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/people/presentation/dependents_screen.dart';
import 'package:vitta_mobile/features/people/presentation/family_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/presentation/vaccination_card_screen.dart';
import 'package:vitta_mobile/features/vaccines/presentation/vaccines_screen.dart';

void main() {
  test('wallet selection starts at currentPersonId and returns to it', () {
    final controller = WalletSelectionController()..bindCurrentPerson(_owner);

    expect(_child.authUid, isNull);
    expect(_child.canAuthenticate, isFalse);
    expect(_child.toMap()['authUid'], isNull);
    expect(controller.currentPersonId, 'owner-person');
    expect(controller.selectedPersonId, 'owner-person');
    controller.selectPerson(_child);
    expect(controller.selectedPersonId, 'child-person');
    controller.selectCurrentPerson();
    expect(controller.selectedPersonId, 'owner-person');
  });

  testWidgets('Demo OFF opens the functional family form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DependentsScreen(
          authRepository: _AuthFake(),
          peopleRepository: _PeopleFake(),
          demoModeEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Nome completo'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'CPF'), findsOneWidget);
    expect(find.text('Adicionar familiar'), findsWidgets);
  });

  testWidgets('family selects a direct member without a redundant detail', (
    tester,
  ) async {
    final controller = WalletSelectionController();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => FamilyScreen(
                    authRepository: _AuthFake(),
                    peopleRepository: _PeopleFake(),
                    vaccinationRepository: _VaccinationFake(),
                    walletController: controller,
                    demoModeEnabled: false,
                  ),
                ),
              ),
              child: const Text('Abrir família'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir família'));
    await tester.pumpAndSettle();

    expect(find.text('Minha família'), findsOneWidget);
    expect(find.text('Criança Teste'), findsOneWidget);
    await tester.tap(find.text('Criança Teste'));
    await tester.pumpAndSettle();
    expect(controller.selectedPersonId, 'child-person');
    expect(find.text('Abrir família'), findsOneWidget);
    expect(find.text('Selecionar carteira'), findsNothing);
  });

  testWidgets('vaccination card queries the selected patientId', (
    tester,
  ) async {
    final controller = WalletSelectionController()
      ..bindCurrentPerson(_owner)
      ..selectPerson(_child);
    final repository = _VaccinationFake(
      records: [
        VaccinationRecord(
          id: 'record-1',
          patientId: 'child-person',
          vaccineName: 'BCG',
          doseLabel: 'Dose única',
          appliedAt: DateTime(2026, 8, 1),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VaccinationCardScreen(
          authRepository: _AuthFake(),
          vaccinationRepository: repository,
          walletController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedPersonId, 'child-person');
    expect(repository.requestedResponsibleId, 'owner-person');
    expect(find.text('Criança Teste'), findsOneWidget);
    expect(find.text('BCG'), findsOneWidget);
    expect(
      find.byKey(const Key('vaccination-card-header-band')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Acompanhe aplicações e próximas doses'),
      findsOneWidget,
    );
  });

  testWidgets(
    'vaccine detail scrolls above Android bar and never exposes professional UID',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 30);
      tester.view.viewPadding = const FakeViewPadding(bottom: 30);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      const uid = 'technical-professional-uid-secret';
      final repository = _VaccinationFake(
        vaccines: const [
          Vaccine(
            id: 'bcg',
            name: 'BCG',
            sourceName: 'Calendário Nacional de Vacinação / PNI',
            description: 'Protege contra formas graves de tuberculose.',
            prevents: ['Formas graves de tuberculose'],
            targetGroups: ['Crianças ao nascer'],
            doseSchedule: ['Dose única ao nascer'],
            expectedReactions: ['Dor leve no local da aplicação'],
            warningSigns: ['Reação intensa ou persistente'],
            contraindications: ['Avaliar condições clínicas específicas'],
          ),
        ],
        records: [
          VaccinationRecord(
            id: 'bcg',
            patientId: 'owner-person',
            vaccineName: 'BCG',
            doseLabel: 'Dose única',
            appliedAt: DateTime(2026, 9, 14),
            professionalUid: uid,
            source: 'professional_panel',
            notes: 'Observação de teste',
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: VaccinationCardScreen(
            authRepository: _AuthFake(),
            vaccinationRepository: repository,
            walletController: WalletSelectionController()
              ..bindCurrentPerson(_owner),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('BCG'),
        find.byType(ListView).first,
        const Offset(0, -120),
      );
      await tester.tap(find.text('BCG').first);
      await tester.pumpAndSettle();
      expect(find.text(uid), findsNothing);
      expect(find.text('Registrado pelo Portal Vitta'), findsOneWidget);
      final audience = find.text('Público/faixa etária');
      await tester.dragUntilVisible(
        audience,
        find.byKey(const Key('vaccination-detail-scroll')),
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();
      expect(audience, findsOneWidget);
      final source = find.textContaining(
        'Fonte: Calendário Nacional de Vacinação / PNI',
      );
      await tester.dragUntilVisible(
        source,
        find.byType(ListView).last,
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();
      expect(source, findsOneWidget);
      expect(tester.getBottomRight(source).dy, lessThanOrEqualTo(538));
      final detailScroll = tester.widget<ListView>(
        find.byKey(const Key('vaccination-detail-scroll')),
      );
      expect((detailScroll.padding! as EdgeInsets).bottom, 62);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Adicionar familiar stays above a 48px Android navigation bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: DependentsScreen(
          authRepository: _AuthFake(),
          peopleRepository: _PeopleFake(),
          demoModeEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final addButton = find.byKey(const Key('confirm-add-family'));
    await tester.dragUntilVisible(
      addButton,
      find.byType(ListView),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    expect(tester.getBottomRight(addButton).dy, lessThanOrEqualTo(520));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Applied, upcoming and overdue cards match their own occurrence',
    (tester) async {
      final today = DateTime.now();
      final repository = _VaccinationFake(
        records: [
          VaccinationRecord(
            id: 'bcg',
            patientId: 'owner-person',
            vaccineName: 'BCG',
            appliedAt: today.subtract(const Duration(days: 2)),
            nextDoseAt: today.add(const Duration(days: 20)),
          ),
          VaccinationRecord(
            id: 'hpv',
            patientId: 'owner-person',
            vaccineName: 'HPV',
            nextDoseAt: today.subtract(const Duration(days: 4)),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: VaccinationCardScreen(
            authRepository: _AuthFake(),
            vaccinationRepository: repository,
            walletController: WalletSelectionController()
              ..bindCurrentPerson(_owner),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicadas'));
      await tester.pumpAndSettle();
      expect(find.text('Aplicada'), findsOneWidget);
      expect(find.textContaining('Aplicada em'), findsOneWidget);
      expect(find.text('Próxima'), findsNothing);
      await tester.tap(find.text('Próximas'));
      await tester.pumpAndSettle();
      expect(find.text('Próxima'), findsOneWidget);
      expect(find.textContaining('Próxima dose em'), findsOneWidget);
      expect(find.text('Aplicada'), findsNothing);
      await tester.tap(find.text('Atrasadas'));
      await tester.pumpAndSettle();
      expect(find.text('Atrasada'), findsOneWidget);
      expect(find.textContaining('Dose prevista para'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home summary has no check and recent records have a surface', (
    tester,
  ) async {
    final repository = _VaccinationFake(
      records: [
        VaccinationRecord(
          id: 'bcg',
          patientId: 'owner-person',
          vaccineName: 'BCG',
          appliedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          authRepository: _AuthFake(),
          peopleRepository: _PeopleFake(),
          vaccinationRepository: repository,
          walletController: WalletSelectionController()
            ..bindCurrentPerson(_owner),
          demoModeEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('home-summary-card')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('manage-family-button')), findsOneWidget);
    expect(find.byKey(const Key('home-header-band')), findsOneWidget);
    await tester.dragUntilVisible(
      find.byKey(const Key('recent-vaccine-surface')),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.byKey(const Key('recent-vaccine-surface')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Carteira places filters above the left search', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VaccinationCardScreen(
          authRepository: _AuthFake(),
          vaccinationRepository: _VaccinationFake(),
          walletController: WalletSelectionController()
            ..bindCurrentPerson(_owner),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final filters = find.byKey(const Key('vaccination-card-filters'));
    final search = find.byKey(const ValueKey('collapsed-search'));
    expect(
      tester.getTopLeft(filters).dy,
      lessThan(tester.getTopLeft(search).dy),
    );
    expect(tester.getTopLeft(search).dx, lessThan(40));
  });

  testWidgets('selected wallet without records shows its empty state', (
    tester,
  ) async {
    final controller = WalletSelectionController()
      ..bindCurrentPerson(_owner)
      ..selectPerson(_child);
    await tester.pumpWidget(
      MaterialApp(
        home: VaccinationCardScreen(
          authRepository: _AuthFake(),
          vaccinationRepository: _VaccinationFake(),
          walletController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Nenhuma aplicação registrada nesta carteira'),
      findsOneWidget,
    );
  });

  testWidgets('Caderneta queries the selected patientId', (tester) async {
    final controller = WalletSelectionController()
      ..bindCurrentPerson(_owner)
      ..selectPerson(_child);
    final repository = _VaccinationFake();

    await tester.pumpWidget(
      MaterialApp(
        home: VaccinationCardScreen(
          authRepository: _AuthFake(),
          vaccinationRepository: repository,
          walletController: controller,
          initialShowBooklet: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedPersonId, 'child-person');
    expect(repository.requestedResponsibleId, 'owner-person');
    expect(find.text('Carteira Digital de Vacinação'), findsOneWidget);
  });

  testWidgets(
    'Caderneta exposes complete Vitta PDF through its primary action',
    (tester) async {
      final person = AppUser(
        uid: 'owner-person',
        personId: 'owner-person',
        name: 'Pessoa Titular',
        email: 'titular@example.com',
        cpf: '12345678909',
        birthDate: DateTime(1990, 4, 12),
        role: 'responsible',
      );
      final repository = _VaccinationFake(
        records: [
          VaccinationRecord(
            id: 'record-complete',
            patientId: 'owner-person',
            vaccineName: 'BCG',
            doseLabel: 'Dose única',
            appliedAt: DateTime(2026, 9, 14),
            lot: 'LOTE-123',
            manufacturer: 'Instituto Teste',
            facilityName: 'UBS Central',
          ),
        ],
      );
      List<int>? sharedBytes;
      String? sharedName;

      await tester.pumpWidget(
        MaterialApp(
          home: VaccinationCardScreen(
            authRepository: _AuthFake(),
            vaccinationRepository: repository,
            selectedPerson: person,
            initialShowBooklet: true,
            shareBooklet: (bytes, fileName) async {
              sharedBytes = bytes;
              sharedName = fileName;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Carteira Digital de Vacinação'), findsOneWidget);
      expect(find.text('CPF: ***.***.789-**'), findsOneWidget);
      expect(find.textContaining('Lote: LOTE-123'), findsOneWidget);
      expect(
        find.textContaining('Fabricante: Instituto Teste'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Unidade de saúde: UBS Central'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Compartilhar ou baixar caderneta'));
      await tester.pumpAndSettle();
      expect(sharedName, 'carteira-digital-vitta.pdf');
      expect(String.fromCharCodes(sharedBytes!.take(5)), '%PDF-');

      await tester.tap(find.text('Vacinas').first);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('share-booklet-context-action')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home follows selectedPersonId and identifies the family wallet',
    (tester) async {
      final controller = WalletSelectionController()
        ..bindCurrentPerson(_owner)
        ..selectPerson(_child);
      final repository = _VaccinationFake();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            authRepository: _AuthFake(),
            peopleRepository: _PeopleFake(),
            vaccinationRepository: repository,
            walletController: controller,
            demoModeEnabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.requestedPersonId, 'child-person');
      expect(repository.requestedResponsibleId, 'owner-person');
      expect(find.text('Visualizando: Criança Teste'), findsOneWidget);
    },
  );

  testWidgets('Vaccines crosses catalog with the selected patientId', (
    tester,
  ) async {
    final controller = WalletSelectionController()
      ..bindCurrentPerson(_owner)
      ..selectPerson(_child);
    final repository = _VaccinationFake();

    await tester.pumpWidget(
      MaterialApp(
        home: VaccinesScreen(
          authRepository: _AuthFake(),
          vaccinationRepository: repository,
          walletController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedPersonId, 'child-person');
    expect(repository.requestedResponsibleId, 'owner-person');
    expect(find.textContaining('Visualizando:'), findsNothing);
  });

  testWidgets('Notifications queries the selected patientId', (tester) async {
    final controller = WalletSelectionController()
      ..bindCurrentPerson(_owner)
      ..selectPerson(_child);
    final repository = _VaccinationFake();

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          authRepository: _AuthFake(),
          vaccinationRepository: repository,
          walletController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedPersonId, 'child-person');
    expect(repository.requestedResponsibleId, 'owner-person');
    expect(find.byKey(const Key('notifications-empty-state')), findsOneWidget);
  });
}

final _owner = AppUser(
  uid: 'auth-owner',
  authUid: 'auth-owner',
  personId: 'owner-person',
  name: 'Pessoa Titular',
  email: 'titular@example.com',
  role: 'responsible',
  dependentIds: const ['child-person'],
);

final _child = AppUser(
  uid: 'child-person',
  personId: 'child-person',
  authUid: null,
  canAuthenticate: false,
  name: 'Criança Teste',
  email: '',
  role: 'dependent',
  birthDate: DateTime(2020, 1, 1),
  majorityAt: DateTime(2038, 1, 1),
  guardianIds: const ['owner-person'],
  managedByUserIds: const ['owner-person'],
  relationshipToGuardian: 'Filho(a)',
);

final _directRelationship = PersonRelationship(
  id: 'owner-person_child-person',
  fromPersonId: 'owner-person',
  toPersonId: 'child-person',
  type: RelationshipType.legalGuardian,
  status: RelationshipStatus.verified,
  permissions: RelationshipPermissions(viewVaccination: true),
  consentStatus: AdultConsentStatus.notRequiredMinor,
);

class _AuthFake implements AuthRepository {
  @override
  Stream<AppUser?> authStateChanges() => Stream.value(_owner);

  @override
  Future<AppUser?> getCurrentUser() async => _owner;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => _owner;

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
  }) async => _owner;

  @override
  Future<AppUser> updateProfile(AppUser user) async => user;
}

class _PeopleFake implements PeopleRepository {
  @override
  Future<AppUser> createDependent({
    required String guardianId,
    required String name,
    required DateTime birthDate,
    required String relationship,
    required String cpf,
  }) async => _child;

  @override
  Future<List<AppUser>> getAvailablePeople(String guardianId) async => [
    _owner,
    _child,
  ];

  @override
  Future<List<FamilyMember>> getFamilyMembers(String currentPersonId) async => [
    FamilyMember(person: _owner, isCurrent: true),
    FamilyMember(person: _child, relationship: _directRelationship),
  ];
}

class _VaccinationFake implements VaccinationRepository {
  _VaccinationFake({this.records = const [], this.vaccines = const []});

  final List<VaccinationRecord> records;
  final List<Vaccine> vaccines;
  String? requestedPersonId;
  String? requestedResponsibleId;

  @override
  Future<List<VaccinationRecord>> getRecordsByChild(String childId) async =>
      records;

  @override
  Future<List<VaccinationRecord>> getRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) async => records;

  @override
  Future<List<VaccinationRecord>> getRecordsByResponsible(
    String responsibleId,
  ) async => records;

  @override
  Future<List<Vaccine>> getVaccines() async => vaccines;

  @override
  Stream<List<VaccinationRecord>> watchRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) async* {
    requestedPersonId = personId;
    requestedResponsibleId = responsibleId;
    yield records;
  }

  @override
  Stream<List<VaccinationRecord>> watchPatientRecords(String patientId) =>
      watchRecordsByPerson(personId: patientId, responsibleId: patientId);
}
