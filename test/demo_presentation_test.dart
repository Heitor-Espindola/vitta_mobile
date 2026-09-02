import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/app/demo/demo_presentation.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';

void main() {
  test('modo de demonstração preenche uma carteira vazia localmente', () {
    final records = DemoPresentation.recordsForPresentation(
      const <VaccinationRecord>[],
      enabled: true,
    );

    expect(records, hasLength(6));
    expect(
      records.map((record) => record.vaccineName),
      containsAll(<String>[
        'BCG',
        'Hepatite B',
        'Tríplice Viral',
        'HPV',
        'Influenza',
        'Febre Amarela',
      ]),
    );
    expect(
      records.every((record) => record.source == 'demo_presentation'),
      isTrue,
    );
  });

  test('registros reais têm prioridade sobre os dados de demonstração', () {
    const realRecord = VaccinationRecord(
      id: 'real-record',
      patientId: 'person-1',
      vaccineName: 'Vacina real',
    );

    final records = DemoPresentation.recordsForPresentation(
      const <VaccinationRecord>[realRecord],
      enabled: true,
    );

    expect(records, <VaccinationRecord>[realRecord]);
  });

  test('notificações demonstrativas só aparecem com carteira vazia', () {
    final notifications = DemoPresentation.notificationsForPresentation(
      const <VaccinationRecord>[],
      enabled: true,
    );

    expect(notifications, hasLength(5));
    expect(
      notifications.map((notification) => notification.message),
      contains('Sua dose de Influenza está atrasada.'),
    );
    expect(
      DemoPresentation.notificationsForPresentation(<VaccinationRecord>[
        VaccinationRecord(
          id: 'real-record',
          vaccineName: 'Vacina real',
          nextDoseAt: DateTime.now().add(const Duration(days: 2)),
        ),
      ], enabled: true).map((item) => item.id),
      contains('upcoming-real-record'),
    );
  });

  test(
    'modo de demonstração desligado não injeta registros nem notificações',
    () {
      expect(
        DemoPresentation.recordsForPresentation(
          const <VaccinationRecord>[],
          enabled: false,
        ),
        isEmpty,
      );
      expect(
        DemoPresentation.notificationsForPresentation(
          const <VaccinationRecord>[],
          enabled: false,
        ),
        isEmpty,
      );
    },
  );
}
