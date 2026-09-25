import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/core/config/domain_repository_factory.dart';
import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/date_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/core/validators/birth_date_validator.dart';
import 'package:vitta_mobile/core/validators/cpf_validator.dart';
import 'package:vitta_mobile/core/validators/full_name_validator.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/domain/repositories/people_repository.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class DependentsScreen extends StatefulWidget {
  const DependentsScreen({
    super.key,
    this.authRepository,
    this.peopleRepository,
    this.demoModeEnabled,
  });

  final AuthRepository? authRepository;
  final PeopleRepository? peopleRepository;
  final bool? demoModeEnabled;

  @override
  State<DependentsScreen> createState() => _DependentsScreenState();
}

class _DependentsScreenState extends State<DependentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cpfController = TextEditingController();
  late final AuthRepository _authRepository =
      widget.authRepository ?? DomainRepositoryFactory.auth();
  late final PeopleRepository _peopleRepository =
      widget.peopleRepository ?? DomainRepositoryFactory.people();
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
        guardianId: guardian.effectivePersonId,
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
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(
      child: Column(
        children: [
          const AppPageHeader(title: 'Adicionar familiar', showBack: true),
          Expanded(child: _form()),
        ],
      ),
    ),
  );

  Widget _form() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.normal),
            decoration: AppCardStyle.decoration(
              context,
              color: context.appPrimarySoft,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined, color: context.appPrimaryInk),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Versão acadêmica do Vitta. O familiar será vinculado imediatamente para uso no aplicativo; este fluxo não representa validação governamental.',
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.normal),
          Container(
            padding: const EdgeInsets.all(AppSpacing.normal),
            decoration: AppCardStyle.decoration(context),
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
                  const SizedBox(height: AppSpacing.normal),
                  TextFormField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: '000.000.000-00',
                    ),
                    validator: validateCpf,
                  ),
                  const SizedBox(height: AppSpacing.normal),
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
                  const SizedBox(height: AppSpacing.normal),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _relationship,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de vínculo',
                    ),
                    items:
                        const [
                              'Filho(a)',
                              'Responsável legal',
                              'Outro familiar',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _relationship = value ?? _relationship),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.normal),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cancel = OutlinedButton(
                        key: const Key('cancel-add-family'),
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Cancelar'),
                      );
                      final add = FilledButton.icon(
                        key: const Key('confirm-add-family'),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(
                          _saving ? 'Salvando...' : 'Adicionar familiar',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      );
                      if (constraints.maxWidth < 360) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            cancel,
                            const SizedBox(height: AppSpacing.sm),
                            add,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: cancel),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(flex: 2, child: add),
                        ],
                      );
                    },
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
