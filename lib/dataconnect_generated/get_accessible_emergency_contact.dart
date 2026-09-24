part of 'mobile_connector.dart';

class GetAccessibleEmergencyContactVariablesBuilder {
  String patientId;

  final FirebaseDataConnect _dataConnect;
  GetAccessibleEmergencyContactVariablesBuilder(
    this._dataConnect, {
    required this.patientId,
  });
  Deserializer<GetAccessibleEmergencyContactData> dataDeserializer =
      (dynamic json) =>
          GetAccessibleEmergencyContactData.fromJson(jsonDecode(json));
  Serializer<GetAccessibleEmergencyContactVariables> varsSerializer =
      (GetAccessibleEmergencyContactVariables vars) =>
          jsonEncode(vars.toJson());
  Future<
    QueryResult<
      GetAccessibleEmergencyContactData,
      GetAccessibleEmergencyContactVariables
    >
  >
  execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<
    GetAccessibleEmergencyContactData,
    GetAccessibleEmergencyContactVariables
  >
  ref() {
    GetAccessibleEmergencyContactVariables vars =
        GetAccessibleEmergencyContactVariables(patientId: patientId);
    return _dataConnect.query(
      "GetAccessibleEmergencyContact",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class GetAccessibleEmergencyContactPatient {
  final GetAccessibleEmergencyContactPatientUser user;
  GetAccessibleEmergencyContactPatient.fromJson(dynamic json)
    : user = GetAccessibleEmergencyContactPatientUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessibleEmergencyContactPatient otherTyped =
        other as GetAccessibleEmergencyContactPatient;
    return user == otherTyped.user;
  }

  @override
  int get hashCode => user.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user'] = user.toJson();
    return json;
  }

  GetAccessibleEmergencyContactPatient({required this.user});
}

@immutable
class GetAccessibleEmergencyContactPatientUser {
  final GetAccessibleEmergencyContactPatientUserEmergencyContactOnUser?
  emergencyContact_on_user;
  GetAccessibleEmergencyContactPatientUser.fromJson(dynamic json)
    : emergencyContact_on_user = json['emergencyContact_on_user'] == null
          ? null
          : GetAccessibleEmergencyContactPatientUserEmergencyContactOnUser.fromJson(
              json['emergencyContact_on_user'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessibleEmergencyContactPatientUser otherTyped =
        other as GetAccessibleEmergencyContactPatientUser;
    return emergencyContact_on_user == otherTyped.emergencyContact_on_user;
  }

  @override
  int get hashCode => emergencyContact_on_user.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (emergencyContact_on_user != null) {
      json['emergencyContact_on_user'] = emergencyContact_on_user!.toJson();
    }
    return json;
  }

  GetAccessibleEmergencyContactPatientUser({this.emergencyContact_on_user});
}

@immutable
class GetAccessibleEmergencyContactPatientUserEmergencyContactOnUser {
  final String name;
  final String phone;
  final String relationship;
  final Timestamp? updatedAt;
  GetAccessibleEmergencyContactPatientUserEmergencyContactOnUser.fromJson(
    dynamic json,
  ) : name = nativeFromJson<String>(json['name']),
      phone = nativeFromJson<String>(json['phone']),
      relationship = nativeFromJson<String>(json['relationship']),
      updatedAt = json['updatedAt'] == null
          ? null
          : Timestamp.fromJson(json['updatedAt']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessibleEmergencyContactPatientUserEmergencyContactOnUser
    otherTyped =
        other as GetAccessibleEmergencyContactPatientUserEmergencyContactOnUser;
    return name == otherTyped.name &&
        phone == otherTyped.phone &&
        relationship == otherTyped.relationship &&
        updatedAt == otherTyped.updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    name.hashCode,
    phone.hashCode,
    relationship.hashCode,
    updatedAt.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['phone'] = nativeToJson<String>(phone);
    json['relationship'] = nativeToJson<String>(relationship);
    if (updatedAt != null) {
      json['updatedAt'] = updatedAt!.toJson();
    }
    return json;
  }

  GetAccessibleEmergencyContactPatientUserEmergencyContactOnUser({
    required this.name,
    required this.phone,
    required this.relationship,
    this.updatedAt,
  });
}

@immutable
class GetAccessibleEmergencyContactData {
  final GetAccessibleEmergencyContactPatient? patient;
  GetAccessibleEmergencyContactData.fromJson(dynamic json)
    : patient = json['patient'] == null
          ? null
          : GetAccessibleEmergencyContactPatient.fromJson(json['patient']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessibleEmergencyContactData otherTyped =
        other as GetAccessibleEmergencyContactData;
    return patient == otherTyped.patient;
  }

  @override
  int get hashCode => patient.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (patient != null) {
      json['patient'] = patient!.toJson();
    }
    return json;
  }

  GetAccessibleEmergencyContactData({this.patient});
}

@immutable
class GetAccessibleEmergencyContactVariables {
  final String patientId;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  GetAccessibleEmergencyContactVariables.fromJson(Map<String, dynamic> json)
    : patientId = nativeFromJson<String>(json['patientId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessibleEmergencyContactVariables otherTyped =
        other as GetAccessibleEmergencyContactVariables;
    return patientId == otherTyped.patientId;
  }

  @override
  int get hashCode => patientId.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['patientId'] = nativeToJson<String>(patientId);
    return json;
  }

  GetAccessibleEmergencyContactVariables({required this.patientId});
}
