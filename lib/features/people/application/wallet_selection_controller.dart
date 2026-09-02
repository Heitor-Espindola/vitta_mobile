import 'package:flutter/foundation.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';

class WalletSelectionController extends ChangeNotifier {
  WalletSelectionController();

  static final WalletSelectionController instance = WalletSelectionController();

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
  }

  void selectCurrentPerson() {
    final current = _currentPerson;
    if (current == null || isViewingCurrent) return;
    _selectedPerson = current;
    notifyListeners();
  }

  void reset() {
    _currentPerson = null;
    _selectedPerson = null;
    notifyListeners();
  }
}
