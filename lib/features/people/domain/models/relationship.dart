import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';

enum RelationshipType { mother, father, legalGuardian, tutor, caregiver }

enum RelationshipStatus { pending, verified, rejected, revoked }

enum AdultConsentStatus { notRequiredMinor, pending, granted, revoked, expired }

class RelationshipPermissions {
  const RelationshipPermissions({
    this.viewVaccination = false,
    this.receiveNotifications = false,
  });

  final bool viewVaccination;
  final bool receiveNotifications;

  factory RelationshipPermissions.fromMap(Object? value) {
    if (value is! Map) return const RelationshipPermissions();
    return RelationshipPermissions(
      viewVaccination: value['viewVaccination'] == true,
      receiveNotifications: value['receiveNotifications'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'viewVaccination': viewVaccination,
    'receiveNotifications': receiveNotifications,
  };
}

class PersonRelationship {
  const PersonRelationship({
    required this.id,
    required this.fromPersonId,
    required this.toPersonId,
    required this.type,
    this.status = RelationshipStatus.pending,
    this.permissions = const RelationshipPermissions(),
    this.consentStatus = AdultConsentStatus.pending,
    this.verificationSource = 'manual_pending',
    this.verifiedAt,
    this.validUntil,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fromPersonId;
  final String toPersonId;
  final RelationshipType type;
  final RelationshipStatus status;
  final RelationshipPermissions permissions;
  final AdultConsentStatus consentStatus;
  final String verificationSource;
  final DateTime? verifiedAt;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String deterministicId(String fromPersonId, String toPersonId) =>
      '${fromPersonId}_$toPersonId';

  factory PersonRelationship.fromMap(String id, Map<String, dynamic> map) =>
      PersonRelationship(
        id: id,
        fromPersonId: map['fromPersonId'] as String? ?? '',
        toPersonId: map['toPersonId'] as String? ?? '',
        type: _relationshipType(map['type']),
        status: _relationshipStatus(map['status']),
        permissions: RelationshipPermissions.fromMap(map['permissions']),
        consentStatus: _consentStatus(map['consentStatus']),
        verificationSource:
            map['verificationSource'] as String? ?? 'manual_pending',
        verifiedAt: dateTimeFromMap(map['verifiedAt']),
        validUntil: dateTimeFromMap(map['validUntil']),
        createdAt: dateTimeFromMap(map['createdAt']),
        updatedAt: dateTimeFromMap(map['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
    'fromPersonId': fromPersonId,
    'toPersonId': toPersonId,
    'type': _enumValue(type),
    'status': _enumValue(status),
    'permissions': permissions.toMap(),
    'consentStatus': _enumValue(consentStatus),
    'verificationSource': verificationSource,
    'verifiedAt': verifiedAt,
    'validUntil': validUntil,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

RelationshipType _relationshipType(Object? value) => switch (value) {
  'mother' => RelationshipType.mother,
  'father' => RelationshipType.father,
  'legal_guardian' => RelationshipType.legalGuardian,
  'tutor' => RelationshipType.tutor,
  _ => RelationshipType.caregiver,
};

RelationshipStatus _relationshipStatus(Object? value) => switch (value) {
  'verified' => RelationshipStatus.verified,
  'rejected' => RelationshipStatus.rejected,
  'revoked' => RelationshipStatus.revoked,
  _ => RelationshipStatus.pending,
};

AdultConsentStatus _consentStatus(Object? value) => switch (value) {
  'not_required_minor' => AdultConsentStatus.notRequiredMinor,
  'granted' => AdultConsentStatus.granted,
  'revoked' => AdultConsentStatus.revoked,
  'expired' => AdultConsentStatus.expired,
  _ => AdultConsentStatus.pending,
};

String _enumValue(Enum value) => switch (value) {
  RelationshipType.legalGuardian => 'legal_guardian',
  AdultConsentStatus.notRequiredMinor => 'not_required_minor',
  _ => value.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  ),
};
