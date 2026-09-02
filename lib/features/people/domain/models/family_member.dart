import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/people/domain/models/relationship.dart';
import 'package:vitta_mobile/features/people/domain/services/relationship_access_policy.dart';

class VaccinationAccessGrant {
  const VaccinationAccessGrant({
    required this.id,
    required this.granteePersonId,
    required this.subjectPersonId,
    required this.viewVaccination,
    required this.consentStatus,
    this.validUntil,
  });

  final String id;
  final String granteePersonId;
  final String subjectPersonId;
  final bool viewVaccination;
  final String consentStatus;
  final DateTime? validUntil;

  factory VaccinationAccessGrant.fromMap(String id, Map<String, dynamic> map) =>
      VaccinationAccessGrant(
        id: id,
        granteePersonId: map['granteePersonId'] as String? ?? '',
        subjectPersonId: map['subjectPersonId'] as String? ?? '',
        viewVaccination: map['viewVaccination'] == true,
        consentStatus: map['consentStatus'] as String? ?? '',
        validUntil: dateTimeFromMap(map['validUntil']),
      );

  bool isActiveDirect({
    required String granteeId,
    required String subjectId,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return granteePersonId == granteeId &&
        subjectPersonId == subjectId &&
        viewVaccination &&
        consentStatus == 'granted' &&
        (validUntil == null || reference.isBefore(validUntil!));
  }
}

class FamilyMember {
  const FamilyMember({
    required this.person,
    this.relationship,
    this.accessGrant,
    this.isCurrent = false,
  });

  final AppUser person;
  final PersonRelationship? relationship;
  final VaccinationAccessGrant? accessGrant;
  final bool isCurrent;

  bool isDirectFor(String currentPersonId) {
    if (isCurrent) return person.effectivePersonId == currentPersonId;
    final directRelationship = relationship;
    final relationshipIsDirect =
        directRelationship != null &&
        RelationshipAccessPolicy.isDirectRelationship(
          directRelationship,
          currentPersonId,
          person.effectivePersonId,
        );
    final grantIsDirect =
        accessGrant?.granteePersonId == currentPersonId &&
        accessGrant?.subjectPersonId == person.effectivePersonId;
    return relationshipIsDirect || grantIsDirect;
  }

  bool canViewVaccination({
    required String currentPersonId,
    bool demoEnabled = false,
    DateTime? now,
  }) {
    if (isCurrent) return person.effectivePersonId == currentPersonId;
    if (!isDirectFor(currentPersonId)) return false;
    final reference = now ?? DateTime.now();
    final majorityAt = person.effectiveMajorityAt;
    final isMinor = majorityAt != null && reference.isBefore(majorityAt);
    final directRelationship = relationship;
    final relationshipAllows =
        isMinor &&
        directRelationship != null &&
        RelationshipAccessPolicy.canViewVaccination(
          relationship: directRelationship,
          subject: person,
          now: reference,
        );
    final grantAllows =
        accessGrant?.isActiveDirect(
          granteeId: currentPersonId,
          subjectId: person.effectivePersonId,
          now: reference,
        ) ??
        false;
    return relationshipAllows || grantAllows;
  }
}
