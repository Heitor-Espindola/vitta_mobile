import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

enum _VaccineFilter { all, late, next, done }

class VaccinationCardScreen extends StatefulWidget {
  const VaccinationCardScreen({
    super.key,
    this.authRepository,
    this.vaccinationRepository,
  });

  final AuthRepository? authRepository;
  final VaccinationRepository? vaccinationRepository;

  @override
  State<VaccinationCardScreen> createState() => _VaccinationCardScreenState();
}

class _VaccinationCardScreenState extends State<VaccinationCardScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  late final VaccinationRepository _vaccinationRepository =
      widget.vaccinationRepository ?? FirebaseVaccinationRepository();
  final _searchController = TextEditingController();

  var _showBooklet = false;
  var _filter = _VaccineFilter.all;
  final Set<String> _expandedRecordIds = {};
  AppUser? _currentUser;
  List<VaccinationRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('Usuario nao autenticado.');
      }
      final records = await _vaccinationRepository.getRecordsByResponsible(
        user.uid,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = _withAdultFallback(user);
        _records = records;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = _withAdultFallback(_currentUser);
        _records = _adultSampleRecords;
        _errorMessage = 'Nao foi possivel carregar os dados reais agora.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<VaccinationRecord> get _visibleRecords {
    final query = _searchController.text.trim().toLowerCase();
    return _displayRecords.where((record) {
      final matchesQuery =
          query.isEmpty ||
          record.vaccineName.toLowerCase().contains(query) ||
          record.dose.toLowerCase().contains(query) ||
          statusLabel(record.status).toLowerCase().contains(query) ||
          (record.healthUnit ?? '').toLowerCase().contains(query);

      if (!matchesQuery) {
        return false;
      }

      return switch (_filter) {
        _VaccineFilter.all => true,
        _VaccineFilter.late => _isLate(record.status),
        _VaccineFilter.next =>
          _isPending(record.status) || record.nextDoseDate != null,
        _VaccineFilter.done => _isDone(record.status),
      };
    }).toList();
  }

  Future<void> _downloadPdf() async {
    final bytes = await _buildPdf(user: _currentUser, records: _displayRecords);
    await Printing.layoutPdf(
      name: 'caderneta-vacinal.pdf',
      onLayout: (_) async => bytes,
    );
  }

  List<VaccinationRecord> get _displayRecords =>
      _records.isEmpty ? _adultSampleRecords : _records;

  @override
  Widget build(BuildContext context) {
    final visibleRecords = _visibleRecords;

    return VittaMobileShell(
      title: 'Carteira',
      currentTab: VittaTab.card,
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 28, 12, 24),
          children: [
            _CardTabs(
              showBooklet: _showBooklet,
              onChanged: (value) => setState(() => _showBooklet = value),
            ),
            const SizedBox(height: 20),
            if (_showBooklet)
              _BookletPreview(
                user: _currentUser,
                records: _displayRecords,
                onDownload: _downloadPdf,
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: VittaSearchField(controller: _searchController),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterPill(
                      label: 'Todas',
                      selected: _filter == _VaccineFilter.all,
                      onTap: () => setState(() => _filter = _VaccineFilter.all),
                    ),
                    const SizedBox(width: 14),
                    _FilterPill(
                      label: 'Atrasadas',
                      selected: _filter == _VaccineFilter.late,
                      onTap: () =>
                          setState(() => _filter = _VaccineFilter.late),
                    ),
                    const SizedBox(width: 14),
                    _FilterPill(
                      label: 'Proximas',
                      selected: _filter == _VaccineFilter.next,
                      onTap: () =>
                          setState(() => _filter = _VaccineFilter.next),
                    ),
                    const SizedBox(width: 14),
                    _FilterPill(
                      label: 'Concluidas',
                      selected: _filter == _VaccineFilter.done,
                      onTap: () =>
                          setState(() => _filter = _VaccineFilter.done),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 38),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visibleRecords.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma vacina encontrada para este filtro.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...visibleRecords.map(
                  (record) => _RecordTile(
                    record: record,
                    expanded: _expandedRecordIds.contains(record.id),
                    onToggle: () => setState(() {
                      if (_expandedRecordIds.contains(record.id)) {
                        _expandedRecordIds.remove(record.id);
                      } else {
                        _expandedRecordIds.add(record.id);
                      }
                    }),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardTabs extends StatelessWidget {
  const _CardTabs({required this.showBooklet, required this.onChanged});

  final bool showBooklet;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          _TabButton(
            label: 'Minhas Vacinas',
            selected: !showBooklet,
            onTap: () => onChanged(false),
          ),
          const Spacer(),
          _TabButton(
            label: 'Cardeneta',
            selected: showBooklet,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? vittaDarkBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFD0D5DB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.expanded,
    required this.onToggle,
  });

  final VaccinationRecord record;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final date = record.applicationDate == null
        ? 'Aplicada em: --/--/----'
        : 'Aplicada em: ${formatBrazilianDate(record.applicationDate)}';
    final unit = _filled(record.healthUnit, 'Maternidade Sao Luiz');
    final lot = _filled(record.vaccineId, 'BCG-A22-019');

    return Container(
      margin: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: vittaLineBlue),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: '${record.vaccineName}\n',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(
                          text: '${record.dose}\n$date',
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                StatusChip(label: record.status),
                const SizedBox(width: 12),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 24),
            _DetailBubble(label: 'LOCAL DE APLICACAO', value: unit),
            const SizedBox(height: 10),
            _DetailBubble(label: 'Lote', value: lot),
          ],
        ],
      ),
    );
  }
}

class _DetailBubble extends StatelessWidget {
  const _DetailBubble({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text.rich(
        TextSpan(
          text: '$label\n',
          style: const TextStyle(color: Color(0xFF555555), fontSize: 8.5),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookletPreview extends StatelessWidget {
  const _BookletPreview({
    required this.user,
    required this.records,
    required this.onDownload,
  });

  final AppUser? user;
  final List<VaccinationRecord> records;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final personName = _filled(user?.name, 'Eduardo Carvalho');
    final birthDate = user?.birthDate == null
        ? '--/--/----'
        : formatBrazilianDate(user!.birthDate);
    final cpf = _filled(user?.cpf, '123.456.789-00');

    return Column(
      children: [
        const SizedBox(height: 28),
        Container(
          height: 392,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(color: Colors.white),
          child: RotatedBox(
            quarterTurns: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 8,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BookletTable(records: records.take(8).toList()),
                        const SizedBox(height: 10),
                        _BookletTable(records: records.skip(8).toList()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Carteira Nacional de Vacinacao Digital',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _GovernmentMark(),
                        const SizedBox(height: 10),
                        Text(
                          'Nome\n$personName',
                          style: const TextStyle(fontSize: 9),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nascimento\n$birthDate',
                          style: const TextStyle(fontSize: 9),
                        ),
                        const SizedBox(height: 8),
                        Text('CPF\n$cpf', style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 48,
          width: 235,
          child: FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download, color: vittaDarkBlue),
            label: const Text('Baixar  PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: vittaSoftBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB8CFDD),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookletTable extends StatelessWidget {
  const _BookletTable({required this.records});

  final List<VaccinationRecord> records;

  @override
  Widget build(BuildContext context) {
    final rows = records.isEmpty
        ? _adultSampleRecords.take(8).toList()
        : records.take(8).toList();

    return Table(
      border: TableBorder.all(color: Colors.black87, width: .55),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFE8E8E8)),
          children: [
            _BookletCell('Vacina', bold: true),
            _BookletCell('Prevencao', bold: true),
            _BookletCell('Dose', bold: true),
            _BookletCell('Data', bold: true),
            _BookletCell('Lote', bold: true),
            _BookletCell('Unid.', bold: true),
          ],
        ),
        ...rows.map(
          (record) => TableRow(
            children: [
              _BookletCell(record.vaccineName),
              _BookletCell(_preventionFor(record.vaccineName)),
              _BookletCell(record.dose),
              _BookletCell(
                record.applicationDate == null
                    ? '--/--/----'
                    : formatBrazilianDate(record.applicationDate),
              ),
              _BookletCell(_filled(record.vaccineId, record.id)),
              _BookletCell(_filled(record.healthUnit, '--')),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookletCell extends StatelessWidget {
  const _BookletCell(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 6.5,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _GovernmentMark extends StatelessWidget {
  const _GovernmentMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0E8F4F),
            border: Border.all(color: const Color(0xFFF4D338), width: 3),
          ),
          child: const Icon(Icons.star, color: Colors.yellow, size: 18),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Ministerio da Saude\nGoverno Federal',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

Future<Uint8List> _buildPdf({
  required AppUser? user,
  required List<VaccinationRecord> records,
}) async {
  final doc = pw.Document();
  final personName = _filled(user?.name, 'Eduardo Carvalho');
  final birthDate = user?.birthDate == null
      ? '--/--/----'
      : formatBrazilianDate(user!.birthDate);
  final cpf = _filled(user?.cpf, '123.456.789-00');

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Carteira Nacional de Vacinacao Digital',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Vitta',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text('Pessoa: $personName'),
            pw.Text('Nascimento: $birthDate'),
            pw.Text('CPF: $cpf'),
            pw.Text('Email: ${_filled(user?.email, '--')}'),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Vacina',
                'Dose',
                'Status',
                'Aplicacao',
                'Proxima dose',
                'Unidade',
                'Lote',
              ],
              data: records.map((record) {
                return [
                  record.vaccineName,
                  record.dose,
                  statusLabel(record.status),
                  record.applicationDate == null
                      ? '--/--/----'
                      : formatBrazilianDate(record.applicationDate),
                  record.nextDoseDate == null
                      ? '--/--/----'
                      : formatBrazilianDate(record.nextDoseDate),
                  _filled(record.healthUnit, '--'),
                  _filled(record.vaccineId, record.id),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          ],
        );
      },
    ),
  );

  return Uint8List.fromList(await doc.save());
}

bool _isLate(String status) {
  final normalized = status.toLowerCase();
  return normalized.contains('atras') || normalized.contains('late');
}

bool _isPending(String status) {
  final normalized = status.toLowerCase();
  return normalized.contains('pend') || normalized.contains('pending');
}

bool _isDone(String status) {
  final normalized = status.toLowerCase();
  return normalized.contains('concl') ||
      normalized.contains('applied') ||
      normalized.contains('aplic');
}

AppUser? _withAdultFallback(AppUser? user) {
  if (user == null) {
    return const AppUser(
      uid: 'sample',
      name: 'Eduardo Carvalho',
      email: 'eduardo.carvalho@email.com',
      role: 'responsible',
      cpf: '123.456.789-00',
      birthDate: null,
    ).copyWith(birthDate: DateTime(2008, 6, 23));
  }
  return user.copyWith(
    name: user.name.trim().isEmpty ? 'Eduardo Carvalho' : user.name,
    cpf: user.cpf?.trim().isEmpty == false ? user.cpf : '123.456.789-00',
    birthDate: user.birthDate ?? DateTime(2008, 6, 23),
  );
}

String _preventionFor(String vaccineName) {
  final name = vaccineName.toLowerCase();
  if (name.contains('bcg')) {
    return 'Tuberculose';
  }
  if (name.contains('hepatite')) {
    return 'Hepatite';
  }
  if (name.contains('triplice') || name.contains('dtp')) {
    return 'Difteria, tetano e coqueluche';
  }
  if (name.contains('poli')) {
    return 'Poliomielite';
  }
  if (name.contains('sarampo') || name.contains('viral')) {
    return 'Sarampo, caxumba e rubeola';
  }
  if (name.contains('hpv')) {
    return 'HPV';
  }
  if (name.contains('covid')) {
    return 'Covid-19';
  }
  if (name.contains('gripe')) {
    return 'Influenza';
  }
  return 'Imunizacao';
}

String _filled(String? value, String fallback) {
  final text = value?.trim();
  return text == null || text.isEmpty ? fallback : text;
}

final _adultSampleRecords = [
  VaccinationRecord(
    id: 'BCG-2008-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'BCG',
    dose: 'Dose unica',
    status: 'Concluida',
    applicationDate: DateTime(2008, 6, 24),
    vaccineId: 'BCG-08A-451',
    healthUnit: 'Maternidade Sao Luiz',
  ),
  VaccinationRecord(
    id: 'HEPB-2008-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'Hepatite B',
    dose: '1ª dose',
    status: 'Concluida',
    applicationDate: DateTime(2008, 6, 24),
    vaccineId: 'HB-08B-119',
    healthUnit: 'Maternidade Sao Luiz',
  ),
  VaccinationRecord(
    id: 'PENTA-2008-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'Pentavalente',
    dose: '3ª dose',
    status: 'Concluida',
    applicationDate: DateTime(2008, 12, 23),
    vaccineId: 'PENTA-08C-778',
    healthUnit: 'UBS Jardim Europa',
  ),
  VaccinationRecord(
    id: 'POLIO-2009-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'Poliomielite',
    dose: 'Reforco',
    status: 'Concluida',
    applicationDate: DateTime(2009, 9, 10),
    vaccineId: 'VIP-09D-302',
    healthUnit: 'UBS Jardim Europa',
  ),
  VaccinationRecord(
    id: 'TRIVIRAL-2009-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'Triplice Viral',
    dose: '1ª dose',
    status: 'Concluida',
    applicationDate: DateTime(2009, 6, 26),
    vaccineId: 'SCR-09F-882',
    healthUnit: 'Clinica Vida Plena',
  ),
  VaccinationRecord(
    id: 'DTP-2012-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'DTP',
    dose: '2º reforco',
    status: 'Concluida',
    applicationDate: DateTime(2012, 8, 3),
    vaccineId: 'DTP-12G-440',
    healthUnit: 'UBS Central',
  ),
  VaccinationRecord(
    id: 'FEBRE-2017-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'Febre Amarela',
    dose: 'Dose unica',
    status: 'Concluida',
    applicationDate: DateTime(2017, 4, 18),
    vaccineId: 'FA-17H-221',
    healthUnit: 'Posto Municipal Norte',
  ),
  VaccinationRecord(
    id: 'HPV-2021-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'HPV',
    dose: '2ª dose',
    status: 'Concluida',
    applicationDate: DateTime(2021, 11, 12),
    vaccineId: 'HPV-21K-654',
    healthUnit: 'UBS Central',
  ),
  VaccinationRecord(
    id: 'MENINGO-2022-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'Meningococica ACWY',
    dose: 'Dose unica',
    status: 'Concluida',
    applicationDate: DateTime(2022, 5, 7),
    vaccineId: 'ACWY-22M-710',
    healthUnit: 'Clinica Sao Bento',
  ),
  VaccinationRecord(
    id: 'COVID-2024-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'Covid-19',
    dose: 'Reforco',
    status: 'Concluida',
    applicationDate: DateTime(2024, 3, 15),
    vaccineId: 'COV-24N-503',
    healthUnit: 'Centro de Imunizacao Paulista',
  ),
  VaccinationRecord(
    id: 'GRIPE-2026-001',
    childId: '',
    responsibleId: 'sample',
    vaccineName: 'Gripe',
    dose: 'Campanha anual',
    status: 'Pendente',
    nextDoseDate: DateTime(2026, 7, 10),
    vaccineId: 'INF-26P-090',
    healthUnit: 'UBS Central',
  ),
];
