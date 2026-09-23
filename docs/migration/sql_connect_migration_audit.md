# Auditoria da migração Mobile para Firebase SQL Connect

Data da auditoria: 22/09/2026  
Modo: somente leitura; nenhum deploy, push ou migração de dados foi executado.

## 1. Instância SQL Connect real

| Item | Valor encontrado |
| --- | --- |
| Firebase project | `vitta-5ec1e` |
| serviceId | `vitta-5ec1e-service` |
| connectorId implantado | `example` |
| location | `southamerica-east1` |
| Cloud SQL instance | `vitta-5ec1e-instance` |
| database | `vitta-5ec1e-database` |
| schema validation local | `COMPATIBLE` |
| última atualização do schema remoto | `2026-09-01T22:30:03.572280734Z` |
| última atualização do connector remoto | `2026-09-13T16:43:46.199541864Z` |

O `firebase dataconnect:sql:diff` não está vazio: o schema local declara
`Patient.motherName`, mas a coluna `patient.mother_name` ainda não existe no
Cloud SQL. Por isso, a operação local `ListPatients` falha contra o serviço
implantado com `unrecognized field Patient.motherName`.

## 2. Schema encontrado

Todas as tabelas usam a chave implícita `id: UUID`. Chaves e referências reais:

| Model | Campos relevantes | Unicidade / referências |
| --- | --- | --- |
| `User` | `name`, `birthDate`, `email`, `status`, `cpf`, `sex` | `email` e `cpf` únicos |
| `Patient` | `user`, `patientType`, `responsible`, `motherName` | `user` único; `responsible -> Patient` opcional |
| `UBS` | `name`, endereço | sem chave de negócio explícita |
| `Professional` | `user`, `professionalType`, `professionalRegistration`, `ubs` | `user` único; FKs para `User` e `UBS` |
| `Vaccine` | `name`, `description`, `requiredDoses` | sem chave de negócio explícita |
| `Batch` | `vaccine`, `manufacturer`, `batchCode`, quantidades e datas | FK para `Vaccine` |
| `Appointment` | `patient`, `vaccine`, `ubs`, datas, `status`, `notes` | FKs para `Patient`, `Vaccine` e `UBS` |
| `Application` | `patient`, `vaccine`, `batch`, `appointment`, `professional`, `ubs`, `applicationDate`, `doseNumber`, `notes` | FKs; `professional` e `ubs` são obrigatórios |

Enums: `UserStatus`, `PatientType`, `ProfessionalType` e
`AppointmentStatus`.

## 3. Operações do connector Web

Queries:

- usuários: `ListUsers`, `GetUser`, `GetUserByCpf`, `GetUserByEmail`;
- pacientes: `ListPatients`, `GetPatient`, `GetPatientByUser`;
- unidades: `ListUbs`, `GetUbs`, `SearchUbsByName`;
- profissionais: `ListProfessionals`, `GetProfessional`, `GetProfessionalByUser`;
- vacinas: `ListVaccines`, `GetVaccine`, `SearchVaccinesByName`;
- lotes: `ListBatches`, `GetBatch`, `ListBatchesByVaccine`;
- agendamentos: `ListAppointments`, `GetAppointment`, `ListAppointmentsByPatient`, `ListAppointmentsByStatus`;
- aplicações: `ListApplications`, `GetApplication`, `ListApplicationsByPatient`, `ListApplicationsByVaccine`.

Mutations: `Create`, `Update` e `Delete` para `User`, `Patient`, `Ubs`,
`Professional`, `Vaccine`, `Batch`, `Appointment` e `Application` (24
operations).

## 4. Modelo de autenticação e achado crítico de segurança

O Web mantém o login no Firebase Authentication, mas resolve o perfil
profissional em `Firestore/auth_links` e `Firestore/users` no cliente. Essa
checagem não protege diretamente as operações SQL.

Todas as 51 operations encontradas (27 queries e 24 mutations) usam
`@auth(level: USER)`. Nenhuma usa
`auth.uid`, `auth.token`, `@check` ou uma consulta redigida para vincular o
chamador à linha acessada. Portanto, qualquer conta Firebase autenticada pode,
em nível de connector:

- listar todos os usuários, pacientes, profissionais e aplicações;
- consultar qualquer CPF exato;
- ler uma carteira fornecendo qualquer `patientId`;
- executar mutations administrativas, inclusive alteração/exclusão.

O connector `example` não é seguro para ser reutilizado pelo Mobile. A
documentação oficial do Firebase também classifica uma operation `USER` que
não referencia `auth.uid` como insegura.

## 5. Mapa Firestore para SQL real

| Firestore Mobile | Destino real ou proposto | Situação |
| --- | --- | --- |
| `users` | `User` + `Patient` | parcial; faltam `authUid`, telefone, metadados e suporte a e-mail nulo para dependentes |
| `auth_links` | `User.authUid` | campo não existe |
| `cpf_registry` | `User.cpf @unique` + lookup protegido | unicidade existe; lookup atual é global para qualquer usuário autenticado |
| `relationships` | nova `FamilyRelationship` | não existe equivalente para múltiplos vínculos diretos |
| `access_grants` | nova `PatientAccess` | não existe equivalente de autorização direta |
| `users/*/private/emergency_contact` | nova `EmergencyContact` 1:1 | não existe |
| `vaccines` | `Vaccine` | model real existe, mas só cobre nome, descrição e quantidade de doses |
| `vaccination_records` | `Application` | parcial; faltam `legacyRecordId`, `nextDoseAt`, `doseLabel`, snapshots e relações opcionais para legado |
| `vaccination_schedules` | nenhuma tabela | coleção está vazia; schema não possui calendário versionado |
| `children` | `User` + `Patient` + relações | legado a reconciliar; não deve virar tabela paralela |
| `professional_patient_access` | autorização no connector | concessão Firestore é temporária e não deve ser copiada cegamente |
| `information_posts` | sem destino atual | coleção vazia; conteúdo atual do app é local |
| `news_articles` | permanece no Firestore | explicitamente fora da migração |

## 6. Inventário somente leitura

O relatório reproduzível está em `firestore_sql_audit.json`. Nenhum CPF, nome
ou e-mail é emitido.

| Origem | Entidade | Quantidade |
| --- | --- | ---: |
| Firestore | `users` | 16 |
| Firestore | `auth_links` | 4 |
| Firestore | `cpf_registry` | 10 |
| Firestore | `relationships` | 7 |
| Firestore | `access_grants` | 7 |
| Firestore | `vaccines` | 19 |
| Firestore | `vaccination_records` | 3 |
| Firestore | contatos de emergência | 3 |
| Firestore | `news_articles` | 1 |
| SQL | `Patient` | 4 |
| SQL | `Application` | 9 |
| SQL | `Vaccine` | 19 |

Matching preliminar:

- pacientes: 3 CPFs presentes nas duas bases, 8 apenas no Firestore e 1 apenas no SQL;
- 5 documentos `users` não possuem CPF utilizável e exigem classificação manual/legada;
- vacinas: 12 nomes coincidem; 7 aparecem apenas em cada lado;
- aplicações: nenhuma das 3 do Firestore teve correspondência heurística exata no SQL;
- um `legacyRecordId` único é necessário para idempotência confiável.

## 7. Extensão mínima proposta (ainda não aplicada)

Mudanças aditivas/compatíveis sempre que possível:

1. `User`: `authUid` único e opcional, `phone`, `photoUrl`, timestamps e papel
   de portal não editável pelo connector Mobile. Tornar `email` opcional para
   dependentes sem Firebase Auth.
2. `Patient`: `legacyPersonId` único para idempotência e auditoria.
3. `EmergencyContact`: relação 1:1 com `User`.
4. `FamilyRelationship`: par direto `fromPatient/toPatient`, tipo, estado,
   consentimento e validade.
5. `PatientAccess`: concessão direta por `granteeAuthUid + patient`, sem
   fechamento transitivo. Deve existir uma concessão `SELF` para o titular e
   uma concessão explícita para cada dependente.
6. `Application`: `legacyRecordId` único, `nextDoseAt`, `doseLabel`, `source` e
   snapshots opcionais. Avaliar tornar `professional` e `ubs` opcionais para
   registros legados, mantendo-os obrigatórios nas mutations profissionais.
7. `Vaccine`: `legacyVaccineId` único e campos editoriais somente se a paridade
   do catálogo detalhado for exigida pelo produto.

O `PatientAccess` é a peça que preserva a regra crítica: se A acessa B e B
acessa C, A não ganha acesso a C. As queries usam somente grants em que
`granteeAuthUid_expr: auth.uid`; não percorrem relações recursivamente.

## 8. Connectors propostos

- `example`: manter para o Web, mas substituir as autorizações globais por
  preflight SQL com `auth.uid` e `@check/@redact`. Operações administrativas
  exigem papel de administrador; aplicações exigem profissional ativo.
- `mobile-connector`: novo connector no mesmo `vitta-5ec1e-service`, mesmo
  banco e mesmo schema. Expor somente perfil próprio, carteiras concedidas,
  catálogo, aplicações das carteiras concedidas, atualização limitada de
  perfil e cadastro seguro.

Nenhuma operation Mobile aceitará `authUid`, papel, CPF, nascimento ou
`personId` como campo livre em atualização.

## 9. Impactos e riscos antes do deploy

- O Web precisa regenerar seu SDK porque o schema implantado já está atrás do
  schema local em `motherName`.
- Alterar `email` de obrigatório para opcional e permitir relações opcionais em
  `Application` muda nulabilidade dos tipos gerados; os mapeadores Web atuais
  já são defensivos, mas os testes precisam cobrir isso.
- O bootstrap de papéis profissionais/administrativos deve vir do Firestore
  atual por ferramenta administrativa auditável; nunca de uma mutation pública.
- O deploy do schema cria migration SQL. Ele não pode acontecer antes de revisar
  o diff e um backup do banco.
- O SDK Dart seguro só deve ser gerado a partir do `mobile-connector`; gerar o
  SDK do connector atual propagaria operações inseguras para o app.

## 10. Próxima fase condicionada à aprovação

Após aprovação deste desenho:

1. implementar localmente a extensão do schema e o `mobile-connector`;
2. validar o schema e o SQL diff sem deploy;
3. gerar o SDK Dart oficial em `vitta_mobile`;
4. implementar repositories SQL e testes com emulator/fakes;
5. criar o migrador idempotente em modo `dry-run` por padrão;
6. apresentar novamente migration/diff antes de qualquer deploy Data Connect.
