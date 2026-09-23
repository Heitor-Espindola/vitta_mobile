# Basic Usage

```dart
MobileConnectorConnector.instance.CompleteMobileRegistration(completeMobileRegistrationVariables).execute();
MobileConnectorConnector.instance.UpdateMobilePhone(updateMobilePhoneVariables).execute();
MobileConnectorConnector.instance.CreateMobileDependent(createMobileDependentVariables).execute();
MobileConnectorConnector.instance.UpsertAccessibleEmergencyContact(upsertAccessibleEmergencyContactVariables).execute();
MobileConnectorConnector.instance.GetMobileCurrentPerson().execute();
MobileConnectorConnector.instance.GetAccessibleFamilyMembers().execute();
MobileConnectorConnector.instance.GetAccessiblePatientProfile(getAccessiblePatientProfileVariables).execute();
MobileConnectorConnector.instance.GetAccessiblePatientVaccinations(getAccessiblePatientVaccinationsVariables).execute();
MobileConnectorConnector.instance.GetMobileVaccines().execute();
MobileConnectorConnector.instance.GetAccessibleEmergencyContact(getAccessibleEmergencyContactVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await MobileConnectorConnector.instance.CreateMobileDependent({ ... })
.sex(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

