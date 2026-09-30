import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccines/domain/models/vaccine_audience_guidance.dart';
import 'package:vitta_mobile/features/vaccines/presentation/vaccines_screen.dart';

void main() {
  test(
    'known vaccines retain every official audience instead of one category',
    () {
      List<String> audiences(String name) =>
          VaccineAudienceGuidance.categoriesForVaccine(
            Vaccine(id: 'remote-id', name: name),
          );

      expect(
        audiences('Covid-19'),
        unorderedEquals(['Infantis', 'Gestantes', 'Idosos']),
      );
      expect(
        audiences('Hepatite B'),
        unorderedEquals(['Infantis', 'Juvenis', 'Gestantes', 'Idosos']),
      );
      expect(
        audiences('Influenza'),
        unorderedEquals(['Infantis', 'Gestantes', 'Idosos']),
      );
      expect(
        audiences('Febre amarela'),
        unorderedEquals(['Infantis', 'Juvenis', 'Gestantes', 'Idosos']),
      );
      expect(
        audiences('Meningocócica ACWY'),
        unorderedEquals(['Infantis', 'Juvenis']),
      );
      expect(audiences('VSR'), ['Gestantes']);
    },
  );

  test('unknown vaccines retain all explicitly registered audiences', () {
    const vaccine = Vaccine(
      id: 'new-vaccine',
      name: 'Nova vacina',
      targetGroups: ['Crianças', 'Adolescentes', 'Gestantes', 'Idosos'],
    );

    expect(
      VaccineAudienceGuidance.categoriesForVaccine(vaccine),
      unorderedEquals(['Infantis', 'Juvenis', 'Gestantes', 'Idosos']),
    );
  });

  test('similar vaccine names keep distinct age indications', () {
    String audience(String name) => VaccineAudienceGuidance.forVaccine(
      Vaccine(id: 'remote-id', name: name),
      'Infantis',
    )!.description;

    expect(audience('Tríplice bacteriana (DTP)'), contains('15 meses'));
    expect(audience('dTpa'), contains('20ª semana'));
    expect(audience('dT'), contains('7 anos'));
    expect(audience('TRIPLICE VIRAL (SCR)'), contains('1 ano e aos 15 meses'));
    expect(audience('Pneumocócica 10-valente'), contains('Em 2026'));
    expect(
      VaccineAudienceGuidance.forVaccine(
        const Vaccine(id: 'unknown', name: 'Pneumocócica 13-valente'),
        'Infantis',
      ),
      isNull,
    );
  });

  test('remote short names and IDs resolve without changing the catalog', () {
    for (final vaccine in const [
      Vaccine(id: 'remote-id', name: 'Nome cadastrado', shortName: 'VIP'),
      Vaccine(id: 'poliomielite', name: 'Nome cadastrado'),
    ]) {
      expect(
        VaccineAudienceGuidance.forVaccine(vaccine, 'Infantis')!.description,
        contains('reforços aos 15 meses (1 ano e 3 meses) e aos 4 anos'),
      );
    }
  });

  for (final (category, vaccineName, expectedAge) in const [
    ('Infantis', 'BCG', 'antes de completar 5 anos'),
    (
      'Infantis',
      'Tríplice bacteriana (DTP)',
      '15 meses (1 ano e 3 meses) e aos 4 anos',
    ),
    ('Infantis', 'Hepatite A', '15 meses'),
    ('Juvenis', 'HPV', '9 a 14 anos'),
    ('Gestantes', 'dTpa', '20ª semana'),
    ('Gestantes', 'Hepatite B', 'início da gravidez'),
    ('Gestantes', 'Influenza', 'qualquer fase da gravidez'),
    ('Idosos', 'Influenza', '60 anos'),
    ('Idosos', 'Covid-19', 'a cada 6 meses'),
    ('Idosos', 'Febre amarela', 'conversar com a equipe do posto de saúde'),
  ]) {
    testWidgets('$vaccineName in $category shows researched age and source', (
      tester,
    ) async {
      await _openDetails(
        tester,
        Vaccine(
          id: 'remote-id',
          name: vaccineName,
          recommendedAge: 'Texto antigo do cadastro',
          targetGroups: [category],
        ),
        category,
      );
      expect(find.text('Quem deve tomar'), findsOneWidget);
      expect(find.textContaining(expectedAge), findsOneWidget);
      expect(find.text('Texto antigo do cadastro'), findsNothing);
      final source = find.text('Consultar no Ministério da Saúde');
      await tester.ensureVisible(source);
      await tester.pumpAndSettle();
      expect(source, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unknown remote vaccine retains its registered age', (
    tester,
  ) async {
    await _openDetails(
      tester,
      const Vaccine(
        id: 'new-vaccine',
        name: 'Nova vacina no catálogo',
        recommendedAge: 'Faixa etária específica informada no cadastro',
      ),
      'Infantis',
    );
    expect(
      find.text('Faixa etária específica informada no cadastro'),
      findsOneWidget,
    );
    expect(find.text('Fonte oficial'), findsNothing);
    expect(find.text('Consultar no Ministério da Saúde'), findsNothing);
  });

  testWidgets(
    'Covid-19 appears for children, pregnant people and older adults',
    (tester) async {
      tester.view.physicalSize = const Size(430, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: VaccinesScreen(
            authRepository: _AuthFake(),
            vaccinationRepository: _CatalogFake(
              const Vaccine(
                id: 'covid-19',
                name: 'Covid-19',
                targetGroups: ['Gestantes'],
              ),
            ),
            walletController: WalletSelectionController(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('vaccine-card-Covid-19'));
      expect(card, findsOneWidget);

      await tester.tap(find.byKey(const Key('vaccine-category-Juvenis')));
      await tester.pumpAndSettle();
      expect(card, findsNothing);

      final categoryScroller = find.descendant(
        of: find.byKey(const Key('vaccine-category-filters')),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(categoryScroller, const Offset(-260, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('vaccine-category-Gestantes')));
      await tester.pumpAndSettle();
      expect(card, findsOneWidget);

      await tester.tap(find.byKey(const Key('vaccine-category-Idosos')));
      await tester.pumpAndSettle();
      expect(card, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _openDetails(
  WidgetTester tester,
  Vaccine vaccine,
  String category,
) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: VaccinesScreen(
        authRepository: _AuthFake(),
        vaccinationRepository: _CatalogFake(vaccine),
        walletController: WalletSelectionController(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final filter = find.byKey(Key('vaccine-category-$category'));
  await tester.ensureVisible(filter);
  await tester.tap(filter);
  await tester.pumpAndSettle();
  final card = find.byKey(Key('vaccine-card-${vaccine.name}'));
  await tester.ensureVisible(card);
  await tester.tap(card);
  await tester.pumpAndSettle();
}

class _AuthFake implements AuthRepository {
  @override
  Future<AppUser?> getCurrentUser() async => const AppUser(
    uid: 'test-user',
    name: 'Pessoa de teste',
    email: 'teste@example.com',
    role: 'responsible',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CatalogFake implements VaccinationRepository {
  _CatalogFake(this.vaccine);
  final Vaccine vaccine;

  @override
  Future<List<Vaccine>> getVaccines() async => [vaccine];

  @override
  Stream<List<VaccinationRecord>> watchRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
