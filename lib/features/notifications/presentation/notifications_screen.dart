import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/notifications/domain/models/vaccination_notification.dart';
import 'package:vitta_mobile/features/notifications/domain/services/vaccination_notification_service.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.authRepository,
    this.vaccinationRepository,
  });

  final AuthRepository? authRepository;
  final VaccinationRepository? vaccinationRepository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final AuthRepository _auth =
      widget.authRepository ?? FirebaseAuthRepository();
  late final VaccinationRepository _vaccinations =
      widget.vaccinationRepository ?? FirebaseVaccinationRepository();
  Stream<List<VaccinationRecord>>? _records;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _auth.getCurrentUser();
      if (user == null) throw StateError('Sessão não encontrada.');
      if (!mounted) return;
      setState(() {
        _records = _vaccinations.watchPatientRecords(user.uid);
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Não foi possível carregar as notificações agora.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          const AppPageHeader(
            title: 'Notificações',
            subtitle: 'Atualizações da sua carteira',
            showBack: true,
          ),
          Expanded(child: _body()),
        ],
      ),
    ),
  );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _NotificationMessage(message: _error!, onRetry: _load);
    }
    return StreamBuilder<List<VaccinationRecord>>(
      stream: _records,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _NotificationMessage(
            message: 'Não foi possível carregar as notificações agora.',
            onRetry: _load,
          );
        }
        final items = VaccinationNotificationService.derive(
          snapshot.data ?? const [],
        );
        if (items.isEmpty) {
          return const _NotificationMessage(
            message: 'Nenhuma notificação no momento.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) => _NotificationCard(item: items[index]),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final VaccinationNotification item;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.kind) {
      VaccinationNotificationKind.overdue => (
        Icons.warning_amber_rounded,
        AppColors.danger,
      ),
      VaccinationNotificationKind.upcoming => (
        Icons.event_outlined,
        AppColors.primaryDark,
      ),
      VaccinationNotificationKind.applied => (
        Icons.check_circle_outline,
        AppColors.success,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppCardStyle.decoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(item.message, style: AppTypography.body),
                const SizedBox(height: 5),
                Text(
                  formatBrazilianDate(item.date),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 36),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
        ],
      ),
    ),
  );
}
