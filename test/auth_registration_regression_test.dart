import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/auth/data/registration_compensator.dart';
import 'package:vitta_mobile/features/auth/presentation/auth_error_mapper.dart';
import 'package:vitta_mobile/features/people/domain/models/auth_link.dart';
import 'package:vitta_mobile/features/people/domain/services/person_identity_resolver.dart';

void main() {
  group('person identity compatibility', () {
    test('old login without auth_link falls back only when link is absent', () {
      expect(
        PersonIdentityResolver.resolve(authUid: 'legacy-uid'),
        'legacy-uid',
      );
    });

    test('new login uses the personId from its auth_link', () {
      final link = AuthLink.fromMap('new-auth-uid', {
        'personId': 'permanent-person-id',
      });

      expect(link.authUid, 'new-auth-uid');
      expect(
        PersonIdentityResolver.resolve(
          authUid: link.authUid,
          linkedPersonId: link.personId,
        ),
        'permanent-person-id',
      );
    });

    test('permission-denied is translated without technical details', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );

      expect(
        mapSignInError(error),
        'Não foi possível acessar seu perfil agora. Tente novamente.',
      );
      expect(mapSignInError(error), isNot(contains('permission-denied')));
    });
  });

  group('registration compensation', () {
    test(
      'Firestore failure invokes Auth compensation and keeps original error',
      () async {
        var compensationCalls = 0;
        final original = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );

        await expectLater(
          RegistrationCompensator.run<void>(
            operation: () async => throw original,
            compensate: () async {
              compensationCalls++;
            },
          ),
          throwsA(same(original)),
        );
        expect(compensationCalls, 1);
      },
    );

    test(
      'failure before Firestore commit also invokes Auth compensation',
      () async {
        var deleted = false;

        await expectLater(
          RegistrationCompensator.run<void>(
            operation: () async =>
                throw FirebaseAuthException(code: 'verification-email-failed'),
            compensate: () async {
              deleted = true;
            },
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
        expect(deleted, isTrue);
      },
    );

    test(
      'compensation failure preserves both errors for administration',
      () async {
        final original = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
        final cleanup = FirebaseAuthException(code: 'requires-recent-login');

        await expectLater(
          RegistrationCompensator.run<void>(
            operation: () async => throw original,
            compensate: () async => throw cleanup,
          ),
          throwsA(
            isA<RegistrationCompensationException>()
                .having((error) => error.cause, 'cause', same(original))
                .having(
                  (error) => error.compensationError,
                  'compensationError',
                  same(cleanup),
                ),
          ),
        );
      },
    );

    test('successful operation does not invoke compensation', () async {
      var compensated = false;
      final result = await RegistrationCompensator.run<String>(
        operation: () async => 'created',
        compensate: () async {
          compensated = true;
        },
      );

      expect(result, 'created');
      expect(compensated, isFalse);
    });
  });
}
