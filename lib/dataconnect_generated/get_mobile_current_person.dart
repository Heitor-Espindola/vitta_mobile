part of 'mobile_connector.dart';

class GetMobileCurrentPersonVariablesBuilder {
  final FirebaseDataConnect _dataConnect;
  GetMobileCurrentPersonVariablesBuilder(this._dataConnect);
  Deserializer<GetMobileCurrentPersonData> dataDeserializer = (dynamic json) =>
      GetMobileCurrentPersonData.fromJson(jsonDecode(json));

  Future<QueryResult<GetMobileCurrentPersonData, void>> execute({
    QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache,
  }) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetMobileCurrentPersonData, void> ref() {
    return _dataConnect.query(
      "GetMobileCurrentPerson",
      dataDeserializer,
      emptySerializer,
      null,
    );
  }
}

@immutable
class GetMobileCurrentPersonUsers {
  final String id;
  final String name;
  final DateTime birthDate;
  final String? email;
  final String? authUid;
  final EnumValue<UserStatus> status;
  final String cpf;
  final String? sex;
  final String? phone;
  final String? photoUrl;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? lastLoginAt;
  final GetMobileCurrentPersonUsersPatientOnUser? patient_on_user;
  GetMobileCurrentPersonUsers.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      name = nativeFromJson<String>(json['name']),
      birthDate = nativeFromJson<DateTime>(json['birthDate']),
      email = json['email'] == null
          ? null
          : nativeFromJson<String>(json['email']),
      authUid = json['authUid'] == null
          ? null
          : nativeFromJson<String>(json['authUid']),
      status = userStatusDeserializer(json['status']),
      cpf = nativeFromJson<String>(json['cpf']),
      sex = json['sex'] == null ? null : nativeFromJson<String>(json['sex']),
      phone = json['phone'] == null
          ? null
          : nativeFromJson<String>(json['phone']),
      photoUrl = json['photoUrl'] == null
          ? null
          : nativeFromJson<String>(json['photoUrl']),
      createdAt = json['createdAt'] == null
          ? null
          : Timestamp.fromJson(json['createdAt']),
      updatedAt = json['updatedAt'] == null
          ? null
          : Timestamp.fromJson(json['updatedAt']),
      lastLoginAt = json['lastLoginAt'] == null
          ? null
          : Timestamp.fromJson(json['lastLoginAt']),
      patient_on_user = json['patient_on_user'] == null
          ? null
          : GetMobileCurrentPersonUsersPatientOnUser.fromJson(
              json['patient_on_user'],
            );
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMobileCurrentPersonUsers otherTyped =
        other as GetMobileCurrentPersonUsers;
    return id == otherTyped.id &&
        name == otherTyped.name &&
        birthDate == otherTyped.birthDate &&
        email == otherTyped.email &&
        authUid == otherTyped.authUid &&
        status == otherTyped.status &&
        cpf == otherTyped.cpf &&
        sex == otherTyped.sex &&
        phone == otherTyped.phone &&
        photoUrl == otherTyped.photoUrl &&
        createdAt == otherTyped.createdAt &&
        updatedAt == otherTyped.updatedAt &&
        lastLoginAt == otherTyped.lastLoginAt &&
        patient_on_user == otherTyped.patient_on_user;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    name.hashCode,
    birthDate.hashCode,
    email.hashCode,
    authUid.hashCode,
    status.hashCode,
    cpf.hashCode,
    sex.hashCode,
    phone.hashCode,
    photoUrl.hashCode,
    createdAt.hashCode,
    updatedAt.hashCode,
    lastLoginAt.hashCode,
    patient_on_user.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['birthDate'] = nativeToJson<DateTime>(birthDate);
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    if (authUid != null) {
      json['authUid'] = nativeToJson<String?>(authUid);
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
    if (createdAt != null) {
      json['createdAt'] = createdAt!.toJson();
    }
    if (updatedAt != null) {
      json['updatedAt'] = updatedAt!.toJson();
    }
    if (lastLoginAt != null) {
      json['lastLoginAt'] = lastLoginAt!.toJson();
    }
    if (patient_on_user != null) {
      json['patient_on_user'] = patient_on_user!.toJson();
    }
    return json;
  }

  GetMobileCurrentPersonUsers({
    required this.id,
    required this.name,
    required this.birthDate,
    this.email,
    this.authUid,
    required this.status,
    required this.cpf,
    this.sex,
    this.phone,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.patient_on_user,
  });
}

@immutable
class GetMobileCurrentPersonUsersPatientOnUser {
  final String id;
  final bool active;
  final EnumValue<PatientType> patientType;
  final String? legacyPersonId;
  GetMobileCurrentPersonUsersPatientOnUser.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']),
      active = nativeFromJson<bool>(json['active']),
      patientType = patientTypeDeserializer(json['patientType']),
      legacyPersonId = json['legacyPersonId'] == null
          ? null
          : nativeFromJson<String>(json['legacyPersonId']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMobileCurrentPersonUsersPatientOnUser otherTyped =
        other as GetMobileCurrentPersonUsersPatientOnUser;
    return id == otherTyped.id &&
        active == otherTyped.active &&
        patientType == otherTyped.patientType &&
        legacyPersonId == otherTyped.legacyPersonId;
  }

  @override
  int get hashCode => Object.hashAll([
    id.hashCode,
    active.hashCode,
    patientType.hashCode,
    legacyPersonId.hashCode,
  ]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['active'] = nativeToJson<bool>(active);
    json['patientType'] = patientTypeSerializer(patientType);
    if (legacyPersonId != null) {
      json['legacyPersonId'] = nativeToJson<String?>(legacyPersonId);
    }
    return json;
  }

  GetMobileCurrentPersonUsersPatientOnUser({
    required this.id,
    required this.active,
    required this.patientType,
    this.legacyPersonId,
  });
}

@immutable
class GetMobileCurrentPersonData {
  final List<GetMobileCurrentPersonUsers> users;
  GetMobileCurrentPersonData.fromJson(dynamic json)
    : users = (json['users'] as List<dynamic>)
          .map((e) => GetMobileCurrentPersonUsers.fromJson(e))
          .toList();
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final GetMobileCurrentPersonData otherTyped =
        other as GetMobileCurrentPersonData;
    return users == otherTyped.users;
  }

  @override
  int get hashCode => users.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  GetMobileCurrentPersonData({required this.users});
}
