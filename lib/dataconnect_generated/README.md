# vitta_mobile SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
MobileConnectorConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetMobileCurrentPerson
#### Required Arguments
```dart
// No required arguments
MobileConnectorConnector.instance.getMobileCurrentPerson().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMobileCurrentPersonData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await MobileConnectorConnector.instance.getMobileCurrentPerson();
GetMobileCurrentPersonData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = MobileConnectorConnector.instance.getMobileCurrentPerson().ref();
ref.execute();

ref.subscribe(...);
```


### GetAccessibleFamilyMembers
#### Required Arguments
```dart
// No required arguments
MobileConnectorConnector.instance.getAccessibleFamilyMembers().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAccessibleFamilyMembersData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await MobileConnectorConnector.instance.getAccessibleFamilyMembers();
GetAccessibleFamilyMembersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = MobileConnectorConnector.instance.getAccessibleFamilyMembers().ref();
ref.execute();

ref.subscribe(...);
```


### GetAccessiblePatientProfile
#### Required Arguments
```dart
String patientId = ...;
MobileConnectorConnector.instance.getAccessiblePatientProfile(
  patientId: patientId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAccessiblePatientProfileData, GetAccessiblePatientProfileVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await MobileConnectorConnector.instance.getAccessiblePatientProfile(
  patientId: patientId,
);
GetAccessiblePatientProfileData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String patientId = ...;

final ref = MobileConnectorConnector.instance.getAccessiblePatientProfile(
  patientId: patientId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetAccessiblePatientVaccinations
#### Required Arguments
```dart
String patientId = ...;
MobileConnectorConnector.instance.getAccessiblePatientVaccinations(
  patientId: patientId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAccessiblePatientVaccinationsData, GetAccessiblePatientVaccinationsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await MobileConnectorConnector.instance.getAccessiblePatientVaccinations(
  patientId: patientId,
);
GetAccessiblePatientVaccinationsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String patientId = ...;

final ref = MobileConnectorConnector.instance.getAccessiblePatientVaccinations(
  patientId: patientId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetMobileVaccines
#### Required Arguments
```dart
// No required arguments
MobileConnectorConnector.instance.getMobileVaccines().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMobileVaccinesData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await MobileConnectorConnector.instance.getMobileVaccines();
GetMobileVaccinesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = MobileConnectorConnector.instance.getMobileVaccines().ref();
ref.execute();

ref.subscribe(...);
```


### GetAccessibleEmergencyContact
#### Required Arguments
```dart
String patientId = ...;
MobileConnectorConnector.instance.getAccessibleEmergencyContact(
  patientId: patientId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAccessibleEmergencyContactData, GetAccessibleEmergencyContactVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await MobileConnectorConnector.instance.getAccessibleEmergencyContact(
  patientId: patientId,
);
GetAccessibleEmergencyContactData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String patientId = ...;

final ref = MobileConnectorConnector.instance.getAccessibleEmergencyContact(
  patientId: patientId,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CompleteMobileRegistration
#### Required Arguments
```dart
String name = ...;
DateTime birthDate = ...;
String email = ...;
String cpf = ...;
MobileConnectorConnector.instance.completeMobileRegistration(
  name: name,
  birthDate: birthDate,
  email: email,
  cpf: cpf,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CompleteMobileRegistration, we created `CompleteMobileRegistrationBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CompleteMobileRegistrationVariablesBuilder {
  ...
   CompleteMobileRegistrationVariablesBuilder sex(String? t) {
   _sex.value = t;
   return this;
  }

  ...
}
MobileConnectorConnector.instance.completeMobileRegistration(
  name: name,
  birthDate: birthDate,
  email: email,
  cpf: cpf,
)
.sex(sex)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CompleteMobileRegistrationData, CompleteMobileRegistrationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await MobileConnectorConnector.instance.completeMobileRegistration(
  name: name,
  birthDate: birthDate,
  email: email,
  cpf: cpf,
);
CompleteMobileRegistrationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String name = ...;
DateTime birthDate = ...;
String email = ...;
String cpf = ...;

final ref = MobileConnectorConnector.instance.completeMobileRegistration(
  name: name,
  birthDate: birthDate,
  email: email,
  cpf: cpf,
).ref();
ref.execute();
```


### UpdateMobilePhone
#### Required Arguments
```dart
// No required arguments
MobileConnectorConnector.instance.updateMobilePhone().execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateMobilePhone, we created `UpdateMobilePhoneBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateMobilePhoneVariablesBuilder {
  ...
 
  UpdateMobilePhoneVariablesBuilder phone(String? t) {
   _phone.value = t;
   return this;
  }

  ...
}
MobileConnectorConnector.instance.updateMobilePhone()
.phone(phone)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateMobilePhoneData, UpdateMobilePhoneVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await MobileConnectorConnector.instance.updateMobilePhone();
UpdateMobilePhoneData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = MobileConnectorConnector.instance.updateMobilePhone().ref();
ref.execute();
```


### CreateMobileDependent
#### Required Arguments
```dart
String guardianPatientId = ...;
String name = ...;
DateTime birthDate = ...;
String cpf = ...;
RelationshipType relationshipType = ...;
MobileConnectorConnector.instance.createMobileDependent(
  guardianPatientId: guardianPatientId,
  name: name,
  birthDate: birthDate,
  cpf: cpf,
  relationshipType: relationshipType,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateMobileDependent, we created `CreateMobileDependentBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateMobileDependentVariablesBuilder {
  ...
   CreateMobileDependentVariablesBuilder sex(String? t) {
   _sex.value = t;
   return this;
  }

  ...
}
MobileConnectorConnector.instance.createMobileDependent(
  guardianPatientId: guardianPatientId,
  name: name,
  birthDate: birthDate,
  cpf: cpf,
  relationshipType: relationshipType,
)
.sex(sex)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateMobileDependentData, CreateMobileDependentVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await MobileConnectorConnector.instance.createMobileDependent(
  guardianPatientId: guardianPatientId,
  name: name,
  birthDate: birthDate,
  cpf: cpf,
  relationshipType: relationshipType,
);
CreateMobileDependentData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String guardianPatientId = ...;
String name = ...;
DateTime birthDate = ...;
String cpf = ...;
RelationshipType relationshipType = ...;

final ref = MobileConnectorConnector.instance.createMobileDependent(
  guardianPatientId: guardianPatientId,
  name: name,
  birthDate: birthDate,
  cpf: cpf,
  relationshipType: relationshipType,
).ref();
ref.execute();
```


### UpsertAccessibleEmergencyContact
#### Required Arguments
```dart
String patientId = ...;
String name = ...;
String phone = ...;
String relationship = ...;
MobileConnectorConnector.instance.upsertAccessibleEmergencyContact(
  patientId: patientId,
  name: name,
  phone: phone,
  relationship: relationship,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpsertAccessibleEmergencyContactData, UpsertAccessibleEmergencyContactVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await MobileConnectorConnector.instance.upsertAccessibleEmergencyContact(
  patientId: patientId,
  name: name,
  phone: phone,
  relationship: relationship,
);
UpsertAccessibleEmergencyContactData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String patientId = ...;
String name = ...;
String phone = ...;
String relationship = ...;

final ref = MobileConnectorConnector.instance.upsertAccessibleEmergencyContact(
  patientId: patientId,
  name: name,
  phone: phone,
  relationship: relationship,
).ref();
ref.execute();
```

