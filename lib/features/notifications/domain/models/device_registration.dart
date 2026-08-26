class DeviceRegistration {
  const DeviceRegistration({
    required this.deviceId,
    required this.fcmToken,
    required this.platform,
    this.notificationsEnabled = true,
    this.createdAt,
    this.lastSeenAt,
  });

  final String deviceId;
  final String fcmToken;
  final String platform;
  final bool notificationsEnabled;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
}
