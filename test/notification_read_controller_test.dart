import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/notifications/application/notification_read_controller.dart';
import 'package:vitta_mobile/features/notifications/domain/models/vaccination_notification.dart';

void main() {
  test(
    'viewed notifications stay read and a new notification becomes unread',
    () async {
      final controller = NotificationReadController();
      final first = VaccinationNotification(
        id: 'upcoming-record-1',
        kind: VaccinationNotificationKind.upcoming,
        title: 'Próxima dose',
        message: 'BCG prevista para amanhã.',
        date: DateTime(2026, 9, 3),
      );

      expect(
        controller.hasUnread(personId: 'person-1', notifications: [first]),
        isTrue,
      );
      await controller.markAsViewed(
        personId: 'person-1',
        notifications: [first],
      );
      expect(
        controller.hasUnread(personId: 'person-1', notifications: [first]),
        isFalse,
      );

      final second = VaccinationNotification(
        id: 'applied-record-2',
        kind: VaccinationNotificationKind.applied,
        title: 'Aplicação registrada',
        message: 'Influenza foi adicionada à sua carteira.',
        date: DateTime(2026, 9, 2),
      );
      expect(
        controller.hasUnread(
          personId: 'person-1',
          notifications: [first, second],
        ),
        isTrue,
      );
      expect(
        controller.hasUnread(personId: 'person-2', notifications: [first]),
        isTrue,
      );
    },
  );

  test('a changed notification kind becomes unread again', () async {
    final controller = NotificationReadController();
    final original = VaccinationNotification(
      id: 'upcoming-record-1',
      kind: VaccinationNotificationKind.upcoming,
      title: 'Próxima dose',
      message: 'BCG prevista para daqui 2 dias.',
      date: DateTime(2026, 9, 4),
    );
    await controller.markAsViewed(
      personId: 'person-1',
      notifications: [original],
    );

    final updated = VaccinationNotification(
      id: original.id,
      kind: VaccinationNotificationKind.overdue,
      title: 'Vacina atrasada',
      message: 'Sua próxima dose de BCG está atrasada.',
      date: DateTime(2026, 9, 3),
    );
    expect(
      controller.hasUnread(personId: 'person-1', notifications: [updated]),
      isTrue,
    );
  });
}
