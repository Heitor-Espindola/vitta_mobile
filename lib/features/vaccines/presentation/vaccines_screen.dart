import 'package:flutter/material.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class VaccinesScreen extends StatelessWidget {
  const VaccinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VittaMobileShell(
      title: 'Vacinas',
      currentTab: VittaTab.vaccines,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 0, 24),
        children: const [
          Padding(
            padding: EdgeInsets.only(right: 34),
            child: VittaSearchField(),
          ),
          SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                VittaPill(label: 'Infantis', selected: true, compact: true),
                SizedBox(width: 16),
                VittaPill(label: 'Juvenis', compact: true),
                SizedBox(width: 16),
                VittaPill(label: 'Gestantes', compact: true),
                SizedBox(width: 16),
                VittaPill(label: 'Idosos', compact: true),
              ],
            ),
          ),
          SizedBox(height: 22),
          _AgeSection(
            title: 'Vacinas RN',
            vaccines: [
              _VaccineItem('BCG', 'Recem-nascido - Dose Unica'),
              _VaccineItem('Hepatite B', '1ª dose.'),
            ],
          ),
          _AgeSection(
            title: 'Vacinas 0 a 2 anos',
            vaccines: [
              _VaccineItem('2 Meses', 'VIP (Poliomielite): 1ª dose.'),
              _VaccineItem(
                '2 Meses',
                'Pneumococica 10v (protege contra otite).',
              ),
            ],
          ),
          _AgeSection(
            title: 'Vacinas 3 a 4 anos',
            vaccines: [
              _VaccineItem(
                'DTP (Triplice Bacteriana)',
                'Reforco da vacina que protege contra difteria, tetano e coqueluche.',
              ),
              _VaccineItem(
                'Poliomielite',
                'Reforco da vacina que protege contra a paralisia infantil.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgeSection extends StatelessWidget {
  const _AgeSection({required this.title, required this.vaccines});

  final String title;
  final List<_VaccineItem> vaccines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 8),
            child: Text(title, style: const TextStyle(fontSize: 12)),
          ),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vaccines.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) =>
                  _VaccineCard(item: vaccines[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaccineCard extends StatelessWidget {
  const _VaccineCard({required this.item});

  final _VaccineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      padding: const EdgeInsets.fromLTRB(12, 16, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: vittaLineBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, height: 1.15),
          ),
        ],
      ),
    );
  }
}

class _VaccineItem {
  const _VaccineItem(this.title, this.description);

  final String title;
  final String description;
}
