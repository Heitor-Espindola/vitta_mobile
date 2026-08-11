import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';

class VaccinationSchedule {
  const VaccinationSchedule({
    required this.id,
    required this.version,
    required this.sourceName,
    this.sourceUrl,
    this.publishedAt,
    this.active = false,
    this.entries = const [],
  });

  final String id;
  final String version;
  final String sourceName;
  final String? sourceUrl;
  final DateTime? publishedAt;
  final bool active;
  final List<VaccinationScheduleEntry> entries;

  factory VaccinationSchedule.fromMap(Map<String, dynamic> map) {
    final rawEntries = map['entries'];
    return VaccinationSchedule(
      id: map['id'] as String? ?? '',
      version: map['version'] as String? ?? '',
      sourceName:
          map['sourceName'] as String? ?? map['source'] as String? ?? '',
      sourceUrl: map['sourceUrl'] as String?,
      publishedAt: dateTimeFromMap(map['publishedAt']),
      active: map['active'] as bool? ?? false,
      entries: rawEntries is List
          ? rawEntries
                .whereType<Map>()
                .map(
                  (entry) => VaccinationScheduleEntry.fromMap(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

class VaccinationScheduleEntry {
  const VaccinationScheduleEntry({
    required this.vaccineId,
    required this.doseNumber,
    this.recommendedAge,
    this.minAgeDays,
    this.maxAgeDays,
    this.intervalDays,
    this.targetGroup,
    this.notes,
  });

  final String vaccineId;
  final String doseNumber;
  final String? recommendedAge;
  final int? minAgeDays;
  final int? maxAgeDays;
  final int? intervalDays;
  final String? targetGroup;
  final String? notes;

  factory VaccinationScheduleEntry.fromMap(Map<String, dynamic> map) =>
      VaccinationScheduleEntry(
        vaccineId: map['vaccineId'] as String? ?? '',
        doseNumber: map['doseNumber']?.toString() ?? '',
        recommendedAge: map['recommendedAge'] as String?,
        minAgeDays: _asInt(map['minAgeDays']),
        maxAgeDays: _asInt(map['maxAgeDays']),
        intervalDays: _asInt(map['intervalDays']),
        targetGroup: map['targetGroup'] as String?,
        notes: map['notes'] as String?,
      );
}

int? _asInt(Object? value) => value is num ? value.toInt() : null;
