import 'package:vitta_mobile/features/information/domain/models/news_article.dart';

abstract final class NewsRelevanceFilter {
  static final RegExp _relevantTerms = RegExp(
    r'\b(vacina|vacinas|vacinacao|vacinacoes|vacinal|vacinais|multivacinacao|imunizacao|imunizacoes|imunizar|imunizante|imunizantes|cobertura vacinal|calendario vacinal|doses? (de|da|do) (vacina|imunizante))\b',
    caseSensitive: false,
  );
  static final RegExp _genericHeadlineTerms = RegExp(
    r'\b(eleicao|eleicoes|partido|partidaria|congresso|senado|deputado|economia|mercado financeiro|guerra|conflito|celebridade|famoso|saude|doenca|hospital|bem estar|nutricao|ebola|epidemia|surto)\b',
    caseSensitive: false,
  );

  static bool isRelevant(NewsArticle article) {
    final title = normalize(article.title);
    final description = normalize(article.description ?? '');
    // A manchete é o sinal mais forte. Uma menção lateral no corpo (que a API
    // pode truncar) nunca qualifica um artigo.
    if (_relevantTerms.hasMatch(title)) return true;
    if (_genericHeadlineTerms.hasMatch(title)) return false;

    // Manchetes neutras só entram quando o resumo abre com vacinação como tema,
    // não quando a palavra aparece incidentalmente no fim do texto.
    final lead = description.length > 160
        ? description.substring(0, 160)
        : description;
    return _relevantTerms.hasMatch(lead);
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
