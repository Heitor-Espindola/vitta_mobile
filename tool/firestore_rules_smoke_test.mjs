import { createHash } from 'node:crypto';

const projectId = process.env.GCLOUD_PROJECT || 'vitta-5ec1e';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const firestoreHost =
  process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const databaseRoot = `projects/${projectId}/databases/(default)`;
const apiRoot = `http://${firestoreHost}/v1/${databaseRoot}`;

const timestamp = () => ({ timestampValue: new Date().toISOString() });
const string = (value) => ({ stringValue: value });
const boolean = (value) => ({ booleanValue: value });
const nullableString = (value) =>
  value == null ? { nullValue: null } : string(value);
const strings = (values) => ({
  arrayValue: { values: values.map(string) },
});

async function createAuthUser(label) {
  const response = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        email: `${label}-${Date.now()}@example.test`,
        password: 'TestPassword123!',
        returnSecureToken: true,
      }),
    },
  );
  const body = await response.json();
  if (!response.ok) throw new Error(`Falha no Auth Emulator: ${response.status}`);
  return { uid: body.localId, token: body.idToken };
}

function userFields({
  uid,
  name,
  cpf,
  role,
  roles,
  authUid,
  canAuthenticate,
  guardianIds = [],
  dependentIds = [],
  managedByUserIds = [],
  relationshipToGuardian,
}) {
  const formattedCpf = `${cpf.slice(0, 3)}.${cpf.slice(3, 6)}.${cpf.slice(6, 9)}-${cpf.slice(9)}`;
  return {
    uid: string(uid),
    id: string(uid),
    authUid: string(authUid),
    canAuthenticate: boolean(canAuthenticate),
    name: string(name),
    fullName: string(name),
    normalizedName: string(name.toLowerCase()),
    email: string(canAuthenticate ? `${uid}@example.test` : ''),
    role: string(role),
    roles: strings(roles),
    accountStatus: string('active'),
    cpf: string(cpf),
    cpfDigits: string(cpf),
    cpfFormatted: string(formattedCpf),
    guardianIds: strings(guardianIds),
    dependentIds: strings(dependentIds),
    managedByUserIds: strings(managedByUserIds),
    ...(relationshipToGuardian == null
      ? {}
      : { relationshipToGuardian: string(relationshipToGuardian) }),
    birthDate: timestamp(),
    phone: nullableString(null),
    photoUrl: nullableString(null),
    createdAt: timestamp(),
    updatedAt: timestamp(),
    lastLoginAt: { nullValue: null },
  };
}

const documentName = (path) => `${databaseRoot}/documents/${path}`;

async function commit(token, writes, expectedStatus = 200) {
  const response = await fetch(`${apiRoot}/documents:commit`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ writes }),
  });
  if (response.status !== expectedStatus) {
    const body = await response.text();
    throw new Error(
      `Commit retornou ${response.status}, esperado ${expectedStatus}: ${body}`,
    );
  }
  return response;
}

async function read(token, path) {
  return fetch(`${apiRoot}/documents/${path}`, {
    headers: { authorization: `Bearer ${token}` },
  });
}

async function adminRead(path) {
  return fetch(`${apiRoot}/documents/${path}`, {
    headers: { authorization: 'Bearer owner' },
  });
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const guardian = await createAuthUser('guardian');
const otherUser = await createAuthUser('other');
const guardianCpf = '52998224725';
const dependentCpf = '11144477735';
const guardianPath = `users/${guardian.uid}`;
const guardianFields = userFields({
  uid: guardian.uid,
  name: 'Responsável Teste',
  cpf: guardianCpf,
  role: 'responsible',
  roles: ['user'],
  authUid: guardian.uid,
  canAuthenticate: true,
});

await commit(guardian.token, [
  {
    update: {
      name: documentName(guardianPath),
      fields: guardianFields,
    },
    currentDocument: { exists: false },
  },
]);

const dependentId = 'dependent-valid';
const dependentPath = `users/${dependentId}`;
const cpfHash = createHash('sha256').update(dependentCpf).digest('hex');
const dependentFields = userFields({
  uid: dependentId,
  name: 'Alice Carvalho Libralon',
  cpf: dependentCpf,
  role: 'dependent',
  roles: ['dependent'],
  authUid: '',
  canAuthenticate: false,
  guardianIds: [guardian.uid],
  managedByUserIds: [guardian.uid],
  relationshipToGuardian: 'Filho(a)',
});
const guardianWithDependent = {
  ...guardianFields,
  dependentIds: strings([dependentId]),
  updatedAt: timestamp(),
};

await commit(guardian.token, [
  {
    update: { name: documentName(dependentPath), fields: dependentFields },
    currentDocument: { exists: false },
  },
  {
    update: {
      name: documentName(guardianPath),
      fields: guardianWithDependent,
    },
    currentDocument: { exists: true },
  },
  {
    update: {
      name: documentName(`cpf_registry/${cpfHash}`),
      fields: {
        ownerUid: string(dependentId),
        guardianUid: string(guardian.uid),
        createdAt: timestamp(),
      },
    },
    currentDocument: { exists: false },
  },
]);

assert((await read(guardian.token, dependentPath)).status === 200, 'Responsável não leu o dependente.');
assert((await read(otherUser.token, dependentPath)).status === 403, 'Outro usuário acessou o dependente.');
assert((await read(guardian.token, 'users')).status === 403, 'Listagem global de users foi permitida.');

const duplicateId = 'dependent-duplicate';
const duplicateFields = {
  ...dependentFields,
  uid: string(duplicateId),
  id: string(duplicateId),
};
const guardianWithDuplicate = {
  ...guardianWithDependent,
  dependentIds: strings([dependentId, duplicateId]),
};
const duplicateResponse = await fetch(`${apiRoot}/documents:commit`, {
  method: 'POST',
  headers: {
    authorization: `Bearer ${guardian.token}`,
    'content-type': 'application/json',
  },
  body: JSON.stringify({
    writes: [
      {
        update: {
          name: documentName(`users/${duplicateId}`),
          fields: duplicateFields,
        },
        currentDocument: { exists: false },
      },
      {
        update: {
          name: documentName(guardianPath),
          fields: guardianWithDuplicate,
        },
        currentDocument: { exists: true },
      },
      {
        update: {
          name: documentName(`cpf_registry/${cpfHash}`),
          fields: {
            ownerUid: string(duplicateId),
            guardianUid: string(guardian.uid),
            createdAt: timestamp(),
          },
        },
        currentDocument: { exists: false },
      },
    ],
  }),
});
assert(!duplicateResponse.ok, 'CPF duplicado foi aceito.');
assert(
  (await adminRead(`users/${duplicateId}`)).status === 404,
  'Dependente duplicado ficou órfão.',
);

const guardianAfter = await (await read(guardian.token, guardianPath)).json();
const linkedIds = guardianAfter.fields.dependentIds.arrayValue.values.map(
  (value) => value.stringValue,
);
assert(linkedIds.length === 1 && linkedIds[0] === dependentId, 'Rollback não preservou dependentIds.');

console.log('Firestore Rules: criação atômica, CPF duplicado, rollback e isolamento aprovados.');
