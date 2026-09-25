import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitta_mobile/features/notifications/domain/models/vaccination_notification.dart';

class NotificationReadController extends ChangeNotifier {
  NotificationReadController({SharedPreferencesAsync? storage})
    : _providedStorage = storage;

  static final instance = NotificationReadController();
  final SharedPreferencesAsync? _providedStorage;
  SharedPreferencesAsync? get _storage {
    if (_providedStorage != null) return _providedStorage;
    try {
      return SharedPreferencesAsync();
    } catch (_) {
      return null;
    }
  }

  final Map<String, Set<String>> _viewedByPerson = {};
  final Set<String> _loadedPeople = {};
  final Map<String, Future<void>> _loadingPeople = {};

  Future<void> ensureLoaded(String personId) {
    if (_loadedPeople.contains(personId)) return Future.value();
    return _loadingPeople.putIfAbsent(personId, () => _load(personId));
  }

  Future<void> _load(String personId) async {
    try {
      final stored = await _storage?.getStringList(
        'viewed_notifications_$personId',
      );
      final normalized = (stored ?? const <String>[])
          .map(_normalizeStoredFingerprint)
          .where((value) => value.isNotEmpty)
          .toSet();
      _viewedByPerson
          .putIfAbsent(personId, () => <String>{})
          .addAll(normalized);

      // Persist the normalized representation once so installations that used
      // the old date-based fingerprint are migrated transparently.
      if (stored != null && !setEquals(stored.toSet(), normalized)) {
        await _storage?.setStringList(
          'viewed_notifications_$personId',
          normalized.toList()..sort(),
        );
      }
    } catch (_) {
      // Notification state is best-effort and must never block app startup.
    } finally {
      _loadedPeople.add(personId);
      _loadingPeople.remove(personId);
      notifyListeners();
    }
  }

  bool hasUnread({
    required String personId,
    required Iterable<VaccinationNotification> notifications,
  }) {
    // Do not flash an unread badge while persisted state is still loading.
    if (!_loadedPeople.contains(personId)) return false;
    final viewed = _viewedByPerson[personId] ?? const <String>{};
    return notifications.any(
      (notification) => !viewed.contains(_fingerprint(notification)),
    );
  }

  Future<void> markAsViewed({
    required String personId,
    required Iterable<VaccinationNotification> notifications,
  }) async {
    final fingerprints = notifications.map(_fingerprint).toSet();
    if (fingerprints.isEmpty) return;
    await ensureLoaded(personId);
    final viewed = _viewedByPerson.putIfAbsent(personId, () => <String>{});
    final previousLength = viewed.length;
    viewed.addAll(fingerprints);
    if (viewed.length != previousLength) {
      notifyListeners();
      try {
        await _storage?.setStringList(
          'viewed_notifications_$personId',
          viewed.toList()..sort(),
        );
      } catch (_) {
        // Keep the current session consistent even if local persistence fails.
      }
    }
  }

  String _fingerprint(VaccinationNotification notification) =>
      '${notification.kind.name}|${notification.id}';

  String _normalizeStoredFingerprint(String value) {
    final firstSeparator = value.indexOf('|');
    if (firstSeparator < 0) return value;
    final secondSeparator = value.indexOf('|', firstSeparator + 1);
    return secondSeparator < 0 ? value : value.substring(0, secondSeparator);
  }
}
