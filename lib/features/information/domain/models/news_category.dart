enum NewsCategory {
  forYou,
  children,
  campaigns,
  hpv,
  influenza,
  covid,
  yellowFever,
}

extension NewsCategoryDetails on NewsCategory {
  String get label => switch (this) {
    NewsCategory.forYou => 'Para você',
    NewsCategory.children => 'Infantil',
    NewsCategory.campaigns => 'Campanhas',
    NewsCategory.hpv => 'HPV',
    NewsCategory.influenza => 'Influenza',
    NewsCategory.covid => 'COVID',
    NewsCategory.yellowFever => 'Febre Amarela',
  };

  String get query => switch (this) {
    NewsCategory.forYou => '',
    NewsCategory.children =>
      '("vacinação infantil" OR "vacina para crianças" OR "imunização infantil" OR "calendário vacinal infantil")',
    NewsCategory.campaigns =>
      '("campanha de vacinação" OR "campanha vacinal" OR "mutirão de vacinação" OR "cobertura vacinal")',
    NewsCategory.hpv => '("vacina HPV" OR "vacinação contra HPV")',
    NewsCategory.influenza =>
      '("vacina influenza" OR "vacinação contra gripe")',
    NewsCategory.covid =>
      '("vacina covid" OR "vacinação contra covid" OR "imunização covid")',
    NewsCategory.yellowFever =>
      '("vacina febre amarela" OR "vacinação contra febre amarela")',
  };
}
