import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitta_mobile/app/demo/demo_presentation.dart';
import 'package:vitta_mobile/core/config/domain_repository_factory.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/services/vaccination_record_insights.dart';
import 'package:vitta_mobile/features/vaccination_card/presentation/models/vaccination_occurrence.dart';
import 'package:vitta_mobile/shared/widgets/vitta_logo.dart';
import 'package:vitta_mobile/shared/widgets/dependent_wallet_theme.dart';
import 'package:vitta_mobile/shared/widgets/muuni_sprite.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

enum _VaccineFilter { all, late, next, done }

typedef ShareBookletCallback =
    Future<void> Function(Uint8List bytes, String fileName);

class VaccinationCardScreen extends StatefulWidget {
  const VaccinationCardScreen({
    super.key,
    this.authRepository,
    this.vaccinationRepository,
    this.selectedPerson,
    this.walletController,
    this.initialShowBooklet = false,
    this.shareBooklet,
  });

  final AuthRepository? authRepository;
  final VaccinationRepository? vaccinationRepository;
  final AppUser? selectedPerson;
  final WalletSelectionController? walletController;
  final bool initialShowBooklet;
  final ShareBookletCallback? shareBooklet;

  @override
  State<VaccinationCardScreen> createState() => _VaccinationCardScreenState();
}

class _VaccinationCardScreenState extends State<VaccinationCardScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? DomainRepositoryFactory.auth();
  late final VaccinationRepository _repository =
      widget.vaccinationRepository ?? DomainRepositoryFactory.vaccination();
  late final WalletSelectionController _wallet =
      widget.walletController ?? WalletSelectionController.instance;
  final _searchController = TextEditingController();
  StreamSubscription<List<VaccinationRecord>>? _recordsSubscription;
  AppUser? _guardian;
  AppUser? _person;
  List<VaccinationRecord> _records = const [];
  List<Vaccine> _vaccines = const [];
  _VaccineFilter _filter = _VaccineFilter.all;
  late bool _showBooklet;
  bool _sharingBooklet = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _showBooklet = widget.initialShowBooklet;
    _wallet.addListener(_loadSelectedWallet);
    _searchController.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    _recordsSubscription?.cancel();
    _wallet.removeListener(_loadSelectedWallet);
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _loadSelectedWallet() {
    if (mounted && widget.selectedPerson == null) _load();
  }

  Future<void> _load() async {
    await _recordsSubscription?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final guardian = await _authRepository.getCurrentUser();
      if (guardian == null) throw StateError('Usuário não autenticado.');
      _wallet.bindCurrentPerson(guardian);
      final person =
          widget.selectedPerson ?? _wallet.selectedPerson ?? guardian;
      if (!mounted) return;
      setState(() {
        _guardian = guardian;
        _person = person;
      });
      _recordsSubscription = _repository
          .watchRecordsByPerson(
            personId: person.effectivePersonId,
            responsibleId: guardian.effectivePersonId,
          )
          .listen(
            (records) {
              if (mounted) {
                setState(() {
                  _records = DemoPresentation.recordsForPresentation(records);
                  _loading = false;
                  _error = null;
                });
              }
            },
            onError: (_) {
              if (mounted) {
                setState(() {
                  _loading = false;
                  if (DemoPresentation.isEnabled) {
                    _records = DemoPresentation.demoRecords;
                    _error = null;
                  } else {
                    _error = 'Não foi possível carregar sua carteira agora.';
                  }
                });
              }
            },
          );
      try {
        final vaccines = await _repository.getVaccines();
        if (mounted) setState(() => _vaccines = vaccines);
      } catch (_) {
        // O catálogo educativo é independente do histórico de aplicações.
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (DemoPresentation.isEnabled) {
            _records = DemoPresentation.demoRecords;
            _error = null;
          } else {
            _error = 'Não foi possível carregar sua carteira agora.';
          }
        });
      }
    }
  }

  List<VaccinationOccurrence> get _visibleOccurrences {
    final query = _searchController.text.trim().toLowerCase();
    final entries = VaccinationOccurrence.fromRecords(_records).where((entry) {
      final record = entry.record;
      final matchesQuery =
          query.isEmpty ||
          record.vaccineName.toLowerCase().contains(query) ||
          record.dose.toLowerCase().contains(query);
      if (!matchesQuery) return false;
      return switch (_filter) {
        _VaccineFilter.all => true,
        _VaccineFilter.late => entry.kind == VaccinationOccurrenceKind.overdue,
        _VaccineFilter.next => entry.kind == VaccinationOccurrenceKind.upcoming,
        _VaccineFilter.done => entry.kind == VaccinationOccurrenceKind.applied,
      };
    }).toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Vaccine? _vaccineFor(VaccinationRecord record) {
    for (final vaccine in _vaccines) {
      if ((record.vaccineId?.isNotEmpty ?? false) &&
          vaccine.id == record.vaccineId) {
        return vaccine;
      }
      if (vaccine.name.trim().toLowerCase() ==
          record.vaccineName.trim().toLowerCase()) {
        return vaccine;
      }
    }
    return null;
  }

  Future<void> _openDetails(
    VaccinationRecord record, {
    VaccinationOccurrence? occurrence,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VaccineDetails(
        record: record,
        vaccine: _vaccineFor(record),
        occurrence: occurrence,
      ),
    );
  }

  Future<void> _sharePdf() async {
    if (_sharingBooklet) return;
    setState(() => _sharingBooklet = true);
    try {
      final bytes = await buildVaccinationBookletPdf(
        person: _person,
        records: _records,
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
            'Não foi possível gerar a caderneta agora. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sharingBooklet = false);
    }
  }

  bool get _isViewingDependent =>
      _person != null &&
      _guardian != null &&
      _person?.effectivePersonId != _guardian?.effectivePersonId;

  @override
  Widget build(BuildContext context) => VittaMobileShell(
    title: 'Carteira',
    currentTab: VittaTab.card,
    showTopBar: false,
    body: DependentWalletBackground(
      enabled: _isViewingDependent,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          children: [
            _VaccinationCardHeader(dependent: _isViewingDependent),
            const SizedBox(height: 18),
            _PersonHeader(
              person: _person,
              isOwner:
                  _person?.effectivePersonId == _guardian?.effectivePersonId,
            ),
            const SizedBox(height: 18),
            _ModeSelector(
              showBooklet: _showBooklet,
              onChanged: (value) => setState(() => _showBooklet = value),
            ),
            const SizedBox(height: 22),
            if (_error != null) ...[
              _MessageCard(message: _error!, error: true),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _load,
                  child: const Text('Tentar novamente'),
                ),
              ),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_showBooklet)
              _DigitalBooklet(
                person: _person,
                records: _records,
                onRecordTap: (record) => _openDetails(record),
                onExport: _sharePdf,
                sharing: _sharingBooklet,
              )
            else ...[
              _Filters(
                key: const Key('vaccination-card-filters'),
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 8),
              ExpandableSearch(
                controller: _searchController,
                hint: 'Pesquisar vacina',
                onChanged: (_) => _refresh(),
              ),
              const SizedBox(height: 20),
              if (_visibleOccurrences.isEmpty)
                _MessageCard(
                  message: _records.isEmpty
                      ? 'Nenhuma aplicação registrada nesta carteira. Quando um profissional registrar uma aplicação, ela aparecerá aqui.'
                      : 'Nenhum registro encontrado para este filtro.',
                )
              else
                ..._visibleOccurrences.map(
                  (entry) => _RecordCard(
                    occurrence: entry,
                    onTap: () => _openDetails(entry.record, occurrence: entry),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _VaccinationCardHeader extends StatelessWidget {
  const _VaccinationCardHeader({required this.dependent});

  final bool dependent;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return OverflowBox(
      maxWidth: width,
      fit: OverflowBoxFit.deferToChild,
      child: Container(
        key: const Key('vaccination-card-header-band'),
        width: width,
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dependent
                ? const [DependentWalletColors.sky, Color(0xFFF3FAFD)]
                : const [Color(0xFFE7F4FC), Color(0xFFF8FBFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: const Border(bottom: BorderSide(color: Color(0xFFDCEBF4))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carteira',
                    style: TextStyle(
                      fontSize: 23,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Acompanhe aplicações e próximas doses\nde quem você cuida.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF496273),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (dependent)
              const MuuniTimedPresence(
                key: Key('muuni-card-animation'),
                size: 54,
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDEFFC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: vittaDarkBlue,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.person, required this.isOwner});
  final AppUser? person;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final name = _present(person?.name, 'Usuário');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: isOwner ? vittaBlue : DependentWalletColors.peach,
            foregroundColor: Colors.white,
            child: Text(
              _initials(name),
              style: TextStyle(
                color: isOwner ? Colors.white : DependentWalletColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isOwner
                      ? 'Minha carteira'
                      : _present(person?.relationshipToGuardian, 'Dependente'),
                  style: const TextStyle(color: Color(0xFF54758A)),
                ),
              ],
            ),
          ),
          if (isOwner)
            const Icon(Icons.verified_user_outlined, color: vittaBlue),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.showBooklet, required this.onChanged});
  final bool showBooklet;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6F9),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: _ModeOption(
            label: 'Vacinas',
            icon: Icons.vaccines_outlined,
            selected: !showBooklet,
            onTap: () => onChanged(false),
          ),
        ),
        Expanded(
          child: _ModeOption(
            label: 'Caderneta',
            icon: Icons.auto_stories_outlined,
            selected: showBooklet,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    ),
  );
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x140A3858),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? vittaBlue : const Color(0xFF638096),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? vittaDarkBlue : const Color(0xFF638096),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Filters extends StatelessWidget {
  const _Filters({super.key, required this.selected, required this.onSelected});
  final _VaccineFilter selected;
  final ValueChanged<_VaccineFilter> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: _VaccineFilter.values.map((filter) {
        final labels = {
          _VaccineFilter.all: 'Todas',
          _VaccineFilter.late: 'Atrasadas',
          _VaccineFilter.next: 'Próximas',
          _VaccineFilter.done: 'Aplicadas',
        };
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(labels[filter]!),
            selected: selected == filter,
            onSelected: (_) => onSelected(filter),
          ),
        );
      }).toList(),
    ),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.occurrence, required this.onTap});
  final VaccinationOccurrence occurrence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final record = occurrence.record;
    final color = _occurrenceColor(occurrence.kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(Colors.white),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.vaccines_outlined, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _present(record.vaccineName, 'Vacina'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (record.dose.trim().isNotEmpty)
                        Text(
                          record.dose,
                          style: const TextStyle(color: Color(0xFF718096)),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        '${occurrence.datePrefix} ${formatBrazilianDate(occurrence.date)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF54758A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(occurrence: occurrence),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.occurrence});
  final VaccinationOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final color = _occurrenceColor(occurrence.kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        occurrence.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DigitalBooklet extends StatelessWidget {
  const _DigitalBooklet({
    required this.person,
    required this.records,
    required this.onRecordTap,
    required this.onExport,
    required this.sharing,
  });
  final AppUser? person;
  final List<VaccinationRecord> records;
  final ValueChanged<VaccinationRecord> onRecordTap;
  final VoidCallback onExport;
  final bool sharing;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<VaccinationRecord>>{};
    for (final record in records) {
      final date = record.applicationDate ?? record.nextDoseDate;
      final label = _ageLabel(person?.birthDate, date);
      groups.putIfAbsent(label, () => []).add(record);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('vitta-booklet-identity'),
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const VittaLogo(
                    size: 42,
                    semanticLabel: 'Logo Vitta na caderneta',
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Carteira Digital de Vacinação',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: sharing ? null : onExport,
                    tooltip: 'Compartilhar ou baixar caderneta',
                    icon: sharing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                _present(person?.name, 'Usuário'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (person?.birthDate != null)
                Text(
                  'Nascimento: ${formatBrazilianDate(person!.birthDate)}',
                  style: const TextStyle(color: Color(0xFF54758A)),
                ),
              if ((person?.cpf ?? '').trim().isNotEmpty)
                Text(
                  'CPF: ${_maskedCpf(person!.cpf!)}',
                  style: const TextStyle(color: Color(0xFF54758A)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (records.isEmpty)
          const _MessageCard(
            message:
                'Sua carteira ainda não possui aplicações registradas. Quando um profissional registrar uma aplicação, ela aparecerá aqui.',
          )
        else
          ...groups.entries.map(
            (entry) => _BookletGroup(
              title: entry.key,
              records: entry.value,
              onRecordTap: onRecordTap,
            ),
          ),
      ],
    );
  }
}

class _BookletGroup extends StatelessWidget {
  const _BookletGroup({
    required this.title,
    required this.records,
    required this.onRecordTap,
  });
  final String title;
  final List<VaccinationRecord> records;
  final ValueChanged<VaccinationRecord> onRecordTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: vittaDarkBlue,
          ),
        ),
        const Divider(height: 22, color: Color(0xFFDCE8F0)),
        ...records.map(
          (record) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _isDone(record)
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: _statusColor(record),
            ),
            title: Text(
              _present(record.vaccineName, 'Vacina'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(vaccinationBookletRecordDetails(record).join('\n')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onRecordTap(record),
          ),
        ),
      ],
    ),
  );
}

class _VaccineDetails extends StatelessWidget {
  const _VaccineDetails({
    required this.record,
    required this.vaccine,
    this.occurrence,
  });
  final VaccinationRecord record;
  final Vaccine? vaccine;
  final VaccinationOccurrence? occurrence;

  @override
  Widget build(BuildContext context) {
    final applicationFields = <MapEntry<String, String>>[
      MapEntry('Situação', occurrence?.label ?? _statusLabel(record)),
      if (record.dose.trim().isNotEmpty) MapEntry('Dose', record.dose),
      if (record.applicationDate != null)
        MapEntry(
          'Data de aplicação',
          formatBrazilianDate(record.applicationDate),
        ),
      if (record.nextDoseDate != null)
        MapEntry('Próxima dose', formatBrazilianDate(record.nextDoseDate)),
      if ((record.batchNumber ?? '').trim().isNotEmpty)
        MapEntry('Lote', record.batchNumber!),
      if ((record.manufacturer ?? '').trim().isNotEmpty)
        MapEntry('Fabricante', record.manufacturer!),
      if ((record.healthUnit ?? '').trim().isNotEmpty)
        MapEntry('Unidade de saúde', record.healthUnit!),
      if ((record.effectiveProfessionalUid ?? '').trim().isNotEmpty ||
          record.source == 'professional_panel')
        const MapEntry('Registro', 'Registrado pelo Portal Vitta'),
      if ((record.notes ?? '').trim().isNotEmpty)
        MapEntry('Observação', record.notes!),
    ];
    final occurrences = VaccinationOccurrence.fromRecords([record]);
    final detailOccurrence =
        occurrence ?? (occurrences.isEmpty ? null : occurrences.first);
    return DraggableScrollableSheet(
      initialChildSize: .88,
      minChildSize: .55,
      maxChildSize: .96,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          key: const Key('vaccination-detail-scroll'),
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            32 +
                MediaQuery.viewPaddingOf(context).bottom +
                MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3DAE0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _present(record.vaccineName, vaccine?.name ?? 'Vacina'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (detailOccurrence != null)
              _StatusChip(occurrence: detailOccurrence),
            const SizedBox(height: 24),
            const _DetailTitle('Dados da aplicação'),
            const SizedBox(height: 10),
            ...applicationFields.map(
              (field) => _DetailRow(label: field.key, value: field.value),
            ),
            if (vaccine != null && _hasEducationalContent(vaccine!)) ...[
              const SizedBox(height: 26),
              const _DetailTitle('Sobre esta vacina'),
              if ((vaccine!.description ?? '').trim().isNotEmpty)
                _TextSection(
                  title: 'Para que serve',
                  text: vaccine!.description!,
                ),
              if (vaccine!.prevents.isNotEmpty)
                _ListSection(
                  title: 'Protege contra',
                  values: vaccine!.prevents,
                ),
              if (vaccine!.doseSchedule.isNotEmpty)
                _ListSection(
                  title: 'Esquema de doses',
                  values: vaccine!.doseSchedule
                      .map(_scheduleText)
                      .where((value) => value.isNotEmpty)
                      .toList(),
                ),
              if (vaccine!.targetGroups.isNotEmpty)
                _ListSection(
                  title: 'Público/faixa etária',
                  values: vaccine!.targetGroups,
                ),
              if (vaccine!.expectedReactions.isNotEmpty)
                _ListSection(
                  title: 'Reações esperadas',
                  values: vaccine!.expectedReactions,
                ),
              if (vaccine!.warningSigns.isNotEmpty)
                _ListSection(
                  title: 'Quando procurar atendimento',
                  values: vaccine!.warningSigns,
                ),
              if (vaccine!.contraindications.isNotEmpty)
                _ListSection(
                  title: 'Contraindicações e observações',
                  values: vaccine!.contraindications,
                ),
              if ((vaccine!.sourceName ?? '').trim().isNotEmpty)
                _SourceLink(vaccine: vaccine!),
            ] else ...[
              const SizedBox(height: 24),
              const _MessageCard(
                message:
                    'O conteúdo educativo oficial desta vacina ainda não foi cadastrado.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF718096))),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          text,
          style: const TextStyle(height: 1.45, color: Color(0xFF4A5568)),
        ),
      ],
    ),
  );
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.values});
  final String title;
  final List<String> values;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        ...values.map(
          (value) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '• $value',
              style: const TextStyle(height: 1.4, color: Color(0xFF4A5568)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.vaccine});
  final Vaccine vaccine;
  @override
  Widget build(BuildContext context) {
    final updatedAt = vaccine.sourceUpdatedAt;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: OutlinedButton.icon(
        onPressed: (vaccine.sourceUrl ?? '').trim().isEmpty
            ? null
            : () async {
                final uri = Uri.tryParse(vaccine.sourceUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
        icon: const Icon(Icons.verified_outlined),
        label: Text(
          'Fonte: ${vaccine.sourceName}'
          '${updatedAt == null ? '' : ' • atualizada em ${formatBrazilianDate(updatedAt)}'}',
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.error = false});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(error ? const Color(0xFFFFF0F0) : Colors.white),
    child: Row(
      children: [
        Icon(
          error ? Icons.error_outline : Icons.info_outline,
          color: error ? Colors.red : vittaBlue,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

BoxDecoration _cardDecoration(Color color) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFFEDF1F4)),
  boxShadow: const [
    BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, 6)),
  ],
);

bool _isDone(VaccinationRecord record) {
  return VaccinationRecordInsights.isApplied(record);
}

bool _isLate(VaccinationRecord record) {
  return VaccinationRecordInsights.situation(record) ==
      VaccinationRecordSituation.overdue;
}

bool _isPending(VaccinationRecord record) =>
    VaccinationRecordInsights.situation(record) ==
    VaccinationRecordSituation.upcoming;

Color _statusColor(VaccinationRecord record) {
  if (_isDone(record)) return const Color(0xFF268A5B);
  if (_isLate(record)) return const Color(0xFFC53D44);
  if (_isPending(record)) return const Color(0xFF287EB5);
  return const Color(0xFF718096);
}

String _statusLabel(VaccinationRecord record) {
  if (_isDone(record)) return 'Aplicada';
  if (_isLate(record)) return 'Atrasada';
  if (_isPending(record)) return 'Próxima';
  return 'Sem data';
}

Color _occurrenceColor(VaccinationOccurrenceKind kind) => switch (kind) {
  VaccinationOccurrenceKind.applied => const Color(0xFF268A5B),
  VaccinationOccurrenceKind.upcoming => const Color(0xFF287EB5),
  VaccinationOccurrenceKind.overdue => const Color(0xFFC53D44),
};

String _present(String? value, String fallback) {
  final text = value?.trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _maskedCpf(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return '***.***.***-**';
  return '***.***.${digits.substring(6, 9)}-**';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final value = parts.take(2).map((part) => part[0]).join().toUpperCase();
  return value.isEmpty ? 'U' : value;
}

String _ageLabel(DateTime? birthDate, DateTime? eventDate) {
  if (birthDate == null || eventDate == null || eventDate.isBefore(birthDate)) {
    return 'Data não informada';
  }
  final months =
      (eventDate.year - birthDate.year) * 12 +
      eventDate.month -
      birthDate.month -
      (eventDate.day < birthDate.day ? 1 : 0);
  if (months <= 0) return 'Ao nascer';
  if (months < 12) return '$months ${months == 1 ? 'mês' : 'meses'}';
  final years = months ~/ 12;
  return '$years ${years == 1 ? 'ano' : 'anos'}';
}

bool _hasEducationalContent(Vaccine vaccine) =>
    (vaccine.description ?? '').trim().isNotEmpty ||
    vaccine.prevents.isNotEmpty ||
    vaccine.targetGroups.isNotEmpty ||
    vaccine.doseSchedule.isNotEmpty ||
    vaccine.expectedReactions.isNotEmpty ||
    vaccine.warningSigns.isNotEmpty ||
    vaccine.contraindications.isNotEmpty ||
    (vaccine.sourceName ?? '').trim().isNotEmpty;

String _scheduleText(Object? value) {
  if (value is String) return value;
  if (value is Map) {
    return [value['doseNumber'], value['recommendedAge'], value['notes']]
        .whereType<Object>()
        .map((part) => part.toString())
        .where((part) => part.isNotEmpty)
        .join(' • ');
  }
  return '';
}

String vaccinationBookletFileName() => 'carteira-digital-vitta.pdf';

List<String> vaccinationBookletRecordDetails(VaccinationRecord record) => [
  if (record.dose.trim().isNotEmpty) 'Dose: ${record.dose}',
  if (record.applicationDate != null)
    'Aplicada em ${formatBrazilianDate(record.applicationDate)}'
  else if (record.nextDoseDate != null)
    'Prevista para ${formatBrazilianDate(record.nextDoseDate)}',
  if ((record.batchNumber ?? '').trim().isNotEmpty)
    'Lote: ${record.batchNumber!.trim()}',
  if ((record.manufacturer ?? '').trim().isNotEmpty)
    'Fabricante: ${record.manufacturer!.trim()}',
  if ((record.healthUnit ?? '').trim().isNotEmpty)
    'Unidade de saúde: ${record.healthUnit!.trim()}',
];

Future<Uint8List> buildVaccinationBookletPdf({
  required AppUser? person,
  required List<VaccinationRecord> records,
  DateTime? generatedAt,
  Uint8List? logoBytes,
}) async {
  final logoData = logoBytes == null
      ? await rootBundle.load('assets/images/vitta_logo.png')
      : null;
  final effectiveLogoBytes =
      logoBytes ??
      logoData!.buffer.asUint8List(
        logoData.offsetInBytes,
        logoData.lengthInBytes,
      );
  final regularFontData = await rootBundle.load(
    'assets/fonts/Roboto-Regular.ttf',
  );
  final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  final generated = generatedAt ?? DateTime.now();
  final logo = pw.MemoryImage(effectiveLogoBytes);
  final regularFont = pw.Font.ttf(regularFontData);
  final boldFont = pw.Font.ttf(boldFontData);
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Vitta', style: const pw.TextStyle(fontSize: 8)),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
      build: (_) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(logo, width: 52, height: 52),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Vitta',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#256B9B'),
                    ),
                  ),
                  pw.Text(
                    'Carteira Digital de Vacinação',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#EDF7FC'),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _present(person?.name, 'Usuário'),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (person?.birthDate != null)
                pw.Text(
                  'Nascimento: ${formatBrazilianDate(person!.birthDate)}',
                ),
              if ((person?.cpf ?? '').trim().isNotEmpty)
                pw.Text('CPF: ${_maskedCpf(person!.cpf!)}'),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Histórico de aplicações',
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        if (records.isEmpty)
          pw.Text('Nenhum registro disponível.')
        else
          ...records.map(
            (record) => pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#DCE8F0')),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _present(record.vaccineName, 'Vacina'),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  ...vaccinationBookletRecordDetails(record).map(
                    (detail) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        detail,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Gerado em ${formatBrazilianDate(generated)} pelo Vitta.',
          style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#54758A')),
        ),
      ],
    ),
  );
  return Uint8List.fromList(await document.save());
}
