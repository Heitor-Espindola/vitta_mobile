import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/demo/demo_presentation.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/services/vaccination_record_insights.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.authRepository,
    this.vaccinationRepository,
    this.peopleRepository,
  });

  final AuthRepository? authRepository;
  final VaccinationRepository? vaccinationRepository;
  final PeopleRepository? peopleRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  late final VaccinationRepository _vaccinationRepository =
      widget.vaccinationRepository ?? FirebaseVaccinationRepository();
  late Future<_HomeData> _data = _loadData();
  String? _recordsStreamPersonId;
  Stream<List<VaccinationRecord>>? _recordsStream;

  Future<_HomeData> _loadData() async {
    final user = await _authRepository.getCurrentUser();
    if (user == null) return const _HomeData();
    return _HomeData(user: user);
  }

  void _retry() => setState(() {
    _recordsStreamPersonId = null;
    _recordsStream = null;
    _data = _loadData();
  });

  Future<void> _showDependentsInfo() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.family_restroom_outlined, color: vittaBlue),
        title: const Text('Vincular dependente'),
        content: const Text(
          'O vínculo familiar com acesso à carteira será disponibilizado '
          'quando houver validação segura. Esta área já está preparada para '
          'acompanhar suas carteiras.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Stream<List<VaccinationRecord>> _recordsFor(_HomeData data) {
    final user = data.user;
    if (user == null) return const Stream.empty();
    if (_recordsStreamPersonId == user.uid && _recordsStream != null) {
      return _recordsStream!;
    }
    _recordsStreamPersonId = user.uid;
    _recordsStream = _vaccinationRepository.watchPatientRecords(user.uid);
    return _recordsStream!;
  }

  @override
  Widget build(BuildContext context) => VittaMobileShell(
    title: 'Início',
    currentTab: VittaTab.home,
    showGreetingHeader: true,
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
            final usingDemoRecords =
                DemoPresentation.isEnabled && realRecords.isEmpty;
            final data = _HomeData(
              user: baseData.user,
              records: DemoPresentation.recordsForPresentation(realRecords),
            );
            return _buildContent(
              data,
              loading:
                  recordsSnapshot.connectionState == ConnectionState.waiting &&
                  !usingDemoRecords,
              hasError: recordsSnapshot.hasError && !usingDemoRecords,
              showDemoDependent: usingDemoRecords,
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
    required bool showDemoDependent,
  }) {
    final upcoming = data.upcoming;
    final recent = data.recent;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          sliver: SliverList.list(
            children: [
              _HomeHeader(name: _firstName(data.user?.name)),
              const SizedBox(height: 16),
              _SummaryCard(appliedCount: data.appliedCount),
              const SizedBox(height: 20),
              _WalletsSection(
                user: data.user!,
                appliedCount: data.appliedCount,
                showDemoDependent: showDemoDependent,
                onAddDependent: _showDependentsInfo,
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
                  text: 'Nenhuma próxima dose cadastrada.',
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
                  text: 'Nenhuma vacina registrada ainda.',
                )
              else
                ...recent.map(_RecentVaccineCard.new),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5FC),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x140A5B91), blurRadius: 12),
          ],
        ),
        child: const Icon(Icons.vaccines_outlined, color: vittaBlue, size: 23),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
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
          Positioned(
            right: 8,
            top: 7,
            child: Container(
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
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.appliedCount});

  final int appliedCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3C9FE3), Color(0xFF267BB8)],
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
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 4),
              Text(
                'Sua carteira digital está atualizada',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
        ),
      ],
    ),
  );
}

class _WalletsSection extends StatelessWidget {
  const _WalletsSection({
    required this.user,
    required this.appliedCount,
    required this.showDemoDependent,
    required this.onAddDependent,
  });

  final AppUser user;
  final int appliedCount;
  final bool showDemoDependent;
  final VoidCallback onAddDependent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionHeader(title: 'Carteiras'),
      const SizedBox(height: 12),
      SizedBox(
        height: 116,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _WalletPersonCard(
              name: user.name,
              subtitle: 'Minha carteira',
              detail: '$appliedCount aplicações',
              color: const Color(0xFFEAF5FC),
              icon: Icons.person_outline_rounded,
            ),
            if (showDemoDependent) ...[
              const SizedBox(width: 10),
              const _WalletPersonCard(
                name: DemoPresentation.dependentName,
                subtitle: 'Dependente',
                detail: DemoPresentation.dependentDescription,
                color: Color(0xFFFFF4E6),
                icon: Icons.child_care_outlined,
              ),
            ],
            const SizedBox(width: 10),
            _AddDependentCard(onTap: onAddDependent),
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
  });

  final String name;
  final String subtitle;
  final String detail;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 194,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF426B86)),
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
      ],
    ),
  );
}

class _AddDependentCard extends StatelessWidget {
  const _AddDependentCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Adicionar dependente',
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
              'Adicionar\ndependente',
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
    children: List.generate(records.length, (index) {
      final record = records[index];
      final overdue =
          VaccinationRecordInsights.situation(record) ==
          VaccinationRecordSituation.overdue;
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: overdue
                          ? const Color(0xFFE85B61)
                          : const Color(0xFF4C9ED5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 4),
                      ],
                    ),
                  ),
                  if (index < records.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: const Color(0xFFDCE8F0),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UpcomingDoseCard(record: record, overdue: overdue),
              ),
            ),
          ],
        ),
      );
    }),
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
      borderRadius: BorderRadius.circular(18),
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
                    ? 'Dose atrasada desde ${formatBrazilianDate(record.nextDoseDate)}'
                    : 'Prevista para ${formatBrazilianDate(record.nextDoseDate)}',
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
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F9FC),
      borderRadius: BorderRadius.circular(18),
    ),
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
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12)],
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF8AA7BA)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
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
  const _HomeData({this.user, this.records = const []});

  final AppUser? user;
  final List<VaccinationRecord> records;

  int get appliedCount => VaccinationRecordInsights.appliedCount(records);

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
