import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';

/// Educational PNI guidance reviewed on 2026-09-23. Sources and scope are
/// documented in docs/VACCINE_AUDIENCE_SOURCES.md. This does not schedule doses.
class VaccineAudienceGuidance {
  const VaccineAudienceGuidance(this.description, this.sourceUrl);

  final String description;
  final String sourceUrl;

  static const calendarUrl =
      'https://www.gov.br/saude/pt-br/vacinacao/calendario';
  static const _technicalUrl =
      'https://www.gov.br/saude/pt-br/vacinacao/publicacoes/'
      'instrucao-normativa-que-instrui-o-calendario-nacional-de-vacinacao-2026.pdf';
  static const _childUrl =
      'https://www.gov.br/saude/pt-br/composicao/svsa/pni/calendario-tecnico/'
      'calendario-tecnico-nacional-de-vacinacao-crianca';
  static const _pregnancyUrl =
      'https://www.gov.br/saude/pt-br/vacinacao/arquivos/'
      'calendario-nacional-de-vacinacao-gestante';
  static const _elderlyUrl =
      'https://www.gov.br/saude/pt-br/vacinacao/arquivos/'
      'calendario-nacional-de-vacinacao-idoso';
  static const _youthUrl =
      'https://www.gov.br/saude/pt-br/composicao/svsa/pni/calendario-tecnico/'
      'calendario-tecnico-nacional-de-vacinacao-adolescentes-jovens';

  /// Match explicit aliases, never substrings: DTP and dTpa, for example,
  /// have different indications. Unknown remote entries retain their own age.
  static VaccineAudienceGuidance? forVaccine(Vaccine vaccine, String category) {
    for (final value in [vaccine.name, vaccine.shortName, vaccine.id]) {
      if (value == null) continue;
      final key = _aliases[_normalize(value)];
      if (key == null) continue;
      return switch (key) {
        'hepatiteb' when category == 'Gestantes' => const VaccineAudienceGuidance(
          'Gestantes de qualquer idade podem tomar desde o início da gravidez. '
          'A vacina é indicada para quem ainda não tomou todas as 3 doses.\n\n'
          'Leve a carteira de vacinação ao posto de saúde para conferir '
          'quais doses faltam.',
          _pregnancyUrl,
        ),
        'influenza' when category == 'Gestantes' =>
          const VaccineAudienceGuidance(
            'Gestantes de qualquer idade devem tomar a vacina contra a gripe '
            'todos os anos. Ela pode ser tomada em qualquer fase da gravidez, '
            'inclusive nos primeiros meses.',
            _pregnancyUrl,
          ),
        'influenza' when category == 'Idosos' => const VaccineAudienceGuidance(
          'Pessoas com 60 anos ou mais devem tomar a vacina contra a gripe '
          'todos os anos. Mesmo quem se vacinou no ano passado precisa '
          'receber a vacina deste ano.',
          _elderlyUrl,
        ),
        'covid19' when category == 'Idosos' => const VaccineAudienceGuidance(
          'Pessoas com 60 anos ou mais devem tomar uma dose a cada 6 meses. '
          'Conte esse tempo a partir da última dose recebida.',
          _elderlyUrl,
        ),
        'covid19' when category == 'Gestantes' => const VaccineAudienceGuidance(
          'Gestantes de qualquer idade devem tomar uma dose em cada gravidez. '
          'A vacina pode ser tomada em qualquer fase da gestação.',
          _pregnancyUrl,
        ),
        'febreamarela' when category == 'Idosos' =>
          const VaccineAudienceGuidance(
            'Pessoas com 60 anos ou mais que nunca tomaram essa vacina precisam '
            'conversar com a equipe do posto de saúde antes de se vacinar. '
            'Nessa idade, ela só é indicada quando há alto risco de pegar '
            'febre amarela.\n\n'
            'Se a equipe recomendar a vacina para uma viagem, tome a dose '
            'pelo menos 10 dias antes de viajar.',
            _elderlyUrl,
          ),
        'febreamarela' when category == 'Gestantes' =>
          const VaccineAudienceGuidance(
            'Durante a gravidez, essa vacina só é indicada em casos especiais: '
            'quando há risco de pegar febre amarela e não é possível evitar '
            'a área de risco ou adiar a viagem.\n\n'
            'A equipe do posto de saúde precisa avaliar a gestante e conferir '
            'as doses que ela já tomou antes de recomendar a vacina.',
            _pregnancyUrl,
          ),
        _ => _guidance[key],
      };
    }
    return null;
  }

  static const _guidance = <String, VaccineAudienceGuidance>{
    'bcg': VaccineAudienceGuidance(
      'Bebês devem tomar uma dose ao nascer, de preferência ainda na maternidade. '
      'Se a criança não tomou essa dose, pode recebê-la antes de completar '
      '5 anos.',
      _childUrl,
    ),
    'hepatitea': VaccineAudienceGuidance(
      'Crianças devem tomar uma dose aos 15 meses (1 ano e 3 meses). '
      'Se a dose estiver atrasada, a criança pode recebê-la antes de '
      'completar 5 anos.',
      _childUrl,
    ),
    'hepatiteb': VaccineAudienceGuidance(
      'Bebês devem tomar a primeira dose ao nascer, de preferência nas '
      'primeiras 12 horas de vida. Aos 2, 4 e 6 meses, recebem a pentavalente, '
      'que também protege contra a hepatite B.\n\n'
      'Pessoas de qualquer idade que não tomaram todas as doses devem levar '
      'a carteira de vacinação ao posto de saúde para completar a proteção.',
      _technicalUrl,
    ),
    'pentavalente': VaccineAudienceGuidance(
      'Bebês devem tomar 3 doses: aos 2, 4 e 6 meses.\n\n'
      'Se alguma dose estiver atrasada, procure o posto de saúde. '
      'A pentavalente só pode ser usada antes de a criança completar 7 anos.',
      _childUrl,
    ),
    'dtp': VaccineAudienceGuidance(
      'Crianças devem tomar aos 15 meses (1 ano e 3 meses) e aos 4 anos. '
      'Essas doses são reforços: ajudam a manter a proteção iniciada '
      'com a pentavalente.\n\n'
      'A DTP só pode ser usada antes dos 7 anos. A partir dessa idade, '
      'o posto de saúde usa a dT para completar a proteção contra '
      'difteria e tétano.',
      _childUrl,
    ),
    'poliomielite': VaccineAudienceGuidance(
      'Bebês devem tomar 3 doses: aos 2, 4 e 6 meses. Depois, precisam '
          'de reforços aos 15 meses (1 ano e 3 meses) e aos 4 anos. '
          'A vacina usada é a VIP, aplicada por injeção.\n\n'
          'Se alguma dose estiver atrasada, leve a carteira de vacinação '
          'ao posto de saúde.',
      'https://www.gov.br/saude/pt-br/assuntos/noticias-ms/2026/agosto/'
          'ministerio-da-saude-reforca-vacinacao-de-criancas-e-adolescentes-contra-sarampo-pneumonias-e-outras-doencas',
    ),
    'pneumo10': VaccineAudienceGuidance(
      'Indicada para crianças antes dos 5 anos.\n\n'
          'Em 2026, o SUS está trocando a pneumocócica 10-valente pela '
          '20-valente. Durante essa mudança, a criança recebe a 10-valente '
          'aos 4 meses e a 20-valente aos 2 meses e com 1 ano. Quando acabarem '
          'as doses da 10-valente, todas serão com a 20-valente.\n\n'
          'Leve a carteira de vacinação ao posto de saúde para saber '
          'qual dose a criança precisa receber.',
      'https://www.gov.br/saude/pt-br/assuntos/noticias-ms/2026/setembro/'
          'sus-ja-vacinou-mais-de-119-mil-criancas-contra-doencas-pneumococicas-em-minas-gerais',
    ),
    'rotavirus': VaccineAudienceGuidance(
      'Bebês devem tomar 2 doses: a primeira aos 2 meses e a segunda '
      'aos 4 meses.\n\n'
      'Há limites de idade para receber essa vacina. A primeira dose pode '
      'ser dada a partir de 1 mês e 15 dias, mas deve ser tomada antes '
      'de completar 1 ano.\n\n'
      'A segunda pode ser dada a partir de 3 meses e 15 dias, mas deve '
      'ser tomada antes de completar 2 anos. Para recebê-la, o bebê '
      'precisa ter tomado a primeira dose dentro do prazo. O posto de '
      'saúde confere o tempo necessário entre as doses.',
      calendarUrl,
    ),
    'meningoc': VaccineAudienceGuidance(
      'Bebês devem tomar 2 doses: aos 3 e 5 meses. Com 1 ano, recebem '
      'um reforço com outra vacina, a meningocócica ACWY.\n\n'
      'Se a criança já tem 1 ano e ainda não completou 5 anos, '
      'o posto de saúde confere as doses que faltam e usa a ACWY '
      'para completar a proteção.',
      _technicalUrl,
    ),
    'meningoacwy': VaccineAudienceGuidance(
      'Crianças devem tomar uma dose com 1 ano, como reforço. Se essa '
      'dose estiver atrasada, podem recebê-la antes de completar 5 anos.\n\n'
      'Adolescentes de 11 a 14 anos também devem tomar uma dose, '
      'mesmo que tenham sido vacinados na infância.',
      _technicalUrl,
    ),
    'hpv': VaccineAudienceGuidance(
      'Meninas e meninos de 9 a 14 anos devem tomar uma dose.\n\n'
      'Quem tem de 15 a 19 anos e nunca tomou a vacina pode ser atendido '
      'em ações de vacinação do estado. Pergunte no posto de saúde '
      'se essa vacinação está disponível.\n\n'
      'Algumas pessoas precisam de um número diferente de doses ou '
      'podem se vacinar em outras idades. A equipe de saúde avalia esses casos.',
      _youthUrl,
    ),
    'dt': VaccineAudienceGuidance(
      'Pessoas com 7 anos ou mais que ainda não tomaram todas as doses '
      'contra difteria e tétano.\n\n'
      'Depois de completar as doses, é preciso tomar um reforço a cada '
      '10 anos para manter a proteção. Quando há risco de pegar essas '
      'doenças, a equipe de saúde pode antecipar o reforço para 5 anos.',
      _technicalUrl,
    ),
    'dtpa': VaccineAudienceGuidance(
      'Gestantes devem tomar uma dose a partir da 20ª semana de gravidez. '
      'É preciso tomar essa dose em cada gravidez, mesmo que já tenha '
      'recebido a vacina antes. Se não tomou durante a gestação, '
      'procure o posto de saúde para receber até 45 dias após o parto.\n\n'
      'A vacina também é indicada para profissionais de saúde e '
      'para parteiras e estagiários que atendem recém-nascidos. '
      'O posto confere quais doses essas pessoas precisam tomar.',
      _technicalUrl,
    ),
    'influenza': VaccineAudienceGuidance(
      'Devem se vacinar todos os anos: crianças a partir dos 6 meses '
      'e antes de completar 6 anos, gestantes e pessoas com 60 anos ou mais.\n\n'
      'Outras pessoas também podem ter direito à vacina contra a gripe. '
      'Pergunte no posto de saúde quem pode se vacinar na campanha atual.',
      calendarUrl,
    ),
    'covid19': VaccineAudienceGuidance(
      'A vacinação é recomendada para crianças a partir dos 6 meses '
      'e antes de completar 5 anos, gestantes e pessoas com 60 anos ou mais.\n\n'
      'Outras pessoas também podem ter indicação. Leve a carteira de '
      'vacinação ao posto de saúde: a equipe confere quais doses você '
      'precisa, de acordo com sua idade e as vacinas que já tomou.',
      calendarUrl,
    ),
    'febreamarela': VaccineAudienceGuidance(
      'Crianças devem tomar a primeira dose aos 9 meses e um reforço '
      'aos 4 anos.\n\n'
      'Dos 5 aos 59 anos: quem nunca tomou deve receber uma dose. '
      'Quem tomou apenas uma dose antes dos 5 anos precisa de um reforço.\n\n'
      'Pessoas com 60 anos ou mais precisam conversar com a equipe '
      'de saúde, que avalia se a vacina é indicada para cada pessoa.',
      calendarUrl,
    ),
    'tripliceviral': VaccineAudienceGuidance(
      'Crianças devem tomar 2 doses: com 1 ano e aos 15 meses '
      '(1 ano e 3 meses).\n\n'
      'Quem tem até 29 anos precisa ter recebido 2 doses. Dos 30 aos '
      '59 anos, é preciso ter recebido pelo menos uma dose. '
      'Trabalhadores da saúde precisam de 2 doses em qualquer idade.\n\n'
      'Leve a carteira ao posto de saúde para conferir se falta alguma dose. '
      'Gestantes não devem tomar essa vacina.',
      calendarUrl,
    ),
    'varicela': VaccineAudienceGuidance(
      'Crianças devem tomar aos 15 meses (1 ano e 3 meses) e aos 4 anos. '
      'Se alguma dose estiver atrasada, procure o posto de saúde '
      'antes de a criança completar 7 anos.\n\n'
      'Pessoas indígenas e trabalhadores da saúde que ainda não estão '
      'protegidos também podem precisar da vacina. A equipe de saúde '
      'avalia cada caso. Gestantes não devem tomar essa vacina.',
      _childUrl,
    ),
    'dengue': VaccineAudienceGuidance(
      'No SUS, a vacina dengue tetravalente (DNG4) é indicada para '
      'crianças e adolescentes de 10 a 14 anos. São 2 doses: '
      'a segunda deve ser tomada 3 meses depois da primeira.\n\n'
      'Existem outras vacinas contra a dengue, com recomendações '
      'diferentes. Confirme no posto de saúde qual é oferecida para sua idade.',
      _youthUrl,
    ),
    'vsr': VaccineAudienceGuidance(
      'Gestantes de qualquer idade devem tomar uma dose a partir da '
      '28ª semana de gravidez. A dose deve ser tomada em cada gravidez '
      'e ajuda a proteger o bebê nos primeiros meses de vida.',
      _pregnancyUrl,
    ),
  };

  static final _aliases = <String, String>{
    for (final entry in const <String, List<String>>{
      'bcg': ['BCG', 'BCG ID'],
      'hepatitea': ['Hepatite A', 'Hepatite A infantil', 'HA'],
      'hepatiteb': ['Hepatite B', 'Hepatite B (recombinante)', 'HB'],
      'pentavalente': ['Pentavalente', 'Penta', 'DTP Hib HB', 'DTP HB Hib'],
      'dtp': ['DTP', 'Tríplice bacteriana', 'Tríplice bacteriana (DTP)'],
      'poliomielite': [
        'Poliomielite',
        'VIP',
        'Poliomielite (VIP)',
        'Poliomielite inativada (VIP)',
      ],
      'pneumo10': [
        'Pneumocócica 10v',
        'Pneumocócica 10-valente',
        'Pneumocócica 10',
        'Pneumo 10',
        'VPC10',
      ],
      'rotavirus': [
        'Rotavírus',
        'Rotavírus humano',
        'Rotavírus humano (VORH)',
        'VORH',
      ],
      'meningoc': [
        'Meningocócica C',
        'Meningocócica C (conjugada)',
        'Meningo C',
        'Men C',
      ],
      'meningoacwy': [
        'Meningocócica ACWY',
        'Meningocócica ACWY (conjugada)',
        'Meningo ACWY',
        'Men ACWY',
        'ACWY',
      ],
      'hpv': [
        'HPV',
        'HPV4',
        'HPV quadrivalente',
        'HPV (quadrivalente)',
        'HPV (Papilomavírus humano)',
      ],
      'dt': [
        'dT',
        'Dupla adulto',
        'Dupla adulto (dT)',
        'Dupla bacteriana (dT)',
      ],
      'dtpa': [
        'dTpa',
        'Tríplice bacteriana acelular',
        'Tríplice bacteriana acelular (dTpa)',
        'dTpa (gestantes)',
      ],
      'influenza': [
        'Influenza',
        'Influenza (gripe)',
        'Influenza trivalente',
        'Gripe',
      ],
      'covid19': ['Covid-19', 'Covid'],
      'febreamarela': ['Febre amarela', 'FA'],
      'tripliceviral': ['Tríplice viral', 'Tríplice viral (SCR)', 'SCR'],
      'varicela': ['Varicela', 'Varicela (catapora)', 'Varicela monovalente'],
      'dengue': ['Dengue', 'Dengue tetravalente', 'DNG4', 'Qdenga'],
      'vsr': [
        'VSR',
        'VVSR',
        'Vírus sincicial respiratório',
        'Vírus sincicial respiratório (VSR)',
      ],
    }.entries)
      for (final alias in entry.value) _normalize(alias): entry.key,
  };

  static String _normalize(String value) {
    var result = value.toLowerCase();
    const accents = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    for (final entry in accents.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.replaceAll(RegExp('[^a-z0-9]'), '');
  }
}
