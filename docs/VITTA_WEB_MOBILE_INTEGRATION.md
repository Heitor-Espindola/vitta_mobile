# Integração Vitta Web ↔ Mobile

## Projetos e fonte de verdade

- Firebase: `vitta-5ec1e`.
- Pessoa: `users/{personId}`.
- Conta: Firebase Auth UID ligado por `auth_links/{authUid}`.
- CPF: `cpf_registry/{sha256(cpfDigits)}`.
- Catálogo: `vaccines`.
- Aplicações: `vaccination_records`.
- Rules e índices oficiais: `firestore.rules` e `firestore.indexes.json` na
  raiz do projeto Mobile.

## Fluxo profissional

1. Firebase Authentication autentica e fornece `professionalUid`.
2. O Web resolve `auth_links/{professionalUid}` com fallback para o UID.
3. `users/{personIdDoProfissional}` precisa ter `accountStatus: active` e role
   `health_professional` ou `admin`.
4. O CPF do paciente é normalizado para 11 dígitos, validado e transformado
   em SHA-256 no navegador.
5. O Web executa somente `GET cpf_registry/{hash}`. `LIST` é negado.
6. A Rule valida uma autorização curta em
   `professional_patient_access/{professionalUid}_{patientId}`.
7. Com essa autorização, o profissional pode obter apenas aquele paciente e
   consultar sua carteira por `patientId`.
8. A nova aplicação grava `professionalUid` diretamente da sessão e
   `source: professional_panel`.

## Atualização em tempo real

O Web e o Mobile usam listeners sobre a mesma consulta:

```text
vaccination_records
where patientId == PERSON_ID
orderBy appliedAt DESC
```

O Mobile combina essa consulta com a consulta legada por `patientUid` apenas
para o titular autenticado. O Web nunca cria `patientUid` novo. Home, Carteira,
Caderneta, Vacinas e Notificações derivam seu estado dos snapshots recebidos;
não é necessário refresh ou novo login.

## Limites de segurança do MVP

- Não existe listagem global de pacientes.
- Um profissional pode consultar suas próprias aplicações auditadas.
- Histórico completo de terceiro exige atendimento validado por CPF e expira.
- Aplicações oficiais não podem ser editadas nem excluídas pelo cliente.
- O catálogo permanece somente leitura no painel nesta etapa.
- Firebase Admin SDK e Cloud Functions não fazem parte do navegador.
