part of 'mobile_connector.dart';

class UpdateMobilePhoneVariablesBuilder {
  Optional<String> _phone = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  UpdateMobilePhoneVariablesBuilder phone(String? t) {
   _phone.value = t;
   return this;
  }

  UpdateMobilePhoneVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateMobilePhoneData> dataDeserializer = (dynamic json)  => UpdateMobilePhoneData.fromJson(jsonDecode(json));
  Serializer<UpdateMobilePhoneVariables> varsSerializer = (UpdateMobilePhoneVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateMobilePhoneData, UpdateMobilePhoneVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateMobilePhoneData, UpdateMobilePhoneVariables> ref() {
    UpdateMobilePhoneVariables vars= UpdateMobilePhoneVariables(phone: _phone,);
    return _dataConnect.mutation("UpdateMobilePhone", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateMobilePhoneUserUpdate {
  final String id;
  UpdateMobilePhoneUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMobilePhoneUserUpdate otherTyped = other as UpdateMobilePhoneUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateMobilePhoneUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateMobilePhoneData {
  final UpdateMobilePhoneUserUpdate? user_update;
  UpdateMobilePhoneData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateMobilePhoneUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMobilePhoneData otherTyped = other as UpdateMobilePhoneData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateMobilePhoneData({
    this.user_update,
  });
}

@immutable
class UpdateMobilePhoneVariables {
  late final Optional<String>phone;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateMobilePhoneVariables.fromJson(Map<String, dynamic> json) {
  
  
    phone = Optional.optional(nativeFromJson, nativeToJson);
    phone.value = json['phone'] == null ? null : nativeFromJson<String>(json['phone']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMobilePhoneVariables otherTyped = other as UpdateMobilePhoneVariables;
    return phone == otherTyped.phone;
    
  }
  @override
  int get hashCode => phone.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(phone.state == OptionalState.set) {
      json['phone'] = phone.toJson();
    }
    return json;
  }

  UpdateMobilePhoneVariables({
    required this.phone,
  });
}

