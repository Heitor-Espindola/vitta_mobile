import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:vitta_mobile/app/demo/demo_presentation.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccines/domain/models/patient_vaccine_summary.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

const _pageBackground = Color(0xFFF7F9FB);
const _secondaryText = Color(0xFF455967);
const _softBlue = Color(0xFFE2F0F9);

class VaccinesScreen extends StatefulWidget {
  const VaccinesScreen({
    super.key,
    this.authRepository,
    this.vaccinationRepository,
    this.walletController,
  });

  final AuthRepository? authRepository;
  final VaccinationRepository? vaccinationRepository;
  final WalletSelectionController? walletController;

  @override
  State<VaccinesScreen> createState() => _VaccinesScreenState();
}

class _VaccinesScreenState extends State<VaccinesScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  late final VaccinationRepository _vaccinationRepository =
      widget.vaccinationRepository ?? FirebaseVaccinationRepository();
  late final WalletSelectionController _wallet =
      widget.walletController ?? WalletSelectionController.instance;
  final _searchController = TextEditingController();
  StreamSubscription<List<VaccinationRecord>>? _recordsSubscription;
  String _category = 'Infantis';
  String _query = '';
  List<Vaccine> _catalog = const [];
  List<VaccinationRecord> _records = const [];
  bool _loading = true;
  String? _error;
  AppUser? _currentPerson;
  AppUser? _selectedPerson;

  List<Vaccine> _fallbackCatalog() =>
      _vaccines.map((item) => item.toVaccine()).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _wallet.addListener(_loadSelectedWallet);
    _load();
  }

  void _loadSelectedWallet() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    await _recordsSubscription?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) throw StateError('Sessão não encontrada.');
      _wallet.bindCurrentPerson(user);
      final selected = _wallet.selectedPerson ?? user;
      List<Vaccine> catalog;
      try {
        catalog = await _vaccinationRepository.getVaccines();
      } catch (_) {
        catalog = const [];
      }
      if (catalog.isEmpty) catalog = _fallbackCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _currentPerson = user;
        _selectedPerson = selected;
      });
      _recordsSubscription = _vaccinationRepository
          .watchRecordsByPerson(
            personId: selected.effectivePersonId,
            responsibleId: user.effectivePersonId,
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
                    _error = 'Não foi possível cruzar sua carteira agora.';
                  }
                });
              }
            },
          );
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (DemoPresentation.isEnabled) {
            _records = DemoPresentation.demoRecords;
            _error = null;
          } else {
            _error = 'Não foi possível carregar as vacinas agora.';
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _recordsSubscription?.cancel();
    _wallet.removeListener(_loadSelectedWallet);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.toLowerCase();
    final summaries = PatientVaccineSummary.combine(_catalog, _records);
    final vaccines = summaries.where((summary) {
      final item = _VaccineItem.fromVaccine(summary.vaccine);
      final belongsToCategory = item.category == _category;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.description.toLowerCase().contains(normalizedQuery);
      return belongsToCategory && matchesQuery;
    }).toList();

    return VittaMobileShell(
      title: 'Vacinas',
      currentTab: VittaTab.vaccines,
      showTopBar: false,
      body: ColoredBox(
        color: _pageBackground,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _VaccinesHeader(),
                    if (_selectedPerson?.effectivePersonId !=
                        _currentPerson?.effectivePersonId) ...[
                      const SizedBox(height: 8),
                      _SelectedPersonBanner(
                        name: _selectedPerson?.name ?? 'Familiar',
                        onReturn: _wallet.selectCurrentPerson,
                      ),
                    ],
                    const SizedBox(height: 16),
                    const _SectionHeading('Categorias'),
                    const SizedBox(height: 14),
                    _CategorySelector(
                      key: const Key('vaccine-category-filters'),
                      selected: _category,
                      onSelected: (category) =>
                          setState(() => _category = category),
                    ),
                    const SizedBox(height: 8),
                    ExpandableSearch(
                      controller: _searchController,
                      hint: 'Pesquisar vacina',
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                    ),
                    const SizedBox(height: 20),
                    const _EducationalCard(),
                    const SizedBox(height: 20),
                    const _SectionHeading('Vacinas recomendadas'),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Text(_error!),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Tentar novamente'),
                      ),
                    ] else if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (vaccines.isEmpty)
                      const _EmptyVaccines()
                    else
                      ...vaccines.map(
                        (summary) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _VaccineCard(
                            item: _VaccineItem.fromVaccine(summary.vaccine),
                            summary: summary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaccinesHeader extends StatelessWidget {
  const _VaccinesHeader();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return OverflowBox(
      maxWidth: width,
      fit: OverflowBoxFit.deferToChild,
      child: Container(
        key: const Key('vaccines-header-band'),
        width: width,
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE7F4FC), Color(0xFFF8FBFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(bottom: BorderSide(color: Color(0xFFDCEBF4))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vacinas',
                    style: TextStyle(
                      fontSize: 23,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Informações para cuidar de você e\nde quem você ama.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: _secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.vaccines_outlined,
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

class _SelectedPersonBanner extends StatelessWidget {
  const _SelectedPersonBanner({required this.name, required this.onReturn});

  final String name;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _softBlue,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD1E6F3)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.switch_account_outlined,
          color: vittaDarkBlue,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Visualizando: $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(onPressed: onReturn, child: const Text('Minha carteira')),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.25,
    ),
  );
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: _categories.map((category) {
        final isSelected = category == selected;
        return Padding(
          padding: EdgeInsets.only(
            right: category == _categories.last ? 0 : 12,
          ),
          child: ChoiceChip(
            key: Key('vaccine-category-$category'),
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(category),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            backgroundColor: Colors.white,
            selectedColor: vittaDarkBlue,
            side: BorderSide(
              color: isSelected ? vittaDarkBlue : const Color(0xFFDCE2E6),
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF263944),
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class _EducationalCard extends StatelessWidget {
  const _EducationalCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFDDEDF7),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FCFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: vittaDarkBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vacinar é proteger',
                style: TextStyle(
                  color: vittaDarkBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'As vacinas ajudam a prevenir doenças e reduzir complicações. '
                'Consulte sempre informações de fontes oficiais.',
                style: TextStyle(
                  color: Color(0xFF314B5B),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _VaccineCard extends StatelessWidget {
  const _VaccineCard({required this.item, required this.summary});

  final _VaccineItem item;
  final PatientVaccineSummary summary;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    elevation: 0,
    shadowColor: const Color(0x180C527E),
    child: InkWell(
      key: Key('vaccine-card-${item.title}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _VaccineDetailsScreen(item: item),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F3F5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0C527E),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.vaccines_outlined,
                size: 20,
                color: vittaDarkBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF87959D),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.categoryLabel} · ${summary.latestRecord?.effectiveDoseLabel.isNotEmpty == true ? summary.latestRecord!.effectiveDoseLabel : 'Esquema vacinal'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: _secondaryText,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(summary).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          _statusLabel(summary),
                          style: TextStyle(
                            color: _statusColor(summary),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_statusDate(summary) != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            formatBrazilianDate(_statusDate(summary)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VaccineDetailsScreen extends StatelessWidget {
  const _VaccineDetailsScreen({required this.item});

  final _VaccineItem item;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pageBackground,
    appBar: AppBar(
      backgroundColor: _pageBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Voltar',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Detalhes da vacina',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VaccineDetailsHeader(item: item),
                  const SizedBox(height: 24),
                  _DetailSection(
                    icon: Icons.health_and_safety_outlined,
                    title: 'O que ela previne',
                    text: item.description,
                  ),
                  _DetailSection(
                    icon: Icons.groups_2_outlined,
                    title: 'Quem deve tomar',
                    text: item.audienceDescription,
                  ),
                  const _DetailSection(
                    icon: Icons.event_note_outlined,
                    title: 'Esquema de doses',
                    text:
                        'O número de doses e os intervalos variam conforme a '
                        'idade e o histórico vacinal. Consulte sua carteira e '
                        'uma unidade de saúde.',
                  ),
                  const _DetailSection(
                    icon: Icons.info_outline_rounded,
                    title: 'Possíveis reações',
                    text:
                        'As reações podem variar. Consulte a equipe de saúde e '
                        'as orientações fornecidas no momento da vacinação.',
                  ),
                  const _DetailSection(
                    icon: Icons.local_hospital_outlined,
                    title: 'Quando procurar atendimento',
                    text:
                        'Procure um serviço de saúde se houver sintomas '
                        'intensos, persistentes ou qualquer preocupação após '
                        'a vacinação.',
                  ),
                  const _DetailSection(
                    icon: Icons.verified_outlined,
                    title: 'Fonte oficial',
                    text:
                        'Ministério da Saúde — Calendário Nacional de '
                        'Vacinação. Confirme sempre as recomendações vigentes.',
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _VaccineDetailsHeader extends StatelessWidget {
  const _VaccineDetailsHeader({required this.item});

  final _VaccineItem item;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: const Color(0xFFDDEDF7),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.vaccines_outlined,
            color: vittaDarkBlue,
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.description,
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.text,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F3F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0C527E),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: _softBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: vittaDarkBlue, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyVaccines extends StatelessWidget {
  const _EmptyVaccines();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
    ),
    child: const Column(
      children: [
        Icon(Icons.search_off_rounded, size: 42, color: Color(0xFF91A6B3)),
        SizedBox(height: 12),
        Text(
          'Nenhuma vacina encontrada.',
          style: TextStyle(fontSize: 15, color: _secondaryText),
        ),
      ],
    ),
  );
}

class _VaccineItem {
  const _VaccineItem({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final String category;

  factory _VaccineItem.fromVaccine(Vaccine vaccine) => _VaccineItem(
    title: vaccine.name,
    description:
        vaccine.description ?? 'Consulte as orientações oficiais desta vacina.',
    category: _categoryFor(vaccine),
  );

  Vaccine toVaccine() => Vaccine(
    id: title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
    name: title,
    description: description,
    targetGroups: [category],
    active: true,
  );

  String get categoryLabel => switch (category) {
    'Infantis' => 'Infantil',
    'Juvenis' => 'Juvenil',
    'Gestantes' => 'Gestante',
    'Idosos' => 'Idoso',
    _ => category,
  };

  String get audienceDescription => switch (category) {
    'Infantis' =>
      'Crianças, conforme a faixa etária e o calendário de vacinação.',
    'Juvenis' => 'Adolescentes, conforme a faixa etária e o histórico vacinal.',
    'Gestantes' => 'Gestantes, após avaliação e orientação da equipe de saúde.',
    'Idosos' => 'Pessoas idosas, conforme avaliação e recomendação de saúde.',
    _ => 'Consulte uma unidade de saúde para orientação individual.',
  };
}

String _categoryFor(Vaccine vaccine) {
  final text = [
    vaccine.recommendedAge,
    ...vaccine.targetGroups,
  ].whereType<String>().join(' ').toLowerCase();
  if (text.contains('gest')) return 'Gestantes';
  if (text.contains('idos')) return 'Idosos';
  if (text.contains('adolesc') || text.contains('juven')) return 'Juvenis';
  final existing = _vaccines.where(
    (item) => item.title.toLowerCase() == vaccine.name.toLowerCase(),
  );
  return existing.isEmpty ? 'Infantis' : existing.first.category;
}

String _statusLabel(PatientVaccineSummary summary) =>
    switch (summary.status()) {
      PatientVaccineStatus.applied => 'Aplicada',
      PatientVaccineStatus.upcoming => 'Próxima dose',
      PatientVaccineStatus.overdue => 'Atrasada',
      PatientVaccineStatus.notApplied => 'Não aplicada',
    };

Color _statusColor(PatientVaccineSummary summary) => switch (summary.status()) {
  PatientVaccineStatus.applied => const Color(0xFF268A5B),
  PatientVaccineStatus.upcoming => vittaDarkBlue,
  PatientVaccineStatus.overdue => const Color(0xFFC9474E),
  PatientVaccineStatus.notApplied => const Color(0xFF687985),
};

DateTime? _statusDate(PatientVaccineSummary summary) =>
    summary.nextDoseAt ?? summary.latestRecord?.effectiveAppliedAt;

const _categories = ['Infantis', 'Juvenis', 'Gestantes', 'Idosos'];

const _vaccines = [
  _VaccineItem(
    title: 'BCG',
    description: 'Ajuda a proteger contra formas graves da tuberculose.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Hepatite B',
    description: 'Protege contra a infecção pelo vírus da hepatite B.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Pentavalente',
    description:
        'Protege contra cinco doenças importantes em uma única aplicação.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Poliomielite',
    description: 'Ajuda a proteger contra a poliomielite.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Pneumocócica 10v',
    description: 'Ajuda a proteger contra doenças pneumocócicas.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Rotavírus',
    description: 'Ajuda a proteger contra formas graves de gastroenterite.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'HPV',
    description: 'Proteção recomendada conforme a faixa etária.',
    category: 'Juvenis',
  ),
  _VaccineItem(
    title: 'Meningocócica ACWY',
    description: 'Ajuda a proteger contra doenças meningocócicas.',
    category: 'Juvenis',
  ),
  _VaccineItem(
    title: 'dT',
    description: 'Reforço de proteção contra difteria e tétano.',
    category: 'Juvenis',
  ),
  _VaccineItem(
    title: 'dTpa',
    description: 'Indicada na gestação conforme orientação de saúde.',
    category: 'Gestantes',
  ),
  _VaccineItem(
    title: 'Influenza',
    description: 'Proteção contra a gripe conforme recomendação vigente.',
    category: 'Gestantes',
  ),
  _VaccineItem(
    title: 'Hepatite B',
    description: 'Esquema pode ser completado quando indicado.',
    category: 'Gestantes',
  ),
  _VaccineItem(
    title: 'Influenza',
    description: 'Proteção anual contra a gripe.',
    category: 'Idosos',
  ),
  _VaccineItem(
    title: 'Covid-19',
    description: 'Reforços conforme a recomendação vigente.',
    category: 'Idosos',
  ),
  _VaccineItem(
    title: 'Febre amarela',
    description: 'Indicada após avaliação individual de risco.',
    category: 'Idosos',
  ),
];
