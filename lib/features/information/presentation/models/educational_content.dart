import 'package:flutter/material.dart';
import 'package:vitta_mobile/shared/widgets/vitta_mobile_shell.dart';

class EducationalContent {
  const EducationalContent({
    required this.title,
    required this.searchTerm,
    required this.introduction,
    required this.topics,
    required this.color,
    required this.icon,
    this.iconColor = vittaBlue,
  });

  final String title;
  final String searchTerm;
  final String introduction;
  final List<String> topics;
  final Color color;
  final IconData icon;
  final Color iconColor;

  bool matches(String term) {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return '$title $introduction ${topics.join(' ')}'.toLowerCase().contains(
      normalized,
    );
  }
}

const educationalContents = [
  EducationalContent(
    title: 'Vacinação Infantil',
    searchTerm: 'vacinação infantil',
    introduction:
        'A vacinação na infância ajuda a proteger a criança e toda a comunidade contra doenças que podem causar complicações graves.',
    topics: [
      'Mantenha a caderneta atualizada desde o nascimento.',
      'Respeite as datas das doses e dos reforços recomendados.',
      'Leve a carteira de vacinação em todas as consultas e campanhas.',
      'Em caso de atraso, procure uma unidade de saúde para atualizar as doses.',
    ],
    color: Color(0xFFF1C874),
    icon: Icons.family_restroom,
  ),
  EducationalContent(
    title: 'Descobertas Recentes',
    searchTerm: 'novas vacinas imunização',
    introduction:
        'Pesquisas em imunização avaliam novas vacinas, formas de aplicação e estratégias para ampliar a proteção da população.',
    topics: [
      'Novos estudos precisam passar por etapas rigorosas de segurança.',
      'Recomendações oficiais podem mudar conforme novas evidências.',
      'Consulte Ministério da Saúde, Anvisa e sociedades científicas.',
      'Notícias externas devem ser confirmadas em canais oficiais.',
    ],
    color: Color(0xFFECF6FF),
    icon: Icons.lightbulb_outline,
  ),
  EducationalContent(
    title: 'Dúvidas Frequentes',
    searchTerm: 'dúvidas sobre vacinação',
    introduction:
        'Informações confiáveis ajudam a tomar decisões seguras sobre vacinação. Veja orientações gerais para dúvidas comuns.',
    topics: [
      'Reações leves, como dor local, podem ocorrer após algumas vacinas.',
      'Atrasar uma dose não significa necessariamente reiniciar o esquema.',
      'Condições de saúde específicas devem ser avaliadas por profissional.',
      'A unidade de saúde pode conferir doses pendentes e contraindicações.',
    ],
    color: Color(0xFFFFF0F0),
    icon: Icons.question_mark,
    iconColor: Color(0xFFE43F3A),
  ),
  EducationalContent(
    title: 'Calendário Vacinal',
    searchTerm: 'calendário vacinal',
    introduction:
        'O calendário vacinal organiza as doses recomendadas em cada fase da vida e facilita o acompanhamento da proteção.',
    topics: [
      'Consulte o calendário oficial do Programa Nacional de Imunizações.',
      'As recomendações variam conforme idade e condições específicas.',
      'A unidade de saúde pode orientar a atualização de doses atrasadas.',
      'Mudanças oficiais devem ser verificadas nos canais do Ministério da Saúde.',
    ],
    color: Color(0xFFE8F4FC),
    icon: Icons.calendar_month_outlined,
  ),
  EducationalContent(
    title: 'Cuidados com a Carteira',
    searchTerm: 'carteira de vacinação',
    introduction:
        'A carteira de vacinação reúne o histórico de doses e deve ser conservada para consultas, campanhas e atendimentos.',
    topics: [
      'Guarde o documento em local seco e protegido.',
      'Leve a carteira em consultas e aplicações de vacina.',
      'Confira se data, lote e unidade foram registrados corretamente.',
      'Em caso de perda, procure a unidade onde as doses foram aplicadas.',
    ],
    color: Color(0xFFEFF7EF),
    icon: Icons.badge_outlined,
    iconColor: Color(0xFF398250),
  ),
  EducationalContent(
    title: 'Doses de Reforço',
    searchTerm: 'dose de reforço vacinação',
    introduction:
        'Algumas vacinas precisam de doses de reforço para manter a proteção ao longo do tempo.',
    topics: [
      'A necessidade de reforço depende do imunizante e da faixa etária.',
      'Verifique as datas registradas na carteira de vacinação.',
      'Não antecipe ou adie doses sem orientação da unidade de saúde.',
      'Campanhas podem oferecer reforços para públicos definidos oficialmente.',
    ],
    color: Color(0xFFFFF4E4),
    icon: Icons.replay_circle_filled_outlined,
    iconColor: Color(0xFFC77718),
  ),
  EducationalContent(
    title: 'HPV',
    searchTerm: 'vacinação HPV',
    introduction:
        'A vacinação contra o HPV faz parte das estratégias de prevenção e segue públicos definidos pelo calendário oficial.',
    topics: [
      'Consulte a faixa etária contemplada no calendário vigente.',
      'O esquema pode variar conforme idade e condições específicas.',
      'A vacina está disponível conforme as orientações do SUS.',
      'Procure uma unidade de saúde para conferir o esquema registrado.',
    ],
    color: Color(0xFFF3ECFB),
    icon: Icons.health_and_safety_outlined,
    iconColor: Color(0xFF7452A7),
  ),
  EducationalContent(
    title: 'Influenza',
    searchTerm: 'vacinação influenza',
    introduction:
        'A vacinação contra a influenza é atualizada periodicamente e ajuda a reduzir formas graves da doença.',
    topics: [
      'As campanhas informam públicos e períodos prioritários.',
      'A composição da vacina acompanha as recomendações sanitárias.',
      'Confira os canais oficiais para datas e locais de vacinação.',
      'Leve sua carteira para registrar a aplicação.',
    ],
    color: Color(0xFFEAF6F5),
    icon: Icons.air_outlined,
    iconColor: Color(0xFF2C837B),
  ),
  EducationalContent(
    title: 'Febre Amarela',
    searchTerm: 'vacinação febre amarela',
    introduction:
        'A vacina contra a febre amarela é recomendada conforme o calendário e orientações para áreas com indicação.',
    topics: [
      'Verifique a recomendação oficial para sua região ou destino.',
      'Planeje a vacinação antes de viagens para áreas com indicação.',
      'Consulte uma unidade de saúde em caso de dúvida sobre o registro.',
      'Condições específicas devem ser avaliadas por um profissional.',
    ],
    color: Color(0xFFFFF8D9),
    icon: Icons.wb_sunny_outlined,
    iconColor: Color(0xFF9A7900),
  ),
  EducationalContent(
    title: 'Vacinação na Gestação',
    searchTerm: 'vacinação gestantes gravidez',
    introduction:
        'A vacinação durante a gestação protege a pessoa gestante e pode contribuir para a proteção do bebê nos primeiros meses de vida.',
    topics: [
      'Leve a carteira de vacinação às consultas de pré-natal.',
      'O calendário considera a idade gestacional e o histórico de doses.',
      'Nem toda vacina é indicada durante a gestação.',
      'Confirme cada dose com a equipe responsável pelo pré-natal.',
    ],
    color: Color(0xFFF7ECF5),
    icon: Icons.pregnant_woman_outlined,
    iconColor: Color(0xFF9A4F88),
  ),
  EducationalContent(
    title: 'Vacinação na Adolescência',
    searchTerm: 'vacinação adolescentes',
    introduction:
        'A adolescência é uma oportunidade importante para conferir doses anteriores e completar a proteção recomendada para essa fase.',
    topics: [
      'Confira se o esquema iniciado na infância está completo.',
      'Observe as recomendações oficiais para HPV e meningocócica.',
      'Leve a carteira em consultas, campanhas e atendimentos escolares.',
      'Doses atrasadas devem ser avaliadas pela unidade de saúde.',
    ],
    color: Color(0xFFEAF7EF),
    icon: Icons.groups_2_outlined,
    iconColor: Color(0xFF398250),
  ),
  EducationalContent(
    title: 'Vacinação da Pessoa Idosa',
    searchTerm: 'vacinação pessoa idosa',
    introduction:
        'Manter a vacinação atualizada ajuda a reduzir complicações de doenças que podem ser mais graves com o avanço da idade.',
    topics: [
      'Leve a carteira para revisão nas consultas de rotina.',
      'Campanhas sazonais podem ter públicos e períodos específicos.',
      'Condições clínicas devem ser informadas ao profissional de saúde.',
      'A unidade de saúde pode orientar doses e reforços recomendados.',
    ],
    color: Color(0xFFEAF3FB),
    icon: Icons.elderly_outlined,
    iconColor: Color(0xFF3B7198),
  ),
  EducationalContent(
    title: 'Vacinação e Viagens',
    searchTerm: 'vacinação viagem viajantes',
    introduction:
        'Alguns destinos exigem planejamento prévio da vacinação e podem ter recomendações específicas para viajantes.',
    topics: [
      'Consulte as orientações oficiais sobre o destino com antecedência.',
      'Verifique a validade dos registros e certificados necessários.',
      'Não deixe a atualização da carteira para a véspera da viagem.',
      'Procure orientação profissional em situações de saúde específicas.',
    ],
    color: Color(0xFFFFF4E8),
    icon: Icons.luggage_outlined,
    iconColor: Color(0xFFA86421),
  ),
];
