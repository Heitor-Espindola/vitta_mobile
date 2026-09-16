import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:vitta_mobile/core/config/app_preferences.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/notifications/application/notification_read_controller.dart';
import 'package:vitta_mobile/features/notifications/domain/models/vaccination_notification.dart';
import 'package:vitta_mobile/features/home/presentation/home_screen.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/profile/presentation/profile_detail_screens.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/presentation/models/vaccination_occurrence.dart';
import 'package:vitta_mobile/shared/widgets/muuni_sprite.dart';

void main() {
  late SharedPreferencesAsync storage;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    storage = SharedPreferencesAsync();
  });

  test('application and next dose have separate badges and dates', () {
    final record = VaccinationRecord(
      id: 'bcg',
      vaccineName: 'BCG',
      appliedAt: DateTime(2026, 9, 14),
      nextDoseAt: DateTime(2026, 10, 14),
      professionalUid: 'uid-secret',
    );
    final occurrences = VaccinationOccurrence.fromRecords([
      record,
    ], now: DateTime(2026, 9, 16));
    expect(occurrences.map((event) => event.kind), [
      VaccinationOccurrenceKind.applied,
      VaccinationOccurrenceKind.upcoming,
    ]);
    expect(occurrences.map((event) => event.label), ['Aplicada', 'Próxima']);
    expect(occurrences.map((event) => event.datePrefix), [
      'Aplicada em',
      'Próxima dose em',
    ]);
    expect(occurrences.map((event) => event.date.day), [14, 14]);
    expect(occurrences.map((event) => event.date.month), [9, 10]);
  });

  test('overdue occurrence is derived, never persisted', () {
    final record = VaccinationRecord(
      id: 'bcg',
      vaccineName: 'BCG',
      nextDoseAt: DateTime(2026, 9, 14),
    );
    final event = VaccinationOccurrence.fromRecords([
      record,
    ], now: DateTime(2026, 9, 16)).single;
    expect(event.kind, VaccinationOccurrenceKind.overdue);
    expect(event.label, 'Atrasada');
    expect(event.datePrefix, 'Dose prevista para');
  });

  test('family palette is blue for children and mint for teenagers', () {
    final now = DateTime(2026, 9, 16);
    expect(
      familyWalletCardColor(DateTime(2020, 1, 1), now: now),
      const Color(0xFFE9F5FD),
    );
    expect(
      familyWalletCardColor(DateTime(2010, 1, 1), now: now),
      const Color(0xFFE4F5EC),
    );
  });

  test(
    'remembered wallet restores only for its owner and available people',
    () async {
      final preferences = AppPreferences(storage: storage);
      await preferences.load();
      final wallet = WalletSelectionController(preferences: preferences)
        ..bindCurrentPerson(owner);
      wallet.selectPerson(child);
      expect(await preferences.lastWalletFor('owner'), isNull);
      await preferences.setRememberLastWallet(true, ownerId: 'owner');
      wallet.selectCurrentPerson();
      wallet.selectPerson(child);
      final restartedPreferences = AppPreferences(storage: storage);
      await restartedPreferences.load();
      final restarted = WalletSelectionController(
        preferences: restartedPreferences,
      )..bindCurrentPerson(owner);
      await restarted.restoreSelection([owner]);
      expect(restarted.selectedPersonId, 'owner');
      await restarted.restoreSelection([owner, child]);
      expect(restarted.selectedPersonId, 'child');
      expect(await restartedPreferences.lastWalletFor('other-owner'), isNull);
      await restartedPreferences.setRememberLastWallet(false, ownerId: 'owner');
      expect(await restartedPreferences.lastWalletFor('owner'), isNull);
    },
  );

  test(
    'read fingerprint survives recreation and a new date is unread',
    () async {
      final first = VaccinationNotification(
        id: 'bcg',
        kind: VaccinationNotificationKind.applied,
        title: 'BCG',
        message: 'Aplicação',
        date: DateTime(2026, 9, 14),
      );
      final controller = NotificationReadController(storage: storage);
      await controller.markAsViewed(personId: 'child', notifications: [first]);
      final restarted = NotificationReadController(storage: storage);
      await restarted.ensureLoaded('child');
      expect(
        restarted.hasUnread(personId: 'child', notifications: [first]),
        isFalse,
      );
      expect(
        restarted.hasUnread(personId: 'owner', notifications: [first]),
        isTrue,
      );
      final changed = VaccinationNotification(
        id: first.id,
        kind: first.kind,
        title: first.title,
        message: first.message,
        date: DateTime(2026, 9, 15),
      );
      expect(
        restarted.hasUnread(personId: 'child', notifications: [changed]),
        isTrue,
      );
    },
  );

  testWidgets(
    'settings contains only functional switches and Muuni respects toggle',
    (tester) async {
      final preferences = AppPreferences(storage: storage);
      await preferences.load();
      await tester.pumpWidget(
        MaterialApp(home: ProfileSettingsScreen(preferences: preferences)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      expect(find.text('Idioma'), findsNothing);
      expect(find.text('Aparência'), findsNothing);
      expect(find.text('Sessão'), findsNothing);
      await tester.tap(find.text('Animações da Muuni'));
      await tester.pumpAndSettle();
      expect(preferences.animationsEnabled, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuuniEntranceAnimation(preferences: preferences),
          ),
        ),
      );
      expect(find.byType(MuuniSpriteFrame), findsOneWidget);
      expect(
        tester.widget<MuuniSpriteFrame>(find.byType(MuuniSpriteFrame)).frame,
        11,
      );
    },
  );
}

const owner = AppUser(
  uid: 'owner',
  personId: 'owner',
  name: 'Owner',
  email: 'owner@example.com',
  role: 'responsible',
);
const child = AppUser(
  uid: 'child',
  personId: 'child',
  name: 'Child',
  email: '',
  role: 'dependent',
);
