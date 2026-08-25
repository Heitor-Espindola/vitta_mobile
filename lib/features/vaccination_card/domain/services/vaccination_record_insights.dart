import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';

enum VaccinationRecordSituation { applied, upcoming, overdue }

abstract final class VaccinationRecordInsights {
  static bool isApplied(VaccinationRecord record) =>
      record.effectiveAppliedAt != null;

  static int appliedCount(Iterable<VaccinationRecord> records) =>
      records.where(isApplied).length;

  static VaccinationRecordSituation situation(
    VaccinationRecord record, {
    DateTime? now,
  }) {
    final nextDose = record.effectiveNextDoseAt;
    if (nextDose == null) return VaccinationRecordSituation.applied;
    final today = _dateOnly(now ?? DateTime.now());
    return _dateOnly(nextDose).isBefore(today)
        ? VaccinationRecordSituation.overdue
        : VaccinationRecordSituation.upcoming;
  }

  static List<VaccinationRecord> recentApplied(
    Iterable<VaccinationRecord> records, {
    int limit = 3,
  }) {
    final result = records.where(isApplied).toList()
      ..sort((a, b) => _recordDate(b).compareTo(_recordDate(a)));
    return result.take(limit).toList(growable: false);
  }

  static List<VaccinationRecord> latestByVaccine(
    Iterable<VaccinationRecord> records,
  ) {
    final latest = <String, VaccinationRecord>{};
    for (final record in records) {
      final id = record.vaccineId?.trim();
      final key = id != null && id.isNotEmpty
          ? id
          : record.vaccineName.trim().toLowerCase();
      if (key.isEmpty) continue;
      final current = latest[key];
      if (current == null ||
          _recordDate(record).isAfter(_recordDate(current))) {
        latest[key] = record;
      }
    }
    return latest.values.toList(growable: false);
  }

  static List<VaccinationRecord> nextDoses(
    Iterable<VaccinationRecord> records,
  ) {
    final result =
        latestByVaccine(
          records,
        ).where((record) => record.effectiveNextDoseAt != null).toList()..sort(
          (a, b) => a.effectiveNextDoseAt!.compareTo(b.effectiveNextDoseAt!),
        );
    return result;
  }

  static DateTime _recordDate(VaccinationRecord record) =>
      record.effectiveAppliedAt ??
      record.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
