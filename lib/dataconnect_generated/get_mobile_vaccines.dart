part of 'mobile_connector.dart';

class GetMobileVaccinesVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetMobileVaccinesVariablesBuilder(this._dataConnect);
  Deserializer<GetMobileVaccinesData> dataDeserializer = (dynamic json) =>
      GetMobileVaccinesData.fromJson(jsonDecode(json));

  Future<QueryResult<GetMobileVaccinesData, void>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetMobileVaccinesData, void> ref() {
    return _dataConnect.query(
      "GetMobileVaccines",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetMobileVaccinesVaccines {
  final String id;
  final String? legacyVaccineId;
  final String name;
  final String? shortName;
  final String? description;
  final String? recommendedAge;
  final int requiredDoses;
  final int? intervalDays;
  final List<String>? prevents;
  final List<String>? targetGroups;
  final AnyValue? doseSchedule;
  final List<String>? expectedReactions;
  final List<String>? warningSigns;
  final List<String>? contraindications;
  final String? sourceName;
  final String? sourceUrl;
  final Timestamp? sourceUpdatedAt;
  final String? calendarVersion;
  final bool active;
  GetMobileVaccinesVaccines.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      legacyVaccineId = json['legacyVaccineId'] == null
          ? null
          : nativeFromJson<String>(json['legacyVaccineId']),
      name = nativeFromJson<String>(json['name']),
      shortName = json['shortName'] == null
          ? null
          : nativeFromJson<String>(json['shortName']),
      description = json['description'] == null
          ? null
          : nativeFromJson<String>(json['description']),
      recommendedAge = json['recommendedAge'] == null
          ? null
          : nativeFromJson<String>(json['recommendedAge']),
      requiredDoses = nativeFromJson<int>(json['requiredDoses']),
      intervalDays = json['intervalDays'] == null
          ? null
          : nativeFromJson<int>(json['intervalDays']),
      prevents = json['prevents'] == null
          ? null
          : (json['prevents'] as List<dynamic>)
                .map((e) => nativeFromJson<String>(e))
                .toList(),
      targetGroups = json['targetGroups'] == null
          ? null
          : (json['targetGroups'] as List<dynamic>)
                .map((e) => nativeFromJson<String>(e))
                .toList(),
      doseSchedule = json['doseSchedule'] == null
          ? null
          : AnyValue.fromJson(json['doseSchedule']),
      expectedReactions = json['expectedReactions'] == null
          ? null
          : (json['expectedReactions'] as List<dynamic>)
                .map((e) => nativeFromJson<String>(e))
                .toList(),
      warningSigns = json['warningSigns'] == null
          ? null
          : (json['warningSigns'] as List<dynamic>)
                .map((e) => nativeFromJson<String>(e))
                .toList(),
      contraindications = json['contraindications'] == null
          ? null
          : (json['contraindications'] as List<dynamic>)
                .map((e) => nativeFromJson<String>(e))
                .toList(),
      sourceName = json['sourceName'] == null
          ? null
          : nativeFromJson<String>(json['sourceName']),
      sourceUrl = json['sourceUrl'] == null
          ? null
          : nativeFromJson<String>(json['sourceUrl']),
      sourceUpdatedAt = json['sourceUpdatedAt'] == null
          ? null
          : Timestamp.fromJson(json['sourceUpdatedAt']),
      calendarVersion = json['calendarVersion'] == null
          ? null
          : nativeFromJson<String>(json['calendarVersion']),
      active = nativeFromJson<bool>(json['active']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMobileVaccinesVaccines otherTyped =
        other as GetMobileVaccinesVaccines;
    return id == otherTyped.id &&
        legacyVaccineId == otherTyped.legacyVaccineId &&
        name == otherTyped.name &&
        shortName == otherTyped.shortName &&
        description == otherTyped.description &&
        recommendedAge == otherTyped.recommendedAge &&
        requiredDoses == otherTyped.requiredDoses &&
        intervalDays == otherTyped.intervalDays &&
        prevents == otherTyped.prevents &&
        targetGroups == otherTyped.targetGroups &&
        doseSchedule == otherTyped.doseSchedule &&
        expectedReactions == otherTyped.expectedReactions &&
        warningSigns == otherTyped.warningSigns &&
        contraindications == otherTyped.contraindications &&
        sourceName == otherTyped.sourceName &&
        sourceUrl == otherTyped.sourceUrl &&
        sourceUpdatedAt == otherTyped.sourceUpdatedAt &&
        calendarVersion == otherTyped.calendarVersion &&
        active == otherTyped.active;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    legacyVaccineId.hashCode,
    name.hashCode,
    shortName.hashCode,
    description.hashCode,
    recommendedAge.hashCode,
    requiredDoses.hashCode,
    intervalDays.hashCode,
    prevents.hashCode,
    targetGroups.hashCode,
    doseSchedule.hashCode,
    expectedReactions.hashCode,
    warningSigns.hashCode,
    contraindications.hashCode,
    sourceName.hashCode,
    sourceUrl.hashCode,
    sourceUpdatedAt.hashCode,
    calendarVersion.hashCode,
    active.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (legacyVaccineId != null) {
      json['legacyVaccineId'] = nativeToJson<String?>(legacyVaccineId);
    }
    json['name'] = nativeToJson<String>(name);
    if (shortName != null) {
      json['shortName'] = nativeToJson<String?>(shortName);
    }
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    if (recommendedAge != null) {
      json['recommendedAge'] = nativeToJson<String?>(recommendedAge);
    }
    json['requiredDoses'] = nativeToJson<int>(requiredDoses);
    if (intervalDays != null) {
      json['intervalDays'] = nativeToJson<int?>(intervalDays);
    }
    if (prevents != null) {
      json['prevents'] = prevents?.map((e) => nativeToJson<String>(e)).toList();
    }
    if (targetGroups != null) {
      json['targetGroups'] = targetGroups
          ?.map((e) => nativeToJson<String>(e))
          .toList();
    }
    if (doseSchedule != null) {
      json['doseSchedule'] = doseSchedule!.toJson();
    }
    if (expectedReactions != null) {
      json['expectedReactions'] = expectedReactions
          ?.map((e) => nativeToJson<String>(e))
          .toList();
    }
    if (warningSigns != null) {
      json['warningSigns'] = warningSigns
          ?.map((e) => nativeToJson<String>(e))
          .toList();
    }
    if (contraindications != null) {
      json['contraindications'] = contraindications
          ?.map((e) => nativeToJson<String>(e))
          .toList();
    }
    if (sourceName != null) {
      json['sourceName'] = nativeToJson<String?>(sourceName);
    }
    if (sourceUrl != null) {
      json['sourceUrl'] = nativeToJson<String?>(sourceUrl);
    }
    if (sourceUpdatedAt != null) {
      json['sourceUpdatedAt'] = sourceUpdatedAt!.toJson();
    }
    if (calendarVersion != null) {
      json['calendarVersion'] = nativeToJson<String?>(calendarVersion);
    }
    json['active'] = nativeToJson<bool>(active);
    return json;
  }

  GetMobileVaccinesVaccines({
    required this.id,
    this.legacyVaccineId,
    required this.name,
    this.shortName,
    this.description,
    this.recommendedAge,
    required this.requiredDoses,
    this.intervalDays,
    this.prevents,
    this.targetGroups,
    this.doseSchedule,
    this.expectedReactions,
    this.warningSigns,
    this.contraindications,
    this.sourceName,
    this.sourceUrl,
    this.sourceUpdatedAt,
    this.calendarVersion,
    required this.active,
  });
}

@immutable
class GetMobileVaccinesData {
  final List<GetMobileVaccinesVaccines> vaccines;
  GetMobileVaccinesData.fromJson(dynamic json)
    : vaccines = (json['vaccines'] as List<dynamic>)
          .map((e) => GetMobileVaccinesVaccines.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMobileVaccinesData otherTyped = other as GetMobileVaccinesData;
    return vaccines == otherTyped.vaccines;
  }

  @override
  int get hashCode => vaccines.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['vaccines'] = vaccines.map((e) => e.toJson()).toList();
    return json;
  }

  GetMobileVaccinesData({required this.vaccines});
}
