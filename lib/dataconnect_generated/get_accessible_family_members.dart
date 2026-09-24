part of 'mobile_connector.dart';

class GetAccessibleFamilyMembersVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetAccessibleFamilyMembersVariablesBuilder(this._dataConnect);
  Deserializer<GetAccessibleFamilyMembersData> dataDeserializer =
      (dynamic json) =>
          GetAccessibleFamilyMembersData.fromJson(jsonDecode(json));

  Future<QueryResult<GetAccessibleFamilyMembersData, void>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetAccessibleFamilyMembersData, void> ref() {
    return _dataConnect.query(
      "GetAccessibleFamilyMembers",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetAccessibleFamilyMembersPatientAccesses {
  final EnumValue<PatientAccessKind> accessKind;
  final bool receiveNotifications;
  final Timestamp? validUntil;
  final GetAccessibleFamilyMembersPatientAccessesPatient patient;
  GetAccessibleFamilyMembersPatientAccesses.fromJson(dynamic json)
    : accessKind = patientAccessKindDeserializer(json['accessKind']),
      receiveNotifications = nativeFromJson<bool>(json['receiveNotifications']),
      validUntil = json['validUntil'] == null
          ? null
          : Timestamp.fromJson(json['validUntil']),
      patient = GetAccessibleFamilyMembersPatientAccessesPatient.fromJson(
        json['patient'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessibleFamilyMembersPatientAccesses otherTyped =
        other as GetAccessibleFamilyMembersPatientAccesses;
    return accessKind == otherTyped.accessKind &&
        receiveNotifications == otherTyped.receiveNotifications &&
        validUntil == otherTyped.validUntil &&
        patient == otherTyped.patient;
  }

  @override
  int get hashCode => Object.hashAll([
    accessKind.hashCode,
    receiveNotifications.hashCode,
    validUntil.hashCode,
    patient.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['accessKind'] = patientAccessKindSerializer(accessKind);
    json['receiveNotifications'] = nativeToJson<bool>(receiveNotifications);
    if (validUntil != null) {
      json['validUntil'] = validUntil!.toJson();
    }
    json['patient'] = patient.toJson();
    return json;
  }

  GetAccessibleFamilyMembersPatientAccesses({
    required this.accessKind,
    required this.receiveNotifications,
    this.validUntil,
    required this.patient,
  });
}

@immutable
class GetAccessibleFamilyMembersPatientAccessesPatient {
  final String id;
  final EnumValue<PatientType> patientType;
  final String? legacyPersonId;
  final GetAccessibleFamilyMembersPatientAccessesPatientUser user;
  GetAccessibleFamilyMembersPatientAccessesPatient.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      patientType = patientTypeDeserializer(json['patientType']),
      legacyPersonId = json['legacyPersonId'] == null
          ? null
          : nativeFromJson<String>(json['legacyPersonId']),
      user = GetAccessibleFamilyMembersPatientAccessesPatientUser.fromJson(
        json['user'],
      );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessibleFamilyMembersPatientAccessesPatient otherTyped =
        other as GetAccessibleFamilyMembersPatientAccessesPatient;
    return id == otherTyped.id &&
        patientType == otherTyped.patientType &&
        legacyPersonId == otherTyped.legacyPersonId &&
        user == otherTyped.user;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    patientType.hashCode,
    legacyPersonId.hashCode,
    user.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['patientType'] = patientTypeSerializer(patientType);
    if (legacyPersonId != null) {
      json['legacyPersonId'] = nativeToJson<String?>(legacyPersonId);
    }
    json['user'] = user.toJson();
    return json;
  }

  GetAccessibleFamilyMembersPatientAccessesPatient({
    required this.id,
    required this.patientType,
    this.legacyPersonId,
    required this.user,
  });
}

@immutable
class GetAccessibleFamilyMembersPatientAccessesPatientUser {
  final String id;
  final String name;
  final DateTime birthDate;
  final String? email;
  final EnumValue<UserStatus> status;
  final String cpf;
  final String? sex;
  final String? phone;
  final String? photoUrl;
  GetAccessibleFamilyMembersPatientAccessesPatientUser.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      name = nativeFromJson<String>(json['name']),
      birthDate = nativeFromJson<DateTime>(json['birthDate']),
      email = json['email'] == null
          ? null
          : nativeFromJson<String>(json['email']),
      status = userStatusDeserializer(json['status']),
      cpf = nativeFromJson<String>(json['cpf']),
      sex = json['sex'] == null ? null : nativeFromJson<String>(json['sex']),
      phone = json['phone'] == null
          ? null
          : nativeFromJson<String>(json['phone']),
      photoUrl = json['photoUrl'] == null
          ? null
          : nativeFromJson<String>(json['photoUrl']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessibleFamilyMembersPatientAccessesPatientUser otherTyped =
        other as GetAccessibleFamilyMembersPatientAccessesPatientUser;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        birthDate == otherTyped.birthDate &&
        email == otherTyped.email &&
        status == otherTyped.status &&
        cpf == otherTyped.cpf &&
        sex == otherTyped.sex &&
        phone == otherTyped.phone &&
        photoUrl == otherTyped.photoUrl;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    name.hashCode,
    birthDate.hashCode,
    email.hashCode,
    status.hashCode,
    cpf.hashCode,
    sex.hashCode,
    phone.hashCode,
    photoUrl.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['birthDate'] = nativeToJson<DateTime>(birthDate);
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    json['status'] = userStatusSerializer(status);
    json['cpf'] = nativeToJson<String>(cpf);
    if (sex != null) {
      json['sex'] = nativeToJson<String?>(sex);
    }
    if (phone != null) {
      json['phone'] = nativeToJson<String?>(phone);
    }
    if (photoUrl != null) {
      json['photoUrl'] = nativeToJson<String?>(photoUrl);
    }
    return json;
  }

  GetAccessibleFamilyMembersPatientAccessesPatientUser({
    required this.id,
    required this.name,
    required this.birthDate,
    this.email,
    required this.status,
    required this.cpf,
    this.sex,
    this.phone,
    this.photoUrl,
  });
}

@immutable
class GetAccessibleFamilyMembersData {
  final List<GetAccessibleFamilyMembersPatientAccesses> patientAccesses;
  GetAccessibleFamilyMembersData.fromJson(dynamic json)
    : patientAccesses = (json['patientAccesses'] as List<dynamic>)
          .map((e) => GetAccessibleFamilyMembersPatientAccesses.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessibleFamilyMembersData otherTyped =
        other as GetAccessibleFamilyMembersData;
    return patientAccesses == otherTyped.patientAccesses;
  }

  @override
  int get hashCode => patientAccesses.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['patientAccesses'] = patientAccesses.map((e) => e.toJson()).toList();
    return json;
  }

  GetAccessibleFamilyMembersData({required this.patientAccesses});
}
