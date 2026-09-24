import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/validators/cpf_validator.dart';
import 'package:vitta_mobile/core/validators/full_name_validator.dart';
import 'package:vitta_mobile/dataconnect_generated/mobile_connector.dart' as dc;
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/people/domain/models/family_member.dart';
import 'package:vitta_mobile/features/people/domain/models/relationship.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';

class SqlPeopleRepository implements PeopleRepository {
  SqlPeopleRepository({dc.MobileConnectorConnector? connector})
    : _connector = connector ?? dc.MobileConnectorConnector.instance;

  final dc.MobileConnectorConnector _connector;

  @override
  Future<List<AppUser>> getAvailablePeople(String guardianId) async {
    final members = await getFamilyMembers(guardianId);
    return members.map((member) => member.person).toList(growable: false);
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers(String currentPersonId) async {
    final result = await _connector.getAccessibleFamilyMembers().execute(
      fetchPolicy: QueryFetchPolicy.serverOnly,
    );
    final members = result.data.patientAccesses
        .map((access) {
          final patient = access.patient;
          final user = patient.user;
          final isCurrent =
              patient.id == currentPersonId ||
              access.accessKind.stringValue == dc.PatientAccessKind.SELF.name;
          final relationshipLabel = _relationshipLabel(access.accessKind);
          final person = AppUser(
            uid: patient.id,
            personId: patient.id,
            canAuthenticate: isCurrent && (user.email?.isNotEmpty ?? false),
            name: user.name,
            email: user.email ?? '',
            role: isCurrent ? 'responsible' : 'dependent',
            roles: [isCurrent ? 'user' : 'dependent'],
            accountStatus: user.status.stringValue.toLowerCase(),
            guardianIds: isCurrent ? const [] : [currentPersonId],
            relationshipToGuardian: isCurrent ? null : relationshipLabel,
            cpf: user.cpf,
            birthDate: user.birthDate,
            majorityAt: calculateMajorityAt(user.birthDate),
            phone: user.phone,
            photoUrl: user.photoUrl,
          );
          if (isCurrent) return FamilyMember(person: person, isCurrent: true);

          final pairId = PersonRelationship.deterministicId(
            currentPersonId,
            patient.id,
          );
          return FamilyMember(
            person: person,
            relationship: PersonRelationship(
              id: pairId,
              fromPersonId: currentPersonId,
              toPersonId: patient.id,
              type: _domainRelationshipType(access.accessKind),
              status: RelationshipStatus.verified,
              permissions: RelationshipPermissions(
                viewVaccination: true,
                receiveNotifications: access.receiveNotifications,
              ),
              consentStatus: AdultConsentStatus.granted,
              verificationSource: 'sql_connect',
              validUntil: access.validUntil?.toDateTime(),
            ),
            accessGrant: VaccinationAccessGrant(
              id: pairId,
              granteePersonId: currentPersonId,
              subjectPersonId: patient.id,
              viewVaccination: true,
              consentStatus: 'granted',
              validUntil: access.validUntil?.toDateTime(),
            ),
          );
        })
        .toList(growable: false);
    members.sort((a, b) {
      if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
      return a.person.name.compareTo(b.person.name);
    });
    return members;
  }

  @override
  Future<AppUser> createDependent({
    required String guardianId,
    required String name,
    required DateTime birthDate,
    required String relationship,
    required String cpf,
  }) async {
    final formattedName = formatPersonName(name);
    final nameError = validateFullName(formattedName);
    if (nameError != null) throw StateError(nameError);
    final cpfError = validateCpf(cpf);
    if (cpfError != null) throw StateError(cpfError);

    final relation = _connectorRelationshipType(relationship);
    final result = await _connector
        .createMobileDependent(
          guardianPatientId: guardianId,
          name: formattedName,
          birthDate: birthDate,
          cpf: cpfDigitsOnly(cpf),
          relationshipType: relation,
        )
        .execute();
    final patientId = result.data.patient_insert.id;
    return AppUser(
      uid: patientId,
      personId: patientId,
      canAuthenticate: false,
      name: formattedName,
      email: '',
      role: 'dependent',
      roles: const ['dependent'],
      accountStatus: 'active',
      guardianIds: [guardianId],
      relationshipToGuardian: relationship.trim(),
      cpf: cpfDigitsOnly(cpf),
      birthDate: birthDate,
      majorityAt: calculateMajorityAt(birthDate),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

String _relationshipLabel(dc.EnumValue<dc.PatientAccessKind> kind) =>
    switch (kind.stringValue) {
      'DEPENDENT' => 'Filho(a)',
      'CAREGIVER' => 'Outro familiar',
      'PROFESSIONAL' => 'Profissional',
      _ => 'Familiar',
    };

RelationshipType _domainRelationshipType(
  dc.EnumValue<dc.PatientAccessKind> kind,
) => switch (kind.stringValue) {
  'DEPENDENT' => RelationshipType.legalGuardian,
  _ => RelationshipType.caregiver,
};

dc.RelationshipType _connectorRelationshipType(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('mae') || normalized.contains('mãe')) {
    return dc.RelationshipType.MOTHER;
  }
  if (normalized.contains('pai')) return dc.RelationshipType.FATHER;
  if (normalized.contains('respons') || normalized.contains('tutor')) {
    return dc.RelationshipType.TUTOR;
  }
  if (normalized.contains('filh') || normalized.contains('guard')) {
    return dc.RelationshipType.LEGAL_GUARDIAN;
  }
  return dc.RelationshipType.CAREGIVER;
}
