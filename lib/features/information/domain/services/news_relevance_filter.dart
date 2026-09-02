import 'package:vitta_mobile/features/information/domain/models/news_article.dart';

abstract final class NewsRelevanceFilter {
  static final RegExp _relevantTerms = RegExp(
    r'\b(vacina|vacinas|vacinacao|vacinal|imunizacao|imunizante|imunizantes|dose|doses|cobertura vacinal|calendario vacinal)\b',
    caseSensitive: false,
  );
  static final RegExp _genericHeadlineTerms = RegExp(
    r'\b(eleicao|eleicoes|partido|partidaria|congresso|senado|deputado|economia|mercado financeiro|guerra|conflito|celebridade|famoso|saude|doenca|hospital|bem estar|nutricao)\b',
    caseSensitive: false,
  );

  static bool isRelevant(NewsArticle article) {
    final title = normalize(article.title);
    final description = normalize(article.description ?? '');
    final text = '$title $description';
    if (!_relevantTerms.hasMatch(text)) return false;

    // Uma manchete genérica/política com uma menção lateral a vacina não deve
    // entrar no feed. A matéria continua aceita quando o próprio título deixa
    // claro que vacinação é o assunto principal.
    if (_genericHeadlineTerms.hasMatch(title) &&
        !_relevantTerms.hasMatch(title)) {
      return false;
    }
    return true;
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
