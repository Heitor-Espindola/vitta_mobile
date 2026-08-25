import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/services/vaccination_record_insights.dart';

void main() {
  group('VaccinationRecord', () {
    test('parses official Firestore fields and Timestamp values safely', () {
      final appliedAt = DateTime.utc(2026, 8, 18, 14, 30);
      final record = VaccinationRecord.fromMap({
        'id': 'record-1',
        'patientId': 'patient-1',
        'vaccineId': 'bcg',
        'vaccineName': 'BCG',
        'doseLabel': 'Dose única',
        'doseNumber': 1,
        'appliedAt': Timestamp.fromDate(appliedAt),
        'professionalUid': 'professional-1',
        'source': 'professional_panel',
        'createdAt': Timestamp.fromDate(appliedAt),
        'updatedAt': Timestamp.fromDate(appliedAt),
      });

      expect(record.patientId, 'patient-1');
      expect(record.doseLabel, 'Dose única');
      expect(
        record.appliedAt?.millisecondsSinceEpoch,
        appliedAt.millisecondsSinceEpoch,
      );
      expect(record.nextDoseAt, isNull);
      expect(record.lot, isNull);
      expect(record.toFirestore(), containsPair('patientId', 'patient-1'));
      expect(record.toFirestore(), isNot(contains('patientUid')));
      expect(record.toFirestore(), isNot(contains('status')));
    });

    test('accepts absent optional fields and legacy names', () {
      final record = VaccinationRecord.fromMap({
        'id': 'legacy',
        'personId': 'patient-legacy',
        'vaccineName': 'Influenza',
        'dose': 'Reforço anual',
        'applicationDate': DateTime(2026, 8, 3),
        'batchNumber': 'LOT-1',
      });

      expect(record.effectivePatientUid, 'patient-legacy');
      expect(record.doseLabel, 'Reforço anual');
      expect(record.lot, 'LOT-1');
      expect(record.manufacturer, isNull);
    });
  });

  group('VaccinationRecordInsights', () {
    final now = DateTime(2026, 8, 24, 12);

    VaccinationRecord record({
      required String id,
      required String vaccineId,
      required DateTime appliedAt,
      DateTime? nextDoseAt,
    }) => VaccinationRecord(
      id: id,
      patientUid: 'patient',
      vaccineId: vaccineId,
      vaccineName: vaccineId,
      doseLabel: 'Dose',
      appliedAt: appliedAt,
      nextDoseAt: nextDoseAt,
    );

    test('counts and orders the latest applied records', () {
      final records = [
        record(id: 'old', vaccineId: 'a', appliedAt: DateTime(2026, 1, 1)),
        record(id: 'new', vaccineId: 'b', appliedAt: DateTime(2026, 8, 20)),
      ];

      expect(VaccinationRecordInsights.appliedCount(records), 2);
      expect(VaccinationRecordInsights.recentApplied(records).first.id, 'new');
    });

    test('derives upcoming and overdue situations from nextDoseAt', () {
      final future = record(
        id: 'future',
        vaccineId: 'a',
        appliedAt: DateTime(2026, 8, 1),
        nextDoseAt: DateTime(2026, 9, 1),
      );
      final overdue = record(
        id: 'overdue',
        vaccineId: 'b',
        appliedAt: DateTime(2026, 7, 1),
        nextDoseAt: DateTime(2026, 8, 23),
      );

      expect(
        VaccinationRecordInsights.situation(future, now: now),
        VaccinationRecordSituation.upcoming,
      );
      expect(
        VaccinationRecordInsights.situation(overdue, now: now),
        VaccinationRecordSituation.overdue,
      );
    });

    test('uses only the latest record per vaccine for next doses', () {
      final old = record(
        id: 'dose-1',
        vaccineId: 'hepatitis-b',
        appliedAt: DateTime(2026, 1, 1),
        nextDoseAt: DateTime(2026, 2, 1),
      );
      final latest = record(
        id: 'dose-2',
        vaccineId: 'hepatitis-b',
        appliedAt: DateTime(2026, 8, 1),
        nextDoseAt: DateTime(2026, 9, 1),
      );

      final nextDoses = VaccinationRecordInsights.nextDoses([old, latest]);
      expect(nextDoses, hasLength(1));
      expect(nextDoses.single.id, 'dose-2');
      expect(VaccinationRecordInsights.nextDoses(const []), isEmpty);
    });
  });
}
