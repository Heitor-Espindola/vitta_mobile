# Fontes de “Quem deve tomar?”

Pesquisa revisada em 05/10/2026, com orientações do Ministério da Saúde para o calendário brasileiro do SUS. Os textos são educativos: não calculam elegibilidade individual, não geram agendamentos e não substituem a avaliação do histórico vacinal.

Os textos foram revisados em linguagem simples para quem utiliza o SUS. A idade de rotina aparece primeiro, seguida das orientações para atrasos ou situações específicas, em parágrafos separados. Limites como “4 anos, 11 meses e 29 dias” são apresentados como “antes de completar 5 anos”. As recomendações e as fontes da pesquisa foram preservadas.

## Cobertura

O catálogo local de `vaccines_screen.dart` contém 15 entradas históricas, consolidadas por vacina antes da exibição. A filtragem não reduz mais cada vacina a uma única categoria: uma mesma vacina aparece em todas as fases nas quais existe recomendação de rotina ou indicação especial no calendário 2026. As cinco fases exibidas são crianças, adolescentes e jovens, adultos, gestantes e idosos.

COVID-19 e influenza aparecem também para jovens e adultos, mas o detalhe deixa explícito que não são vacinas de rotina para todas as pessoas dessas faixas. Para COVID-19, pessoas de 5 a 59 anos sem vacinação prévia podem receber uma dose, enquanto grupos especiais possuem recomendação periódica. Indicações condicionais como pneumocócica 20-valente, varicela, dTpa e tríplice viral em faixas específicas também são descritas sem tratá-las como recomendação universal.

O catálogo exibido em produção é carregado pelo repositório de domínio do Firebase SQL Connect. O Firestore permanece apenas nos fluxos explicitamente legados e no sistema de notícias, fora deste catálogo. A implementação também reconhece DTP e hepatite A, visíveis nas imagens fornecidas, além de meningocócica C, tríplice viral, varicela, dengue DNG4 e VSR. Nomes, siglas e IDs conhecidos são associados em `VaccineAudienceGuidance`; não se usa correspondência parcial que possa confundir produtos distintos.

Para entradas ainda não reconhecidas, a tela preserva `recommendedAge` do cadastro SQL, sem atribuir esse conteúdo à pesquisa oficial; se a idade estiver ausente, informa explicitamente essa ausência. Novas vacinas precisam de revisão e associação próprias.

## Referências

| Conteúdo | Fonte oficial consultada |
| --- | --- |
| BCG, pentavalente, DTP, hepatite A e varicela | [Calendário técnico da criança](https://www.gov.br/saude/pt-br/composicao/svsa/pni/calendario-tecnico/calendario-tecnico-nacional-de-vacinacao-crianca) |
| Hepatite B, meningocócicas C/ACWY, dT e dTpa | [Instrução Normativa do Calendário Nacional de Vacinação 2026](https://www.gov.br/saude/pt-br/vacinacao/publicacoes/instrucao-normativa-que-instrui-o-calendario-nacional-de-vacinacao-2026.pdf) |
| Rotavírus, tríplice viral, influenza, covid-19 e febre amarela | [Calendário Nacional de Vacinação](https://www.gov.br/saude/pt-br/vacinacao/calendario) |
| HPV e dengue DNG4 | [Calendário técnico de adolescentes e jovens](https://www.gov.br/saude/pt-br/composicao/svsa/pni/calendario-tecnico/calendario-tecnico-nacional-de-vacinacao-adolescentes-jovens) |
| Hepatite B, dT, febre amarela, tríplice viral e indicações especiais de adultos | [Calendário técnico do adulto](https://www.gov.br/saude/pt-br/composicao/svsa/pni/calendario-tecnico/calendario-tecnico-nacional-de-vacinacao-adulto) |
| Recomendações específicas na gestação e VSR | [Calendário da gestante 2026](https://www.gov.br/saude/pt-br/vacinacao/arquivos/calendario-nacional-de-vacinacao-gestante) |
| Recomendações específicas para idosos | [Calendário do idoso 2026](https://www.gov.br/saude/pt-br/vacinacao/arquivos/calendario-nacional-de-vacinacao-idoso) |
| COVID-19 para pessoas de 5 a 59 anos e grupos especiais | [Esquema vacinal COVID-19](https://www.gov.br/saude/pt-br/assuntos/saude-de-a-a-z/c/covid-19/esquemas-vacinais/esquema-vacinal-covid-19) |
| Atualização da poliomielite | [Comunicado de agosto de 2026](https://www.gov.br/saude/pt-br/assuntos/noticias-ms/2026/agosto/ministerio-da-saude-reforca-vacinacao-de-criancas-e-adolescentes-contra-sarampo-pneumonias-e-outras-doencas) |
| Transição da pneumocócica 10v para 20v | [Comunicado de setembro de 2026](https://www.gov.br/saude/pt-br/assuntos/noticias-ms/2026/setembro/sus-ja-vacinou-mais-de-119-mil-criancas-contra-doencas-pneumococicas-em-minas-gerais) |

As publicações complementares de 2026 prevalecem sobre versões anteriores dos calendários técnicos. A tela mantém um link específico da fonte de faixa etária e a data da consulta. Revisar os textos quando houver mudanças no PNI, especialmente nas estratégias temporárias de HPV e na transição das pneumocócicas.
