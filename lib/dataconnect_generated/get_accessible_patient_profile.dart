part of 'mobile_connector.dart';

class GetAccessiblePatientProfileVariablesBuilder {
  String patientId;

  final FirebaseDataConnect _dataConnect;
  GetAccessiblePatientProfileVariablesBuilder(this._dataConnect, {required  this.patientId,});
  Deserializer<GetAccessiblePatientProfileData> dataDeserializer = (dynamic json)  => GetAccessiblePatientProfileData.fromJson(jsonDecode(json));
  Serializer<GetAccessiblePatientProfileVariables> varsSerializer = (GetAccessiblePatientProfileVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetAccessiblePatientProfileData, GetAccessiblePatientProfileVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetAccessiblePatientProfileData, GetAccessiblePatientProfileVariables> ref() {
    GetAccessiblePatientProfileVariables vars= GetAccessiblePatientProfileVariables(patientId: patientId,);
    return _dataConnect.query("GetAccessiblePatientProfile", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetAccessiblePatientProfilePatient {
  final String id;
  final bool active;
  final EnumValue<PatientType> patientType;
  final String? legacyPersonId;
  final GetAccessiblePatientProfilePatientUser user;
  GetAccessiblePatientProfilePatient.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  active = nativeFromJson<bool>(json['active']),
  patientType = patientTypeDeserializer(json['patientType']),
  legacyPersonId = json['legacyPersonId'] == null ? null : nativeFromJson<String>(json['legacyPersonId']),
  user = GetAccessiblePatientProfilePatientUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientProfilePatient otherTyped = other as GetAccessiblePatientProfilePatient;
    return id == otherTyped.id && 
    active == otherTyped.active && 
    patientType == otherTyped.patientType && 
    legacyPersonId == otherTyped.legacyPersonId && 
    user == otherTyped.user;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, active.hashCode, patientType.hashCode, legacyPersonId.hashCode, user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['active'] = nativeToJson<bool>(active);
    json['patientType'] = 
    patientTypeSerializer(patientType)
    ;
    if (legacyPersonId != null) {
      json['legacyPersonId'] = nativeToJson<String?>(legacyPersonId);
    }
    json['user'] = user.toJson();
    return json;
  }

  GetAccessiblePatientProfilePatient({
    required this.id,
    required this.active,
    required this.patientType,
    this.legacyPersonId,
    required this.user,
  });
}

@immutable
class GetAccessiblePatientProfilePatientUser {
  final String id;
  final String name;
  final DateTime birthDate;
  final String? email;
  final EnumValue<UserStatus> status;
  final String cpf;
  final String? sex;
  final String? phone;
  final String? photoUrl;
  GetAccessiblePatientProfilePatientUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']),
  birthDate = nativeFromJson<DateTime>(json['birthDate']),
  email = json['email'] == null ? null : nativeFromJson<String>(json['email']),
  status = userStatusDeserializer(json['status']),
  cpf = nativeFromJson<String>(json['cpf']),
  sex = json['sex'] == null ? null : nativeFromJson<String>(json['sex']),
  phone = json['phone'] == null ? null : nativeFromJson<String>(json['phone']),
  photoUrl = json['photoUrl'] == null ? null : nativeFromJson<String>(json['photoUrl']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientProfilePatientUser otherTyped = other as GetAccessiblePatientProfilePatientUser;
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
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode, birthDate.hashCode, email.hashCode, status.hashCode, cpf.hashCode, sex.hashCode, phone.hashCode, photoUrl.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    json['birthDate'] = nativeToJson<DateTime>(birthDate);
    if (email != null) {
      json['email'] = nativeToJson<String?>(email);
    }
    json['status'] = 
    userStatusSerializer(status)
    ;
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

  GetAccessiblePatientProfilePatientUser({
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
class GetAccessiblePatientProfileData {
  final GetAccessiblePatientProfilePatient? patient;
  GetAccessiblePatientProfileData.fromJson(dynamic json):
  
  patient = json['patient'] == null ? null : GetAccessiblePatientProfilePatient.fromJson(json['patient']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientProfileData otherTyped = other as GetAccessiblePatientProfileData;
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

  GetAccessiblePatientProfileData({
    this.patient,
  });
}

@immutable
class GetAccessiblePatientProfileVariables {
  final String patientId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetAccessiblePatientProfileVariables.fromJson(Map<String, dynamic> json):
  
  patientId = nativeFromJson<String>(json['patientId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientProfileVariables otherTyped = other as GetAccessiblePatientProfileVariables;
    return patientId == otherTyped.patientId;
    
  }
  @override
  int get hashCode => patientId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['patientId'] = nativeToJson<String>(patientId);
    return json;
  }

  GetAccessiblePatientProfileVariables({
    required this.patientId,
  });
}

