import 'package:flutter/material.dart';
import 'package:vitta_mobile/features/information/presentation/models/educational_content.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class EducationalContentCard extends StatelessWidget {
  const EducationalContentCard({
    required this.content,
    required this.onTap,
    this.compact = true,
    this.selected = false,
    super.key,
  });

  final EducationalContent content;
  final VoidCallback onTap;
  final bool compact;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _ContentIcon(content: content, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        content.introduction,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: vittaDarkBlue),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 108,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                width: 108,
                height: 64,
                decoration: BoxDecoration(
                  color: content.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? vittaDarkBlue : vittaLineBlue,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Icon(content.icon, size: 28, color: content.iconColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                content.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 108,
            height: 4,
            margin: const EdgeInsets.only(top: 3),
            color: selected ? vittaDarkBlue : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _ContentIcon extends StatelessWidget {
  const _ContentIcon({required this.content, required this.size});

  final EducationalContent content;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: content.color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(content.icon, color: content.iconColor, size: size * .55),
  );
}

Future<bool?> showEducationalContent(
  BuildContext context,
  EducationalContent content,
) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => _EducationalContentSheet(content: content),
);

class _EducationalContentSheet extends StatelessWidget {
  const _EducationalContentSheet({required this.content});

  final EducationalContent content;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DDE2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _ContentIcon(content: content, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              content.introduction,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            ...content.topics.map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: vittaBlue,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        topic,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Este conteúdo é educativo. Para orientações individuais, procure uma unidade de saúde.',
                style: TextStyle(fontSize: 11, color: Color(0xFF566D7A)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('search-related-news'),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.search),
              label: const Text('Buscar notícias relacionadas'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
