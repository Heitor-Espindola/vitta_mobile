import 'package:vitta_mobile/features/notifications/domain/models/vaccination_notification.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/services/vaccination_record_insights.dart';

abstract final class VaccinationNotificationService {
  static List<VaccinationNotification> derive(
    Iterable<VaccinationRecord> records, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final notifications = <VaccinationNotification>[];
    for (final record in VaccinationRecordInsights.nextDoses(records)) {
      final nextDose = record.effectiveNextDoseAt!;
      final situation = VaccinationRecordInsights.situation(
        record,
        now: reference,
      );
      final days = _dateOnly(nextDose).difference(_dateOnly(reference)).inDays;
      if (situation == VaccinationRecordSituation.overdue) {
        notifications.add(
          VaccinationNotification(
            id: 'overdue-${record.id}',
            kind: VaccinationNotificationKind.overdue,
            title: 'Vacina atrasada',
            message: 'Sua próxima dose de ${record.vaccineName} está atrasada.',
            date: nextDose,
          ),
        );
      } else {
        final when = days == 0
            ? 'para hoje'
            : days == 1
            ? 'para amanhã'
            : 'para daqui $days dias';
        notifications.add(
          VaccinationNotification(
            id: 'upcoming-${record.id}',
            kind: VaccinationNotificationKind.upcoming,
            title: 'Próxima dose',
            message: '${record.vaccineName} prevista $when.',
            date: nextDose,
          ),
        );
      }
    }
    for (final record in VaccinationRecordInsights.recentApplied(
      records,
      limit: 3,
    )) {
      notifications.add(
        VaccinationNotification(
          id: 'applied-${record.id}',
          kind: VaccinationNotificationKind.applied,
          title: 'Aplicação registrada',
          message:
              '${record.vaccineName} (${record.effectiveDoseLabel}) foi adicionada à sua carteira.',
          date: record.effectiveAppliedAt!,
        ),
      );
    }
    return notifications;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
