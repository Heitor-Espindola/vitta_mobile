enum NewsErrorType {
  apiKeyMissing,
  apiKeyInvalid,
  rateLimited,
  timeout,
  network,
  invalidResponse,
  server,
}

class NewsException implements Exception {
  const NewsException(this.type);
  final NewsErrorType type;

  String get userMessage => switch (type) {
    NewsErrorType.apiKeyMissing =>
      'Não foi possível carregar as notícias no momento.',
    NewsErrorType.apiKeyInvalid =>
      'Não foi possível autenticar o serviço de notícias.',
    NewsErrorType.rateLimited =>
      'O limite temporário de notícias foi atingido. Tente novamente mais tarde.',
    NewsErrorType.timeout => 'O serviço de notícias demorou para responder.',
    NewsErrorType.network => 'Sem conexão. Verifique sua internet.',
    NewsErrorType.invalidResponse =>
      'O serviço de notícias enviou uma resposta inválida.',
    NewsErrorType.server =>
      'O serviço de notícias está indisponível no momento.',
  };
}
