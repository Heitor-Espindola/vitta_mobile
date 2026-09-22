import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _projectId = 'vitta-5ec1e';

Future<void> main() async {
  final root = File.fromUri(Platform.script).parent.parent;
  final helper =
      '${root.path}${Platform.pathSeparator}tool${Platform.pathSeparator}firebase_cli_access_token.mjs';
  final tokenResult = await Process.run('node', [helper], runInShell: true);
  if (tokenResult.exitCode != 0 || '${tokenResult.stdout}'.trim().isEmpty) {
    throw StateError(
      'Não foi possível reutilizar a autenticação do Firebase CLI.',
    );
  }
  final token = '${tokenResult.stdout}'.trim();
  final fieldName =
      'projects/$_projectId/databases/(default)/collectionGroups/news_articles/fields/expiresAt';
  final response = await http.patch(
    Uri.parse(
      'https://firestore.googleapis.com/v1/$fieldName?updateMask=ttlConfig',
    ),
    headers: {
      'authorization': 'Bearer $token',
      'content-type': 'application/json',
    },
    body: jsonEncode({'name': fieldName, 'ttlConfig': <String, dynamic>{}}),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final message = _apiErrorMessage(response.body);
    throw HttpException(
      'Não foi possível habilitar TTL (${response.statusCode}): $message',
    );
  }
  final verification = await http.get(
    Uri.parse('https://firestore.googleapis.com/v1/$fieldName'),
    headers: {'authorization': 'Bearer $token'},
  );
  if (verification.statusCode < 200 || verification.statusCode >= 300) {
    throw HttpException(
      'TTL solicitado, mas a verificação falhou (${verification.statusCode}).',
    );
  }
  final decoded = jsonDecode(verification.body);
  final ttlConfig = decoded is Map<String, dynamic>
      ? decoded['ttlConfig']
      : null;
  final state = ttlConfig is Map<String, dynamic>
      ? ttlConfig['state'] as String? ?? 'STATE_UNSPECIFIED'
      : 'MISSING';
  stdout.writeln('TTL news_articles.expiresAt: $state.');
}

String _apiErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        return error['message'] as String? ?? 'erro sem mensagem';
      }
    }
  } catch (_) {
    // Do not echo an unstructured remote response.
  }
  return 'erro sem mensagem';
}
