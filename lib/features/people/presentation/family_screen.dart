import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/demo/demo_presentation.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/core/config/domain_repository_factory.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/people/domain/models/family_member.dart';
import 'package:vitta_mobile/features/people/domain/models/relationship.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/features/people/presentation/dependents_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
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
      widget.authRepository ?? DomainRepositoryFactory.auth();
  late final PeopleRepository _people =
      widget.peopleRepository ?? DomainRepositoryFactory.people();
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

  void _openMember(FamilyMember member) {
    final current = _current;
    if (current == null) return;
    if (!member.canViewVaccination(
      currentPersonId: current.effectivePersonId,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acesso indisponível para este vínculo.')),
      );
      return;
    }
    _wallet.selectPerson(member.person);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          onTap: () {
            _wallet.selectCurrentPerson();
            Navigator.of(context).pop();
          },
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
            context,
            color: selected ? context.appPrimarySoft : context.appSurface,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: context.appPrimarySoft,
                foregroundColor: context.appPrimaryInk,
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
                      Text(
                        'Acesso indisponível para este vínculo',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appTextSecondary,
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
                    ? context.appPrimaryInk
                    : context.appTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
      decoration: AppCardStyle.decoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.family_restroom_outlined, color: context.appPrimaryInk),
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
