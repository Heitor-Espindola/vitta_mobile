import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/notifications/domain/models/vaccination_notification.dart';
import 'package:vitta_mobile/features/notifications/domain/services/vaccination_notification_service.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccines/domain/models/patient_vaccine_summary.dart';

void main() {
  final now = DateTime(2026, 8, 24, 12);

  test('catalog is crossed with latest record without claiming completion', () {
    const vaccines = [
      Vaccine(id: 'bcg', name: 'BCG'),
      Vaccine(id: 'hpv', name: 'HPV'),
    ];
    final records = [
      VaccinationRecord(
        id: 'old',
        patientId: 'person-1',
        vaccineId: 'bcg',
        vaccineName: 'BCG',
        doseLabel: '1ª dose',
        appliedAt: DateTime(2026, 1, 1),
      ),
      VaccinationRecord(
        id: 'latest',
        patientId: 'person-1',
        vaccineId: 'bcg',
        vaccineName: 'BCG',
        doseLabel: '2ª dose',
        appliedAt: DateTime(2026, 8, 1),
        nextDoseAt: DateTime(2026, 9, 1),
      ),
    ];

    final result = PatientVaccineSummary.combine(vaccines, records);

    expect(result, hasLength(2));
    expect(result.first.latestRecord?.id, 'latest');
    expect(result.first.status(now: now), PatientVaccineStatus.upcoming);
    expect(result.last.status(now: now), PatientVaccineStatus.notApplied);
  });

  test('notifications derive overdue, upcoming and applied events', () {
    final records = [
      VaccinationRecord(
        id: 'late',
        patientId: 'person-1',
        vaccineName: 'Hepatite B',
        doseLabel: '2ª dose',
        appliedAt: DateTime(2026, 1, 1),
        nextDoseAt: DateTime(2026, 8, 20),
      ),
      VaccinationRecord(
        id: 'next',
        patientId: 'person-1',
        vaccineName: 'HPV',
        doseLabel: '1ª dose',
        appliedAt: DateTime(2026, 8, 1),
        nextDoseAt: DateTime(2026, 8, 25),
      ),
    ];

    final notifications = VaccinationNotificationService.derive(
      records,
      now: now,
    );

    expect(
      notifications.map((item) => item.kind),
      containsAll([
        VaccinationNotificationKind.overdue,
        VaccinationNotificationKind.upcoming,
        VaccinationNotificationKind.applied,
      ]),
    );
    expect(
      notifications
          .singleWhere(
            (item) => item.kind == VaccinationNotificationKind.upcoming,
          )
          .message,
      contains('amanhã'),
    );
  });
}
