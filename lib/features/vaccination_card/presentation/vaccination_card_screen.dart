import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

enum _VaccineFilter { all, late, next, done }

class VaccinationCardScreen extends StatefulWidget {
  const VaccinationCardScreen({
    super.key,
    this.authRepository,
    this.vaccinationRepository,
    this.selectedPerson,
  });

  final AuthRepository? authRepository;
  final VaccinationRepository? vaccinationRepository;
  final AppUser? selectedPerson;

  @override
  State<VaccinationCardScreen> createState() => _VaccinationCardScreenState();
}

class _VaccinationCardScreenState extends State<VaccinationCardScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  late final VaccinationRepository _repository =
      widget.vaccinationRepository ?? FirebaseVaccinationRepository();
  final _searchController = TextEditingController();
  StreamSubscription<List<VaccinationRecord>>? _recordsSubscription;
  AppUser? _guardian;
  AppUser? _person;
  List<VaccinationRecord> _records = const [];
  List<Vaccine> _vaccines = const [];
  _VaccineFilter _filter = _VaccineFilter.all;
  bool _showBooklet = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    _recordsSubscription?.cancel();
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _load() async {
    await _recordsSubscription?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final guardian = await _authRepository.getCurrentUser();
      if (guardian == null) throw StateError('Usuário não autenticado.');
      final person = widget.selectedPerson ?? guardian;
      final vaccines = await _repository.getVaccines();
      if (!mounted) return;
      setState(() {
        _guardian = guardian;
        _person = person;
        _vaccines = vaccines;
      });
      _recordsSubscription = _repository
          .watchRecordsByPerson(
            personId: person.uid,
            responsibleId: guardian.uid,
          )
          .listen(
            (records) {
              if (mounted) {
                setState(() {
                  _records = records;
                  _loading = false;
                  _error = null;
                });
              }
            },
            onError: (_) {
              if (mounted) {
                setState(() {
                  _loading = false;
                  _error = 'Não foi possível atualizar a carteira.';
                });
              }
            },
          );
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Não foi possível carregar a carteira.';
        });
      }
    }
  }

  List<VaccinationRecord> get _visibleRecords {
    final query = _searchController.text.trim().toLowerCase();
    final records = _records.where((record) {
      final matchesQuery =
          query.isEmpty ||
          record.vaccineName.toLowerCase().contains(query) ||
          record.dose.toLowerCase().contains(query);
      if (!matchesQuery) return false;
      return switch (_filter) {
        _VaccineFilter.all => true,
        _VaccineFilter.late => _isLate(record),
        _VaccineFilter.next => _isPending(record),
        _VaccineFilter.done => _isDone(record),
      };
    }).toList();
    records.sort((a, b) {
      final aDate = a.applicationDate ?? a.nextDoseDate;
      final bDate = b.applicationDate ?? b.nextDoseDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return records;
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

  Future<void> _openDetails(VaccinationRecord record) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _VaccineDetails(record: record, vaccine: _vaccineFor(record)),
    );
  }

  Future<void> _exportPdf() async {
    final bytes = await _buildPdf(person: _person, records: _records);
    await Printing.layoutPdf(
      name: 'carteira-vacinal-${_person?.uid ?? 'vitta'}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  @override
  Widget build(BuildContext context) => VittaMobileShell(
    title: 'Carteira',
    currentTab: VittaTab.card,
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          _PersonHeader(
            person: _person,
            isOwner: _person?.uid == _guardian?.uid,
          ),
          const SizedBox(height: 18),
          _ModeSelector(
            showBooklet: _showBooklet,
            onChanged: (value) => setState(() => _showBooklet = value),
          ),
          const SizedBox(height: 22),
          if (_error != null) _MessageCard(message: _error!, error: true),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_showBooklet)
            _DigitalBooklet(
              person: _person,
              records: _records,
              onRecordTap: _openDetails,
              onExport: _exportPdf,
            )
          else ...[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Pesquisar vacina',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            _Filters(
              selected: _filter,
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 20),
            if (_visibleRecords.isEmpty)
              const _MessageCard(
                message: 'Nenhum registro encontrado para esta carteira.',
              )
            else
              ..._visibleRecords.map(
                (record) => _RecordCard(
                  record: record,
                  onTap: () => _openDetails(record),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.person, required this.isOwner});
  final AppUser? person;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final name = _present(person?.name, 'Usuário');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(const Color(0xFFEAF5FC)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: vittaBlue,
            foregroundColor: Colors.white,
            child: Text(_initials(name)),
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
  Widget build(BuildContext context) => SegmentedButton<bool>(
    segments: const [
      ButtonSegment(
        value: false,
        label: Text('Vacinas'),
        icon: Icon(Icons.vaccines_outlined),
      ),
      ButtonSegment(
        value: true,
        label: Text('Caderneta'),
        icon: Icon(Icons.auto_stories_outlined),
      ),
    ],
    selected: {showBooklet},
    onSelectionChanged: (values) => onChanged(values.first),
    showSelectedIcon: false,
  );
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onSelected});
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
          _VaccineFilter.done: 'Concluídas',
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
  const _RecordCard({required this.record, required this.onTap});
  final VaccinationRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = record.applicationDate ?? record.nextDoseDate;
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
                    color: _statusColor(record).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.vaccines_outlined,
                    color: _statusColor(record),
                  ),
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
                      if (date != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${record.applicationDate != null ? 'Aplicada' : 'Prevista'} em ${formatBrazilianDate(date)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF54758A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(record: record),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.record});
  final VaccinationRecord record;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: _statusColor(record).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _statusLabel(record),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: _statusColor(record),
      ),
    ),
  );
}

class _DigitalBooklet extends StatelessWidget {
  const _DigitalBooklet({
    required this.person,
    required this.records,
    required this.onRecordTap,
    required this.onExport,
  });
  final AppUser? person;
  final List<VaccinationRecord> records;
  final ValueChanged<VaccinationRecord> onRecordTap;
  final VoidCallback onExport;

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
        Row(
          children: [
            const Expanded(
              child: Text(
                'Caderneta digital',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: onExport,
              tooltip: 'Exportar PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Histórico organizado pela idade na data da aplicação ou previsão.',
          style: TextStyle(color: Color(0xFF718096)),
        ),
        const SizedBox(height: 20),
        if (records.isEmpty)
          const _MessageCard(
            message: 'Nenhum registro disponível na caderneta.',
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
            subtitle: Text(
              [
                if (record.dose.trim().isNotEmpty) record.dose,
                if (record.applicationDate != null)
                  'Aplicada em ${formatBrazilianDate(record.applicationDate)}',
                if (record.applicationDate == null &&
                    record.nextDoseDate != null)
                  'Prevista para ${formatBrazilianDate(record.nextDoseDate)}',
              ].join(' • '),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onRecordTap(record),
          ),
        ),
      ],
    ),
  );
}

class _VaccineDetails extends StatelessWidget {
  const _VaccineDetails({required this.record, required this.vaccine});
  final VaccinationRecord record;
  final Vaccine? vaccine;

  @override
  Widget build(BuildContext context) {
    final applicationFields = <MapEntry<String, String>>[
      MapEntry('Situação', _statusLabel(record)),
      if (record.dose.trim().isNotEmpty) MapEntry('Dose', record.dose),
      if (record.applicationDate != null)
        MapEntry(
          'Data de aplicação',
          formatBrazilianDate(record.applicationDate),
        ),
      if ((record.batchNumber ?? '').trim().isNotEmpty)
        MapEntry('Lote', record.batchNumber!),
      if ((record.manufacturer ?? '').trim().isNotEmpty)
        MapEntry('Fabricante', record.manufacturer!),
      if ((record.healthUnit ?? '').trim().isNotEmpty)
        MapEntry('Unidade de saúde', record.healthUnit!),
      if ((record.professionalId ?? record.healthProfessionalId ?? '')
          .trim()
          .isNotEmpty)
        MapEntry(
          'Profissional responsável',
          record.professionalId ?? record.healthProfessionalId!,
        ),
      if ((record.notes ?? '').trim().isNotEmpty)
        MapEntry('Observação', record.notes!),
    ];
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
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
            _StatusChip(record: record),
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
  final status = record.status.toLowerCase();
  return status.contains('concl') ||
      status.contains('aplic') ||
      status == 'applied';
}

bool _isLate(VaccinationRecord record) {
  final status = record.status.toLowerCase();
  final date = record.nextDoseDate;
  return status.contains('atras') ||
      status == 'late' ||
      (!_isDone(record) && date != null && date.isBefore(DateTime.now()));
}

bool _isPending(VaccinationRecord record) =>
    !_isDone(record) && !_isLate(record);

Color _statusColor(VaccinationRecord record) {
  if (_isDone(record)) return const Color(0xFF268A5B);
  if (_isLate(record)) return const Color(0xFFC53D44);
  return const Color(0xFF287EB5);
}

String _statusLabel(VaccinationRecord record) {
  if (_isDone(record)) return 'Concluída';
  if (_isLate(record)) return 'Atrasada';
  return 'Pendente';
}

String _present(String? value, String fallback) {
  final text = value?.trim();
  return text == null || text.isEmpty ? fallback : text;
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

Future<Uint8List> _buildPdf({
  required AppUser? person,
  required List<VaccinationRecord> records,
}) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Text(
          'Carteira Digital de Vacinação',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Pessoa: ${_present(person?.name, 'Usuário')}'),
        if (person?.birthDate != null)
          pw.Text('Nascimento: ${formatBrazilianDate(person!.birthDate)}'),
        pw.SizedBox(height: 18),
        if (records.isEmpty)
          pw.Text('Nenhum registro disponível.')
        else
          pw.TableHelper.fromTextArray(
            headers: const [
              'Vacina',
              'Dose',
              'Situação',
              'Aplicação',
              'Próxima dose',
              'Unidade',
              'Lote',
            ],
            data: records
                .map(
                  (record) => [
                    record.vaccineName,
                    record.dose,
                    _statusLabel(record),
                    formatBrazilianDate(record.applicationDate),
                    formatBrazilianDate(record.nextDoseDate),
                    record.healthUnit ?? '',
                    record.batchNumber ?? '',
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
      ],
    ),
  );
  return Uint8List.fromList(await document.save());
}
