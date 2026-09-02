import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/demo/demo_presentation.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/people/data/repositories/firebase_people_repository.dart';
import 'package:vitta_mobile/features/people/domain/models/family_member.dart';
import 'package:vitta_mobile/features/people/domain/models/relationship.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/people/presentation/dependents_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/services/vaccination_record_insights.dart';
import 'package:vitta_mobile/features/vaccination_card/presentation/vaccination_card_screen.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({
    super.key,
    this.authRepository,
    this.peopleRepository,
    this.vaccinationRepository,
    this.walletController,
    this.demoModeEnabled,
  });

  final AuthRepository? authRepository;
  final PeopleRepository? peopleRepository;
  final VaccinationRepository? vaccinationRepository;
  final WalletSelectionController? walletController;
  final bool? demoModeEnabled;

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  late final AuthRepository _auth =
      widget.authRepository ?? FirebaseAuthRepository();
  late final PeopleRepository _people =
      widget.peopleRepository ?? FirebasePeopleRepository();
  late final VaccinationRepository _vaccinations =
      widget.vaccinationRepository ?? FirebaseVaccinationRepository();
  late final WalletSelectionController _wallet =
      widget.walletController ?? WalletSelectionController.instance;
  List<FamilyMember> _members = const [];
  AppUser? _current;
  bool _loading = true;
  String? _error;

  bool get _demoEnabled => widget.demoModeEnabled ?? DemoPresentation.isEnabled;

  @override
  void initState() {
    super.initState();
    _wallet.addListener(_refreshSelection);
    _load();
  }

  @override
  void dispose() {
    _wallet.removeListener(_refreshSelection);
    super.dispose();
  }

  void _refreshSelection() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final current = await _auth.getCurrentUser();
      if (current == null) throw StateError('Sessão não encontrada.');
      _wallet.bindCurrentPerson(current);
      final members = await _people.getFamilyMembers(current.effectivePersonId);
      if (!mounted) return;
      setState(() {
        _current = current;
        _members = members.isEmpty
            ? [FamilyMember(person: current, isCurrent: true)]
            : members;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Não foi possível carregar sua família agora.';
        });
      }
    }
  }

  Future<void> _addFamilyMember() async {
    final created = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(
        builder: (_) => DependentsScreen(
          authRepository: _auth,
          peopleRepository: _people,
          demoModeEnabled: _demoEnabled,
        ),
      ),
    );
    if (created != null) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Familiar adicionado com sucesso.')),
        );
      }
    }
  }

  Future<void> _openMember(FamilyMember member) async {
    final current = _current;
    if (current == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _FamilyMemberScreen(
          member: member,
          current: current,
          vaccinationRepository: _vaccinations,
          authRepository: _auth,
          walletController: _wallet,
          demoEnabled: _demoEnabled,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          const AppPageHeader(
            title: 'Minha família',
            subtitle: 'Carteiras vinculadas à sua identidade',
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
      return _FamilyMessage(message: _error!, onRetry: _load);
    }
    final currentMember = _members.where((member) => member.isCurrent).first;
    final relatives = _members.where((member) => !member.isCurrent).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const Text('Minha carteira', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        _FamilyCard(
          member: currentMember,
          selected:
              _wallet.selectedPersonId ==
              currentMember.person.effectivePersonId,
          canOpen: true,
          onTap: () => _wallet.selectCurrentPerson(),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('Familiares', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        if (relatives.isEmpty)
          const _FamilyMessage(message: 'Nenhum familiar vinculado ainda.')
        else
          ...relatives.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FamilyCard(
                member: member,
                selected:
                    _wallet.selectedPersonId == member.person.effectivePersonId,
                canOpen: member.canViewVaccination(
                  currentPersonId: _current!.effectivePersonId,
                ),
                onTap: () => _openMember(member),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          key: const Key('add-family-member'),
          onPressed: _addFamilyMember,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Adicionar familiar'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        if (!_wallet.isViewingCurrent) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _wallet.selectCurrentPerson,
            icon: const Icon(Icons.person_outline_rounded),
            label: const Text('Voltar para Minha carteira'),
          ),
        ],
      ],
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.member,
    required this.selected,
    required this.canOpen,
    required this.onTap,
  });

  final FamilyMember member;
  final bool selected;
  final bool canOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final person = member.person;
    final name = person.name.trim().isEmpty ? 'Familiar' : person.name.trim();
    final relationship = member.isCurrent
        ? 'Titular'
        : _relationshipLabel(member);
    final age = _ageText(person.birthDate);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppCardStyle.decoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                child: Text(_initials(name)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [relationship, ?age].join(' • '),
                      style: AppTypography.caption,
                    ),
                    if (!member.isCurrent && !canOpen) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Acesso indisponível para este vínculo',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyMemberScreen extends StatelessWidget {
  const _FamilyMemberScreen({
    required this.member,
    required this.current,
    required this.vaccinationRepository,
    required this.authRepository,
    required this.walletController,
    required this.demoEnabled,
  });

  final FamilyMember member;
  final AppUser current;
  final VaccinationRepository vaccinationRepository;
  final AuthRepository authRepository;
  final WalletSelectionController walletController;
  final bool demoEnabled;

  bool get _canOpen =>
      member.canViewVaccination(currentPersonId: current.effectivePersonId);

  Stream<List<VaccinationRecord>> get _records =>
      vaccinationRepository.watchRecordsByPerson(
        personId: member.person.effectivePersonId,
        responsibleId: current.effectivePersonId,
      );

  void _select(BuildContext context) {
    walletController.selectPerson(member.person);
    Navigator.of(context).pop();
  }

  void _openWallet(BuildContext context, {required bool booklet}) {
    walletController.selectPerson(member.person);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VaccinationCardScreen(
          authRepository: authRepository,
          vaccinationRepository: vaccinationRepository,
          walletController: walletController,
          initialShowBooklet: booklet,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          AppPageHeader(
            title: member.person.name,
            subtitle: [
              _relationshipLabel(member),
              ?_ageText(member.person.birthDate),
            ].join(' • '),
            showBack: true,
          ),
          Expanded(
            child: _canOpen
                ? StreamBuilder<List<VaccinationRecord>>(
                    stream: _records,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !demoEnabled) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError && !demoEnabled) {
                        return const _FamilyMessage(
                          message:
                              'A autorização atual não permite abrir esta carteira.',
                        );
                      }
                      final records = DemoPresentation.recordsForPresentation(
                        snapshot.data ?? const <VaccinationRecord>[],
                        enabled: demoEnabled,
                      );
                      return _MemberSummary(
                        records: records,
                        onSelect: () => _select(context),
                        onWallet: () => _openWallet(context, booklet: false),
                        onBooklet: () => _openWallet(context, booklet: true),
                      );
                    },
                  )
                : const _FamilyMessage(
                    message:
                        'Não foi possível acessar esta carteira vinculada.',
                  ),
          ),
        ],
      ),
    ),
  );
}

class _MemberSummary extends StatelessWidget {
  const _MemberSummary({
    required this.records,
    required this.onSelect,
    required this.onWallet,
    required this.onBooklet,
  });

  final List<VaccinationRecord> records;
  final VoidCallback onSelect;
  final VoidCallback onWallet;
  final VoidCallback onBooklet;

  @override
  Widget build(BuildContext context) {
    final applied = VaccinationRecordInsights.appliedCount(records);
    final next = VaccinationRecordInsights.nextDoses(records);
    final overdue = next
        .where(
          (record) =>
              VaccinationRecordInsights.situation(record) ==
              VaccinationRecordSituation.overdue,
        )
        .length;
    final upcoming = next.length - overdue;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const Text('Resumo da carteira', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        if (records.isEmpty)
          const _FamilyMessage(
            message:
                'Nenhuma aplicação registrada nesta carteira. Quando houver um registro, ele aparecerá aqui.',
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.normal),
            decoration: AppCardStyle.decoration(),
            child: Row(
              children: [
                _SummaryValue(value: applied, label: 'aplicadas'),
                _SummaryValue(value: upcoming, label: 'próximas'),
                _SummaryValue(value: overdue, label: 'atrasadas'),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onSelect,
          icon: const Icon(Icons.switch_account_outlined),
          label: const Text('Selecionar carteira'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onWallet,
          icon: const Icon(Icons.article_outlined),
          label: const Text('Ver carteira'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onBooklet,
          icon: const Icon(Icons.auto_stories_outlined),
          label: const Text('Ver caderneta'),
        ),
      ],
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark,
          ),
        ),
        Text(label, style: AppTypography.caption),
      ],
    ),
  );
}

class _FamilyMessage extends StatelessWidget {
  const _FamilyMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.all(AppSpacing.normal),
      padding: const EdgeInsets.all(AppSpacing.normal),
      decoration: AppCardStyle.decoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.family_restroom_outlined,
            color: AppColors.primaryDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center, style: AppTypography.body),
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

String? _ageText(DateTime? birthDate, {DateTime? now}) {
  if (birthDate == null) return null;
  final reference = now ?? DateTime.now();
  var years = reference.year - birthDate.year;
  if (reference.month < birthDate.month ||
      (reference.month == birthDate.month && reference.day < birthDate.day)) {
    years--;
  }
  return '$years ${years == 1 ? 'ano' : 'anos'}';
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _relationshipLabel(FamilyMember member) {
  final storedLabel = member.person.relationshipToGuardian?.trim();
  if (storedLabel?.isNotEmpty ?? false) return storedLabel!;
  return switch (member.relationship?.type) {
    RelationshipType.mother => 'Mãe',
    RelationshipType.father => 'Pai',
    RelationshipType.legalGuardian => 'Filho(a)',
    RelationshipType.tutor => 'Responsável legal',
    RelationshipType.caregiver => 'Outro familiar',
    null => 'Familiar',
  };
}
