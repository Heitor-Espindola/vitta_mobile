import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/validators/gmail_validator.dart';
import 'package:vitta_mobile/features/auth/presentation/auth_error_mapper.dart';

class PasswordResetController extends ChangeNotifier {
  PasswordResetController(
    this._authRepository, {
    this.cooldown = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuthRepository _authRepository;
  final Duration cooldown;
  final DateTime Function() _now;

  bool isLoading = false;
  String? lastError;
  DateTime? _cooldownUntil;

  bool get isCoolingDown => _cooldownUntil?.isAfter(_now()) ?? false;

  Future<bool> sendPasswordReset(String email) async {
    if (isLoading || isCoolingDown) return false;

    final validationError = validateGmail(email);
    if (validationError != null) {
      lastError = validationError;
      notifyListeners();
      return false;
    }

    isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      await _authRepository.sendPasswordResetEmail(normalizeEmail(email));
      _cooldownUntil = _now().add(cooldown);
      return true;
    } on FirebaseAuthException catch (error) {
      // A resposta permanece neutra para não revelar contas cadastradas.
      if (error.code == 'user-not-found') {
        _cooldownUntil = _now().add(cooldown);
        return true;
      }
      lastError = mapPasswordResetError(error);
      return false;
    } catch (error) {
      lastError = mapPasswordResetError(error);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
