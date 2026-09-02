import 'package:flutter/foundation.dart';
import 'package:vitta_mobile/features/notifications/domain/models/vaccination_notification.dart';

class NotificationReadController extends ChangeNotifier {
  NotificationReadController();

  static final instance = NotificationReadController();

  final Map<String, Set<String>> _viewedByPerson = {};

  bool hasUnread({
    required String personId,
    required Iterable<VaccinationNotification> notifications,
  }) {
    final viewed = _viewedByPerson[personId] ?? const <String>{};
    return notifications.any(
      (notification) => !viewed.contains(_fingerprint(notification)),
    );
  }

  void markAsViewed({
    required String personId,
    required Iterable<VaccinationNotification> notifications,
  }) {
    final fingerprints = notifications.map(_fingerprint).toSet();
    if (fingerprints.isEmpty) return;
    final viewed = _viewedByPerson.putIfAbsent(personId, () => <String>{});
    final previousLength = viewed.length;
    viewed.addAll(fingerprints);
    if (viewed.length != previousLength) notifyListeners();
  }

  String _fingerprint(VaccinationNotification notification) =>
      '${notification.kind.name}|${notification.id}';
}
