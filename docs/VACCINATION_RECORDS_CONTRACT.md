# Contrato de integração — aplicações de vacinas

## Fonte de verdade

- `users/{personId}` representa uma pessoa.
- `vaccines/{vaccineId}` contém o catálogo e o conteúdo educativo.
- `vaccination_records/{recordId}` contém aplicações realizadas.
- `auth_links/{authUid}.personId` liga uma autenticação Firebase à pessoa.

Home, Vacinas, Carteira e Caderneta derivam suas informações das mesmas
coleções. Não grave `status`: o aplicativo calcula `Aplicada`, `Próxima dose`
ou `Atrasada` usando `appliedAt`, `nextDoseAt` e a data atual. Um registro
aplicado não significa que todo o esquema vacinal está concluído.

## Campos de `vaccination_records`

| Campo | Tipo Firestore | Uso | Descrição |
| --- | --- | --- | --- |
| `patientId` | string | obrigatório em novas gravações | ID da pessoa em `users/{personId}`. Não é necessariamente um UID do Firebase Auth. |
| `vaccineId` | string | obrigatório | ID estável da vacina. |
| `vaccineName` | string | obrigatório | Nome exibido da vacina. |
| `doseLabel` | string | obrigatório | Ex.: `Dose única` ou `2ª dose`. |
| `doseNumber` | integer | opcional | Número ordinal da dose. |
| `appliedAt` | Timestamp | obrigatório | Data real da aplicação. |
| `nextDoseAt` | Timestamp | opcional | Próxima dose informada pelo profissional. |
| `lot` | string | opcional | Lote. |
| `manufacturer` | string | opcional | Fabricante. |
| `facilityId` | string | opcional | ID da unidade. |
| `facilityName` | string | opcional | Nome da unidade/local. |
| `professionalUid` | string | obrigatório | UID Firebase do profissional autenticado; deve ser igual a `auth.currentUser.uid`. |
| `notes` | string | opcional | Observações. |
| `source` | string | obrigatório | Nesta versão: `professional_panel`. |
| `createdAt` | server Timestamp | obrigatório | Use `serverTimestamp()`. |
| `updatedAt` | server Timestamp | obrigatório | Use `serverTimestamp()` na criação. |

Campos opcionais sem valor devem ser omitidos. Campos fora desta tabela são
recusados nas novas gravações.

`patientUid` é aceito somente na leitura de documentos legados. Não o envie em
novos registros. O aplicativo combina e remove duplicatas das consultas atual
(`patientId`) e legada (`patientUid`) para o titular autenticado.

## Exemplo exato para Firebase Web SDK

```javascript
import {
  addDoc,
  collection,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';
import { auth, db } from './firebase';

export async function registerVaccination({
  patientId,
  vaccineId,
  vaccineName,
  doseLabel,
  doseNumber,
  appliedAt,
  nextDoseAt,
  lot,
  manufacturer,
  facilityId,
  facilityName,
  notes,
}) {
  const professional = auth.currentUser;
  if (!professional) throw new Error('Profissional não autenticado.');

  const data = {
    patientId,
    vaccineId,
    vaccineName,
    doseLabel,
    appliedAt: Timestamp.fromDate(appliedAt),
    professionalUid: professional.uid,
    source: 'professional_panel',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };

  if (Number.isInteger(doseNumber)) data.doseNumber = doseNumber;
  if (nextDoseAt instanceof Date) data.nextDoseAt = Timestamp.fromDate(nextDoseAt);
  if (lot) data.lot = lot;
  if (manufacturer) data.manufacturer = manufacturer;
  if (facilityId) data.facilityId = facilityId;
  if (facilityName) data.facilityName = facilityName;
  if (notes) data.notes = notes;

  return addDoc(collection(db, 'vaccination_records'), data);
}
```

O `users/{personIdDoProfissional}` precisa conter
`roles: ['health_professional', ...]` e `accountStatus: 'active'`. A autorização
resolve esse `personId` por `auth_links`, enquanto `professionalUid` conserva o
UID Firebase que executou a operação para auditoria.

## Permissões

- Titular autenticado: lê sua própria pessoa após resolver `auth_links`, com
  fallback compatível para `auth.uid`.
- Responsável por menor: lê somente por relacionamento direto, verificado e
  com `permissions.viewVaccination == true`.
- Após a maioridade: o relacionamento permanece, mas a leitura exige um
  `access_grants/{responsavelId}_{adultoId}` concedido e válido.
- Profissional ativo: cria registros válidos e auditados pelo próprio UID;
  não recebe leitura ampla, edição ou exclusão.
- Não existe acesso transitivo: um vínculo com a mãe não concede acesso
  automático ao filho dela.

## Consultas e índices

Consulta atual:

```text
where patientId == PERSON_ID
orderBy appliedAt DESC
```

Compatibilidade do titular legado:

```text
where patientUid == AUTH_UID
orderBy appliedAt DESC
```

Os dois índices compostos estão em `firestore.indexes.json`.

## Teste manual Web → Firestore → Mobile

1. Entre no mobile e obtenha o `personId` por `auth_links/{authUid}`; se o
   documento não existir, use temporariamente o próprio `authUid`.
2. Confirme que `users/{personId}` existe.
3. Entre no painel com um profissional ativo.
4. Registre BCG/Dose única usando `patientId`, nunca `patientUid`.
5. Com o Vitta aberto, confira a atualização em tempo real na Home e Carteira.
6. Confira data, lote, fabricante, unidade e próxima dose quando enviados.

## Legado

`dependentIds`, `guardianIds`, `managedByUserIds` e a coleção `children`
continuam presentes para compatibilidade, mas não são a nova fonte de
autorização. Novos vínculos são representados também em `relationships`.
Consulte `PERSON_IDENTITY_MIGRATION.md` antes de migrar dados existentes.

## Deploy manual (não executado)

Após revisão do responsável pelo Firebase:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project vitta-5ec1e
```
