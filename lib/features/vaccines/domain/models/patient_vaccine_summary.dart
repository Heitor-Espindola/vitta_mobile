import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/services/vaccination_record_insights.dart';

enum PatientVaccineStatus { applied, upcoming, overdue, notApplied }

class PatientVaccineSummary {
  const PatientVaccineSummary({required this.vaccine, this.latestRecord});

  final Vaccine vaccine;
  final VaccinationRecord? latestRecord;

  bool get hasBeenApplied => latestRecord != null;
  DateTime? get nextDoseAt => latestRecord?.effectiveNextDoseAt;

  PatientVaccineStatus status({DateTime? now}) {
    final record = latestRecord;
    if (record == null) return PatientVaccineStatus.notApplied;
    return switch (VaccinationRecordInsights.situation(record, now: now)) {
      VaccinationRecordSituation.overdue => PatientVaccineStatus.overdue,
      VaccinationRecordSituation.upcoming => PatientVaccineStatus.upcoming,
      VaccinationRecordSituation.applied => PatientVaccineStatus.applied,
    };
  }

  static List<PatientVaccineSummary> combine(
    Iterable<Vaccine> vaccines,
    Iterable<VaccinationRecord> records,
  ) {
    final latest = VaccinationRecordInsights.latestByVaccine(records);
    VaccinationRecord? match(Vaccine vaccine) {
      for (final record in latest) {
        if (record.vaccineId?.trim().isNotEmpty == true &&
            record.vaccineId == vaccine.id) {
          return record;
        }
        if (record.vaccineName.trim().toLowerCase() ==
            vaccine.name.trim().toLowerCase()) {
          return record;
        }
      }
      return null;
    }

    return vaccines
        .map(
          (vaccine) => PatientVaccineSummary(
            vaccine: vaccine,
            latestRecord: match(vaccine),
          ),
        )
        .toList(growable: false);
  }
}
