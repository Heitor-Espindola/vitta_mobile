/// Explicit editorial allowlist. A NewsAPI source name alone is not proof of origin;
/// the article URL must belong to one of these hosts (and paths where specified).
abstract final class TrustedNewsSources {
  static const trustedNewsDomains = <String>[
    'gov.br',
    'saude.gov.br',
    'fiocruz.br',
    'butantan.gov.br',
    'who.int',
    'paho.org',
    'agenciabrasil.ebc.com.br',
    'g1.globo.com',
    'bbc.com',
  ];

  static const _sources = <_TrustedSource>[
    _TrustedSource('gov.br', 'Ministério da Saúde', pathPrefix: '/saude/'),
    _TrustedSource('saude.gov.br', 'Ministério da Saúde'),
    _TrustedSource('fiocruz.br', 'Fiocruz', subdomains: true),
    _TrustedSource('butantan.gov.br', 'Instituto Butantan', subdomains: true),
    _TrustedSource('who.int', 'Organização Mundial da Saúde', subdomains: true),
    _TrustedSource('paho.org', 'OPAS', subdomains: true),
    _TrustedSource('agenciabrasil.ebc.com.br', 'Agência Brasil'),
    _TrustedSource('g1.globo.com', 'g1'),
    _TrustedSource('bbc.com', 'BBC News Brasil', pathPrefix: '/portuguese/'),
  ];

  static String? nameForUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) {
      return null;
    }
    for (final source in _sources) {
      if (source.matches(uri)) return source.name;
    }
    return null;
  }
}

class _TrustedSource {
  const _TrustedSource(
    this.domain,
    this.name, {
    this.pathPrefix,
    this.subdomains = false,
  });

  final String domain;
  final String name;
  final String? pathPrefix;
  final bool subdomains;

  bool matches(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host != domain &&
        host != 'www.$domain' &&
        !(subdomains && host.endsWith('.$domain'))) {
      return false;
    }
    final prefix = pathPrefix;
    return prefix == null ||
        uri.path == prefix.substring(0, prefix.length - 1) ||
        uri.path.startsWith(prefix);
  }
}
