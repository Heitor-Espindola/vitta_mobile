import 'package:vitta_mobile/features/information/domain/models/news_article.dart';

abstract final class NewsRelevanceFilter {
  static final RegExp _relevantTerms = RegExp(
    r'\b(vacina|vacinas|vacinacao|vacinal|imunizacao|imunizante|imunizantes|dose|doses)\b',
    caseSensitive: false,
  );

  static bool isRelevant(NewsArticle article) {
    final text = normalize('${article.title} ${article.description ?? ''}');
    return _relevantTerms.hasMatch(text);
  }

  static String normalize(String value) {
    const source = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const target = 'aaaaaeeeeiiiiooooouuuuc';
    var result = value.toLowerCase();
    for (var index = 0; index < source.length; index++) {
      result = result.replaceAll(source[index], target[index]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
