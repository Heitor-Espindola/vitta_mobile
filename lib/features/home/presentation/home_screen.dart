import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      appBar: AppBar(
        title: const Text('Vitta'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: FutureBuilder<AppUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          final userName = snapshot.data?.name.trim();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                userName == null || userName.isEmpty
                    ? 'Ola!'
                    : 'Ola, $userName!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Acesse as principais areas da carteira digital.'),
              const SizedBox(height: 24),
              _HomeActionCard(
                title: 'Criancas',
                subtitle: 'Gerencie seus dependentes.',
                icon: Icons.child_care,
                routeName: AppRoutes.children,
              ),
              _HomeActionCard(
                title: 'Carteira Vacinal',
                subtitle: 'Consulte registros vacinais.',
                icon: Icons.vaccines,
                routeName: AppRoutes.vaccinationCard,
              ),
              _HomeActionCard(
                title: 'Informacoes',
                subtitle: 'Leia conteudos sobre vacinacao.',
                icon: Icons.article_outlined,
                routeName: AppRoutes.information,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed(routeName),
      ),
    );
  }
}
