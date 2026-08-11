import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/routes.dart';

const vittaDarkBlue = Color(0xFF2B6D9D);
const vittaBlue = Color(0xFF3A92D3);
const vittaSoftBlue = Color(0xFF78B5D4);
const vittaLineBlue = Color(0xFF83ACD4);
const vittaPink = Color(0xFFFF3DAD);
const vittaSurface = Color(0xFFF8FAFC);

enum VittaTab { home, card, content, vaccines, profile }

class VittaMobileShell extends StatelessWidget {
  const VittaMobileShell({
    super.key,
    required this.title,
    required this.currentTab,
    required this.body,
    this.showGreetingHeader = false,
    this.appBarHeight = 78,
  });

  final String title;
  final VittaTab currentTab;
  final Widget body;
  final bool showGreetingHeader;
  final double appBarHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vittaSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (showGreetingHeader)
              const SizedBox(height: 12)
            else
              VittaTopBar(title: title, height: appBarHeight),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: VittaBottomNav(currentTab: currentTab),
    );
  }
}

class VittaTopBar extends StatelessWidget {
  const VittaTopBar({super.key, required this.title, this.height = 54});

  final String title;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [vittaDarkBlue, vittaBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF1599F5), width: 3)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            left: 24,
            right: 24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VittaBottomNav extends StatelessWidget {
  const VittaBottomNav({super.key, required this.currentTab});

  final VittaTab currentTab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8EDF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180C527E),
              blurRadius: 24,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Início',
              tab: VittaTab.home,
              currentTab: currentTab,
              routeName: AppRoutes.home,
            ),
            _NavItem(
              icon: Icons.article_outlined,
              label: 'Carteira',
              tab: VittaTab.card,
              currentTab: currentTab,
              routeName: AppRoutes.vaccinationCard,
            ),
            _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'Conteúdo',
              tab: VittaTab.content,
              currentTab: currentTab,
              routeName: AppRoutes.information,
            ),
            _NavItem(
              icon: Icons.vaccines_outlined,
              label: 'Vacinas',
              tab: VittaTab.vaccines,
              currentTab: currentTab,
              routeName: AppRoutes.vaccines,
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              tab: VittaTab.profile,
              currentTab: currentTab,
              routeName: AppRoutes.profile,
              replaceCurrentRoute: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.tab,
    required this.currentTab,
    required this.routeName,
    this.replaceCurrentRoute = true,
  });

  final IconData icon;
  final String label;
  final VittaTab tab;
  final VittaTab currentTab;
  final String routeName;
  final bool replaceCurrentRoute;

  @override
  Widget build(BuildContext context) {
    final selected = currentTab == tab;
    final color = selected ? vittaDarkBlue : const Color(0xFF849199);

    return Expanded(
      child: InkWell(
        onTap: selected
            ? null
            : () {
                if (replaceCurrentRoute) {
                  Navigator.of(context).pushReplacementNamed(routeName);
                } else {
                  Navigator.of(context).pushNamed(routeName);
                }
              },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: double.infinity,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: selected ? 25 : 23),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 5 : 0,
                  height: selected ? 5 : 0,
                  decoration: const BoxDecoration(
                    color: vittaDarkBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VittaSearchField extends StatelessWidget {
  const VittaSearchField({
    super.key,
    this.hint = 'Pesquise',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onSearchTap,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12),
          suffixIcon: IconButton(
            tooltip: 'Pesquisar',
            onPressed: onSearchTap,
            icon: const Icon(Icons.search, size: 18),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          filled: true,
          fillColor: const Color(0xFFF4F8FB),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: vittaLineBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: vittaDarkBlue, width: 1.3),
          ),
        ),
      ),
    );
  }
}

class VittaPill extends StatelessWidget {
  const VittaPill({
    super.key,
    required this.label,
    this.selected = false,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: selected ? Colors.black : const Color(0xFFEFF4F7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontSize: compact ? 10 : 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.compact = false,
  });

  final String title;
  final String? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: Color(0xFF123B91),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final isLate = normalized.contains('atras') || normalized.contains('late');
    final isPending =
        normalized.contains('pend') || normalized.contains('pending');
    final color = isLate
        ? const Color(0xFFFF4B54)
        : isPending
        ? const Color(0xFF89C0DC)
        : const Color(0xFFB9F2BF);
    final textColor = isLate
        ? Colors.white
        : isPending
        ? vittaDarkBlue
        : const Color(0xFF0B9A42);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusLabel(label),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'applied':
      return 'Concluida';
    case 'pending':
      return 'Pendente';
    case 'late':
      return 'Atrasada';
    default:
      return status.isEmpty ? 'Concluida' : status;
  }
}
