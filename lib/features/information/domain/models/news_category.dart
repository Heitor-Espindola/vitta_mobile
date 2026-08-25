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
      '("vacinação infantil" OR "vacina criança" OR "imunização infantil")',
    NewsCategory.campaigns =>
      '("campanha de vacinação" OR "mutirão vacinação" OR "cobertura vacinal")',
    NewsCategory.hpv => '("vacina HPV" OR "vacinação HPV")',
    NewsCategory.influenza => '("vacina influenza" OR "vacinação gripe")',
    NewsCategory.covid => '("vacina covid" OR "vacinação covid")',
    NewsCategory.yellowFever => '"vacina febre amarela"',
  };
}
