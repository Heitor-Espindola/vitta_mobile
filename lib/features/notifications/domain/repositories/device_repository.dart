import 'package:vitta_mobile/features/notifications/domain/models/device_registration.dart';

/// Contrato reservado para a futura integração com Firebase Messaging.
/// Nenhum token é obtido enquanto `firebase_messaging` não estiver habilitado.
abstract interface class DeviceRepository {
  Future<void> saveDevice(String userId, DeviceRegistration device);
  Future<void> removeDevice(String userId, String deviceId);
}
