import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/routes.dart';
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
  late final Future<AppUser?> _userFuture = _authRepository.getCurrentUser();

  Future<void> _signOut() async {
    await _authRepository.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vittaSurface,
      body: SafeArea(
        child: FutureBuilder<AppUser?>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final name = user?.name.trim().isNotEmpty == true
                ? user!.name
                : 'Eduardo Henrique Carvalho Silva';
            final email = user?.email.trim().isNotEmpty == true
                ? user!.email
                : 'eduhcfardszavinho@gmail.com';

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 112,
                  color: vittaBlue,
                  padding: const EdgeInsets.fromLTRB(10, 14, 18, 16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          tooltip: 'Voltar',
                        ),
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
                                '$name\nCPF 123.456.789-00\n$email',
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
                      const _SettingsGroup(
                        children: [
                          _SettingsRow(
                            icon: Icons.person_outline,
                            title: 'Dados Pessoais',
                          ),
                          _SettingsRow(
                            icon: Icons.shield_outlined,
                            title: 'Privacidade e Dados',
                          ),
                          _SettingsRow(
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
            );
          },
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
  const _SettingsRow({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9EDF1))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: vittaDarkBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
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
    return 'EH';
  }
  return parts.take(2).map((part) => part[0]).join().toUpperCase();
}
