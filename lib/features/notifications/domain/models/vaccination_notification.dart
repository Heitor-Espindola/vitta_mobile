enum VaccinationNotificationKind { overdue, upcoming, applied }

class VaccinationNotification {
  const VaccinationNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.date,
  });

  final String id;
  final VaccinationNotificationKind kind;
  final String title;
  final String message;
  final DateTime date;
}
