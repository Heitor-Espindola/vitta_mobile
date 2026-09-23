import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

const _projectId = 'vitta-5ec1e';
const _serviceId = 'vitta-5ec1e-service';
const _location = 'southamerica-east1';

const _collections = <String>[
  'users',
  'auth_links',
  'cpf_registry',
  'relationships',
  'access_grants',
  'vaccines',
  'vaccination_records',
  'vaccination_schedules',
  'children',
  'professional_patient_access',
  'information_posts',
  'news_articles',
];

Future<void> main(List<String> arguments) async {
  final root = File.fromUri(Platform.script).parent.parent;
  final outputPath = arguments.isEmpty
      ? '${root.path}${Platform.pathSeparator}docs${Platform.pathSeparator}migration${Platform.pathSeparator}firestore_sql_audit.json'
      : arguments.first;
  final token = await _firebaseCliToken(root.path);

  final firestore = <String, List<_Document>>{};
  for (final collection in _collections) {
    firestore[collection] = await _readCollection(
      accessToken: token,
      collection: collection,
    );
  }
  final privateDocuments = await _readCollection(
    accessToken: token,
    collection: 'private',
    allDescendants: true,
  );
  final emergencyContacts = privateDocuments
      .where((document) => document.id == 'emergency_contact')
      .toList(growable: false);

  final webRoot = [
    Directory(root.path).parent.path,
    'vitta_web',
    'Firebase_SQL_Connect',
  ].join(Platform.pathSeparator);
  final sqlPatients = await _executeDataConnect(
    root: root.path,
    webRoot: webRoot,
    operation: 'AuditPatients',
    field: 'patients',
  );
  final sqlApplications = await _executeDataConnect(
    root: root.path,
    webRoot: webRoot,
    operation: 'AuditApplications',
    field: 'applications',
  );
  final sqlVaccines = await _executeDataConnect(
    root: root.path,
    webRoot: webRoot,
    operation: 'AuditVaccines',
    field: 'vaccines',
  );

  final users = firestore['users']!;
  final records = firestore['vaccination_records']!;
  final vaccines = firestore['vaccines']!;
  final sqlPatientsByCpf = <String, Map<String, dynamic>>{
    for (final patient in sqlPatients)
      if (_digits(_nested(patient, ['user', 'cpf'])).isNotEmpty)
        _digits(_nested(patient, ['user', 'cpf'])): patient,
  };
  final firestoreUsersByCpf = <String, _Document>{
    for (final user in users)
      if (_digits(user.fields['cpfDigits'] ?? user.fields['cpf']).isNotEmpty)
        _digits(user.fields['cpfDigits'] ?? user.fields['cpf']): user,
  };

  final patientMatches = <String, int>{
    'matchedByCpf': 0,
    'firestoreOnly': 0,
    'sqlOnly': 0,
  };
  for (final cpf in firestoreUsersByCpf.keys) {
    if (sqlPatientsByCpf.containsKey(cpf)) {
      patientMatches['matchedByCpf'] = patientMatches['matchedByCpf']! + 1;
    } else {
      patientMatches['firestoreOnly'] = patientMatches['firestoreOnly']! + 1;
    }
  }
  patientMatches['sqlOnly'] = sqlPatientsByCpf.keys
      .where((cpf) => !firestoreUsersByCpf.containsKey(cpf))
      .length;

  final sqlVaccineNames = {
    for (final vaccine in sqlVaccines) _normalized(vaccine['name']),
  }..remove('');
  final firestoreVaccineNames = {
    for (final vaccine in vaccines) _normalized(vaccine.fields['name']),
  }..remove('');

  final sqlApplicationSignatures = {
    for (final application in sqlApplications)
      _sqlApplicationSignature(application),
  }..remove('');
  var vaccinationMatches = 0;
  var vaccinationUnmatched = 0;
  final ambiguousRecordHashes = <String>[];
  for (final record in records) {
    final signature = _firestoreApplicationSignature(record, users);
    if (signature.isNotEmpty && sqlApplicationSignatures.contains(signature)) {
      vaccinationMatches++;
    } else {
      vaccinationUnmatched++;
      if (ambiguousRecordHashes.length < 25) {
        ambiguousRecordHashes.add(_safeHash(record.path));
      }
    }
  }

  final report = <String, dynamic>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'mode': 'read-only',
    'projectId': _projectId,
    'sqlConnect': {
      'serviceId': _serviceId,
      'connectorId': 'example',
      'location': _location,
      'counts': {
        'patients': sqlPatients.length,
        'applications': sqlApplications.length,
        'vaccines': sqlVaccines.length,
      },
    },
    'firestore': {
      'counts': {
        for (final entry in firestore.entries) entry.key: entry.value.length,
        'users/*/private/emergency_contact': emergencyContacts.length,
      },
      'activeAfterMigration': ['news_articles'],
      'legacyBackupOnly': _collections
          .where((collection) => collection != 'news_articles')
          .toList(growable: false),
    },
    'matching': {
      'patients': {
        'key': 'normalized CPF (audit only; no CPF is emitted)',
        ...patientMatches,
      },
      'vaccines': {
        'key': 'normalized vaccine name',
        'matchedNames': firestoreVaccineNames
            .intersection(sqlVaccineNames)
            .length,
        'firestoreOnlyNames': firestoreVaccineNames
            .difference(sqlVaccineNames)
            .length,
        'sqlOnlyNames': sqlVaccineNames
            .difference(firestoreVaccineNames)
            .length,
      },
      'vaccinationRecords': {
        'key': 'patient CPF + vaccine name + application date + dose + batch',
        'heuristicMatches': vaccinationMatches,
        'unmatched': vaccinationUnmatched,
        'unmatchedRecordHashes': ambiguousRecordHashes,
        'warning':
            'A durable legacyRecordId is required before applying migration.',
      },
    },
    'destinations': {
      'users': 'User + Patient',
      'auth_links': 'User.authUid (schema extension required)',
      'cpf_registry':
          'User.cpf unique constraint; exact lookup must be server-restricted',
      'relationships': 'FamilyRelationship (new table required)',
      'access_grants': 'PatientAccess (new table required)',
      'vaccines': 'Vaccine',
      'vaccination_records': 'Application',
      'users/*/private/emergency_contact':
          'EmergencyContact (new table required)',
      'news_articles': 'Firestore/news_articles (unchanged)',
    },
    'conflicts': {
      'schemaMissingAuthUid': true,
      'schemaMissingFamilyAccess': true,
      'schemaMissingEmergencyContact': true,
      'schemaMissingApplicationLegacyId': true,
      'schemaMissingNextDoseAt': true,
      'existingConnectorUsesAuthLevelOnly': true,
    },
  };

  final output = File(outputPath);
  await output.parent.create(recursive: true);
  await output.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
    flush: true,
  );
  stdout.writeln('Auditoria somente leitura concluída: ${output.path}');
  stdout.writeln(
    'Firestore users=${users.length}, relationships=${firestore['relationships']!.length}, vaccination_records=${records.length}.',
  );
  stdout.writeln(
    'SQL patients=${sqlPatients.length}, applications=${sqlApplications.length}, vaccines=${sqlVaccines.length}.',
  );
}

Future<String> _firebaseCliToken(String root) async {
  final helper =
      '$root${Platform.pathSeparator}tool${Platform.pathSeparator}firebase_cli_access_token.mjs';
  final result = await Process.run('node', [helper], runInShell: true);
  final token = '${result.stdout}'.trim();
  if (result.exitCode != 0 || token.isEmpty) {
    throw StateError('Não foi possível obter a credencial do Firebase CLI.');
  }
  return token;
}

Future<List<_Document>> _readCollection({
  required String accessToken,
  required String collection,
  bool allDescendants = false,
}) async {
  final response = await http.post(
    Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents:runQuery',
    ),
    headers: {
      'authorization': 'Bearer $accessToken',
      'content-type': 'application/json',
    },
    body: jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': collection, 'allDescendants': allDescendants},
        ],
      },
    }),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Falha ao auditar $collection (${response.statusCode}).',
    );
  }
  final decoded = jsonDecode(response.body);
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .where((entry) => entry['document'] is Map)
      .map((entry) {
        final document = Map<String, dynamic>.from(entry['document'] as Map);
        final path = document['name'] as String? ?? '';
        final rawFields = document['fields'] as Map? ?? const {};
        return _Document(
          path: path,
          id: path.split('/').last,
          fields: rawFields.map(
            (key, value) => MapEntry('$key', _firestoreValue(value)),
          ),
        );
      })
      .toList(growable: false);
}

Future<List<Map<String, dynamic>>> _executeDataConnect({
  required String root,
  required String webRoot,
  required String operation,
  required String field,
}) async {
  final queryFile = [
    root,
    'tool',
    'dataconnect_migration_audit.gql',
  ].join(Platform.pathSeparator);
  final firebaseArguments = [
    'dataconnect:execute',
    queryFile,
    operation,
    '--project',
    _projectId,
    '--service',
    _serviceId,
    '--location',
    _location,
    '--json',
  ];
  final executable = Platform.isWindows ? 'cmd.exe' : 'firebase';
  final processArguments = Platform.isWindows
      ? ['/d', '/s', '/c', 'firebase ${firebaseArguments.join(' ')}']
      : firebaseArguments;
  final result = await Process.run(
    executable,
    processArguments,
    workingDirectory: webRoot,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    final diagnostic = '${result.stderr}'.trim();
    final response = '${result.stdout}'.trim();
    throw StateError(
      'Falha ao executar $operation no SQL Connect '
      '(cwd=$webRoot, exit=${result.exitCode}) '
      '${diagnostic.isEmpty ? '' : diagnostic} '
      '${response.isEmpty ? '' : response.substring(0, response.length > 800 ? 800 : response.length)}',
    );
  }
  final decoded = jsonDecode('${result.stdout}');
  final data = decoded is Map ? decoded['result'] : null;
  final operationData = data is Map ? data['data'] : null;
  final rows = operationData is Map ? operationData[field] : null;
  return rows is List
      ? rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false)
      : const [];
}

Object? _firestoreValue(Object? raw) {
  if (raw is! Map) return raw;
  final value = Map<String, dynamic>.from(raw);
  if (value.containsKey('nullValue')) {
    return null;
  }
  if (value.containsKey('stringValue')) return value['stringValue'];
  if (value.containsKey('booleanValue')) return value['booleanValue'];
  if (value.containsKey('integerValue')) {
    return int.tryParse('${value['integerValue']}');
  }
  if (value.containsKey('doubleValue')) return value['doubleValue'];
  if (value.containsKey('timestampValue')) return value['timestampValue'];
  if (value.containsKey('referenceValue')) return value['referenceValue'];
  final array = value['arrayValue'];
  if (array is Map) {
    final values = array['values'];
    return values is List
        ? values.map(_firestoreValue).toList(growable: false)
        : const [];
  }
  final map = value['mapValue'];
  if (map is Map && map['fields'] is Map) {
    return (map['fields'] as Map).map(
      (key, item) => MapEntry('$key', _firestoreValue(item)),
    );
  }
  return null;
}

String _sqlApplicationSignature(Map<String, dynamic> application) {
  final cpf = _digits(_nested(application, ['patient', 'user', 'cpf']));
  final vaccine = _normalized(_nested(application, ['vaccine', 'name']));
  final date = _dateOnly(application['applicationDate']);
  final dose = '${application['doseNumber'] ?? ''}';
  final batch = _normalized(_nested(application, ['batch', 'batchCode']));
  if (cpf.isEmpty || vaccine.isEmpty || date.isEmpty) return '';
  return '$cpf|$vaccine|$date|$dose|$batch';
}

String _firestoreApplicationSignature(_Document record, List<_Document> users) {
  final personId =
      '${record.fields['patientId'] ?? record.fields['patientUid'] ?? record.fields['personId'] ?? record.fields['childId'] ?? ''}';
  final user = users.where((candidate) => candidate.id == personId).firstOrNull;
  final cpf = _digits(user?.fields['cpfDigits'] ?? user?.fields['cpf']);
  final vaccine = _normalized(record.fields['vaccineName']);
  final date = _dateOnly(
    record.fields['appliedAt'] ?? record.fields['applicationDate'],
  );
  final dose = '${record.fields['doseNumber'] ?? ''}';
  final batch = _normalized(
    record.fields['lot'] ??
        record.fields['batchNumber'] ??
        record.fields['lotNumber'],
  );
  if (cpf.isEmpty || vaccine.isEmpty || date.isEmpty) return '';
  return '$cpf|$vaccine|$date|$dose|$batch';
}

Object? _nested(Map<String, dynamic> value, List<String> path) {
  Object? current = value;
  for (final segment in path) {
    if (current is! Map) return null;
    current = current[segment];
  }
  return current;
}

String _digits(Object? value) => '${value ?? ''}'.replaceAll(RegExp(r'\D'), '');

String _normalized(Object? value) =>
    '${value ?? ''}'.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _dateOnly(Object? value) {
  final text = '${value ?? ''}'.trim();
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}

String _safeHash(String value) =>
    sha256.convert(utf8.encode(value)).toString().substring(0, 16);

class _Document {
  const _Document({required this.path, required this.id, required this.fields});

  final String path;
  final String id;
  final Map<String, dynamic> fields;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
