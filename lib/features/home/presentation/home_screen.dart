import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

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

  @override
  Widget build(BuildContext context) {
    return VittaMobileShell(
      title: 'Inicio',
      currentTab: VittaTab.home,
      showGreetingHeader: true,
      body: FutureBuilder<AppUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final firstName = _firstName(user?.name);
          final age = _age(user?.birthDate ?? DateTime(2008, 6, 23));

          return ListView(
            padding: const EdgeInsets.fromLTRB(26, 10, 26, 22),
            children: [
              _HomeHeader(name: firstName, age: age),
              const SizedBox(height: 26),
              const _DocumentCard(),
              const SizedBox(height: 24),
              const _ProgressTile(),
              const SizedBox(height: 18),
              const SectionTitle(
                title: 'Doses Proximas',
                action: 'Ver todas >',
              ),
              const SizedBox(height: 12),
              const _DoseCard(
                title: 'Gripe',
                dose: 'Campanha anual',
                date: 'Prevista para: 10/07/2026',
                status: 'Pendente',
              ),
              const SizedBox(height: 14),
              const _DoseCard(
                title: 'Covid-19',
                dose: 'Reforco conforme calendario',
                date: 'Aplicada em: 15/03/2024',
                status: 'Concluida',
              ),
              const SizedBox(height: 18),
              const SectionTitle(title: 'Vacinas Recentes'),
              const SizedBox(height: 12),
              const _DoseCard(
                title: 'Meningococica ACWY',
                dose: 'Dose unica',
                date: 'Aplicada em: 07/05/2022',
                status: 'Concluida',
              ),
              const SizedBox(height: 14),
              const _DoseCard(
                title: 'HPV',
                dose: '2ª dose',
                date: 'Aplicada em: 12/11/2021',
                status: 'Concluida',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name, required this.age});

  final String name;
  final int age;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Ola,\n',
              style: const TextStyle(fontSize: 22, height: 1.12),
              children: [
                TextSpan(
                  text: '$name\n',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(
                  text: '$age anos',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC9CED5)),
              ),
              child: IconButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.profile),
                icon: const Icon(Icons.notifications_none, size: 31),
                tooltip: 'Notificacoes',
              ),
            ),
            Positioned(
              right: 9,
              top: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6EA7C7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 9,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seu novo documento digital',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Cardeneta\n',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Tudo verificado e atualizado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0x558EC4DE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: const [
              _DocumentButton(icon: Icons.qr_code_2, label: 'Compartilhar'),
              SizedBox(width: 12),
              _DocumentButton(icon: Icons.share_outlined, label: 'enviar'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentButton extends StatelessWidget {
  const _DocumentButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0x668DC0DA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7BDBA5), Color(0xFF6AA4FF)],
              ),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          const Text.rich(
            TextSpan(
              text: '86%\n',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
              children: [
                TextSpan(
                  text: 'Vacinas em dia',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.title,
    required this.dose,
    required this.date,
    required this.status,
  });

  final String title;
  final String dose;
  final String date;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: vittaLineBlue),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$title\n',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.22,
                ),
                children: [
                  TextSpan(
                    text: '$dose\n$date',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          StatusChip(label: status),
        ],
      ),
    );
  }
}

String _firstName(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'Eduardo';
  }
  return trimmed.split(RegExp(r'\s+')).first;
}

int _age(DateTime birthDate) {
  final today = DateTime.now();
  var years = today.year - birthDate.year;
  final birthdayPassed =
      today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!birthdayPassed) {
    years--;
  }
  return years;
}
