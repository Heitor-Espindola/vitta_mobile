part of 'mobile_connector.dart';

class UpsertAccessibleEmergencyContactVariablesBuilder {
  String patientId;
  String name;
  String phone;
  String relationship;

  final FirebaseDataConnect _dataConnect;
  UpsertAccessibleEmergencyContactVariablesBuilder(
    this._dataConnect, {
    required this.patientId,
    required this.name,
    required this.phone,
    required this.relationship,
  });
  Deserializer<UpsertAccessibleEmergencyContactData> dataDeserializer =
      (dynamic json) =>
          UpsertAccessibleEmergencyContactData.fromJson(jsonDecode(json));
  Serializer<UpsertAccessibleEmergencyContactVariables> varsSerializer =
      (UpsertAccessibleEmergencyContactVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    OperationResult<
      UpsertAccessibleEmergencyContactData,
      UpsertAccessibleEmergencyContactVariables
    >
  >
  execute() {
    return ref().execute();
  }

  MutationRef<
    UpsertAccessibleEmergencyContactData,
    UpsertAccessibleEmergencyContactVariables
  >
  ref() {
    UpsertAccessibleEmergencyContactVariables vars =
        UpsertAccessibleEmergencyContactVariables(
          patientId: patientId,
          name: name,
          phone: phone,
          relationship: relationship,
        );
    return _dataConnect.mutation(
      "UpsertAccessibleEmergencyContact",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class UpsertAccessibleEmergencyContactEmergencyContactUpsert {
  final String userId;
  UpsertAccessibleEmergencyContactEmergencyContactUpsert.fromJson(dynamic json)
    : userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertAccessibleEmergencyContactEmergencyContactUpsert otherTyped =
        other as UpsertAccessibleEmergencyContactEmergencyContactUpsert;
    return userId == otherTyped.userId;
  }

  @override
  int get hashCode => userId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  UpsertAccessibleEmergencyContactEmergencyContactUpsert({
    required this.userId,
  });
}

@immutable
class UpsertAccessibleEmergencyContactData {
  final UpsertAccessibleEmergencyContactEmergencyContactUpsert
  emergencyContact_upsert;
  UpsertAccessibleEmergencyContactData.fromJson(dynamic json)
    : emergencyContact_upsert =
          UpsertAccessibleEmergencyContactEmergencyContactUpsert.fromJson(
            json['emergencyContact_upsert'],
          );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertAccessibleEmergencyContactData otherTyped =
        other as UpsertAccessibleEmergencyContactData;
    return emergencyContact_upsert == otherTyped.emergencyContact_upsert;
  }

  @override
  int get hashCode => emergencyContact_upsert.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['emergencyContact_upsert'] = emergencyContact_upsert.toJson();
    return json;
  }

  UpsertAccessibleEmergencyContactData({required this.emergencyContact_upsert});
}

@immutable
class UpsertAccessibleEmergencyContactVariables {
  final String patientId;
  final String name;
  final String phone;
  final String relationship;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpsertAccessibleEmergencyContactVariables.fromJson(Map<String, dynamic> json)
    : patientId = nativeFromJson<String>(json['patientId']),
      name = nativeFromJson<String>(json['name']),
      phone = nativeFromJson<String>(json['phone']),
      relationship = nativeFromJson<String>(json['relationship']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpsertAccessibleEmergencyContactVariables otherTyped =
        other as UpsertAccessibleEmergencyContactVariables;
    return patientId == otherTyped.patientId &&
        name == otherTyped.name &&
        phone == otherTyped.phone &&
        relationship == otherTyped.relationship;
  }

  @override
  int get hashCode => Object.hashAll([
    patientId.hashCode,
    name.hashCode,
    phone.hashCode,
    relationship.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['patientId'] = nativeToJson<String>(patientId);
    json['name'] = nativeToJson<String>(name);
    json['phone'] = nativeToJson<String>(phone);
    json['relationship'] = nativeToJson<String>(relationship);
    return json;
  }

  UpsertAccessibleEmergencyContactVariables({
    required this.patientId,
    required this.name,
    required this.phone,
    required this.relationship,
  });
}
