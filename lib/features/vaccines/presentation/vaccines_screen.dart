import 'package:flutter/material.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

const _pageBackground = Color(0xFFF7F9FB);
const _secondaryText = Color(0xFF455967);
const _softBlue = Color(0xFFE2F0F9);

class VaccinesScreen extends StatefulWidget {
  const VaccinesScreen({super.key});

  @override
  State<VaccinesScreen> createState() => _VaccinesScreenState();
}

class _VaccinesScreenState extends State<VaccinesScreen> {
  final _searchController = TextEditingController();
  String _category = 'Infantis';
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.toLowerCase();
    final vaccines = _vaccines.where((item) {
      final belongsToCategory = item.category == _category;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.description.toLowerCase().contains(normalizedQuery);
      return belongsToCategory && matchesQuery;
    }).toList();

    return VittaMobileShell(
      title: '',
      currentTab: VittaTab.vaccines,
      appBarHeight: 0,
      body: ColoredBox(
        color: _pageBackground,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _VaccinesHeader(),
                    const SizedBox(height: 30),
                    _VaccineSearchField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                    ),
                    const SizedBox(height: 32),
                    const _SectionHeading('Categorias'),
                    const SizedBox(height: 14),
                    _CategorySelector(
                      selected: _category,
                      onSelected: (category) =>
                          setState(() => _category = category),
                    ),
                    const SizedBox(height: 34),
                    const _EducationalCard(),
                    const SizedBox(height: 34),
                    const _SectionHeading('Vacinas recomendadas'),
                    const SizedBox(height: 16),
                    if (vaccines.isEmpty)
                      const _EmptyVaccines()
                    else
                      ...vaccines.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _VaccineCard(item: item),
                        ),
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
}

class _VaccinesHeader extends StatelessWidget {
  const _VaccinesHeader();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vacinas',
              style: TextStyle(
                fontSize: 32,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Informações para cuidar de você e\nde quem você ama.',
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: _secondaryText,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 18),
      Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: _softBlue,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.vaccines_outlined,
          color: vittaDarkBlue,
          size: 28,
        ),
      ),
    ],
  );
}

class _VaccineSearchField extends StatelessWidget {
  const _VaccineSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x100C527E),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: TextField(
      key: const Key('vaccine-search-field'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Pesquisar vacina',
        hintStyle: const TextStyle(color: Color(0xFF536671), fontSize: 16),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 8, right: 2),
          child: Icon(Icons.search_rounded, color: Color(0xFF536671), size: 26),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 54),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 18,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE0E5E9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: vittaBlue, width: 1.4),
        ),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.25,
    ),
  );
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: _categories.map((category) {
        final isSelected = category == selected;
        return Padding(
          padding: EdgeInsets.only(
            right: category == _categories.last ? 0 : 12,
          ),
          child: ChoiceChip(
            key: Key('vaccine-category-$category'),
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(category),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            backgroundColor: Colors.white,
            selectedColor: vittaDarkBlue,
            side: BorderSide(
              color: isSelected ? vittaDarkBlue : const Color(0xFFDCE2E6),
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF263944),
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class _EducationalCard extends StatelessWidget {
  const _EducationalCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    decoration: BoxDecoration(
      color: const Color(0xFFDDEDF7),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FCFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: vittaDarkBlue,
            size: 26,
          ),
        ),
        const SizedBox(width: 18),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vacinar é proteger',
                style: TextStyle(
                  color: vittaDarkBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'As vacinas ajudam a prevenir doenças e reduzir complicações. '
                'Consulte sempre informações de fontes oficiais.',
                style: TextStyle(
                  color: Color(0xFF314B5B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _VaccineCard extends StatelessWidget {
  const _VaccineCard({required this.item});

  final _VaccineItem item;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    elevation: 0,
    shadowColor: const Color(0x180C527E),
    child: InkWell(
      key: Key('vaccine-card-${item.title}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _VaccineDetailsScreen(item: item),
        ),
      ),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 20, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF0F3F5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0C527E),
              blurRadius: 24,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: _softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.vaccines_outlined,
                size: 26,
                color: vittaDarkBlue,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: _secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _softBlue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          item.categoryLabel,
                          style: const TextStyle(
                            color: vittaDarkBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF87959D),
                        size: 28,
                      ),
                    ],
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

class _VaccineDetailsScreen extends StatelessWidget {
  const _VaccineDetailsScreen({required this.item});

  final _VaccineItem item;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pageBackground,
    appBar: AppBar(
      backgroundColor: _pageBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Voltar',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Detalhes da vacina',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VaccineDetailsHeader(item: item),
                  const SizedBox(height: 24),
                  _DetailSection(
                    icon: Icons.health_and_safety_outlined,
                    title: 'O que ela previne',
                    text: item.description,
                  ),
                  _DetailSection(
                    icon: Icons.groups_2_outlined,
                    title: 'Quem deve tomar',
                    text: item.audienceDescription,
                  ),
                  const _DetailSection(
                    icon: Icons.event_note_outlined,
                    title: 'Esquema de doses',
                    text:
                        'O número de doses e os intervalos variam conforme a '
                        'idade e o histórico vacinal. Consulte sua carteira e '
                        'uma unidade de saúde.',
                  ),
                  const _DetailSection(
                    icon: Icons.info_outline_rounded,
                    title: 'Possíveis reações',
                    text:
                        'As reações podem variar. Consulte a equipe de saúde e '
                        'as orientações fornecidas no momento da vacinação.',
                  ),
                  const _DetailSection(
                    icon: Icons.local_hospital_outlined,
                    title: 'Quando procurar atendimento',
                    text:
                        'Procure um serviço de saúde se houver sintomas '
                        'intensos, persistentes ou qualquer preocupação após '
                        'a vacinação.',
                  ),
                  const _DetailSection(
                    icon: Icons.verified_outlined,
                    title: 'Fonte oficial',
                    text:
                        'Ministério da Saúde — Calendário Nacional de '
                        'Vacinação. Confirme sempre as recomendações vigentes.',
                    isLast: true,
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

class _VaccineDetailsHeader extends StatelessWidget {
  const _VaccineDetailsHeader({required this.item});

  final _VaccineItem item;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: const Color(0xFFDDEDF7),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.vaccines_outlined,
            color: vittaDarkBlue,
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.description,
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.text,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F3F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0C527E),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: _softBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: vittaDarkBlue, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 14,
                    height: 1.45,
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

class _EmptyVaccines extends StatelessWidget {
  const _EmptyVaccines();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
    ),
    child: const Column(
      children: [
        Icon(Icons.search_off_rounded, size: 42, color: Color(0xFF91A6B3)),
        SizedBox(height: 12),
        Text(
          'Nenhuma vacina encontrada.',
          style: TextStyle(fontSize: 15, color: _secondaryText),
        ),
      ],
    ),
  );
}

class _VaccineItem {
  const _VaccineItem({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final String category;

  String get categoryLabel => switch (category) {
    'Infantis' => 'Infantil',
    'Juvenis' => 'Juvenil',
    'Gestantes' => 'Gestante',
    'Idosos' => 'Idoso',
    _ => category,
  };

  String get audienceDescription => switch (category) {
    'Infantis' =>
      'Crianças, conforme a faixa etária e o calendário de vacinação.',
    'Juvenis' => 'Adolescentes, conforme a faixa etária e o histórico vacinal.',
    'Gestantes' => 'Gestantes, após avaliação e orientação da equipe de saúde.',
    'Idosos' => 'Pessoas idosas, conforme avaliação e recomendação de saúde.',
    _ => 'Consulte uma unidade de saúde para orientação individual.',
  };
}

const _categories = ['Infantis', 'Juvenis', 'Gestantes', 'Idosos'];

const _vaccines = [
  _VaccineItem(
    title: 'BCG',
    description: 'Ajuda a proteger contra formas graves da tuberculose.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Hepatite B',
    description: 'Protege contra a infecção pelo vírus da hepatite B.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Pentavalente',
    description:
        'Protege contra cinco doenças importantes em uma única aplicação.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Poliomielite',
    description: 'Ajuda a proteger contra a poliomielite.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Pneumocócica 10v',
    description: 'Ajuda a proteger contra doenças pneumocócicas.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'Rotavírus',
    description: 'Ajuda a proteger contra formas graves de gastroenterite.',
    category: 'Infantis',
  ),
  _VaccineItem(
    title: 'HPV',
    description: 'Proteção recomendada conforme a faixa etária.',
    category: 'Juvenis',
  ),
  _VaccineItem(
    title: 'Meningocócica ACWY',
    description: 'Ajuda a proteger contra doenças meningocócicas.',
    category: 'Juvenis',
  ),
  _VaccineItem(
    title: 'dT',
    description: 'Reforço de proteção contra difteria e tétano.',
    category: 'Juvenis',
  ),
  _VaccineItem(
    title: 'dTpa',
    description: 'Indicada na gestação conforme orientação de saúde.',
    category: 'Gestantes',
  ),
  _VaccineItem(
    title: 'Influenza',
    description: 'Proteção contra a gripe conforme recomendação vigente.',
    category: 'Gestantes',
  ),
  _VaccineItem(
    title: 'Hepatite B',
    description: 'Esquema pode ser completado quando indicado.',
    category: 'Gestantes',
  ),
  _VaccineItem(
    title: 'Influenza',
    description: 'Proteção anual contra a gripe.',
    category: 'Idosos',
  ),
  _VaccineItem(
    title: 'Covid-19',
    description: 'Reforços conforme a recomendação vigente.',
    category: 'Idosos',
  ),
  _VaccineItem(
    title: 'Febre amarela',
    description: 'Indicada após avaliação individual de risco.',
    category: 'Idosos',
  ),
];
