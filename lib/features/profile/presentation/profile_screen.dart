import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/core/config/domain_repository_factory.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/core/validators/full_name_validator.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/profile/presentation/profile_detail_screens.dart';
import 'package:vitta_mobile/shared/widgets/dependent_wallet_theme.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.authRepository, this.walletController});

  final AuthRepository? authRepository;
  final WalletSelectionController? walletController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? DomainRepositoryFactory.auth();
  late final WalletSelectionController _wallet =
      widget.walletController ?? WalletSelectionController.instance;

  AppUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _wallet.addListener(_onWalletChanged);
    _loadUser();
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  bool get _isViewingDependent =>
      _wallet.currentPersonId != null && !_wallet.isViewingCurrent;

  @override
  void dispose() {
    _wallet.removeListener(_onWalletChanged);
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authRepository.getCurrentUser();
    if (!mounted) {
      return;
    }
    if (user != null) _wallet.bindCurrentPerson(user);
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
    _wallet.reset();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
  }

  Future<void> _editProfile(_ProfileSection section) async {
    final user = _user;
    if (user == null) {
      return;
    }

    final updated = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) =>
          _ProfileEditor(user: user, section: section, onSave: _saveProfile),
    );
    if (updated == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados atualizados com sucesso.')),
    );
  }

  Future<AppUser> _saveProfile(AppUser updated) async {
    final saved = await _authRepository.updateProfile(updated);
    if (mounted) setState(() => _user = saved);
    return saved;
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openSettings() {
    _openPage(ProfileSettingsScreen(walletController: _wallet));
  }

  void _openSecurity() {
    final user = _user;
    if (user == null) return;

    bool? emailVerified;
    try {
      emailVerified = FirebaseAuth.instance.currentUser?.emailVerified;
    } on FirebaseException {
      // Widget tests and injected repositories may run without Firebase setup.
      emailVerified = null;
    }
    _openPage(
      AccountSecurityScreen(
        email: user.email,
        emailVerified: emailVerified,
        authRepository: _authRepository,
      ),
    );
  }

  void _openHelpCenter() {
    _openPage(const HelpCenterScreen());
  }

  void _openTermsAndPrivacy() {
    _openPage(const TermsPrivacyScreen());
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final name = _filled(user?.name, 'Usuário');
    final email = _filled(user?.email, 'E-mail não informado');
    final cpf = _filled(user?.cpf, 'Não informado');
    final phone = user?.phone?.trim();
    final birthDate = user?.birthDate == null
        ? 'Não informada'
        : formatBrazilianDate(user!.birthDate);

    return Scaffold(
      backgroundColor: _isViewingDependent
          ? DependentWalletPalette.of(context).background
          : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: DependentWalletBackground(
          key: Key(
            _isViewingDependent
                ? 'profile-dependent-theme'
                : 'profile-standard-theme',
          ),
          enabled: _isViewingDependent,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: [
                    AppPageHeader(
                      title: 'Perfil',
                      showBack: true,
                      backgroundColor: _isViewingDependent
                          ? DependentWalletPalette.of(context).sky
                          : null,
                    ),
                    Padding(
                      key: const Key('profile-summary-spacing'),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.normal,
                        AppSpacing.xl,
                        AppSpacing.normal,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.normal),
                            decoration: AppCardStyle.decoration(
                              context,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _isViewingDependent
                                      ? DependentWalletPalette.of(context).peach
                                      : context.appPrimarySoft,
                                  foregroundColor: _isViewingDependent
                                      ? DependentWalletPalette.of(context).ink
                                      : context.appPrimaryInk,
                                  child: Text(
                                    _initials(name),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(email, style: AppTypography.caption),
                                      const SizedBox(height: 2),
                                      Text(
                                        'CPF $cpf  •  Nascimento $birthDate',
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _Label('Conta'),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsGroup(
                            children: [
                              _SettingsRow(
                                icon: Icons.person_outline,
                                title: 'Dados pessoais',
                                subtitle: 'Nascimento: $birthDate',
                                onTap: () =>
                                    _editProfile(_ProfileSection.personal),
                              ),
                              _SettingsRow(
                                icon: Icons.mail_outline,
                                title: 'Contato',
                                subtitle: phone == null || phone.isEmpty
                                    ? email
                                    : '$email  •  $phone',
                                onTap: () =>
                                    _editProfile(_ProfileSection.contact),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _Label('Preferências'),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsGroup(
                            children: [
                              _SettingsRow(
                                icon: Icons.tune_rounded,
                                title: 'Configurações',
                                subtitle: 'Preferências deste dispositivo',
                                onTap: _openSettings,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _Label('Segurança'),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsGroup(
                            children: [
                              _SettingsRow(
                                icon: Icons.shield_outlined,
                                title: 'Segurança da conta',
                                subtitle: 'E-mail, senha e autenticação',
                                onTap: _openSecurity,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const _Label('Suporte'),
                          const SizedBox(height: AppSpacing.sm),
                          _SettingsGroup(
                            children: [
                              _SettingsRow(
                                icon: Icons.help_outline_rounded,
                                title: 'Central de ajuda',
                                onTap: _openHelpCenter,
                              ),
                              _SettingsRow(
                                icon: Icons.policy_outlined,
                                title: 'Termos e privacidade',
                                onTap: _openTermsAndPrivacy,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OutlinedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout, size: 17),
                            label: const Text('Sair da conta'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              minimumSize: const Size.fromHeight(42),
                              side: BorderSide(color: context.appBorder),
                            ),
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
}

enum _ProfileSection { personal, contact }

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({
    required this.user,
    required this.section,
    required this.onSave,
  });

  final AppUser user;
  final _ProfileSection section;
  final Future<AppUser> Function(AppUser user) onSave;

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _phoneController = TextEditingController(
    text: widget.user.phone ?? '',
  );
  late final _emergencyNameController = TextEditingController(
    text: widget.user.emergencyContact?.name ?? '',
  );
  late final _emergencyPhoneController = TextEditingController(
    text: widget.user.emergencyContact?.phone ?? '',
  );
  late final _emergencyRelationshipController = TextEditingController(
    text: widget.user.emergencyContact?.relationship ?? '',
  );
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final updated = widget.user.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      emergencyContact: EmergencyContact(
        name: _emergencyNameController.text,
        phone: _emergencyPhoneController.text,
        relationship: _emergencyRelationshipController.text,
      ),
    );
    try {
      final saved = await widget.onSave(updated);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Não foi possível salvar. Revise os dados e tente novamente.';
      });
    }
  }

  String? _validateEmergencyField(String? value) {
    final fields = [
      _emergencyNameController.text.trim(),
      _emergencyPhoneController.text.trim(),
      _emergencyRelationshipController.text.trim(),
    ];
    final hasAny = fields.any((field) => field.isNotEmpty);
    if (hasAny && (value == null || value.trim().isEmpty)) {
      return 'Preencha todos os dados do contato de emergência.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isPersonal = widget.section == _ProfileSection.personal;

    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      minimum: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isPersonal ? 'Dados pessoais' : 'Contato',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                if (isPersonal) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                    ),
                    inputFormatters: [NameInputFormatter()],
                    validator: validateFullName,
                  ),
                  const SizedBox(height: 12),
                  _ProtectedDetail(
                    label: 'CPF',
                    value: widget.user.cpf ?? 'Não informado',
                  ),
                  const SizedBox(height: 12),
                  _ProtectedDetail(
                    label: 'Data de nascimento',
                    value: widget.user.birthDate == null
                        ? 'Não informada'
                        : formatBrazilianDate(widget.user.birthDate),
                  ),
                ] else ...[
                  TextFormField(
                    initialValue: widget.user.email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      helperText:
                          'O e-mail da conta não pode ser alterado aqui.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('profile-phone-field'),
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Contato de emergência',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dado privado, não exibido automaticamente para profissionais.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('emergency-contact-name-field'),
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    inputFormatters: [NameInputFormatter()],
                    validator: _validateEmergencyField,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('emergency-contact-phone-field'),
                    controller: _emergencyPhoneController,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                    keyboardType: TextInputType.phone,
                    validator: _validateEmergencyField,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('emergency-contact-relationship-field'),
                    controller: _emergencyRelationshipController,
                    decoration: const InputDecoration(
                      labelText: 'Parentesco/relação',
                    ),
                    validator: _validateEmergencyField,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar dados'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProtectedDetail extends StatelessWidget {
  const _ProtectedDetail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: AppCardStyle.decoration(context, color: context.appPrimarySoft),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: AppTypography.body),
            ],
          ),
        ),
        Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: context.appPrimaryInk,
        ),
      ],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.appTextSecondary,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .35),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              Divider(height: 1, color: context.appBorder),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  children: [
                    if (subtitle != null)
                      TextSpan(
                        text: '\n$subtitle',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: .65),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
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
