import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/design_system.dart';
import 'package:vitta_mobile/app/routes.dart';

const vittaDarkBlue = AppColors.primaryDark;
const vittaBlue = AppColors.primary;
const vittaSoftBlue = Color(0xFF78B5D4);
const vittaLineBlue = Color(0xFF83ACD4);
const vittaPink = Color(0xFFFF3DAD);
const vittaSurface = AppColors.background;

enum VittaTab { home, card, content, vaccines, profile }

class VittaMobileShell extends StatelessWidget {
  const VittaMobileShell({
    super.key,
    required this.title,
    required this.currentTab,
    required this.body,
    this.showGreetingHeader = false,
    this.showTopBar = true,
    this.appBarHeight = 58,
  });

  final String title;
  final VittaTab currentTab;
  final Widget body;
  final bool showGreetingHeader;
  final bool showTopBar;
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
            else if (showTopBar)
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
          colors: [Color(0xFFEAF6FC), Color(0xFFF8FBFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE8F0F5))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.pageTitle,
          ),
        ),
      ),
    );
  }
}

class VittaBottomNav extends StatelessWidget {
  const VittaBottomNav({super.key, required this.currentTab});

  final VittaTab currentTab;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      key: const Key('vitta-bottom-nav-safe-padding'),
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: Container(
        key: const Key('vitta-bottom-nav-surface'),
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: const Color(0xFFE8EDF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180C527E),
              blurRadius: 14,
              offset: Offset(0, 5),
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
                  Icon(icon, color: color, size: selected ? 22 : 21),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
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

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.action,
    this.backgroundColor = AppColors.primarySoft,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? action;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: backgroundColor,
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.normal,
      AppSpacing.sm,
      AppSpacing.normal,
      AppSpacing.md,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBack) ...[
          IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.pageTitle),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: AppTypography.caption),
              ],
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class ExpandableSearch extends StatefulWidget {
  const ExpandableSearch({
    super.key,
    required this.controller,
    this.hint = 'Pesquisar',
    this.onChanged,
    this.onSubmitted,
    this.onClosed,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClosed;

  @override
  State<ExpandableSearch> createState() => _ExpandableSearchState();
}

class _ExpandableSearchState extends State<ExpandableSearch> {
  final _focusNode = FocusNode();
  bool _expanded = false;

  void _open() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  void _close() {
    widget.controller.clear();
    widget.onChanged?.call('');
    widget.onClosed?.call();
    _focusNode.unfocus();
    setState(() => _expanded = false);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 180),
    child: _expanded
        ? SizedBox(
            key: const ValueKey('expanded-search'),
            height: 44,
            child: TextField(
              key: const Key('expandable-search-field'),
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(
                  tooltip: 'Fechar pesquisa',
                  onPressed: _close,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ),
            ),
          )
        : Align(
            key: const ValueKey('collapsed-search'),
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Pesquisar',
              onPressed: _open,
              icon: const Icon(Icons.search_rounded),
            ),
          ),
  );
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
      return 'Aplicada';
    case 'pending':
      return 'Pendente';
    case 'late':
      return 'Atrasada';
    default:
      return status.isEmpty ? 'Aplicada' : status;
  }
}
