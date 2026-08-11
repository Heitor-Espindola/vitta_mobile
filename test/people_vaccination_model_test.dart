import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/people/presentation/dependents_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_schedule.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';

void main() {
  test('dependent uses the unified users model without authentication', () {
    final dependent = AppUser.fromMap({
      'uid': 'dependent-id',
      'name': 'Ana Souza',
      'email': '',
      'role': 'dependent',
      'authUid': '',
      'canAuthenticate': false,
      'roles': ['dependent'],
      'guardianIds': ['guardian-id'],
      'dependentIds': <String>[],
      'managedByUserIds': ['guardian-id'],
      'relationshipToGuardian': 'Filha',
    });

    expect(dependent.canAuthenticate, isFalse);
    expect(dependent.guardianIds, ['guardian-id']);
    expect(dependent.relationshipToGuardian, 'Filha');
    expect(dependent.toMap()['authUid'], isEmpty);
    expect(dependent.toMap()['cpf'], isEmpty);
  });

  test('vaccination record reads current and panel-ready fields', () {
    final record = VaccinationRecord.fromMap({
      'id': 'record-id',
      'personId': 'person-id',
      'responsibleId': 'guardian-id',
      'vaccineId': 'vaccine-id',
      'vaccineName': 'Vacina cadastrada',
      'dose': 'Dose 1',
      'status': 'applied',
      'batchNumber': 'LOT-1',
      'manufacturer': 'Fabricante cadastrado',
      'healthUnitId': 'unit-id',
      'professionalId': 'professional-id',
      'source': 'health_professional',
    });

    expect(record.childId, 'person-id');
    expect(record.personId, 'person-id');
    expect(record.batchNumber, 'LOT-1');
    expect(record.toMap()['professionalId'], 'professional-id');
  });

  test('vaccine supports sourced educational content', () {
    final vaccine = Vaccine.fromMap({
      'id': 'vaccine-id',
      'name': 'Vacina cadastrada',
      'prevents': ['Doença informada pela fonte'],
      'doseSchedule': [
        {'doseNumber': 1, 'recommendedAge': 'Faixa cadastrada'},
      ],
      'sourceName': 'Fonte oficial',
      'sourceUrl': 'https://example.gov.br/vacina',
      'calendarVersion': 'versao-oficial',
      'active': true,
    });

    expect(vaccine.prevents, hasLength(1));
    expect(vaccine.doseSchedule.single, isA<Map>());
    expect(vaccine.sourceName, 'Fonte oficial');
    expect(vaccine.active, isTrue);
  });

  test(
    'vaccination schedule parses versioned entries without medical defaults',
    () {
      final schedule = VaccinationSchedule.fromMap({
        'id': 'schedule-id',
        'version': 'official-version',
        'sourceName': 'Fonte oficial',
        'active': true,
        'entries': [
          {
            'vaccineId': 'vaccine-id',
            'doseNumber': 2,
            'minAgeDays': 60,
            'intervalDays': 30,
          },
        ],
      });

      expect(schedule.active, isTrue);
      expect(schedule.entries.single.doseNumber, '2');
      expect(schedule.entries.single.minAgeDays, 60);
      expect(schedule.entries.single.notes, isNull);
    },
  );

  testWidgets('dependent form requires and formats CPF', (tester) async {
    final peopleRepository = _RecordingPeopleRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: DependentsScreen(
          authRepository: _PeopleAuthRepository(),
          peopleRepository: peopleRepository,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome completo'),
      'Ana Souza',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Data de nascimento'),
      '01012015',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'CPF'),
      '52998224725',
    );
    expect(find.text('529.982.247-25'), findsOneWidget);
    await tester.ensureVisible(find.text('Criar carteira'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar carteira'));
    await tester.pumpAndSettle();

    expect(peopleRepository.savedName, 'Ana Souza');
    expect(peopleRepository.savedCpf, '529.982.247-25');
  });
}

const _guardian = AppUser(
  uid: 'guardian-id',
  name: 'Responsável Real',
  email: 'responsavel@gmail.com',
  role: 'responsible',
);

class _RecordingPeopleRepository implements PeopleRepository {
  String? savedName;
  String? savedCpf;

  @override
  Future<AppUser> createDependent({
    required String guardianId,
    required String name,
    required DateTime birthDate,
    required String relationship,
    required String cpf,
  }) async {
    savedName = name;
    savedCpf = cpf;
    return AppUser(
      uid: 'dependent-id',
      name: name,
      email: '',
      role: 'dependent',
      canAuthenticate: false,
      guardianIds: const ['guardian-id'],
    );
  }

  @override
  Future<List<AppUser>> getAvailablePeople(String guardianId) async => const [
    _guardian,
  ];
}

class _PeopleAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> authStateChanges() => Stream.value(_guardian);

  @override
  Future<AppUser?> getCurrentUser() async => _guardian;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => _guardian;

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
  }) async => _guardian;

  @override
  Future<AppUser> updateProfile(AppUser user) async => user;
}
