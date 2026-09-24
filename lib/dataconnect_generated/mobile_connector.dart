library vitta_mobile;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

part 'complete_mobile_registration.dart';

part 'update_mobile_phone.dart';

part 'update_mobile_profile.dart';

part 'create_mobile_dependent.dart';

part 'upsert_accessible_emergency_contact.dart';

part 'get_mobile_current_person.dart';

part 'get_accessible_family_members.dart';

part 'get_accessible_patient_profile.dart';

part 'get_accessible_patient_vaccinations.dart';

part 'get_mobile_vaccines.dart';

part 'get_accessible_emergency_contact.dart';



  enum PatientAccessKind {
    
      SELF,
    
      DEPENDENT,
    
      CAREGIVER,
    
      PROFESSIONAL,
    
  }
  
  String patientAccessKindSerializer(EnumValue<PatientAccessKind> e) {
    return e.stringValue;
  }
  EnumValue<PatientAccessKind> patientAccessKindDeserializer(dynamic data) {
    switch (data) {
      
      case 'SELF':
        return const Known(PatientAccessKind.SELF);
      
      case 'DEPENDENT':
        return const Known(PatientAccessKind.DEPENDENT);
      
      case 'CAREGIVER':
        return const Known(PatientAccessKind.CAREGIVER);
      
      case 'PROFESSIONAL':
        return const Known(PatientAccessKind.PROFESSIONAL);
      
      default:
        return Unknown(data);
    }
  }
  

  enum PatientType {
    
      ADULT,
    
      CHILD,
    
  }
  
  String patientTypeSerializer(EnumValue<PatientType> e) {
    return e.stringValue;
  }
  EnumValue<PatientType> patientTypeDeserializer(dynamic data) {
    switch (data) {
      
      case 'ADULT':
        return const Known(PatientType.ADULT);
      
      case 'CHILD':
        return const Known(PatientType.CHILD);
      
      default:
        return Unknown(data);
    }
  }
  

  enum RelationshipType {
    
      MOTHER,
    
      FATHER,
    
      LEGAL_GUARDIAN,
    
      TUTOR,
    
      CAREGIVER,
    
  }
  
  String relationshipTypeSerializer(EnumValue<RelationshipType> e) {
    return e.stringValue;
  }
  EnumValue<RelationshipType> relationshipTypeDeserializer(dynamic data) {
    switch (data) {
      
      case 'MOTHER':
        return const Known(RelationshipType.MOTHER);
      
      case 'FATHER':
        return const Known(RelationshipType.FATHER);
      
      case 'LEGAL_GUARDIAN':
        return const Known(RelationshipType.LEGAL_GUARDIAN);
      
      case 'TUTOR':
        return const Known(RelationshipType.TUTOR);
      
      case 'CAREGIVER':
        return const Known(RelationshipType.CAREGIVER);
      
      default:
        return Unknown(data);
    }
  }
  

  enum UserStatus {
    
      ACTIVE,
    
      INACTIVE,
    
      BLOCKED,
    
  }
  
  String userStatusSerializer(EnumValue<UserStatus> e) {
    return e.stringValue;
  }
  EnumValue<UserStatus> userStatusDeserializer(dynamic data) {
    switch (data) {
      
      case 'ACTIVE':
        return const Known(UserStatus.ACTIVE);
      
      case 'INACTIVE':
        return const Known(UserStatus.INACTIVE);
      
      case 'BLOCKED':
        return const Known(UserStatus.BLOCKED);
      
      default:
        return Unknown(data);
    }
  }
  



String enumSerializer(Enum e) {
  return e.name;
}



/// A sealed class representing either a known enum value or an unknown string value.
@immutable
sealed class EnumValue<T extends Enum> {
  const EnumValue();

  

  /// The string representation of the value.
  String get stringValue;
  @override
  String toString() {
    return "EnumValue($stringValue)";
  }
}

/// Represents a known, valid enum value.
class Known<T extends Enum> extends EnumValue<T> {
  /// The actual enum value.
  final T value;

  const Known(this.value);

  @override
  String get stringValue => value.name;

  @override
  String toString() {
    return "Known($stringValue)";
  }
}
/// Represents an unknown or unrecognized enum value.
class Unknown extends EnumValue<Never> {
  /// The raw string value that couldn't be mapped to a known enum.
  @override
  final String stringValue;

  const Unknown(this.stringValue);
  @override
  String toString() {
    return "Unknown($stringValue)";
  }
}

class MobileConnectorConnector {
  
  
  CompleteMobileRegistrationVariablesBuilder completeMobileRegistration ({required String name, required DateTime birthDate, required String email, required String cpf, }) {
    return CompleteMobileRegistrationVariablesBuilder(dataConnect, name: name,birthDate: birthDate,email: email,cpf: cpf,);
  }
  
  
  UpdateMobilePhoneVariablesBuilder updateMobilePhone () {
    return UpdateMobilePhoneVariablesBuilder(dataConnect, );
  }
  
  
  UpdateMobileProfileVariablesBuilder updateMobileProfile ({required String name, }) {
    return UpdateMobileProfileVariablesBuilder(dataConnect, name: name,);
  }
  
  
  CreateMobileDependentVariablesBuilder createMobileDependent ({required String guardianPatientId, required String name, required DateTime birthDate, required String cpf, required RelationshipType relationshipType, }) {
    return CreateMobileDependentVariablesBuilder(dataConnect, guardianPatientId: guardianPatientId,name: name,birthDate: birthDate,cpf: cpf,relationshipType: relationshipType,);
  }
  
  
  UpsertAccessibleEmergencyContactVariablesBuilder upsertAccessibleEmergencyContact ({required String patientId, required String name, required String phone, required String relationship, }) {
    return UpsertAccessibleEmergencyContactVariablesBuilder(dataConnect, patientId: patientId,name: name,phone: phone,relationship: relationship,);
  }
  
  
  GetMobileCurrentPersonVariablesBuilder getMobileCurrentPerson () {
    return GetMobileCurrentPersonVariablesBuilder(dataConnect, );
  }
  
  
  GetAccessibleFamilyMembersVariablesBuilder getAccessibleFamilyMembers () {
    return GetAccessibleFamilyMembersVariablesBuilder(dataConnect, );
  }
  
  
  GetAccessiblePatientProfileVariablesBuilder getAccessiblePatientProfile ({required String patientId, }) {
    return GetAccessiblePatientProfileVariablesBuilder(dataConnect, patientId: patientId,);
  }
  
  
  GetAccessiblePatientVaccinationsVariablesBuilder getAccessiblePatientVaccinations ({required String patientId, }) {
    return GetAccessiblePatientVaccinationsVariablesBuilder(dataConnect, patientId: patientId,);
  }
  
  
  GetMobileVaccinesVariablesBuilder getMobileVaccines () {
    return GetMobileVaccinesVariablesBuilder(dataConnect, );
  }
  
  
  GetAccessibleEmergencyContactVariablesBuilder getAccessibleEmergencyContact ({required String patientId, }) {
    return GetAccessibleEmergencyContactVariablesBuilder(dataConnect, patientId: patientId,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'southamerica-east1',
    'mobile-connector',
    'vitta-5ec1e-service',
  );

  MobileConnectorConnector({required this.dataConnect});
  static MobileConnectorConnector get instance {
    
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds:0),
      storage: CacheStorage.persistent,
    );
    
    return MobileConnectorConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            cacheSettings: cacheSettings,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
