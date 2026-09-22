import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/core/config/app_preferences.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    super.key,
    this.preferences,
    this.walletController,
  });

  final AppPreferences? preferences;
  final WalletSelectionController? walletController;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  AppPreferences get _preferences =>
      widget.preferences ?? AppPreferences.instance;

  @override
  void initState() {
    super.initState();
    _preferences.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _preferences.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ProfileDetailPage(
    title: 'Configurações',
    contentTopSpacing: 23,
    introPadding: const EdgeInsets.only(left: AppSpacing.md),
    intro: 'Escolha como o Vitta funciona neste dispositivo.',
    children: [
      _DetailCard(
        children: [
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.animation_rounded),
            title: const Text('Animações da Muuni'),
            value: _preferences.animationsEnabled,
            onChanged: _preferences.setAnimationsEnabled,
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.wallet_outlined),
            title: const Text('Lembrar última carteira selecionada'),
            value: _preferences.rememberLastWallet,
            onChanged: (value) => _preferences.setRememberLastWallet(
              value,
              ownerId:
                  (widget.walletController ??
                          WalletSelectionController.instance)
                      .currentPersonId,
            ),
          ),
        ],
      ),
    ],
  );
}

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({
    super.key,
    required this.email,
    required this.authRepository,
    this.emailVerified,
    this.sendVerificationEmail,
    this.reloadEmailVerified,
  });

  final String email;
  final bool? emailVerified;
  final AuthRepository authRepository;
  final Future<void> Function()? sendVerificationEmail;
  final Future<bool?> Function()? reloadEmailVerified;

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  bool _sendingReset = false;
  bool _sendingVerification = false;
  bool? _verified;

  @override
  void initState() {
    super.initState();
    _verified = widget.emailVerified;
  }

  String get _verificationLabel => switch (_verified) {
    true => 'E-mail verificado',
    false => 'E-mail não verificado',
    null => 'Status indisponível',
  };

  Future<void> _sendPasswordReset() async {
    if (_sendingReset) return;

    setState(() => _sendingReset = true);
    try {
      await widget.authRepository.sendPasswordResetEmail(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Instruções para redefinir sua senha foram enviadas para seu e-mail.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível enviar as instruções agora. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _sendVerification() async {
    if (_sendingVerification) return;
    setState(() => _sendingVerification = true);
    try {
      if (widget.sendVerificationEmail != null) {
        await widget.sendVerificationEmail!();
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw StateError('Sessão não encontrada');
        await user.sendEmailVerification();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'E-mail de verificação enviado. Confira sua caixa de entrada.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível reenviar o e-mail. Tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingVerification = false);
    }
  }

  Future<void> _refreshVerification() async {
    try {
      bool? verified;
      if (widget.reloadEmailVerified != null) {
        verified = await widget.reloadEmailVerified!();
      } else {
        final user = FirebaseAuth.instance.currentUser;
        await user?.reload();
        verified = FirebaseAuth.instance.currentUser?.emailVerified;
      }
      if (mounted) setState(() => _verified = verified);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o status agora.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => _ProfileDetailPage(
    title: 'Segurança da conta',
    contentTopSpacing: 23,
    introPadding: const EdgeInsets.only(left: AppSpacing.md),
    intro: 'Informações e ações para proteger o acesso ao Vitta.',
    children: [
      _DetailCard(
        children: [
          _DetailRow(
            icon: Icons.alternate_email_rounded,
            title: 'E-mail da conta',
            value: widget.email,
          ),
          _DetailRow(
            icon: Icons.verified_user_outlined,
            title: 'Verificação',
            value: _verificationLabel,
          ),
        ],
      ),
      if (_verified == false) ...[
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _sendingVerification ? null : _sendVerification,
          icon: _sendingVerification
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.mark_email_unread_outlined),
          label: const Text('Reenviar e-mail de verificação'),
        ),
        TextButton(
          onPressed: _refreshVerification,
          child: const Text('Já confirmei meu e-mail'),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      FilledButton.icon(
        onPressed: _sendingReset ? null : _sendPasswordReset,
        icon: _sendingReset
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.key_rounded, size: 18),
        label: Text(
          _sendingReset ? 'Enviando instruções...' : 'Redefinir senha',
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const _NoticeCard(
        icon: Icons.shield_outlined,
        text:
            'Nunca compartilhe sua senha. O Vitta não exibe identificadores internos, tokens ou dados técnicos da sua conta.',
      ),
    ],
  );
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _questions = <(String, String)>[
    (
      'Como acompanho minhas vacinas?',
      'A Home apresenta um resumo. Para consultar todos os registros, abra a Carteira Digital.',
    ),
    (
      'Como funciona a Carteira Digital?',
      'Ela reúne as aplicações registradas para a pessoa selecionada e organiza o histórico por data.',
    ),
    (
      'Como vejo próximas doses?',
      'As próximas doses aparecem na Home e na Carteira quando existe uma data futura registrada.',
    ),
    (
      'Como funcionam dependentes?',
      'Pessoas vinculadas podem ser acompanhadas conforme o relacionamento e as permissões disponíveis na conta.',
    ),
    (
      'Como atualizar meus dados?',
      'No Perfil, toque em Dados pessoais ou em Contato. CPF, nascimento e dados de acesso permanecem protegidos.',
    ),
    (
      'Como recuperar minha senha?',
      'Abra Segurança da conta e solicite a redefinição. As instruções serão enviadas para o e-mail cadastrado.',
    ),
  ];

  @override
  Widget build(BuildContext context) => _ProfileDetailPage(
    title: 'Central de ajuda',
    contentTopSpacing: AppSpacing.xl,
    introPadding: const EdgeInsets.only(left: AppSpacing.md),
    headerTitleOffset: const Offset(0, 1),
    intro: 'Respostas rápidas sobre os principais recursos do Vitta.',
    children: [
      for (final question in _questions) ...[
        _QuestionCard(question: question.$1, answer: question.$2),
        const SizedBox(height: AppSpacing.sm),
      ],
    ],
  );
}

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ProfileDetailPage(
    title: 'Termos e privacidade',
    contentTopSpacing: 23,
    introPadding: EdgeInsets.only(left: AppSpacing.md),
    intro: 'Entenda de forma simples como o Vitta cuida das suas informações.',
    children: [
      _NoticeCard(
        icon: Icons.privacy_tip_outlined,
        text:
            'Seus dados são utilizados apenas para viabilizar os recursos do aplicativo e o acompanhamento autorizado da vacinação.',
      ),
      SizedBox(height: AppSpacing.md),
      _TextSection(
        icon: Icons.assignment_ind_outlined,
        title: 'Finalidade dos dados',
        text:
            'As informações são utilizadas para identificar a pessoa, organizar a carteira de vacinação e apresentar lembretes relacionados à saúde.',
      ),
      _TextSection(
        icon: Icons.security_outlined,
        title: 'Proteção e autenticação',
        text:
            'O acesso exige autenticação. As permissões limitam quais pessoas e profissionais podem consultar informações da carteira.',
      ),
      _TextSection(
        icon: Icons.vaccines_outlined,
        title: 'Dados de vacinação',
        text:
            'Registros de aplicação são tratados como informações sensíveis e exibidos somente nos fluxos autorizados do aplicativo.',
      ),
      _TextSection(
        icon: Icons.policy_outlined,
        title: 'Privacidade e LGPD',
        text:
            'O projeto adota privacidade, necessidade e controle de acesso como princípios alinhados à LGPD.',
      ),
      _NoticeCard(
        icon: Icons.gavel_outlined,
        text:
            'Este conteúdo é um resumo informativo do projeto Vitta e não substitui termos jurídicos ou uma política de privacidade completa.',
      ),
    ],
  );
}

class _ProfileDetailPage extends StatelessWidget {
  const _ProfileDetailPage({
    required this.title,
    required this.intro,
    required this.children,
    this.contentTopSpacing = 0,
    this.introPadding = EdgeInsets.zero,
    this.headerTitleOffset = Offset.zero,
  });

  final String title;
  final String intro;
  final List<Widget> children;
  final double contentTopSpacing;
  final EdgeInsetsGeometry introPadding;
  final Offset headerTitleOffset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            AppPageHeader(
              title: title,
              showBack: true,
              titleOffset: headerTitleOffset,
            ),
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.normal,
                top: contentTopSpacing,
                right: AppSpacing.normal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: introPadding,
                    child: Text(intro, style: AppTypography.body),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyle.decoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1)
                const Divider(height: 1, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppCardStyle.decoration(color: AppColors.primarySoft),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.caption)),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: const Color(0x0A173B50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(answer, style: AppTypography.body),
          ),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.normal),
      decoration: AppCardStyle.decoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                Text(text, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
