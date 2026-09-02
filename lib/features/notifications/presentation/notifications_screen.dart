import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/app/demo/demo_presentation.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/notifications/application/notification_read_controller.dart';
import 'package:vitta_mobile/features/notifications/domain/models/vaccination_notification.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/shared/widgets/dependent_wallet_theme.dart';
import 'package:vitta_mobile/shared/widgets/muuni_sprite.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.authRepository,
    this.vaccinationRepository,
    this.walletController,
    this.notificationReadController,
  });

  final AuthRepository? authRepository;
  final VaccinationRepository? vaccinationRepository;
  final WalletSelectionController? walletController;
  final NotificationReadController? notificationReadController;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final AuthRepository _auth =
      widget.authRepository ?? FirebaseAuthRepository();
  late final VaccinationRepository _vaccinations =
      widget.vaccinationRepository ?? FirebaseVaccinationRepository();
  late final WalletSelectionController _wallet =
      widget.walletController ?? WalletSelectionController.instance;
  late final NotificationReadController _notificationReadController =
      widget.notificationReadController ?? NotificationReadController.instance;
  Stream<List<VaccinationRecord>>? _records;
  String? _selectedPersonId;
  String? _selectedPersonName;
  bool _isViewingDependent = false;
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
      _wallet.bindCurrentPerson(user);
      final selected = _wallet.selectedPerson ?? user;
      if (!mounted) return;
      setState(() {
        _selectedPersonId = selected.effectivePersonId;
        _selectedPersonName = selected.name;
        _isViewingDependent =
            selected.effectivePersonId != user.effectivePersonId;
        _records = _vaccinations.watchRecordsByPerson(
          personId: selected.effectivePersonId,
          responsibleId: user.effectivePersonId,
        );
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
    backgroundColor: _isViewingDependent
        ? DependentWalletColors.background
        : AppColors.background,
    body: SafeArea(
      child: DependentWalletBackground(
        enabled: _isViewingDependent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                AppPageHeader(
                  title: 'Notificações',
                  subtitle: _isViewingDependent
                      ? 'Novidades da carteira de ${_selectedPersonName ?? 'seu dependente'}'
                      : 'Atualizações da sua carteira',
                  showBack: true,
                  backgroundColor: _isViewingDependent
                      ? DependentWalletColors.sky
                      : AppColors.primarySoft,
                ),
                Expanded(child: _body()),
              ],
            ),
            const Positioned(
              left: 0,
              bottom: 8,
              child: MuuniEntranceAnimation(
                key: Key('muuni-notification-animation'),
              ),
            ),
          ],
        ),
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
        if (snapshot.hasError && !DemoPresentation.isEnabled) {
          return _NotificationMessage(
            message: 'Não foi possível carregar as notificações agora.',
            onRetry: _load,
          );
        }
        final records = snapshot.data ?? const <VaccinationRecord>[];
        final items = DemoPresentation.notificationsForPresentation(records);
        _markVisibleNotificationsAsViewed(items);
        if (items.isEmpty) {
          return const _NotificationEmptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 132),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) => _NotificationCard(item: items[index]),
        );
      },
    );
  }

  void _markVisibleNotificationsAsViewed(
    List<VaccinationNotification> notifications,
  ) {
    final personId = _selectedPersonId;
    if (personId == null || notifications.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notificationReadController.markAsViewed(
        personId: personId,
        notifications: notifications,
      );
    });
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final VaccinationNotification item;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (item.kind) {
      VaccinationNotificationKind.overdue => (
        Icons.warning_amber_rounded,
        AppColors.danger,
        const Color(0xFFFFEEEE),
      ),
      VaccinationNotificationKind.upcoming => (
        Icons.event_outlined,
        AppColors.primaryDark,
        AppColors.primarySoft,
      ),
      VaccinationNotificationKind.applied => (
        Icons.check_circle_outline,
        AppColors.success,
        const Color(0xFFEAF7F0),
      ),
    };
    return Container(
      key: Key('notification-${item.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppCardStyle.decoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
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

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      key: const Key('notifications-empty-state'),
      margin: const EdgeInsets.all(AppSpacing.normal),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppCardStyle.decoration(),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primaryDark,
            child: Icon(Icons.check_rounded),
          ),
          SizedBox(height: AppSpacing.md),
          Text('Tudo certo por aqui', style: AppTypography.sectionTitle),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Você não possui notificações no momento.',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
        ],
      ),
    ),
  );
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
