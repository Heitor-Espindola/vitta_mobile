import 'package:flutter/foundation.dart';
import 'package:vitta_mobile/features/notifications/domain/models/vaccination_notification.dart';
import 'package:vitta_mobile/features/notifications/domain/services/vaccination_notification_service.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';

/// Dados exclusivamente locais para apresentar uma carteira ainda vazia.
///
/// Nenhum item desta classe é enviado ao Firebase/SQL Connect. Os dados reais
/// continuam prioritários e substituem os exemplos assim que a primeira
/// aplicação profissional é registrada.
abstract final class DemoPresentation {
  /// Compatibilidade com builds antigos voltados a screenshots acadêmicos.
  static const isEnabled = bool.fromEnvironment(
    'VITTA_DEMO_MODE',
    defaultValue: false,
  );

  /// O APK normal mostra exemplos em carteiras realmente vazias para que novos
  /// usuários conheçam a experiência antes do primeiro registro profissional.
  static const showEmptyWalletExamples =
      bool.fromEnvironment(
        'VITTA_EMPTY_WALLET_EXAMPLES',
        defaultValue: false,
      ) ||
      kReleaseMode;

  static bool isIllustrativeRecord(VaccinationRecord record) =>
      record.source == 'demo_presentation';

  static List<VaccinationRecord> recordsForPresentation(
    Iterable<VaccinationRecord> records, {
    bool? enabled,
  }) {
    final values = List<VaccinationRecord>.unmodifiable(records);
    if (values.isNotEmpty ||
        !(enabled ?? (showEmptyWalletExamples || isEnabled))) {
      return values;
    }
    return demoRecords;
  }

  static List<VaccinationNotification> notificationsForPresentation(
    Iterable<VaccinationRecord> records, {
    bool? enabled,
    DateTime? now,
  }) {
    final values = List<VaccinationRecord>.unmodifiable(records);
    if (values.isNotEmpty) {
      return VaccinationNotificationService.derive(values, now: now);
    }
    if (!(enabled ?? (showEmptyWalletExamples || isEnabled))) return const [];
    final reference = now ?? DateTime.now();
    return [
      VaccinationNotification(
        id: 'demo-influenza-overdue',
        kind: VaccinationNotificationKind.overdue,
        title: 'Vacina atrasada',
        message: 'Sua dose de Influenza está atrasada.',
        date: reference.subtract(const Duration(days: 8)),
      ),
      VaccinationNotification(
        id: 'demo-triplice-applied',
        kind: VaccinationNotificationKind.applied,
        title: 'Aplicação registrada',
        message: 'Nova aplicação registrada: Tríplice Viral.',
        date: reference.subtract(const Duration(days: 3)),
      ),
      VaccinationNotification(
        id: 'demo-hpv-upcoming',
        kind: VaccinationNotificationKind.upcoming,
        title: 'Próxima dose',
        message: 'Próxima dose de HPV em 14 dias.',
        date: reference.add(const Duration(days: 14)),
      ),
      VaccinationNotification(
        id: 'demo-wallet-updated',
        kind: VaccinationNotificationKind.applied,
        title: 'Carteira atualizada',
        message: 'Sua carteira foi atualizada com novas informações.',
        date: reference.subtract(const Duration(days: 1)),
      ),
      VaccinationNotification(
        id: 'demo-influenza-campaign',
        kind: VaccinationNotificationKind.upcoming,
        title: 'Campanha disponível',
        message: 'Campanha de vacinação contra Influenza disponível.',
        date: reference,
      ),
    ];
  }

  static List<VaccinationRecord> get demoRecords {
    final now = DateTime.now();
    return [
      VaccinationRecord(
        id: 'demo-bcg',
        vaccineId: 'bcg',
        vaccineName: 'BCG',
        doseLabel: 'Dose única',
        doseNumber: 1,
        appliedAt: now.subtract(const Duration(days: 1800)),
        lot: 'BCG-2025-041',
        manufacturer: 'Fiocruz',
        facilityName: 'UBS Jardim das Flores',
        professionalUid: 'demo-professional',
        source: 'demo_presentation',
      ),
      VaccinationRecord(
        id: 'demo-hepatite-b',
        vaccineId: 'hepatite-b',
        vaccineName: 'Hepatite B',
        doseLabel: '3ª dose',
        doseNumber: 3,
        appliedAt: now.subtract(const Duration(days: 900)),
        lot: 'HBV-2025-102',
        manufacturer: 'Instituto Butantan',
        facilityName: 'UBS Jardim das Flores',
        professionalUid: 'demo-professional',
        source: 'demo_presentation',
      ),
      VaccinationRecord(
        id: 'demo-triplice-viral',
        vaccineId: 'triplice-viral',
        vaccineName: 'Tríplice Viral',
        doseLabel: '2ª dose',
        doseNumber: 2,
        appliedAt: now.subtract(const Duration(days: 3)),
        lot: 'TV-2026-018',
        manufacturer: 'Fiocruz',
        facilityName: 'UBS Jardim das Flores',
        professionalUid: 'demo-professional',
        source: 'demo_presentation',
      ),
      VaccinationRecord(
        id: 'demo-hpv',
        vaccineId: 'hpv',
        vaccineName: 'HPV',
        doseLabel: '2ª dose',
        doseNumber: 2,
        nextDoseAt: now.add(const Duration(days: 14)),
        facilityName: 'UBS Jardim das Flores',
        source: 'demo_presentation',
      ),
      VaccinationRecord(
        id: 'demo-influenza',
        vaccineId: 'influenza',
        vaccineName: 'Influenza',
        doseLabel: 'Dose anual',
        nextDoseAt: now.subtract(const Duration(days: 8)),
        facilityName: 'UBS Jardim das Flores',
        source: 'demo_presentation',
      ),
      VaccinationRecord(
        id: 'demo-febre-amarela',
        vaccineId: 'febre-amarela',
        vaccineName: 'Febre Amarela',
        doseLabel: 'Dose única',
        doseNumber: 1,
        appliedAt: now.subtract(const Duration(days: 420)),
        lot: 'FA-2025-223',
        manufacturer: 'Bio-Manguinhos',
        facilityName: 'UBS Jardim das Flores',
        professionalUid: 'demo-professional',
        source: 'demo_presentation',
      ),
    ];
  }
}
