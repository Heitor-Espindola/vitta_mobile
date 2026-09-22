import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Only presentation choices are stored locally; clinical records remain remote.
class AppPreferences extends ChangeNotifier {
  AppPreferences({SharedPreferencesAsync? storage})
    : _providedStorage = storage;

  static final instance = AppPreferences();
  final SharedPreferencesAsync? _providedStorage;
  SharedPreferencesAsync? get _storage {
    if (_providedStorage != null) return _providedStorage;
    try {
      return SharedPreferencesAsync();
    } catch (_) {
      // Widget tests can run without a registered platform implementation.
      return null;
    }
  }

  bool darkModeEnabled = false;
  double textScale = 1;
  bool rememberLastWallet = false;

  Future<void> load() async {
    darkModeEnabled = await _storage?.getBool('dark_mode') ?? false;
    textScale = _validatedTextScale(
      await _storage?.getDouble('text_scale') ?? 1,
    );
    rememberLastWallet = await _storage?.getBool('remember_wallet') ?? false;
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool value) async {
    await _storage?.setBool('dark_mode', value);
    darkModeEnabled = value;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    final validValue = _validatedTextScale(value);
    await _storage?.setDouble('text_scale', validValue);
    textScale = validValue;
    notifyListeners();
  }

  Future<void> setRememberLastWallet(bool value, {String? ownerId}) async {
    await _storage?.setBool('remember_wallet', value);
    if (!value && ownerId != null) {
      await _storage?.remove('selected_wallet_$ownerId');
    }
    rememberLastWallet = value;
    notifyListeners();
  }

  Future<String?> lastWalletFor(String ownerId) async {
    if (!rememberLastWallet) return null;
    return _storage?.getString('selected_wallet_$ownerId');
  }

  Future<void> saveWallet(String ownerId, String selectedId) async {
    if (!rememberLastWallet) return;
    await _storage?.setString('selected_wallet_$ownerId', selectedId);
  }

  static double _validatedTextScale(double value) {
    const options = <double>[.9, 1, 1.15, 1.3];
    return options.contains(value) ? value : 1;
  }
}
