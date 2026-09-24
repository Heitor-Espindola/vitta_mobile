part of 'mobile_connector.dart';

class UpdateMobileProfileVariablesBuilder {
  String name;
  Optional<String> _phone = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  UpdateMobileProfileVariablesBuilder phone(String? t) {
    _phone.value = t;
    return this;
  }

  UpdateMobileProfileVariablesBuilder(this._dataConnect, {required this.name});
  Deserializer<UpdateMobileProfileData> dataDeserializer = (dynamic json) =>
      UpdateMobileProfileData.fromJson(jsonDecode(json));
  Serializer<UpdateMobileProfileVariables> varsSerializer =
      (UpdateMobileProfileVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateMobileProfileData, UpdateMobileProfileVariables>>
  execute() {
    return ref().execute();
  }

  MutationRef<UpdateMobileProfileData, UpdateMobileProfileVariables> ref() {
    UpdateMobileProfileVariables vars = UpdateMobileProfileVariables(
      name: name,
      phone: _phone,
    );
    return _dataConnect.mutation(
      "UpdateMobileProfile",
      dataDeserializer,
      varsSerializer,
      vars,
    );
  }
}

@immutable
class UpdateMobileProfileUserUpdate {
  final String id;
  UpdateMobileProfileUserUpdate.fromJson(dynamic json)
    : id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMobileProfileUserUpdate otherTyped =
        other as UpdateMobileProfileUserUpdate;
    return id == otherTyped.id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateMobileProfileUserUpdate({required this.id});
}

@immutable
class UpdateMobileProfileData {
  final UpdateMobileProfileUserUpdate? user_update;
  UpdateMobileProfileData.fromJson(dynamic json)
    : user_update = json['user_update'] == null
          ? null
          : UpdateMobileProfileUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMobileProfileData otherTyped = other as UpdateMobileProfileData;
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

  UpdateMobileProfileData({this.user_update});
}

@immutable
class UpdateMobileProfileVariables {
  final String name;
  late final Optional<String> phone;
  @Deprecated(
    'fromJson is deprecated for Variable classes as they are no longer required for deserialization.',
  )
  UpdateMobileProfileVariables.fromJson(Map<String, dynamic> json)
    : name = nativeFromJson<String>(json['name']) {
    phone = Optional.optional(nativeFromJson, nativeToJson);
    phone.value = json['phone'] == null
        ? null
        : nativeFromJson<String>(json['phone']);
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMobileProfileVariables otherTyped =
        other as UpdateMobileProfileVariables;
    return name == otherTyped.name && phone == otherTyped.phone;
  }

  @override
  int get hashCode => Object.hashAll([name.hashCode, phone.hashCode]);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    if (phone.state == OptionalState.set) {
      json['phone'] = phone.toJson();
    }
    return json;
  }

  UpdateMobileProfileVariables({required this.name, required this.phone});
}
