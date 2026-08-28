# Migração compatível de identidade e relacionamentos

## Modelo atual

`users/{personId}` é o cadastro permanente da pessoa. Firebase Authentication
é apenas o mecanismo de login. `auth_links/{authUid}` guarda o `personId`
associado; na ausência desse documento, clientes e regras usam `authUid` como
fallback para preservar contas antigas.

Novas contas começam com `personId == authUid`, mas o contrato não exige que
essa igualdade permaneça para sempre. Dependentes possuem `personId` próprio,
`authUid: null` e `canAuthenticate: false`.

O painel profissional resolve a própria conta por
`auth_links/{authUid}.personId`, mas nunca usa o UID do profissional como ID do
paciente. A pessoa atendida é localizada por SHA-256 do CPF em
`cpf_registry/{hash}`; `personId` é preferido e `ownerUid` permanece como
fallback legado.

## Migração aditiva sugerida

1. Fazer backup/exportação do Firestore.
2. Para cada usuário autenticável legado, criar `auth_links/{authUid}` com
   `personId` apontando ao documento atual e `createdAt` no servidor.
3. Preencher `personId` e `majorityAt` nos documentos legados sem trocar IDs.
4. Converter cada vínculo legado em `relationships/{fromId}_{toId}` inicialmente
   `pending`; verificação oficial/manual deve ocorrer fora do cliente.
5. Migrar `vaccination_records.patientUid` para `patientId` em lotes idempotentes.
   Durante a transição, não apagar o campo legado até todos os clientes antigos
   deixarem de ser usados.
6. Somente após auditoria completa considerar a retirada dos arrays legados.

O aplicativo desta versão não executa migração destrutiva nem inventa uma
verificação oficial. A criação de dependente gera um vínculo
`manual_pending`, sem permissões, que precisa de um processo confiável para
chegar a `verified`.

No MVP, as rotas legadas de filhos/dependentes e o atalho de vínculo familiar
não fazem parte da navegação normal. O código e os dados foram preservados para
uma etapa futura, mas nenhum fluxo cliente incompleto concede acesso a carteiras
de terceiros.

## Relacionamentos e acesso

`relationships/{fromPersonId}_{toPersonId}` representa somente uma aresta
direta. Campos: `fromPersonId`, `toPersonId`, `type`, `status`, `permissions`,
`consentStatus`, `verificationSource`, `verifiedAt`, `validUntil`, `createdAt`
e `updatedAt`.

Para menor de idade, pai, mãe, responsável legal ou tutor pode acessar a
carteira quando o vínculo direto estiver verificado e a permissão habilitada.
Isso contempla uma mãe menor de idade: a idade do responsável não invalida a
maternidade; a maioridade avaliada é a da pessoa cuja carteira será acessada.

`majorityAt` é calculado de `birthDate + 18 anos` (29 de fevereiro é ajustado
para o último dia de fevereiro). Ao atingir essa data:

- o documento de relacionamento permanece para preservar o vínculo familiar;
- a autorização automática de responsável por menor deixa de valer;
- o adulto passa a controlar os próprios dados;
- acesso de terceiro requer `access_grants/{granteeId}_{subjectId}` explícito,
  concedido, com `viewVaccination: true` e ainda dentro de `validUntil` quando
  essa data existir.

Não há travessia de grafo. Avó → mãe e mãe → bebê não implica avó → bebê.

## Campos e coleções legadas

- `dependentIds`, `guardianIds`, `managedByUserIds`: mantidos para telas e
  versões antigas; não devem ser a fonte definitiva de autorização.
- `children`: feature legada isolada; não foi apagada nem migrada nesta etapa.
- `patientUid`: somente leitura compatível de registros antigos.

## Responsabilidades futuras

- backend/Admin SDK para verificar vínculos e emitir/revogar consentimentos;
- migração idempotente e auditável dos dados existentes;
- interface para o adulto conceder, limitar e revogar acesso;
- política de retenção, auditoria e tratamento LGPD;
- notificações push reais, caso aprovadas, sem ampliar permissão de leitura.
