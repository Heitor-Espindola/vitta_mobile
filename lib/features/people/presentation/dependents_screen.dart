import 'package:flutter/material.dart';
import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/date_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/core/validators/birth_date_validator.dart';
import 'package:vitta_mobile/core/validators/cpf_validator.dart';
import 'package:vitta_mobile/core/validators/full_name_validator.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/data/repositories/firebase_people_repository.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class DependentsScreen extends StatefulWidget {
  const DependentsScreen({
    super.key,
    this.authRepository,
    this.peopleRepository,
  });

  final AuthRepository? authRepository;
  final PeopleRepository? peopleRepository;

  @override
  State<DependentsScreen> createState() => _DependentsScreenState();
}

class _DependentsScreenState extends State<DependentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cpfController = TextEditingController();
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  late final PeopleRepository _peopleRepository =
      widget.peopleRepository ?? FirebasePeopleRepository();
  String _relationship = 'Filho(a)';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate:
          parseBirthDate(_birthDateController.text) ?? DateTime(today.year - 8),
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (selected != null) {
      _birthDateController.text = formatBrazilianDate(selected);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final guardian = await _authRepository.getCurrentUser();
      if (guardian == null) {
        throw StateError('Sessão expirada. Entre novamente.');
      }
      final dependent = await _peopleRepository.createDependent(
        guardianId: guardian.uid,
        name: _nameController.text,
        birthDate: parseBirthDate(_birthDateController.text)!,
        relationship: _relationship,
        cpf: _cpfController.text,
      );
      if (mounted) Navigator.of(context).pop<AppUser>(dependent);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: vittaSurface,
    appBar: AppBar(title: const Text('Adicionar dependente')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                size: 48,
                color: vittaBlue,
              ),
              const SizedBox(height: 12),
              const Text(
                'Nova carteira',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'O dependente ficará vinculado à sua conta e não receberá um login próprio.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF718096)),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 18,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [NameInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                        ),
                        validator: validateFullName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _birthDateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [DateInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Data de nascimento',
                          hintText: 'DD/MM/AAAA',
                          suffixIcon: IconButton(
                            onPressed: _pickDate,
                            tooltip: 'Selecionar data',
                            icon: const Icon(Icons.calendar_month_outlined),
                          ),
                        ),
                        validator: validateBirthDate,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _relationship,
                        decoration: const InputDecoration(labelText: 'Vínculo'),
                        items:
                            const [
                                  'Filho(a)',
                                  'Enteado(a)',
                                  'Neto(a)',
                                  'Tutelado(a)',
                                  'Outro',
                                ]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(
                          () => _relationship = value ?? _relationship,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cpfController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CpfInputFormatter()],
                        decoration: const InputDecoration(labelText: 'CPF'),
                        validator: validateCpf,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(_saving ? 'Salvando...' : 'Criar carteira'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
      ),
    ),
  );
}
