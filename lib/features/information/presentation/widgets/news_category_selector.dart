import 'package:flutter/material.dart';
import 'package:vitta_mobile/features/information/domain/models/news_category.dart';

class NewsCategorySelector extends StatelessWidget {
  const NewsCategorySelector({
    required this.selectedCategory,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final NewsCategory selectedCategory;
  final ValueChanged<NewsCategory> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: NewsCategory.values
          .map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                key: Key('news-category-${category.name}'),
                label: Text(category.label),
                selected: selectedCategory == category,
                showCheckmark: false,
                onSelected: enabled ? (_) => onSelected(category) : null,
                visualDensity: VisualDensity.compact,
              ),
            ),
          )
          .toList(growable: false),
    ),
  );
}
