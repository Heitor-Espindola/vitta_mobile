import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vitta_mobile/features/information/data/news_api_service.dart';
import 'package:vitta_mobile/features/information/data/news_sync_service.dart';
import 'package:vitta_mobile/features/information/data/newsdata_api_service.dart';
import 'package:vitta_mobile/features/information/domain/models/news_article.dart';
import 'package:vitta_mobile/features/information/domain/services/news_article_identity.dart';

const _expectedProject = 'vitta-5ec1e';

Future<void> main(List<String> arguments) async {
  final projectId =
      Platform.environment['VITTA_FIREBASE_PROJECT_ID'] ?? _expectedProject;
  if (projectId != _expectedProject) {
    throw StateError('Sincronização bloqueada para projeto inesperado.');
  }
  final root = File.fromUri(Platform.script).parent.parent;
  final newsApiKey = _readSecret(
    root,
    environmentName: 'NEWS_API_KEY',
    fileName: 'news_api.json',
  );
  final newsDataApiKey = _readSecret(
    root,
    environmentName: 'NEWS_DATA_API_KEY',
    fileName: 'news_data.json',
  );
  if (newsApiKey.isEmpty || newsDataApiKey.isEmpty) {
    throw StateError(
      'Configure NEWS_API_KEY e NEWS_DATA_API_KEY no ambiente ou em config local ignorado pelo Git.',
    );
  }

  final token = await _firebaseAccessToken(root);
  final store = FirestoreRestNewsStore(
    projectId: projectId,
    accessToken: token,
  );
  final service = NewsSyncService(
    providers: [
      NewsApiService(apiKey: newsApiKey),
      NewsDataApiService(apiKey: newsDataApiKey),
    ],
    store: store,
  );
  try {
    final report = await service.synchronize(maxPagesPerProvider: 3);
    stdout.writeln(jsonEncode(report.toJson()));
  } on NewsSyncException catch (error) {
    stderr.writeln(jsonEncode(error.report.toJson()));
    exitCode = 1;
  } finally {
    service.dispose();
    store.dispose();
  }
}

String _readSecret(
  Directory root, {
  required String environmentName,
  required String fileName,
}) {
  final environmentValue = Platform.environment[environmentName]?.trim();
  if (environmentValue?.isNotEmpty == true) return environmentValue!;
  final file = File(
    '${root.path}${Platform.pathSeparator}config${Platform.pathSeparator}$fileName',
  );
  if (!file.existsSync()) return '';
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) return '';
  return (decoded[environmentName] as String?)?.trim() ?? '';
}

Future<String> _firebaseAccessToken(Directory root) async {
  final environmentToken = Platform.environment['GOOGLE_OAUTH_ACCESS_TOKEN']
      ?.trim();
  if (environmentToken?.isNotEmpty == true) return environmentToken!;
  final helper =
      '${root.path}${Platform.pathSeparator}tool${Platform.pathSeparator}firebase_cli_access_token.mjs';
  final result = await Process.run('node', [helper], runInShell: true);
  if (result.exitCode != 0) {
    throw StateError(
      'Não foi possível reutilizar a autenticação do Firebase CLI. Execute firebase login.',
    );
  }
  final token = '${result.stdout}'.trim();
  if (token.isEmpty) {
    throw StateError('Firebase CLI retornou credencial vazia.');
  }
  return token;
}

class FirestoreRestNewsStore implements NewsArticleStore {
  FirestoreRestNewsStore({
    required this.projectId,
    required this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String projectId;
  final String accessToken;
  final http.Client _client;
  final bool _ownsClient;

  String get _documentsRoot =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Map<String, String> get _headers => {
    'authorization': 'Bearer $accessToken',
    'content-type': 'application/json',
  };

  @override
  Future<int> upsertAll(List<NewsArticle> articles) async {
    if (articles.isEmpty) return 0;
    final existing = await _loadExisting();
    final byId = {for (final item in existing) item.id: item};
    final idByDedupe = {
      for (final item in existing)
        if (item.dedupeKey.isNotEmpty) item.dedupeKey: item.id,
    };
    var persisted = 0;
    for (final article in articles) {
      final incomingId = article.id!;
      final dedupeKey = NewsArticleIdentity.dedupeKey(
        article.title,
        article.sourceDomain ?? NewsArticleIdentity.sourceDomain(article.url),
      );
      final targetId = idByDedupe[dedupeKey] ?? incomingId;
      final previous = byId[targetId];
      await _write(targetId, article, dedupeKey, previous);
      persisted++;
    }
    return persisted;
  }

  Future<List<_ExistingArticle>> _loadExisting() async {
    final cutoff = DateTime.now().toUtc().subtract(NewsSyncService.retention);
    final response = await _client.post(
      Uri.parse('$_documentsRoot:runQuery'),
      headers: _headers,
      body: jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': 'news_articles'},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'publishedAt'},
              'op': 'GREATER_THAN_OR_EQUAL',
              'value': {'timestampValue': cutoff.toIso8601String()},
            },
          },
          'orderBy': [
            {
              'field': {'fieldPath': 'publishedAt'},
              'direction': 'DESCENDING',
            },
          ],
          'limit': 500,
        },
      }),
    );
    _ensureSuccess(response, 'consultar notícias existentes');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    final values = <_ExistingArticle>[];
    for (final row in decoded.whereType<Map<String, dynamic>>()) {
      final document = row['document'];
      if (document is! Map<String, dynamic>) continue;
      final name = document['name'] as String?;
      final fields = document['fields'];
      if (name == null || fields is! Map<String, dynamic>) continue;
      values.add(
        _ExistingArticle(
          id: name.split('/').last,
          dedupeKey: _firestoreString(fields['dedupeKey']),
          createdAt: _firestoreTimestamp(fields['createdAt']),
          publishedAt: _firestoreTimestamp(fields['publishedAt']),
          expiresAt: _firestoreTimestamp(fields['expiresAt']),
          providers: _firestoreStrings(fields['providers']),
        ),
      );
    }
    return values;
  }

  Future<void> _write(
    String documentId,
    NewsArticle article,
    String dedupeKey,
    _ExistingArticle? previous,
  ) async {
    final now = DateTime.now().toUtc();
    final publishedAt = previous?.publishedAt ?? article.publishedAt!.toUtc();
    final expiresAt =
        previous?.expiresAt ??
        article.expiresAt ??
        publishedAt.add(NewsSyncService.retention);
    final providers = <String>{
      ...?previous?.providers,
      ...article.effectiveProviders,
    }.toList()..sort();
    final fields = <String, dynamic>{
      'id': _stringValue(documentId),
      'title': _stringValue(article.title),
      'description': _nullableStringValue(article.description),
      'url': _stringValue(article.url),
      'imageUrl': _nullableStringValue(article.imageUrl),
      'sourceName': _stringValue(article.sourceName),
      'sourceDomain': _stringValue(article.sourceDomain ?? ''),
      'publishedAt': _timestampValue(publishedAt),
      'fetchedAt': _timestampValue(now),
      'expiresAt': _timestampValue(expiresAt),
      'provider': _stringValue(article.provider),
      'providers': _stringsValue(providers),
      'language': _stringValue(article.language),
      'country': _stringValue(article.country),
      'dedupeKey': _stringValue(dedupeKey),
      'createdAt': _timestampValue(previous?.createdAt ?? now),
      'updatedAt': _timestampValue(now),
    };
    final response = await _client.patch(
      Uri.parse('$_documentsRoot/news_articles/$documentId'),
      headers: _headers,
      body: jsonEncode({'fields': fields}),
    );
    _ensureSuccess(response, 'persistir notícia');
  }

  static void _ensureSuccess(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw HttpException(
      'Falha ao $action no Firestore (${response.statusCode}).',
    );
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

class _ExistingArticle {
  const _ExistingArticle({
    required this.id,
    required this.dedupeKey,
    required this.providers,
    this.createdAt,
    this.publishedAt,
    this.expiresAt,
  });

  final String id;
  final String dedupeKey;
  final List<String> providers;
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
}

Map<String, dynamic> _stringValue(String value) => {'stringValue': value};
Map<String, dynamic> _nullableStringValue(String? value) =>
    value == null ? {'nullValue': null} : _stringValue(value);
Map<String, dynamic> _timestampValue(DateTime value) => {
  'timestampValue': value.toUtc().toIso8601String(),
};
Map<String, dynamic> _stringsValue(List<String> values) => {
  'arrayValue': {'values': values.map(_stringValue).toList(growable: false)},
};

String _firestoreString(Object? value) {
  if (value is! Map<String, dynamic>) return '';
  return value['stringValue'] as String? ?? '';
}

DateTime? _firestoreTimestamp(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  return DateTime.tryParse(value['timestampValue'] as String? ?? '');
}

List<String> _firestoreStrings(Object? value) {
  if (value is! Map<String, dynamic>) return const [];
  final array = value['arrayValue'];
  if (array is! Map<String, dynamic>) return const [];
  final values = array['values'];
  if (values is! List) return const [];
  return values.map(_firestoreString).where((item) => item.isNotEmpty).toList();
}
