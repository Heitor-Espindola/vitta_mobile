import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/people/domain/models/auth_link.dart';
import 'package:vitta_mobile/features/people/domain/models/relationship.dart';
import 'package:vitta_mobile/features/people/domain/services/person_identity_resolver.dart';
import 'package:vitta_mobile/features/people/domain/services/relationship_access_policy.dart';

void main() {
  test('legacy auth UID falls back to the same person ID', () {
    expect(PersonIdentityResolver.resolve(authUid: 'auth-1'), 'auth-1');
  });

  test('auth link maps an auth UID to a different permanent person ID', () {
    expect(
      PersonIdentityResolver.resolve(
        authUid: 'new-auth',
        linkedPersonId: 'existing-person',
      ),
      'existing-person',
    );
    final link = AuthLink.fromMap('new-auth', {'personId': 'existing-person'});
    expect(link.personId, 'existing-person');
  });

  test('dependent has identity and history without Authentication', () {
    const dependent = AppUser(
      uid: 'child-person',
      personId: 'child-person',
      name: 'Criança',
      email: '',
      role: 'dependent',
      authUid: null,
      canAuthenticate: false,
    );
    expect(dependent.effectivePersonId, 'child-person');
    expect(dependent.authUid, isNull);
    expect(dependent.canAuthenticate, isFalse);
  });

  test('majorityAt is derived from birth date, including leap day', () {
    expect(calculateMajorityAt(DateTime(2008, 6, 23)), DateTime(2026, 6, 23));
    expect(calculateMajorityAt(DateTime(2008, 2, 29)), DateTime(2026, 2, 28));
  });

  group('direct relationship access', () {
    final minor = AppUser(
      uid: 'baby',
      personId: 'baby',
      name: 'Bebê',
      email: '',
      role: 'dependent',
      birthDate: DateTime(2025, 1, 1),
    );
    final adult = AppUser(
      uid: 'adult',
      personId: 'adult',
      name: 'Adulto',
      email: '',
      role: 'responsible',
      birthDate: DateTime(2000, 1, 1),
    );

    PersonRelationship relationship({
      required String from,
      required String to,
      RelationshipType type = RelationshipType.mother,
      AdultConsentStatus consent = AdultConsentStatus.notRequiredMinor,
      DateTime? validUntil,
    }) => PersonRelationship(
      id: PersonRelationship.deterministicId(from, to),
      fromPersonId: from,
      toPersonId: to,
      type: type,
      status: RelationshipStatus.verified,
      permissions: const RelationshipPermissions(viewVaccination: true),
      consentStatus: consent,
      validUntil: validUntil,
    );

    test(
      'minor mother may have a direct mother relationship with her baby',
      () {
        final direct = relationship(from: 'mother-17', to: 'baby');
        expect(
          RelationshipAccessPolicy.canViewVaccination(
            relationship: direct,
            subject: minor,
            now: DateTime(2026, 1, 1),
          ),
          isTrue,
        );
      },
    );

    test('relationship remains but automatic access ends at majority', () {
      final parent = relationship(
        from: 'parent',
        to: 'adult',
        type: RelationshipType.father,
      );
      expect(parent.status, RelationshipStatus.verified);
      expect(
        RelationshipAccessPolicy.canViewVaccination(
          relationship: parent,
          subject: adult,
          now: DateTime(2026, 1, 1),
        ),
        isFalse,
      );
    });

    test('explicit adult consent keeps direct access until expiration', () {
      final consented = relationship(
        from: 'parent',
        to: 'adult',
        type: RelationshipType.father,
        consent: AdultConsentStatus.granted,
        validUntil: DateTime(2027, 1, 1),
      );
      expect(
        RelationshipAccessPolicy.canViewVaccination(
          relationship: consented,
          subject: adult,
          now: DateTime(2026, 1, 1),
        ),
        isTrue,
      );
    });

    test('guardian of the mother gets no transitive access to the baby', () {
      final grandmotherToMother = relationship(
        from: 'grandmother',
        to: 'mother-17',
        type: RelationshipType.legalGuardian,
      );
      expect(
        RelationshipAccessPolicy.isDirectRelationship(
          grandmotherToMother,
          'grandmother',
          'baby',
        ),
        isFalse,
      );
    });
  });
}
