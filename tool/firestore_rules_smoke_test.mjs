import { createHash } from 'node:crypto';

const projectId = process.env.GCLOUD_PROJECT || 'vitta-5ec1e';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const firestoreHost =
  process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const databaseRoot = `projects/${projectId}/databases/(default)`;
const apiRoot = `http://${firestoreHost}/v1/${databaseRoot}`;

const timestamp = () => ({ timestampValue: new Date().toISOString() });
const dateTimestamp = (value) => ({ timestampValue: value });
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
    personId: string(uid),
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
    birthDate: dateTimestamp('2000-01-01T00:00:00.000Z'),
    majorityAt: dateTimestamp('2018-01-01T00:00:00.000Z'),
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

async function queryVaccinationRecords(token, patientId, field = 'patientId') {
  return fetch(`${apiRoot}/documents:runQuery`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'vaccination_records' }],
        where: {
          fieldFilter: {
            field: { fieldPath: field },
            op: 'EQUAL',
            value: string(patientId),
          },
        },
        orderBy: [
          { field: { fieldPath: 'appliedAt' }, direction: 'DESCENDING' },
        ],
      },
    }),
  });
}

async function queryProfessionalRecords(token, professionalUid) {
  return fetch(`${apiRoot}/documents:runQuery`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'vaccination_records' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'professionalUid' },
            op: 'EQUAL',
            value: string(professionalUid),
          },
        },
        orderBy: [
          { field: { fieldPath: 'appliedAt' }, direction: 'DESCENDING' },
        ],
        limit: 100,
      },
    }),
  });
}

async function adminRead(path) {
  return fetch(`${apiRoot}/documents/${path}`, {
    headers: { authorization: 'Bearer owner' },
  });
}

async function adminCommit(writes) {
  return commit('owner', writes);
}

function userCreateWrite(uid, fields) {
  return {
    update: { name: documentName(`users/${uid}`), fields },
    currentDocument: { exists: false },
  };
}

function authLinkCreateWrite(authUid, personId = authUid) {
  return {
    update: {
      name: documentName(`auth_links/${authUid}`),
      fields: { personId: string(personId) },
    },
    updateTransforms: [
      { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
    ],
    currentDocument: { exists: false },
  };
}

function cpfRegistryCreateWrite(cpf, ownerUid) {
  const cpfHash = createHash('sha256').update(cpf).digest('hex');
  return {
    update: {
      name: documentName(`cpf_registry/${cpfHash}`),
      fields: {
        ownerUid: string(ownerUid),
        createdAt: timestamp(),
      },
    },
    currentDocument: { exists: false },
  };
}

function lastLoginUpdateWrite(uid) {
  return {
    update: {
      name: documentName(`users/${uid}`),
      fields: {
        lastLoginAt: timestamp(),
        updatedAt: timestamp(),
      },
    },
    updateMask: { fieldPaths: ['lastLoginAt', 'updatedAt'] },
    currentDocument: { exists: true },
  };
}

async function registerAccount(account, fields, cpf) {
  await commit(account.token, [
    userCreateWrite(account.uid, fields),
    cpfRegistryCreateWrite(cpf, account.uid),
    authLinkCreateWrite(account.uid),
  ]);
}

function vaccinationCreateWrite(
  recordId,
  { patientId, professionalUid, source = 'professional_panel' },
) {
  return {
    update: {
      name: documentName(`vaccination_records/${recordId}`),
      fields: {
        patientId: string(patientId),
        vaccineId: string('bcg'),
        vaccineName: string('BCG'),
        doseLabel: string('Dose única'),
        appliedAt: timestamp(),
        professionalUid: string(professionalUid),
        source: string(source),
      },
    },
    updateTransforms: [
      { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
      { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
    ],
    currentDocument: { exists: false },
  };
}

function legacyVaccinationCreateWrite(recordId, patientUid) {
  return {
    update: {
      name: documentName(`vaccination_records/${recordId}`),
      fields: {
        patientUid: string(patientUid),
        vaccineName: string('Vacina legada'),
        dose: string('Dose única'),
        appliedAt: timestamp(),
        createdAt: timestamp(),
      },
    },
    currentDocument: { exists: false },
  };
}

function relationshipCreateWrite(
  fromPersonId,
  toPersonId,
  {
    status = 'pending',
    type = 'legal_guardian',
    viewVaccination = false,
    receiveNotifications = false,
    consentStatus = 'pending',
    verificationSource = 'manual_pending',
    verifiedAt = null,
  } = {},
) {
  return {
    update: {
      name: documentName(
        `relationships/${fromPersonId}_${toPersonId}`,
      ),
      fields: {
        fromPersonId: string(fromPersonId),
        toPersonId: string(toPersonId),
        type: string(type),
        status: string(status),
        permissions: {
          mapValue: {
            fields: {
              viewVaccination: boolean(viewVaccination),
              receiveNotifications: boolean(receiveNotifications),
            },
          },
        },
        consentStatus: string(consentStatus),
        verificationSource: string(verificationSource),
        verifiedAt: verifiedAt == null ? { nullValue: null } : timestamp(),
        validUntil: { nullValue: null },
      },
    },
    updateTransforms: [
      { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
      { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
    ],
    currentDocument: { exists: false },
  };
}

function accessGrantCreateWrite(granteePersonId, subjectPersonId) {
  return {
    update: {
      name: documentName(
        `access_grants/${granteePersonId}_${subjectPersonId}`,
      ),
      fields: {
        granteePersonId: string(granteePersonId),
        subjectPersonId: string(subjectPersonId),
        viewVaccination: boolean(true),
        consentStatus: string('granted'),
        validUntil: { nullValue: null },
        createdAt: timestamp(),
        updatedAt: timestamp(),
      },
    },
    currentDocument: { exists: false },
  };
}

function professionalPatientAccessCreateWrite({
  professionalUid,
  patientId,
  cpf,
  expiresInMinutes = 20,
  exists = false,
}) {
  const cpfHash = createHash('sha256').update(cpf).digest('hex');
  return {
    update: {
      name: documentName(
        `professional_patient_access/${professionalUid}_${patientId}`,
      ),
      fields: {
        professionalUid: string(professionalUid),
        patientId: string(patientId),
        cpfHash: string(cpfHash),
        expiresAt: dateTimestamp(
          new Date(Date.now() + expiresInMinutes * 60 * 1000).toISOString(),
        ),
      },
    },
    updateTransforms: [
      { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
      { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
    ],
    currentDocument: { exists },
  };
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

await registerAccount(guardian, guardianFields, guardianCpf);

const ownAuthLinkResponse = await read(
  guardian.token,
  `auth_links/${guardian.uid}`,
);
assert(
  ownAuthLinkResponse.status === 200,
  'Cadastro novo não criou ou não leu o próprio auth_link.',
);
const ownAuthLink = await ownAuthLinkResponse.json();
assert(
  ownAuthLink.fields.personId.stringValue === guardian.uid,
  'auth_link não aponta para o personId correto.',
);
assert(
  (await read(guardian.token, guardianPath)).status === 200,
  'Login novo com auth_link não leu users/{personId}.',
);
const guardianCpfHash = createHash('sha256').update(guardianCpf).digest('hex');
assert(
  (await read(guardian.token, `cpf_registry/${guardianCpfHash}`)).status === 200,
  'Cadastro novo não criou cpf_registry.',
);

const legacyUser = await createAuthUser('legacy');
const legacyFields = userFields({
  uid: legacyUser.uid,
  name: 'Usuário Legado',
  cpf: '16899535009',
  role: 'responsible',
  roles: ['user'],
  authUid: legacyUser.uid,
  canAuthenticate: true,
});
delete legacyFields.personId;
delete legacyFields.majorityAt;
await adminCommit([userCreateWrite(legacyUser.uid, legacyFields)]);
assert(
  (await read(legacyUser.token, `auth_links/${legacyUser.uid}`)).status === 404,
  'Conta legada recebeu auth_link inesperado.',
);
assert(
  (await read(legacyUser.token, `users/${legacyUser.uid}`)).status === 200,
  'Login legado sem auth_link não conseguiu usar auth.uid.',
);
await commit(legacyUser.token, [lastLoginUpdateWrite(legacyUser.uid)]);

const attacker = await createAuthUser('auth-link-attacker');
assert(
  (await read(attacker.token, `auth_links/${guardian.uid}`)).status === 403,
  'Usuário leu auth_link de outra pessoa.',
);
assert(
  (await read(guardian.token, 'auth_links')).status === 403,
  'Listagem de auth_links foi permitida.',
);
await commit(
  attacker.token,
  [authLinkCreateWrite(attacker.uid, guardian.uid)],
  403,
);
await commit(
  attacker.token,
  [authLinkCreateWrite(guardian.uid, guardian.uid)],
  403,
);
await commit(
  guardian.token,
  [
    {
      update: {
        name: documentName(`auth_links/${guardian.uid}`),
        fields: { personId: string(guardian.uid) },
      },
      updateMask: { fieldPaths: ['personId'] },
      currentDocument: { exists: true },
    },
  ],
  403,
);
await commit(
  guardian.token,
  [{ delete: documentName(`auth_links/${guardian.uid}`) }],
  403,
);

await commit(
  guardian.token,
  [
    {
      update: {
        name: documentName(guardianPath),
        fields: {
          majorityAt: dateTimestamp('2030-01-01T00:00:00.000Z'),
        },
      },
      updateMask: { fieldPaths: ['majorityAt'] },
      currentDocument: { exists: true },
    },
  ],
  403,
);

const rollbackAccount = await createAuthUser('registration-rollback');
const rollbackFields = userFields({
  uid: rollbackAccount.uid,
  name: 'Cadastro Rollback',
  cpf: '39053344705',
  role: 'responsible',
  roles: ['user'],
  authUid: rollbackAccount.uid,
  canAuthenticate: true,
});
const rollbackResponse = await fetch(`${apiRoot}/documents:commit`, {
  method: 'POST',
  headers: {
    authorization: `Bearer ${rollbackAccount.token}`,
    'content-type': 'application/json',
  },
  body: JSON.stringify({
    writes: [
      userCreateWrite(rollbackAccount.uid, rollbackFields),
      cpfRegistryCreateWrite(guardianCpf, rollbackAccount.uid),
      authLinkCreateWrite(rollbackAccount.uid),
    ],
  }),
});
assert(!rollbackResponse.ok, 'Commit inválido do cadastro foi aceito.');
assert(
  (await adminRead(`users/${rollbackAccount.uid}`)).status === 404 &&
    (await adminRead(`auth_links/${rollbackAccount.uid}`)).status === 404,
  'Rollback Firestore deixou users ou auth_links parcial.',
);

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

await commit(guardian.token, [lastLoginUpdateWrite(guardian.uid)]);

await registerAccount(
  otherUser,
  userFields({
    uid: otherUser.uid,
    name: 'Usuário Comum',
    cpf: '12345678909',
    role: 'responsible',
    roles: ['user'],
    authUid: otherUser.uid,
    canAuthenticate: true,
  }),
  '12345678909',
);

const professional = await createAuthUser('professional');
const blockedProfessional = await createAuthUser('professional-blocked');
const professionalFields = userFields({
  uid: professional.uid,
  name: 'Profissional Ativo',
  cpf: '39053344705',
  role: 'health_professional',
  roles: ['health_professional'],
  authUid: professional.uid,
  canAuthenticate: true,
});
const blockedProfessionalFields = {
  ...userFields({
    uid: blockedProfessional.uid,
    name: 'Profissional Bloqueado',
    cpf: '98765432100',
    role: 'health_professional',
    roles: ['health_professional'],
    authUid: blockedProfessional.uid,
    canAuthenticate: true,
  }),
  accountStatus: string('blocked'),
};
await adminCommit([
  {
    update: {
      name: documentName(`users/${professional.uid}`),
      fields: professionalFields,
    },
    currentDocument: { exists: false },
  },
  {
    update: {
      name: documentName(`users/${blockedProfessional.uid}`),
      fields: blockedProfessionalFields,
    },
    currentDocument: { exists: false },
  },
]);

const recordId = 'vaccination-valid';
await commit(professional.token, [
  vaccinationCreateWrite(recordId, {
    patientId: guardian.uid,
    professionalUid: professional.uid,
  }),
]);
assert(
  (await read(guardian.token, `vaccination_records/${recordId}`)).status === 200,
  'A) Paciente não leu o próprio registro.',
);
assert(
  (await queryVaccinationRecords(guardian.token, guardian.uid)).status === 200,
  'A) Consulta patientId + appliedAt do mobile foi negada.',
);
assert(
  (await read(otherUser.token, `vaccination_records/${recordId}`)).status === 403,
  'B) Paciente leu registro de outra pessoa.',
);

const legacyRecordId = 'vaccination-legacy';
await adminCommit([
  legacyVaccinationCreateWrite(legacyRecordId, guardian.uid),
]);
assert(
  (await read(guardian.token, `vaccination_records/${legacyRecordId}`)).status ===
    200,
  'Compatibilidade patientUid: titular não leu o próprio registro legado.',
);
assert(
  (
    await queryVaccinationRecords(
      guardian.token,
      guardian.uid,
      'patientUid',
    )
  ).status === 200,
  'Compatibilidade patientUid + appliedAt foi negada.',
);
assert(
  (await read(otherUser.token, `vaccination_records/${legacyRecordId}`)).status ===
    403,
  'Compatibilidade patientUid permitiu leitura por terceiro.',
);
await commit(
  guardian.token,
  [vaccinationCreateWrite('vaccination-by-patient', {
    patientId: guardian.uid,
    professionalUid: guardian.uid,
  })],
  403,
);
await commit(
  otherUser.token,
  [vaccinationCreateWrite('vaccination-by-common-user', {
    patientId: guardian.uid,
    professionalUid: otherUser.uid,
  })],
  403,
);
await commit(
  professional.token,
  [vaccinationCreateWrite('vaccination-wrong-professional', {
    patientId: guardian.uid,
    professionalUid: blockedProfessional.uid,
  })],
  403,
);
await commit(
  professional.token,
  [vaccinationCreateWrite('vaccination-missing-patient', {
    patientId: 'missing-patient',
    professionalUid: professional.uid,
  })],
  403,
);
await commit(
  professional.token,
  [{
    update: {
      name: documentName(`vaccination_records/${recordId}`),
      fields: { notes: string('tentativa de edição') },
    },
    updateMask: { fieldPaths: ['notes'] },
    currentDocument: { exists: true },
  }],
  403,
);
await commit(
  professional.token,
  [{ delete: documentName(`vaccination_records/${recordId}`) }],
  403,
);
await commit(
  blockedProfessional.token,
  [vaccinationCreateWrite('vaccination-blocked-professional', {
    patientId: guardian.uid,
    professionalUid: blockedProfessional.uid,
  })],
  403,
);
assert(
  (await read(professional.token, `vaccination_records/${recordId}`)).status === 200,
  'Profissional não leu a aplicação registrada pelo próprio UID.',
);
assert(
  (await queryProfessionalRecords(professional.token, professional.uid)).status ===
    200,
  'Profissional não consultou os próprios registros auditados.',
);
assert(
  (await read(professional.token, 'users')).status === 403,
  'I) Profissional conseguiu listar users.',
);
assert(
  (await read(professional.token, 'cpf_registry')).status === 403,
  'J) Profissional conseguiu listar cpf_registry.',
);
assert(
  (await read(professional.token, guardianPath)).status === 403,
  'Profissional leu paciente antes do lookup exato.',
);
assert(
  (await read(professional.token, `cpf_registry/${guardianCpfHash}`)).status ===
    200,
  'H) Profissional não conseguiu o lookup exato permitido.',
);

await commit(
  otherUser.token,
  [professionalPatientAccessCreateWrite({
    professionalUid: otherUser.uid,
    patientId: guardian.uid,
    cpf: guardianCpf,
  })],
  403,
);
assert(
  (await read(otherUser.token, guardianPath)).status === 403,
  'K) Usuário comum utilizou o lookup profissional.',
);
await commit(
  blockedProfessional.token,
  [professionalPatientAccessCreateWrite({
    professionalUid: blockedProfessional.uid,
    patientId: guardian.uid,
    cpf: guardianCpf,
  })],
  403,
);
await commit(
  professional.token,
  [professionalPatientAccessCreateWrite({
    professionalUid: professional.uid,
    patientId: guardian.uid,
    cpf: '12345678909',
  })],
  403,
);
await commit(
  professional.token,
  [professionalPatientAccessCreateWrite({
    professionalUid: professional.uid,
    patientId: guardian.uid,
    cpf: guardianCpf,
    expiresInMinutes: 31,
  })],
  403,
);
await commit(professional.token, [
  professionalPatientAccessCreateWrite({
    professionalUid: professional.uid,
    patientId: guardian.uid,
    cpf: guardianCpf,
  }),
]);
await commit(professional.token, [
  professionalPatientAccessCreateWrite({
    professionalUid: professional.uid,
    patientId: guardian.uid,
    cpf: guardianCpf,
    exists: true,
  }),
]);
assert(
  (await read(professional.token, guardianPath)).status === 200,
  'H) Lookup exato não liberou o GET específico do paciente.',
);
assert(
  (await queryVaccinationRecords(professional.token, guardian.uid)).status ===
    200,
  'H) Atendimento validado não liberou o histórico do paciente.',
);

await commit(guardian.token, [
  relationshipCreateWrite(guardian.uid, dependentId),
]);
await commit(professional.token, [
  vaccinationCreateWrite('vaccination-pending-dependent', {
    patientId: dependentId,
    professionalUid: professional.uid,
  }),
]);
assert(
  (
    await read(
      guardian.token,
      'vaccination_records/vaccination-pending-dependent',
    )
  ).status === 403,
  'Relationship pending concedeu acesso à vacinação.',
);

const minorId = 'minor-for-relationship-test';
const minorFields = {
  ...userFields({
    uid: minorId,
    name: 'Pessoa Menor Teste',
    cpf: '29537947000',
    role: 'dependent',
    roles: ['dependent'],
    authUid: '',
    canAuthenticate: false,
    guardianIds: [otherUser.uid],
    managedByUserIds: [otherUser.uid],
    relationshipToGuardian: 'Filho(a)',
  }),
  birthDate: dateTimestamp('2015-01-01T00:00:00.000Z'),
  majorityAt: dateTimestamp('2033-01-01T00:00:00.000Z'),
};
await adminCommit([userCreateWrite(minorId, minorFields)]);

await commit(
  guardian.token,
  [
    relationshipCreateWrite(guardian.uid, minorId, {
      status: 'verified',
      viewVaccination: true,
      receiveNotifications: true,
      consentStatus: 'not_required_minor',
      verificationSource: 'self_declared',
      verifiedAt: true,
    }),
  ],
  403,
);

await adminCommit([
  relationshipCreateWrite(guardian.uid, otherUser.uid, {
    status: 'verified',
    viewVaccination: true,
    consentStatus: 'granted',
    verificationSource: 'admin_test',
    verifiedAt: true,
  }),
  relationshipCreateWrite(otherUser.uid, minorId, {
    status: 'verified',
    viewVaccination: true,
    receiveNotifications: true,
    consentStatus: 'not_required_minor',
    verificationSource: 'admin_test',
    verifiedAt: true,
  }),
]);
await commit(professional.token, [
  vaccinationCreateWrite('vaccination-minor-direct-only', {
    patientId: minorId,
    professionalUid: professional.uid,
  }),
]);
assert(
  (
    await read(
      otherUser.token,
      'vaccination_records/vaccination-minor-direct-only',
    )
  ).status === 200,
  'Relationship direta verificada de menor não concedeu a leitura esperada.',
);
assert(
  (
    await read(
      guardian.token,
      'vaccination_records/vaccination-minor-direct-only',
    )
  ).status === 403,
  'O) Relationship transitiva concedeu acesso indevido.',
);

await commit(
  guardian.token,
  [accessGrantCreateWrite(guardian.uid, minorId)],
  403,
);

console.log(
  'Firestore Rules: cenários A-P, lookup profissional temporário, patientUid legado, vínculo pendente, relação direta e bloqueio transitivo aprovados.',
);
