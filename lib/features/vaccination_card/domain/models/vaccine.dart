class Vaccine {
  const Vaccine({
    required this.id,
    required this.name,
    this.shortName,
    this.description,
    this.recommendedAge,
    this.doseCount,
    this.intervalDays,
    this.prevents = const [],
    this.targetGroups = const [],
    this.doseSchedule = const [],
    this.expectedReactions = const [],
    this.warningSigns = const [],
    this.contraindications = const [],
    this.sourceName,
    this.sourceUrl,
    this.sourceUpdatedAt,
    this.calendarVersion,
    this.active = true,
  });

  final String id;
  final String name;
  final String? shortName;
  final String? description;
  final String? recommendedAge;
  final int? doseCount;
  final int? intervalDays;
  final List<String> prevents;
  final List<String> targetGroups;
  final List<Object?> doseSchedule;
  final List<String> expectedReactions;
  final List<String> warningSigns;
  final List<String> contraindications;
  final String? sourceName;
  final String? sourceUrl;
  final DateTime? sourceUpdatedAt;
  final String? calendarVersion;
  final bool active;

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      shortName: map['shortName'] as String?,
      description: map['description'] as String?,
      recommendedAge: map['recommendedAge'] as String?,
      doseCount: _intFromMap(map['doseCount']),
      intervalDays: _intFromMap(map['intervalDays']),
      prevents: _stringList(map['prevents']),
      targetGroups: _stringList(map['targetGroups']),
      doseSchedule: _objectList(map['doseSchedule']),
      expectedReactions: _stringList(map['expectedReactions']),
      warningSigns: _stringList(map['warningSigns']),
      contraindications: _stringList(map['contraindications']),
      sourceName: map['sourceName'] as String?,
      sourceUrl: map['sourceUrl'] as String?,
      sourceUpdatedAt: _dateFromMap(map['sourceUpdatedAt']),
      calendarVersion: map['calendarVersion'] as String?,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'description': description,
      'recommendedAge': recommendedAge,
      'doseCount': doseCount,
      'intervalDays': intervalDays,
      'prevents': prevents,
      'targetGroups': targetGroups,
      'doseSchedule': doseSchedule,
      'expectedReactions': expectedReactions,
      'warningSigns': warningSigns,
      'contraindications': contraindications,
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
      'sourceUpdatedAt': sourceUpdatedAt,
      'calendarVersion': calendarVersion,
      'active': active,
    };
  }

  Vaccine copyWith({
    String? id,
    String? name,
    String? shortName,
    String? description,
    String? recommendedAge,
    int? doseCount,
    int? intervalDays,
    List<String>? prevents,
    List<String>? targetGroups,
    List<Object?>? doseSchedule,
    List<String>? expectedReactions,
    List<String>? warningSigns,
    List<String>? contraindications,
    String? sourceName,
    String? sourceUrl,
    DateTime? sourceUpdatedAt,
    String? calendarVersion,
    bool? active,
  }) {
    return Vaccine(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      description: description ?? this.description,
      recommendedAge: recommendedAge ?? this.recommendedAge,
      doseCount: doseCount ?? this.doseCount,
      intervalDays: intervalDays ?? this.intervalDays,
      prevents: prevents ?? this.prevents,
      targetGroups: targetGroups ?? this.targetGroups,
      doseSchedule: doseSchedule ?? this.doseSchedule,
      expectedReactions: expectedReactions ?? this.expectedReactions,
      warningSigns: warningSigns ?? this.warningSigns,
      contraindications: contraindications ?? this.contraindications,
      sourceName: sourceName ?? this.sourceName,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceUpdatedAt: sourceUpdatedAt ?? this.sourceUpdatedAt,
      calendarVersion: calendarVersion ?? this.calendarVersion,
      active: active ?? this.active,
    );
  }
}

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const [];

List<Object?> _objectList(Object? value) =>
    value is List ? List<Object?>.unmodifiable(value) : const [];

DateTime? _dateFromMap(Object? value) {
  if (value is DateTime) return value;
  try {
    return (value as dynamic)?.toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}

int? _intFromMap(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}
