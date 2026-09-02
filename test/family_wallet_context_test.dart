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

  testWidgets('family selects a direct member and returns to current wallet', (
    tester,
  ) async {
    final controller = WalletSelectionController();
    await tester.pumpWidget(
      MaterialApp(
        home: FamilyScreen(
          authRepository: _AuthFake(),
          peopleRepository: _PeopleFake(),
          vaccinationRepository: _VaccinationFake(),
          walletController: controller,
          demoModeEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Minha família'), findsOneWidget);
    expect(find.text('Criança Teste'), findsOneWidget);
    await tester.tap(find.text('Criança Teste'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Nenhuma aplicação registrada nesta carteira'),
      findsOneWidget,
    );

    await tester.tap(find.text('Selecionar carteira'));
    await tester.pumpAndSettle();
    expect(controller.selectedPersonId, 'child-person');
    expect(find.text('Voltar para Minha carteira'), findsOneWidget);

    await tester.tap(find.text('Voltar para Minha carteira'));
    await tester.pumpAndSettle();
    expect(controller.selectedPersonId, 'owner-person');
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
    expect(find.text('Caderneta digital'), findsOneWidget);
  });

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
    expect(find.text('Visualizando: Criança Teste'), findsOneWidget);
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
  _VaccinationFake({this.records = const []});

  final List<VaccinationRecord> records;
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
  Future<List<Vaccine>> getVaccines() async => const [];

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
