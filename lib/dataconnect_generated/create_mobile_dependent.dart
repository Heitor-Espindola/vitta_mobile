part of 'mobile_connector.dart';

class CreateMobileDependentVariablesBuilder {
  String guardianPatientId;
  String name;
  DateTime birthDate;
  String cpf;
  Optional<String> _sex = Optional.optional(nativeFromJson, nativeToJson);
  RelationshipType relationshipType;

  final FirebaseDataConnect _dataConnect;  CreateMobileDependentVariablesBuilder sex(String? t) {
   _sex.value = t;
   return this;
  }

  CreateMobileDependentVariablesBuilder(this._dataConnect, {required  this.guardianPatientId,required  this.name,required  this.birthDate,required  this.cpf,required  this.relationshipType,});
  Deserializer<CreateMobileDependentData> dataDeserializer = (dynamic json)  => CreateMobileDependentData.fromJson(jsonDecode(json));
  Serializer<CreateMobileDependentVariables> varsSerializer = (CreateMobileDependentVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateMobileDependentData, CreateMobileDependentVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateMobileDependentData, CreateMobileDependentVariables> ref() {
    CreateMobileDependentVariables vars= CreateMobileDependentVariables(guardianPatientId: guardianPatientId,name: name,birthDate: birthDate,cpf: cpf,sex: _sex,relationshipType: relationshipType,);
    return _dataConnect.mutation("CreateMobileDependent", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateMobileDependentUserInsert {
  final String id;
  CreateMobileDependentUserInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateMobileDependentUserInsert otherTyped = other as CreateMobileDependentUserInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateMobileDependentUserInsert({
    required this.id,
  });
}

@immutable
class CreateMobileDependentPatientInsert {
  final String id;
  CreateMobileDependentPatientInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateMobileDependentPatientInsert otherTyped = other as CreateMobileDependentPatientInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateMobileDependentPatientInsert({
    required this.id,
  });
}

@immutable
class CreateMobileDependentFamilyRelationshipInsert {
  final String fromPatientId;
  final String toPatientId;
  CreateMobileDependentFamilyRelationshipInsert.fromJson(dynamic json):
  
  fromPatientId = nativeFromJson<String>(json['fromPatientId']),
  toPatientId = nativeFromJson<String>(json['toPatientId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateMobileDependentFamilyRelationshipInsert otherTyped = other as CreateMobileDependentFamilyRelationshipInsert;
    return fromPatientId == otherTyped.fromPatientId && 
    toPatientId == otherTyped.toPatientId;
    
  }
  @override
  int get hashCode => Object.hashAll([fromPatientId.hashCode, toPatientId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['fromPatientId'] = nativeToJson<String>(fromPatientId);
    json['toPatientId'] = nativeToJson<String>(toPatientId);
    return json;
  }

  CreateMobileDependentFamilyRelationshipInsert({
    required this.fromPatientId,
    required this.toPatientId,
  });
}

@immutable
class CreateMobileDependentPatientAccessInsert {
  final String granteeAuthUid;
  final String patientId;
  CreateMobileDependentPatientAccessInsert.fromJson(dynamic json):
  
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

    final CreateMobileDependentPatientAccessInsert otherTyped = other as CreateMobileDependentPatientAccessInsert;
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

  CreateMobileDependentPatientAccessInsert({
    required this.granteeAuthUid,
    required this.patientId,
  });
}

@immutable
class CreateMobileDependentData {
  final CreateMobileDependentUserInsert user_insert;
  final CreateMobileDependentPatientInsert patient_insert;
  final CreateMobileDependentFamilyRelationshipInsert familyRelationship_insert;
  final CreateMobileDependentPatientAccessInsert patientAccess_insert;
  CreateMobileDependentData.fromJson(dynamic json):
  
  user_insert = CreateMobileDependentUserInsert.fromJson(json['user_insert']),
  patient_insert = CreateMobileDependentPatientInsert.fromJson(json['patient_insert']),
  familyRelationship_insert = CreateMobileDependentFamilyRelationshipInsert.fromJson(json['familyRelationship_insert']),
  patientAccess_insert = CreateMobileDependentPatientAccessInsert.fromJson(json['patientAccess_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateMobileDependentData otherTyped = other as CreateMobileDependentData;
    return user_insert == otherTyped.user_insert && 
    patient_insert == otherTyped.patient_insert && 
    familyRelationship_insert == otherTyped.familyRelationship_insert && 
    patientAccess_insert == otherTyped.patientAccess_insert;
    
  }
  @override
  int get hashCode => Object.hashAll([user_insert.hashCode, patient_insert.hashCode, familyRelationship_insert.hashCode, patientAccess_insert.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_insert'] = user_insert.toJson();
    json['patient_insert'] = patient_insert.toJson();
    json['familyRelationship_insert'] = familyRelationship_insert.toJson();
    json['patientAccess_insert'] = patientAccess_insert.toJson();
    return json;
  }

  CreateMobileDependentData({
    required this.user_insert,
    required this.patient_insert,
    required this.familyRelationship_insert,
    required this.patientAccess_insert,
  });
}

@immutable
class CreateMobileDependentVariables {
  final String guardianPatientId;
  final String name;
  final DateTime birthDate;
  final String cpf;
  late final Optional<String>sex;
  final RelationshipType relationshipType;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateMobileDependentVariables.fromJson(Map<String, dynamic> json):
  
  guardianPatientId = nativeFromJson<String>(json['guardianPatientId']),
  name = nativeFromJson<String>(json['name']),
  birthDate = nativeFromJson<DateTime>(json['birthDate']),
  cpf = nativeFromJson<String>(json['cpf']),
  relationshipType = RelationshipType.values.byName(json['relationshipType']) {
  
  
  
  
  
  
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

    final CreateMobileDependentVariables otherTyped = other as CreateMobileDependentVariables;
    return guardianPatientId == otherTyped.guardianPatientId && 
    name == otherTyped.name && 
    birthDate == otherTyped.birthDate && 
    cpf == otherTyped.cpf && 
    sex == otherTyped.sex && 
    relationshipType == otherTyped.relationshipType;
    
  }
  @override
  int get hashCode => Object.hashAll([guardianPatientId.hashCode, name.hashCode, birthDate.hashCode, cpf.hashCode, sex.hashCode, relationshipType.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['guardianPatientId'] = nativeToJson<String>(guardianPatientId);
    json['name'] = nativeToJson<String>(name);
    json['birthDate'] = nativeToJson<DateTime>(birthDate);
    json['cpf'] = nativeToJson<String>(cpf);
    if(sex.state == OptionalState.set) {
      json['sex'] = sex.toJson();
    }
    json['relationshipType'] = 
    relationshipType.name
    ;
    return json;
  }

  CreateMobileDependentVariables({
    required this.guardianPatientId,
    required this.name,
    required this.birthDate,
    required this.cpf,
    required this.sex,
    required this.relationshipType,
  });
}

