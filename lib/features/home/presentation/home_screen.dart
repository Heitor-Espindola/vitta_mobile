import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:share_plus/share_plus.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/app/demo/demo_presentation.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/notifications/application/notification_read_controller.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/people/data/repositories/firebase_people_repository.dart';
import 'package:vitta_mobile/features/people/domain/models/family_member.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/people/presentation/dependents_screen.dart';
import 'package:vitta_mobile/features/people/presentation/family_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/services/vaccination_record_insights.dart';
import 'package:vitta_mobile/features/vaccination_card/presentation/vaccination_card_screen.dart';
import 'package:vitta_mobile/shared/widgets/dependent_wallet_theme.dart';
import 'package:vitta_mobile/shared/widgets/muuni_sprite.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';
import 'package:vitta_mobile/shared/widgets/vitta_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.authRepository,
    this.vaccinationRepository,
    this.peopleRepository,
    this.walletController,
    this.demoModeEnabled,
    this.shareBooklet,
    this.notificationReadController,
  });

  final AuthRepository? authRepository;
  final VaccinationRepository? vaccinationRepository;
  final PeopleRepository? peopleRepository;
  final WalletSelectionController? walletController;
  final bool? demoModeEnabled;
  final ShareBookletCallback? shareBooklet;
  final NotificationReadController? notificationReadController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  late final VaccinationRepository _vaccinationRepository =
      widget.vaccinationRepository ?? FirebaseVaccinationRepository();
  late final PeopleRepository _peopleRepository =
      widget.peopleRepository ?? FirebasePeopleRepository();
  late final WalletSelectionController _wallet =
      widget.walletController ?? WalletSelectionController.instance;
  late final NotificationReadController _notificationReadController =
      widget.notificationReadController ?? NotificationReadController.instance;
  late Future<_HomeData> _data;
  String? _recordsStreamPersonId;
  Stream<List<VaccinationRecord>>? _recordsStream;
  bool _sharingBooklet = false;

  bool get _demoEnabled => widget.demoModeEnabled ?? DemoPresentation.isEnabled;

  @override
  void initState() {
    super.initState();
    _wallet.addListener(_handleWalletSelection);
    _notificationReadController.addListener(_handleNotificationReadState);
    _data = _loadData();
  }

  @override
  void dispose() {
    _wallet.removeListener(_handleWalletSelection);
    _notificationReadController.removeListener(_handleNotificationReadState);
    super.dispose();
  }

  void _handleNotificationReadState() {
    if (mounted) setState(() {});
  }

  void _handleWalletSelection() {
    if (!mounted) return;
    final selectedId = _wallet.selectedPersonId;
    if (selectedId != null) {
      _notificationReadController.ensureLoaded(selectedId);
    }
    setState(() {
      _recordsStreamPersonId = null;
      _recordsStream = null;
    });
  }

  Future<_HomeData> _loadData() async {
    final user = await _authRepository.getCurrentUser();
    if (user == null) return const _HomeData();
    _wallet.bindCurrentPerson(user);
    try {
      final members = await _peopleRepository.getFamilyMembers(
        user.effectivePersonId,
      );
      await _wallet.restoreSelection(
        members
            .where(
              (member) => member.canViewVaccination(
                currentPersonId: user.effectivePersonId,
              ),
            )
            .map((member) => member.person),
      );
      await _notificationReadController.ensureLoaded(
        _wallet.selectedPersonId ?? user.effectivePersonId,
      );
      return _HomeData(
        user: user,
        familyMembers: members.isEmpty
            ? [FamilyMember(person: user, isCurrent: true)]
            : members,
      );
    } catch (_) {
      await _notificationReadController.ensureLoaded(user.effectivePersonId);
      return _HomeData(
        user: user,
        familyMembers: [FamilyMember(person: user, isCurrent: true)],
      );
    }
  }

  void _retry() => setState(() {
    _recordsStreamPersonId = null;
    _recordsStream = null;
    _data = _loadData();
  });

  Future<void> _shareWallet(_HomeData data) async {
    if (_sharingBooklet) return;
    setState(() => _sharingBooklet = true);
    try {
      final bytes = await buildVaccinationBookletPdf(
        person: data.selectedPerson ?? data.user,
        records: data.records,
      );
      final fileName = vaccinationBookletFileName();
      if (widget.shareBooklet != null) {
        await widget.shareBooklet!(bytes, fileName);
      } else {
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            title: 'Carteira Digital de Vacinação',
            subject: 'Carteira Digital de Vacinação — Vitta',
            text: 'Carteira Digital de Vacinação gerada pelo Vitta.',
            files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
            fileNameOverrides: [fileName],
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível gerar ou compartilhar sua caderneta.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sharingBooklet = false);
    }
  }

  Future<void> _openFamily() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FamilyScreen(
          authRepository: _authRepository,
          peopleRepository: _peopleRepository,
          vaccinationRepository: _vaccinationRepository,
          walletController: _wallet,
          demoModeEnabled: _demoEnabled,
        ),
      ),
    );
    if (mounted) _retry();
  }

  Future<void> _addFamilyMember() async {
    final created = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (_) => DependentsScreen(
          authRepository: _authRepository,
          peopleRepository: _peopleRepository,
          demoModeEnabled: _demoEnabled,
        ),
      ),
    );
    if (created != null && mounted) {
      _retry();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Familiar adicionado com sucesso.')),
      );
    }
  }

  void _openWallet(AppUser person) {
    _wallet.selectPerson(person);
    Navigator.of(context).pushReplacementNamed(AppRoutes.vaccinationCard);
  }

  Stream<List<VaccinationRecord>> _recordsFor(_HomeData data) {
    final user = data.user;
    final selected = _wallet.selectedPerson ?? user;
    if (user == null || selected == null) return const Stream.empty();
    final selectedId = selected.effectivePersonId;
    if (_recordsStreamPersonId == selectedId && _recordsStream != null) {
      return _recordsStream!;
    }
    _recordsStreamPersonId = selectedId;
    _recordsStream = _vaccinationRepository.watchRecordsByPerson(
      personId: selectedId,
      responsibleId: user.effectivePersonId,
    );
    return _recordsStream!;
  }

  @override
  Widget build(BuildContext context) => VittaMobileShell(
    title: 'Início',
    currentTab: VittaTab.home,
    showTopBar: false,
    body: FutureBuilder<_HomeData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data?.user == null) {
          return _HomeError(onRetry: _retry);
        }
        final baseData = snapshot.data!;
        return StreamBuilder<List<VaccinationRecord>>(
          stream: _recordsFor(baseData),
          builder: (context, recordsSnapshot) {
            final realRecords =
                recordsSnapshot.data ?? const <VaccinationRecord>[];
            final usingDemoRecords = _demoEnabled && realRecords.isEmpty;
            final notifications = DemoPresentation.notificationsForPresentation(
              realRecords,
              enabled: _demoEnabled,
            );
            final data = _HomeData(
              user: baseData.user,
              selectedPerson: _wallet.selectedPerson ?? baseData.user,
              familyMembers: baseData.familyMembers,
              records: DemoPresentation.recordsForPresentation(
                realRecords,
                enabled: _demoEnabled,
              ),
            );
            final selectedPersonId =
                data.selectedPerson?.effectivePersonId ??
                data.user!.effectivePersonId;
            return _buildContent(
              data,
              loading:
                  recordsSnapshot.connectionState == ConnectionState.waiting &&
                  !usingDemoRecords,
              hasError: recordsSnapshot.hasError && !usingDemoRecords,
              hasNotifications: _notificationReadController.hasUnread(
                personId: selectedPersonId,
                notifications: notifications,
              ),
            );
          },
        );
      },
    ),
  );

  Widget _buildContent(
    _HomeData data, {
    required bool loading,
    required bool hasError,
    required bool hasNotifications,
  }) {
    final upcoming = data.upcoming;
    final recent = data.recent;
    return DependentWalletBackground(
      enabled: !data.isViewingCurrent,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.list(
              children: [
                _HomeHeader(
                  name: _firstName(data.user?.name),
                  hasNotifications: hasNotifications,
                ),
                if (!data.isViewingCurrent) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ViewingWalletBanner(
                    personName: data.selectedPerson?.name ?? 'Familiar',
                    onReturn: _wallet.selectCurrentPerson,
                  ),
                ],
                const SizedBox(height: 16),
                _SummaryCard(
                  appliedCount: data.appliedCount,
                  message: data.summaryMessage,
                  onShare: () => _shareWallet(data),
                  sharing: _sharingBooklet,
                  isDependent: !data.isViewingCurrent,
                ),
                const SizedBox(height: 20),
                _WalletsSection(
                  user: data.user!,
                  familyMembers: data.familyMembers,
                  selectedPersonId: data.selectedPerson?.effectivePersonId,
                  demoEnabled: _demoEnabled,
                  onOpenFamily: _openFamily,
                  onAddFamily: _addFamilyMember,
                  onSelect: _openWallet,
                ),
                const SizedBox(height: 22),
                const _SectionHeader(title: 'Próximas doses'),
                const SizedBox(height: 14),
                if (loading)
                  const _HomeLoading()
                else if (hasError)
                  _HomeError(onRetry: _retry)
                else if (upcoming.isEmpty)
                  const _EmptyCard(
                    icon: Icons.event_available_outlined,
                    title: 'Nenhuma próxima dose cadastrada',
                    text:
                        'Sua carteira não possui doses futuras registradas no momento.',
                  )
                else
                  _DoseTimeline(records: upcoming),
                const SizedBox(height: 30),
                const _SectionHeader(title: 'Últimas vacinas'),
                const SizedBox(height: 14),
                if (loading)
                  const _HomeLoading()
                else if (hasError)
                  const SizedBox.shrink()
                else if (recent.isEmpty)
                  const _EmptyCard(
                    icon: Icons.vaccines_outlined,
                    title: 'Nenhuma aplicação registrada ainda',
                    text:
                        'Quando um profissional registrar uma aplicação, ela aparecerá aqui.',
                  )
                else
                  ...recent.map(_RecentVaccineCard.new),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name, required this.hasNotifications});

  final String name;
  final bool hasNotifications;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return OverflowBox(
      maxWidth: width,
      fit: OverflowBoxFit.deferToChild,
      child: Container(
        key: const Key('home-header-band'),
        width: width,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF6FC), Color(0xFFF8FBFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(bottom: BorderSide(color: Color(0xFFE1EDF4))),
        ),
        child: Row(
          children: [
            const VittaLogo(size: 44, semanticLabel: 'Logo Vitta'),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                    ),
                  ),
                  const Text(
                    'Minha Carteira',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Digital de Vacinação',
                    style: TextStyle(fontSize: 11, color: Color(0xFF718096)),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notifications),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shadowColor: const Color(0x25000000),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: 'Notificações',
                ),
                if (hasNotifications)
                  Positioned(
                    right: 8,
                    top: 7,
                    child: Container(
                      key: const Key('notification-badge'),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE84B4B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.appliedCount,
    required this.message,
    required this.onShare,
    required this.sharing,
    required this.isDependent,
  });

  final int appliedCount;
  final String message;
  final VoidCallback onShare;
  final bool sharing;
  final bool isDependent;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('home-summary-card'),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDependent
            ? const [Color(0xFF60B7DC), Color(0xFF4D93C5)]
            : const [Color(0xFF3C9FE3), Color(0xFF267BB8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x383A92D3),
          blurRadius: 22,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$appliedCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'vacinas aplicadas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('share-wallet-button'),
            onPressed: sharing ? null : onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            ),
            icon: sharing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded, size: 18),
            label: Text(
              sharing ? 'Gerando caderneta...' : 'Compartilhar caderneta',
            ),
          ),
        ),
      ],
    ),
  );
}

class _ViewingWalletBanner extends StatelessWidget {
  const _ViewingWalletBanner({
    required this.personName,
    required this.onReturn,
  });

  final String personName;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
    decoration: AppCardStyle.decoration(
      color: DependentWalletColors.peach,
    ).copyWith(border: Border.all(color: DependentWalletColors.border)),
    child: Row(
      children: [
        const MuuniTimedPresence(frame: 11, size: 44),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Visualizando: $personName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DependentWalletColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        OutlinedButton.icon(
          key: const Key('return-to-own-wallet-button'),
          onPressed: onReturn,
          icon: const Icon(Icons.person_outline_rounded, size: 16),
          label: const Text('Minha carteira'),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .88),
            foregroundColor: AppColors.primaryDark,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    ),
  );
}

class _WalletsSection extends StatelessWidget {
  const _WalletsSection({
    required this.user,
    required this.familyMembers,
    required this.selectedPersonId,
    required this.demoEnabled,
    required this.onOpenFamily,
    required this.onAddFamily,
    required this.onSelect,
  });

  final AppUser user;
  final List<FamilyMember> familyMembers;
  final String? selectedPersonId;
  final bool demoEnabled;
  final VoidCallback onOpenFamily;
  final VoidCallback onAddFamily;
  final ValueChanged<AppUser> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(child: _SectionHeader(title: 'Minha família')),
          OutlinedButton.icon(
            key: const Key('manage-family-button'),
            onPressed: onOpenFamily,
            icon: const Icon(Icons.group_outlined, size: 17),
            label: const Text('Gerenciar'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 116,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _WalletPersonCard(
              name: user.name,
              subtitle: 'Minha carteira',
              detail: 'Titular',
              color: const Color(0xFFEAF5FC),
              icon: Icons.person_outline_rounded,
              selected: selectedPersonId == user.effectivePersonId,
              onTap: () => onSelect(user),
            ),
            ...familyMembers.where((member) => !member.isCurrent).map((member) {
              final canOpen = member.canViewVaccination(
                currentPersonId: user.effectivePersonId,
              );
              return Padding(
                padding: const EdgeInsets.only(left: 10),
                child: _WalletPersonCard(
                  name: member.person.name,
                  subtitle: member.person.relationshipToGuardian ?? 'Familiar',
                  detail: canOpen
                      ? 'Carteira disponível'
                      : 'Acesso indisponível',
                  color: familyWalletCardColor(member.person.birthDate),
                  icon: Icons.family_restroom_outlined,
                  selected: selectedPersonId == member.person.effectivePersonId,
                  onTap: canOpen ? () => onSelect(member.person) : onOpenFamily,
                ),
              );
            }),
            const SizedBox(width: 10),
            _AddDependentCard(onTap: onAddFamily),
          ],
        ),
      ),
    ],
  );
}

class _WalletPersonCard extends StatelessWidget {
  const _WalletPersonCard({
    required this.name,
    required this.subtitle,
    required this.detail,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String detail;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 194,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withValues(alpha: .88),
              foregroundColor: vittaDarkBlue,
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name.trim().isEmpty ? 'Usuário' : name.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF426B86),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: vittaDarkBlue,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryDark,
                size: 18,
              ),
          ],
        ),
      ),
    ),
  );
}

Color familyWalletCardColor(DateTime? birthDate, {DateTime? now}) {
  if (birthDate == null) return const Color(0xFFE9F5FD);
  final today = now ?? DateTime.now();
  var age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age >= 12 && age < 18
      ? const Color(0xFFE4F5EC)
      : const Color(0xFFE9F5FD);
}

class _AddDependentCard extends StatelessWidget {
  const _AddDependentCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Adicionar familiar',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 126,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF9AC8E4),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFFEAF5FC),
              foregroundColor: vittaBlue,
              child: Icon(Icons.add_rounded),
            ),
            SizedBox(height: 4),
            Text(
              'Adicionar\nfamiliar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
  );
}

class _DoseTimeline extends StatelessWidget {
  const _DoseTimeline({required this.records});

  final List<VaccinationRecord> records;

  @override
  Widget build(BuildContext context) => Column(
    children: records.map((record) {
      final overdue =
          VaccinationRecordInsights.situation(record) ==
          VaccinationRecordSituation.overdue;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _UpcomingDoseCard(record: record, overdue: overdue),
      );
    }).toList(),
  );
}

class _UpcomingDoseCard extends StatelessWidget {
  const _UpcomingDoseCard({required this.record, required this.overdue});

  final VaccinationRecord record;
  final bool overdue;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: overdue ? const Color(0xFFFFEEEE) : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(
        color: overdue ? const Color(0xFFFFD2D2) : const Color(0xFFE8EEF3),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.vaccineName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.dose,
                style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
              ),
              const SizedBox(height: 8),
              Text(
                overdue
                    ? 'Atrasada desde ${formatBrazilianDate(record.nextDoseDate)}'
                    : 'Próxima dose em ${formatBrazilianDate(record.nextDoseDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: overdue
                      ? const Color(0xFFC53D44)
                      : const Color(0xFF426B86),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Icon(
          overdue ? Icons.warning_amber_rounded : Icons.calendar_month_outlined,
          color: overdue ? const Color(0xFFE85B61) : vittaBlue,
        ),
      ],
    ),
  );
}

class _RecentVaccineCard extends StatelessWidget {
  const _RecentVaccineCard(this.record);

  final VaccinationRecord record;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('recent-vaccine-surface'),
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: AppCardStyle.decoration(color: Colors.white),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFDDEFFC),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.vaccines_outlined, color: vittaDarkBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.vaccineName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${record.dose} • ${formatBrazilianDate(record.applicationDate)}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: vittaBlue, size: 22),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.normal),
    decoration: AppCardStyle.decoration(),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(text, style: AppTypography.caption),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, color: vittaBlue, size: 38),
          const SizedBox(height: 12),
          const Text(
            'Não foi possível carregar sua carteira agora.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

class _HomeData {
  const _HomeData({
    this.user,
    this.selectedPerson,
    this.familyMembers = const [],
    this.records = const [],
  });

  final AppUser? user;
  final AppUser? selectedPerson;
  final List<FamilyMember> familyMembers;
  final List<VaccinationRecord> records;

  bool get isViewingCurrent =>
      selectedPerson?.effectivePersonId == user?.effectivePersonId;

  int get appliedCount => VaccinationRecordInsights.appliedCount(records);

  bool get hasOverdue => records.any(
    (record) =>
        record.effectiveNextDoseAt != null &&
        VaccinationRecordInsights.situation(record) ==
            VaccinationRecordSituation.overdue,
  );

  bool get hasUpcoming => records.any(
    (record) =>
        record.effectiveNextDoseAt != null &&
        VaccinationRecordInsights.situation(record) ==
            VaccinationRecordSituation.upcoming,
  );

  String get summaryMessage {
    if (hasOverdue) {
      return 'Você possui uma dose que precisa de atenção.';
    }
    if (hasUpcoming) return 'Você possui próximas doses programadas.';
    if (appliedCount > 0) {
      return 'Suas aplicações registradas estão disponíveis.';
    }
    return 'Sua carteira ainda não possui aplicações.';
  }

  List<VaccinationRecord> get upcoming {
    return VaccinationRecordInsights.nextDoses(
      records,
    ).take(3).toList(growable: false);
  }

  List<VaccinationRecord> get recent {
    return VaccinationRecordInsights.recentApplied(records, limit: 3);
  }
}

String _firstName(String? name) {
  final value = name?.trim();
  return value == null || value.isEmpty
      ? 'usuário'
      : value.split(RegExp(r'\s+')).first;
}
