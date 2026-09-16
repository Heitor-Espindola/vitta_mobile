import 'package:flutter/foundation.dart';
import 'package:vitta_mobile/core/config/app_preferences.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';

class WalletSelectionController extends ChangeNotifier {
  WalletSelectionController({AppPreferences? preferences})
    : _preferences = preferences ?? AppPreferences.instance;

  static final WalletSelectionController instance = WalletSelectionController();
  final AppPreferences _preferences;

  AppUser? _currentPerson;
  AppUser? _selectedPerson;

  AppUser? get currentPerson => _currentPerson;
  AppUser? get selectedPerson => _selectedPerson ?? _currentPerson;
  String? get currentPersonId => _currentPerson?.effectivePersonId;
  String? get selectedPersonId => selectedPerson?.effectivePersonId;
  bool get isViewingCurrent =>
      currentPersonId != null && selectedPersonId == currentPersonId;

  void bindCurrentPerson(AppUser person) {
    final previousCurrentId = currentPersonId;
    _currentPerson = person;
    if (previousCurrentId != person.effectivePersonId ||
        _selectedPerson == null) {
      _selectedPerson = person;
      if (previousCurrentId != null) notifyListeners();
      return;
    }
    if (_selectedPerson?.effectivePersonId == person.effectivePersonId) {
      _selectedPerson = person;
    }
  }

  void selectPerson(AppUser person) {
    if (_currentPerson == null) {
      throw StateError('A pessoa titular ainda não foi carregada.');
    }
    if (_selectedPerson?.effectivePersonId == person.effectivePersonId) return;
    _selectedPerson = person;
    notifyListeners();
    _saveSelection();
  }

  void selectCurrentPerson() {
    final current = _currentPerson;
    if (current == null || isViewingCurrent) return;
    _selectedPerson = current;
    notifyListeners();
    _saveSelection();
  }

  Future<void> restoreSelection(Iterable<AppUser> availablePeople) async {
    final ownerId = currentPersonId;
    if (ownerId == null || !isViewingCurrent) return;
    final savedId = await _preferences.lastWalletFor(ownerId);
    if (currentPersonId != ownerId || !isViewingCurrent || savedId == null) {
      return;
    }
    for (final person in availablePeople) {
      if (person.effectivePersonId == savedId) {
        selectPerson(person);
        return;
      }
    }
  }

  void _saveSelection() {
    final ownerId = currentPersonId;
    final selectedId = selectedPersonId;
    if (ownerId != null && selectedId != null) {
      _preferences.saveWallet(ownerId, selectedId);
    }
  }

  void reset() {
    _currentPerson = null;
    _selectedPerson = null;
    notifyListeners();
  }
}
