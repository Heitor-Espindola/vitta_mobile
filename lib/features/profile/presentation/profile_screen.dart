import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/core/input_formatters/date_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/core/validators/birth_date_validator.dart';
import 'package:vitta_mobile/core/validators/full_name_validator.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();

  AppUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authRepository.getCurrentUser();
    if (!mounted) {
      return;
    }
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _authRepository.signOut();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível sair. Tente novamente.'),
          ),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
  }

  Future<void> _editProfile() async {
    final user = _user;
    if (user == null) {
      return;
    }

    final updated = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProfileEditor(user: user),
    );
    if (updated == null) {
      return;
    }

    final saved = await _authRepository.updateProfile(updated);
    if (!mounted) {
      return;
    }
    setState(() => _user = saved);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final name = _filled(user?.name, 'Usuário');
    final email = _filled(user?.email, 'E-mail não informado');
    final cpf = _filled(user?.cpf, 'Não informado');
    final birthDate = user?.birthDate == null
        ? 'Não informada'
        : formatBrazilianDate(user!.birthDate);

    return Scaffold(
      backgroundColor: vittaSurface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    height: 124,
                    color: vittaBlue,
                    padding: const EdgeInsets.fromLTRB(10, 12, 18, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              tooltip: 'Voltar',
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _editProfile,
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                              ),
                              tooltip: 'Editar dados',
                            ),
                          ],
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: vittaDarkBlue,
                                child: Text(
                                  _initials(name),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  '$name\nCPF $cpf\n$email',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 20, 36, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _AccessLevel(),
                        const SizedBox(height: 24),
                        const _Label('Conta'),
                        const SizedBox(height: 12),
                        _SettingsGroup(
                          children: [
                            _SettingsRow(
                              icon: Icons.person_outline,
                              title: 'Dados Pessoais',
                              subtitle: 'Nascimento: $birthDate',
                              onTap: _editProfile,
                            ),
                            _SettingsRow(
                              icon: Icons.mail_outline,
                              title: 'Contato',
                              subtitle: _filled(user?.phone, email),
                              onTap: _editProfile,
                            ),
                            const _SettingsRow(
                              icon: Icons.fingerprint,
                              title: 'Biometria',
                              trailing: _ToggleOff(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _Label('Preferencias'),
                        const SizedBox(height: 12),
                        const _SettingsGroup(
                          children: [
                            _SettingsRow(
                              icon: Icons.dark_mode_outlined,
                              title: 'Tema Escuro',
                              trailing: _ToggleOff(),
                            ),
                            _SettingsRow(
                              icon: Icons.settings_outlined,
                              title: 'Configuracoes Avancadas',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _Label('Suporte'),
                        const SizedBox(height: 12),
                        const _SettingsGroup(
                          children: [
                            _SettingsRow(
                              icon: Icons.help_outline,
                              title: 'Central de Ajuda',
                            ),
                            _SettingsRow(
                              icon: Icons.security_outlined,
                              title: 'Termos e privacidade',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Sair da conta'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            minimumSize: const Size.fromHeight(36),
                            side: const BorderSide(color: Color(0xFFE4E8EC)),
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
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.user});

  final AppUser user;

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _cpfController = TextEditingController(
    text: widget.user.cpf ?? '',
  );
  late final _birthDateController = TextEditingController(
    text: widget.user.birthDate == null
        ? ''
        : formatBrazilianDate(widget.user.birthDate),
  );
  late final _phoneController = TextEditingController(
    text: widget.user.phone ?? '',
  );

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final current = parseBirthDate(_birthDateController.text);
    final selected = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate:
          current ?? widget.user.birthDate ?? DateTime(today.year - 18),
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (selected != null) {
      _birthDateController.text = formatBrazilianDate(selected);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Dados pessoais',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                inputFormatters: [NameInputFormatter()],
                validator: validateFullName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cpfController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  helperText: 'O CPF não pode ser alterado.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: 'Data de nascimento',
                  hintText: 'DD/MM/AAAA',
                  suffixIcon: IconButton(
                    tooltip: 'Selecionar data',
                    onPressed: _pickBirthDate,
                    icon: const Icon(Icons.calendar_month),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [DateInputFormatter()],
                validator: validateBirthDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone opcional',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  Navigator.of(context).pop(
                    widget.user.copyWith(
                      name: _nameController.text.trim(),
                      cpf: _cpfController.text.trim(),
                      birthDate: parseBrazilianDate(_birthDateController.text),
                      phone: _phoneController.text.trim(),
                    ),
                  );
                },
                child: const Text('Salvar dados'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessLevel extends StatelessWidget {
  const _AccessLevel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6DDE4)),
      ),
      child: const Text(
        'nivel ouro - Acesso Completo',
        style: TextStyle(fontSize: 9),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9A9A9A),
        fontSize: 13,
        letterSpacing: 2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E5EA)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE9EDF1))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: vittaDarkBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    if (subtitle != null)
                      TextSpan(
                        text: '\n$subtitle',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ToggleOff extends StatelessWidget {
  const _ToggleOff();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 18,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFD1D1D1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: CircleAvatar(radius: 7, backgroundColor: Colors.white),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) {
    return 'U';
  }
  return parts.take(2).map((part) => part[0]).join().toUpperCase();
}

String _filled(String? value, String fallback) {
  final text = value?.trim();
  return text == null || text.isEmpty ? fallback : text;
}
