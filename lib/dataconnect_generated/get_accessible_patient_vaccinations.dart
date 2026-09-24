part of 'mobile_connector.dart';

class GetAccessiblePatientVaccinationsVariablesBuilder {
  String patientId;

  final FirebaseDataConnect _dataConnect;
  GetAccessiblePatientVaccinationsVariablesBuilder(this._dataConnect, {required  this.patientId,});
  Deserializer<GetAccessiblePatientVaccinationsData> dataDeserializer = (dynamic json)  => GetAccessiblePatientVaccinationsData.fromJson(jsonDecode(json));
  Serializer<GetAccessiblePatientVaccinationsVariables> varsSerializer = (GetAccessiblePatientVaccinationsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetAccessiblePatientVaccinationsData, GetAccessiblePatientVaccinationsVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetAccessiblePatientVaccinationsData, GetAccessiblePatientVaccinationsVariables> ref() {
    GetAccessiblePatientVaccinationsVariables vars= GetAccessiblePatientVaccinationsVariables(patientId: patientId,);
    return _dataConnect.query("GetAccessiblePatientVaccinations", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetAccessiblePatientVaccinationsApplications {
  final String id;
  final String? legacyRecordId;
  final String patientIdSnapshot;
  final String? patientLegacyPersonIdSnapshot;
  final String patientNameSnapshot;
  final String vaccineNameSnapshot;
  final Timestamp applicationDate;
  final Timestamp? nextDoseAt;
  final int? doseNumber;
  final String? doseLabel;
  final String? lotSnapshot;
  final String? manufacturerSnapshot;
  final String facilityNameSnapshot;
  final String professionalNameSnapshot;
  final String? professionalRegistrationSnapshot;
  final String? source;
  final Timestamp? voidedAt;
  final String? voidReason;
  final String? notes;
  final GetAccessiblePatientVaccinationsApplicationsVaccine? vaccine;
  final GetAccessiblePatientVaccinationsApplicationsBatch? batch;
  final GetAccessiblePatientVaccinationsApplicationsProfessional? professional;
  final GetAccessiblePatientVaccinationsApplicationsUbs? ubs;
  GetAccessiblePatientVaccinationsApplications.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  legacyRecordId = json['legacyRecordId'] == null ? null : nativeFromJson<String>(json['legacyRecordId']),
  patientIdSnapshot = nativeFromJson<String>(json['patientIdSnapshot']),
  patientLegacyPersonIdSnapshot = json['patientLegacyPersonIdSnapshot'] == null ? null : nativeFromJson<String>(json['patientLegacyPersonIdSnapshot']),
  patientNameSnapshot = nativeFromJson<String>(json['patientNameSnapshot']),
  vaccineNameSnapshot = nativeFromJson<String>(json['vaccineNameSnapshot']),
  applicationDate = Timestamp.fromJson(json['applicationDate']),
  nextDoseAt = json['nextDoseAt'] == null ? null : Timestamp.fromJson(json['nextDoseAt']),
  doseNumber = json['doseNumber'] == null ? null : nativeFromJson<int>(json['doseNumber']),
  doseLabel = json['doseLabel'] == null ? null : nativeFromJson<String>(json['doseLabel']),
  lotSnapshot = json['lotSnapshot'] == null ? null : nativeFromJson<String>(json['lotSnapshot']),
  manufacturerSnapshot = json['manufacturerSnapshot'] == null ? null : nativeFromJson<String>(json['manufacturerSnapshot']),
  facilityNameSnapshot = nativeFromJson<String>(json['facilityNameSnapshot']),
  professionalNameSnapshot = nativeFromJson<String>(json['professionalNameSnapshot']),
  professionalRegistrationSnapshot = json['professionalRegistrationSnapshot'] == null ? null : nativeFromJson<String>(json['professionalRegistrationSnapshot']),
  source = json['source'] == null ? null : nativeFromJson<String>(json['source']),
  voidedAt = json['voidedAt'] == null ? null : Timestamp.fromJson(json['voidedAt']),
  voidReason = json['voidReason'] == null ? null : nativeFromJson<String>(json['voidReason']),
  notes = json['notes'] == null ? null : nativeFromJson<String>(json['notes']),
  vaccine = json['vaccine'] == null ? null : GetAccessiblePatientVaccinationsApplicationsVaccine.fromJson(json['vaccine']),
  batch = json['batch'] == null ? null : GetAccessiblePatientVaccinationsApplicationsBatch.fromJson(json['batch']),
  professional = json['professional'] == null ? null : GetAccessiblePatientVaccinationsApplicationsProfessional.fromJson(json['professional']),
  ubs = json['ubs'] == null ? null : GetAccessiblePatientVaccinationsApplicationsUbs.fromJson(json['ubs']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientVaccinationsApplications otherTyped = other as GetAccessiblePatientVaccinationsApplications;
    return id == otherTyped.id && 
    legacyRecordId == otherTyped.legacyRecordId && 
    patientIdSnapshot == otherTyped.patientIdSnapshot && 
    patientLegacyPersonIdSnapshot == otherTyped.patientLegacyPersonIdSnapshot && 
    patientNameSnapshot == otherTyped.patientNameSnapshot && 
    vaccineNameSnapshot == otherTyped.vaccineNameSnapshot && 
    applicationDate == otherTyped.applicationDate && 
    nextDoseAt == otherTyped.nextDoseAt && 
    doseNumber == otherTyped.doseNumber && 
    doseLabel == otherTyped.doseLabel && 
    lotSnapshot == otherTyped.lotSnapshot && 
    manufacturerSnapshot == otherTyped.manufacturerSnapshot && 
    facilityNameSnapshot == otherTyped.facilityNameSnapshot && 
    professionalNameSnapshot == otherTyped.professionalNameSnapshot && 
    professionalRegistrationSnapshot == otherTyped.professionalRegistrationSnapshot && 
    source == otherTyped.source && 
    voidedAt == otherTyped.voidedAt && 
    voidReason == otherTyped.voidReason && 
    notes == otherTyped.notes && 
    vaccine == otherTyped.vaccine && 
    batch == otherTyped.batch && 
    professional == otherTyped.professional && 
    ubs == otherTyped.ubs;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, legacyRecordId.hashCode, patientIdSnapshot.hashCode, patientLegacyPersonIdSnapshot.hashCode, patientNameSnapshot.hashCode, vaccineNameSnapshot.hashCode, applicationDate.hashCode, nextDoseAt.hashCode, doseNumber.hashCode, doseLabel.hashCode, lotSnapshot.hashCode, manufacturerSnapshot.hashCode, facilityNameSnapshot.hashCode, professionalNameSnapshot.hashCode, professionalRegistrationSnapshot.hashCode, source.hashCode, voidedAt.hashCode, voidReason.hashCode, notes.hashCode, vaccine.hashCode, batch.hashCode, professional.hashCode, ubs.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (legacyRecordId != null) {
      json['legacyRecordId'] = nativeToJson<String?>(legacyRecordId);
    }
    json['patientIdSnapshot'] = nativeToJson<String>(patientIdSnapshot);
    if (patientLegacyPersonIdSnapshot != null) {
      json['patientLegacyPersonIdSnapshot'] = nativeToJson<String?>(patientLegacyPersonIdSnapshot);
    }
    json['patientNameSnapshot'] = nativeToJson<String>(patientNameSnapshot);
    json['vaccineNameSnapshot'] = nativeToJson<String>(vaccineNameSnapshot);
    json['applicationDate'] = applicationDate.toJson();
    if (nextDoseAt != null) {
      json['nextDoseAt'] = nextDoseAt!.toJson();
    }
    if (doseNumber != null) {
      json['doseNumber'] = nativeToJson<int?>(doseNumber);
    }
    if (doseLabel != null) {
      json['doseLabel'] = nativeToJson<String?>(doseLabel);
    }
    if (lotSnapshot != null) {
      json['lotSnapshot'] = nativeToJson<String?>(lotSnapshot);
    }
    if (manufacturerSnapshot != null) {
      json['manufacturerSnapshot'] = nativeToJson<String?>(manufacturerSnapshot);
    }
    json['facilityNameSnapshot'] = nativeToJson<String>(facilityNameSnapshot);
    json['professionalNameSnapshot'] = nativeToJson<String>(professionalNameSnapshot);
    if (professionalRegistrationSnapshot != null) {
      json['professionalRegistrationSnapshot'] = nativeToJson<String?>(professionalRegistrationSnapshot);
    }
    if (source != null) {
      json['source'] = nativeToJson<String?>(source);
    }
    if (voidedAt != null) {
      json['voidedAt'] = voidedAt!.toJson();
    }
    if (voidReason != null) {
      json['voidReason'] = nativeToJson<String?>(voidReason);
    }
    if (notes != null) {
      json['notes'] = nativeToJson<String?>(notes);
    }
    if (vaccine != null) {
      json['vaccine'] = vaccine!.toJson();
    }
    if (batch != null) {
      json['batch'] = batch!.toJson();
    }
    if (professional != null) {
      json['professional'] = professional!.toJson();
    }
    if (ubs != null) {
      json['ubs'] = ubs!.toJson();
    }
    return json;
  }

  GetAccessiblePatientVaccinationsApplications({
    required this.id,
    this.legacyRecordId,
    required this.patientIdSnapshot,
    this.patientLegacyPersonIdSnapshot,
    required this.patientNameSnapshot,
    required this.vaccineNameSnapshot,
    required this.applicationDate,
    this.nextDoseAt,
    this.doseNumber,
    this.doseLabel,
    this.lotSnapshot,
    this.manufacturerSnapshot,
    required this.facilityNameSnapshot,
    required this.professionalNameSnapshot,
    this.professionalRegistrationSnapshot,
    this.source,
    this.voidedAt,
    this.voidReason,
    this.notes,
    this.vaccine,
    this.batch,
    this.professional,
    this.ubs,
  });
}

@immutable
class GetAccessiblePatientVaccinationsApplicationsVaccine {
  final String id;
  final String? legacyVaccineId;
  final String name;
  final String? description;
  final int requiredDoses;
  GetAccessiblePatientVaccinationsApplicationsVaccine.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  legacyVaccineId = json['legacyVaccineId'] == null ? null : nativeFromJson<String>(json['legacyVaccineId']),
  name = nativeFromJson<String>(json['name']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']),
  requiredDoses = nativeFromJson<int>(json['requiredDoses']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientVaccinationsApplicationsVaccine otherTyped = other as GetAccessiblePatientVaccinationsApplicationsVaccine;
    return id == otherTyped.id && 
    legacyVaccineId == otherTyped.legacyVaccineId && 
    name == otherTyped.name && 
    description == otherTyped.description && 
    requiredDoses == otherTyped.requiredDoses;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, legacyVaccineId.hashCode, name.hashCode, description.hashCode, requiredDoses.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (legacyVaccineId != null) {
      json['legacyVaccineId'] = nativeToJson<String?>(legacyVaccineId);
    }
    json['name'] = nativeToJson<String>(name);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    json['requiredDoses'] = nativeToJson<int>(requiredDoses);
    return json;
  }

  GetAccessiblePatientVaccinationsApplicationsVaccine({
    required this.id,
    this.legacyVaccineId,
    required this.name,
    this.description,
    required this.requiredDoses,
  });
}

@immutable
class GetAccessiblePatientVaccinationsApplicationsBatch {
  final String id;
  final String manufacturer;
  final String batchCode;
  final DateTime expirationDate;
  GetAccessiblePatientVaccinationsApplicationsBatch.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  manufacturer = nativeFromJson<String>(json['manufacturer']),
  batchCode = nativeFromJson<String>(json['batchCode']),
  expirationDate = nativeFromJson<DateTime>(json['expirationDate']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientVaccinationsApplicationsBatch otherTyped = other as GetAccessiblePatientVaccinationsApplicationsBatch;
    return id == otherTyped.id && 
    manufacturer == otherTyped.manufacturer && 
    batchCode == otherTyped.batchCode && 
    expirationDate == otherTyped.expirationDate;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, manufacturer.hashCode, batchCode.hashCode, expirationDate.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['manufacturer'] = nativeToJson<String>(manufacturer);
    json['batchCode'] = nativeToJson<String>(batchCode);
    json['expirationDate'] = nativeToJson<DateTime>(expirationDate);
    return json;
  }

  GetAccessiblePatientVaccinationsApplicationsBatch({
    required this.id,
    required this.manufacturer,
    required this.batchCode,
    required this.expirationDate,
  });
}

@immutable
class GetAccessiblePatientVaccinationsApplicationsProfessional {
  final String id;
  final GetAccessiblePatientVaccinationsApplicationsProfessionalUser user;
  GetAccessiblePatientVaccinationsApplicationsProfessional.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  user = GetAccessiblePatientVaccinationsApplicationsProfessionalUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientVaccinationsApplicationsProfessional otherTyped = other as GetAccessiblePatientVaccinationsApplicationsProfessional;
    return id == otherTyped.id && 
    user == otherTyped.user;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['user'] = user.toJson();
    return json;
  }

  GetAccessiblePatientVaccinationsApplicationsProfessional({
    required this.id,
    required this.user,
  });
}

@immutable
class GetAccessiblePatientVaccinationsApplicationsProfessionalUser {
  final String name;
  GetAccessiblePatientVaccinationsApplicationsProfessionalUser.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientVaccinationsApplicationsProfessionalUser otherTyped = other as GetAccessiblePatientVaccinationsApplicationsProfessionalUser;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetAccessiblePatientVaccinationsApplicationsProfessionalUser({
    required this.name,
  });
}

@immutable
class GetAccessiblePatientVaccinationsApplicationsUbs {
  final String id;
  final String name;
  GetAccessiblePatientVaccinationsApplicationsUbs.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientVaccinationsApplicationsUbs otherTyped = other as GetAccessiblePatientVaccinationsApplicationsUbs;
    return id == otherTyped.id && 
    name == otherTyped.name;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, name.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetAccessiblePatientVaccinationsApplicationsUbs({
    required this.id,
    required this.name,
  });
}

@immutable
class GetAccessiblePatientVaccinationsData {
  final List<GetAccessiblePatientVaccinationsApplications> applications;
  GetAccessiblePatientVaccinationsData.fromJson(dynamic json):
  
  applications = (json['applications'] as List<dynamic>)
        .map((e) => GetAccessiblePatientVaccinationsApplications.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientVaccinationsData otherTyped = other as GetAccessiblePatientVaccinationsData;
    return applications == otherTyped.applications;
    
  }
  @override
  int get hashCode => applications.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['applications'] = applications.map((e) => e.toJson()).toList();
    return json;
  }

  GetAccessiblePatientVaccinationsData({
    required this.applications,
  });
}

@immutable
class GetAccessiblePatientVaccinationsVariables {
  final String patientId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetAccessiblePatientVaccinationsVariables.fromJson(Map<String, dynamic> json):
  
  patientId = nativeFromJson<String>(json['patientId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccessiblePatientVaccinationsVariables otherTyped = other as GetAccessiblePatientVaccinationsVariables;
    return patientId == otherTyped.patientId;
    
  }
  @override
  int get hashCode => patientId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['patientId'] = nativeToJson<String>(patientId);
    return json;
  }

  GetAccessiblePatientVaccinationsVariables({
    required this.patientId,
  });
}

