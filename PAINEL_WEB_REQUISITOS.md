# Requisitos do painel web profissional do Vitta

## Estado desta entrega

O aplicativo Flutter já consome `users`, `vaccination_records` e `vaccines` e mantém a Carteira aberta atualizada por listener do Firestore. Dependentes são documentos da coleção `users`, vinculados ao responsável e sem conta no Firebase Authentication.

O painel web, a autorização profissional, o envio de FCM e o cálculo clínico de doses **não estão implementados** nesta entrega. As estruturas abaixo são o contrato recomendado para a integração futura.

## Módulos do painel

- Dashboard
- Pacientes
- Vacinação
- Calendário vacinal
- Vacinas
- Conteúdos
- Notificações
- Profissionais
- Unidades de saúde
- Auditoria

Fluxo principal: pesquisar paciente autorizado → abrir perfil e carteira → selecionar vacina e dose → registrar aplicação → gravar no Firestore → aplicativo receber o snapshot atualizado.

## Coleções lidas

### `users/{personId}`

Identidade da pessoa. O painel deve usar `personId` como referência de paciente e respeitar `guardianIds`, `dependentIds` e `managedByUserIds`. Dependentes têm `canAuthenticate: false`; isso não os torna menos protegidos.

Uma busca global por CPF ou nome não deve ser liberada diretamente para clientes comuns. O painel precisa de uma camada backend autorizada, trilha de auditoria e justificativa de acesso.

### `vaccines/{vaccineId}`

Catálogo único. Campos compatíveis no Flutter:

- `name`, `shortName`, `description`;
- `prevents[]`, `targetGroups[]`, `doseSchedule[]`;
- `expectedReactions[]`, `warningSigns[]`, `contraindications[]`;
- `sourceName`, `sourceUrl`, `sourceUpdatedAt`;
- `calendarVersion`, `active`.

Conteúdo médico deve ter fonte oficial verificável, revisão editorial e data de atualização. Não publicar informação clínica sem fonte.

### `vaccination_schedules/{version}`

Calendário versionado, com `version`, `publishedAt`, `sourceName`, `sourceUrl`, `active` e `entries[]`. Cada entrada pode conter `vaccineId`, `doseNumber`, `recommendedAge`, `minAgeDays`, `maxAgeDays`, `intervalDays`, `targetGroup` e `notes`.

Somente uma versão deve estar ativa. A ativação precisa ser atômica e auditada. O Flutter já possui modelos compatíveis, mas o cálculo clínico ainda depende de dados oficiais e regras validadas.

### Coleções preservadas

`children`, `information_posts` e `cpf_registry` continuam legítimas. Não migrar ou excluir sem plano explícito. `cpf_registry` é técnico e não deve aparecer em pesquisas comuns do painel.

## Gravação de aplicação

Coleção: `vaccination_records/{recordId}`.

Campos recomendados e compatíveis:

- `personId`: pessoa vacinada;
- `childId`: campo legado mantido durante compatibilidade;
- `responsibleId`: responsável que pode ler o registro no aplicativo;
- `vaccineId`, `vaccineName`, `dose`;
- `status`, `applicationDate`, `nextDoseDate` quando calculada por regra validada;
- `batchNumber`, `manufacturer`;
- `healthUnitId`, `healthUnit`;
- `professionalId`;
- `createdAt`, `createdBy`;
- `source`, por exemplo `health_professional`;
- `notes`.

O formulário do painel deve exigir vacina, dose, data, lote, fabricante, unidade e profissional conforme as normas definidas pelo projeto. O servidor deve preencher identidade do profissional e timestamps; o navegador não pode escolher livremente `createdBy` ou `professionalId`.

Correções não devem apagar o documento original silenciosamente. Registrar evento de auditoria ou uma revisão vinculada ao registro anterior.

## Profissionais e permissões

Estrutura futura sugerida, após confirmar que não existe equivalente no backend:

`professionals/{uid}` com nome, CPF protegido, registro profissional, tipo de registro, `healthUnitIds`, `status`, datas e permissões como `canViewPatients`, `canRegisterVaccines` e `canCorrectRecords`.

Papéis e permissões devem ser concedidos por administrador/backend confiável, idealmente com custom claims validadas nas regras. Nunca permitir que o próprio usuário altere `role`, `roles` ou `accountStatus`.

As regras atuais mantêm escrita de `vaccination_records`, `vaccines` e `vaccination_schedules` bloqueada para clientes. Antes do painel entrar em produção, criar regras específicas e testes no Emulator Suite para:

- profissional ativo e vinculado à unidade;
- acesso mínimo necessário ao paciente;
- validação integral dos campos;
- impossibilidade de autoelevação de privilégio;
- auditoria obrigatória;
- bloqueio de edição/remoção indevida.

## Atualização no Flutter

A Carteira usa snapshots de `vaccination_records` filtrados pelo `responsibleId` autenticado e pelo `personId`/`childId` selecionado. Uma gravação autorizada feita pelo painel aparece sem atualização manual. O registro deve sempre conter `responsibleId` correto para satisfazer as regras e consultas atuais.

## Notificações

### Estrutura preparada

Tokens poderão ser armazenados em `users/{uid}/devices/{deviceId}` com:

- `fcmToken`, `platform`;
- `createdAt`, `lastSeenAt`;
- `notificationsEnabled`.

As regras já reservam a subcoleção para o proprietário. O contrato Flutter `DeviceRepository` existe, mas `firebase_messaging` não foi instalado e nenhum token é coletado nesta etapa.

### Backend futuro

O backend autorizado deve detectar/receber o registro de aplicação, consultar dispositivos habilitados, enviar a notificação por Firebase Cloud Messaging e registrar resultado/erros. Tokens inválidos devem ser removidos. O painel nunca deve receber credenciais administrativas do Firebase no cliente.

Lembretes de datas podem ser agendados localmente no dispositivo depois que a lógica de calendário estiver validada. Permissões, fuso horário, reagendamento e cancelamento precisam ser tratados. Não foi adicionada dependência de notificações locais nesta etapa.

## Auditoria e privacidade

Criar uma coleção de auditoria gravada apenas pelo backend contendo ator, ação, paciente, unidade, data, origem, valores relevantes e motivo de correção. Dados de saúde e CPF exigem controle de acesso, minimização, retenção definida e conformidade com a LGPD.

## Critérios mínimos antes de produção

1. Dados oficiais do PNI revisados e versionados.
2. Regras e custom claims testadas no Emulator Suite.
3. Fluxo de credenciamento profissional controlado.
4. Auditoria imutável e política de correção.
5. Índices do Firestore documentados e implantados.
6. Testes de integração painel → Firestore → Flutter.
7. Política de notificações e consentimento do usuário.
