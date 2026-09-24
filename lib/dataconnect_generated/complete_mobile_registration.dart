part of 'mobile_connector.dart';

class CompleteMobileRegistrationVariablesBuilder {
  String name;
  DateTime birthDate;
  String email;
  String cpf;
  Optional<String> _sex = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CompleteMobileRegistrationVariablesBuilder sex(String? t) {
   _sex.value = t;
   return this;
  }

  CompleteMobileRegistrationVariablesBuilder(this._dataConnect, {required  this.name,required  this.birthDate,required  this.email,required  this.cpf,});
  Deserializer<CompleteMobileRegistrationData> dataDeserializer = (dynamic json)  => CompleteMobileRegistrationData.fromJson(jsonDecode(json));
  Serializer<CompleteMobileRegistrationVariables> varsSerializer = (CompleteMobileRegistrationVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CompleteMobileRegistrationData, CompleteMobileRegistrationVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CompleteMobileRegistrationData, CompleteMobileRegistrationVariables> ref() {
    CompleteMobileRegistrationVariables vars= CompleteMobileRegistrationVariables(name: name,birthDate: birthDate,email: email,cpf: cpf,sex: _sex,);
    return _dataConnect.mutation("CompleteMobileRegistration", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CompleteMobileRegistrationUserInsert {
  final String id;
  CompleteMobileRegistrationUserInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteMobileRegistrationUserInsert otherTyped = other as CompleteMobileRegistrationUserInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CompleteMobileRegistrationUserInsert({
    required this.id,
  });
}

@immutable
class CompleteMobileRegistrationPatientInsert {
  final String id;
  CompleteMobileRegistrationPatientInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteMobileRegistrationPatientInsert otherTyped = other as CompleteMobileRegistrationPatientInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CompleteMobileRegistrationPatientInsert({
    required this.id,
  });
}

@immutable
class CompleteMobileRegistrationPatientAccessInsert {
  final String granteeAuthUid;
  final String patientId;
  CompleteMobileRegistrationPatientAccessInsert.fromJson(dynamic json):
  
  granteeAuthUid = nativeFromJson<String>(json['granteeAuthUid']),
  patientId = nativeFromJson<String>(json['patientId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteMobileRegistrationPatientAccessInsert otherTyped = other as CompleteMobileRegistrationPatientAccessInsert;
    return granteeAuthUid == otherTyped.granteeAuthUid && 
    patientId == otherTyped.patientId;
    
  }
  @override
  int get hashCode => Object.hashAll([granteeAuthUid.hashCode, patientId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['granteeAuthUid'] = nativeToJson<String>(granteeAuthUid);
    json['patientId'] = nativeToJson<String>(patientId);
    return json;
  }

  CompleteMobileRegistrationPatientAccessInsert({
    required this.granteeAuthUid,
    required this.patientId,
  });
}

@immutable
class CompleteMobileRegistrationData {
  final CompleteMobileRegistrationUserInsert user_insert;
  final CompleteMobileRegistrationPatientInsert patient_insert;
  final CompleteMobileRegistrationPatientAccessInsert patientAccess_insert;
  CompleteMobileRegistrationData.fromJson(dynamic json):
  
  user_insert = CompleteMobileRegistrationUserInsert.fromJson(json['user_insert']),
  patient_insert = CompleteMobileRegistrationPatientInsert.fromJson(json['patient_insert']),
  patientAccess_insert = CompleteMobileRegistrationPatientAccessInsert.fromJson(json['patientAccess_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteMobileRegistrationData otherTyped = other as CompleteMobileRegistrationData;
    return user_insert == otherTyped.user_insert && 
    patient_insert == otherTyped.patient_insert && 
    patientAccess_insert == otherTyped.patientAccess_insert;
    
  }
  @override
  int get hashCode => Object.hashAll([user_insert.hashCode, patient_insert.hashCode, patientAccess_insert.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_insert'] = user_insert.toJson();
    json['patient_insert'] = patient_insert.toJson();
    json['patientAccess_insert'] = patientAccess_insert.toJson();
    return json;
  }

  CompleteMobileRegistrationData({
    required this.user_insert,
    required this.patient_insert,
    required this.patientAccess_insert,
  });
}

@immutable
class CompleteMobileRegistrationVariables {
  final String name;
  final DateTime birthDate;
  final String email;
  final String cpf;
  late final Optional<String>sex;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CompleteMobileRegistrationVariables.fromJson(Map<String, dynamic> json):
  
  name = nativeFromJson<String>(json['name']),
  birthDate = nativeFromJson<DateTime>(json['birthDate']),
  email = nativeFromJson<String>(json['email']),
  cpf = nativeFromJson<String>(json['cpf']) {
  
  
  
  
  
  
    sex = Optional.optional(nativeFromJson, nativeToJson);
    sex.value = json['sex'] == null ? null : nativeFromJson<String>(json['sex']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CompleteMobileRegistrationVariables otherTyped = other as CompleteMobileRegistrationVariables;
    return name == otherTyped.name && 
    birthDate == otherTyped.birthDate && 
    email == otherTyped.email && 
    cpf == otherTyped.cpf && 
    sex == otherTyped.sex;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, birthDate.hashCode, email.hashCode, cpf.hashCode, sex.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['birthDate'] = nativeToJson<DateTime>(birthDate);
    json['email'] = nativeToJson<String>(email);
    json['cpf'] = nativeToJson<String>(cpf);
    if(sex.state == OptionalState.set) {
      json['sex'] = sex.toJson();
    }
    return json;
  }

  CompleteMobileRegistrationVariables({
    required this.name,
    required this.birthDate,
    required this.email,
    required this.cpf,
    required this.sex,
  });
}

