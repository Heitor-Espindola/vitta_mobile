import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/people/domain/models/relationship.dart';

abstract final class RelationshipAccessPolicy {
  static bool canViewVaccination({
    required PersonRelationship relationship,
    required AppUser subject,
    DateTime? now,
  }) {
    if (relationship.status != RelationshipStatus.verified ||
        relationship.toPersonId != subject.effectivePersonId ||
        !relationship.permissions.viewVaccination) {
      return false;
    }
    final reference = now ?? DateTime.now();
    final majorityAt = subject.effectiveMajorityAt;
    final directParentalType = {
      RelationshipType.mother,
      RelationshipType.father,
      RelationshipType.legalGuardian,
      RelationshipType.tutor,
    }.contains(relationship.type);
    if (majorityAt != null &&
        reference.isBefore(majorityAt) &&
        directParentalType) {
      return true;
    }
    return relationship.consentStatus == AdultConsentStatus.granted &&
        (relationship.validUntil == null ||
            reference.isBefore(relationship.validUntil!));
  }

  /// A política sempre avalia um vínculo direto; não percorre grafos familiares.
  static bool isDirectRelationship(
    PersonRelationship relationship,
    String granteePersonId,
    String subjectPersonId,
  ) =>
      relationship.fromPersonId == granteePersonId &&
      relationship.toPersonId == subjectPersonId;
}
