import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/services/vaccination_record_insights.dart';

/// UI-only events: an application and its next dose are distinct occurrences.
/// No status is stored or written back to Firestore.
enum VaccinationOccurrenceKind { applied, upcoming, overdue }

class VaccinationOccurrence {
  const VaccinationOccurrence({
    required this.record,
    required this.kind,
    required this.date,
  });

  final VaccinationRecord record;
  final VaccinationOccurrenceKind kind;
  final DateTime date;

  String get label => switch (kind) {
    VaccinationOccurrenceKind.applied => 'Aplicada',
    VaccinationOccurrenceKind.upcoming => 'Próxima',
    VaccinationOccurrenceKind.overdue => 'Atrasada',
  };

  String get datePrefix => switch (kind) {
    VaccinationOccurrenceKind.applied => 'Aplicada em',
    VaccinationOccurrenceKind.upcoming => 'Próxima dose em',
    VaccinationOccurrenceKind.overdue => 'Dose prevista para',
  };

  static List<VaccinationOccurrence> fromRecords(
    Iterable<VaccinationRecord> records, {
    DateTime? now,
  }) {
    final result = <VaccinationOccurrence>[];
    for (final record in records) {
      final applied = record.effectiveAppliedAt;
      if (applied != null) {
        result.add(
          VaccinationOccurrence(
            record: record,
            kind: VaccinationOccurrenceKind.applied,
            date: applied,
          ),
        );
      }
      final next = record.effectiveNextDoseAt;
      if (next != null) {
        final situation = VaccinationRecordInsights.situation(record, now: now);
        result.add(
          VaccinationOccurrence(
            record: record,
            kind: situation == VaccinationRecordSituation.overdue
                ? VaccinationOccurrenceKind.overdue
                : VaccinationOccurrenceKind.upcoming,
            date: next,
          ),
        );
      }
    }
    return result;
  }
}
