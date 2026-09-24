# Vitta Mobile

Aplicativo Flutter da carteira digital de vacinação Vitta. Em produção, o
domínio de perfis, vínculos familiares e aplicações usa Firebase SQL Connect;
Firebase Authentication continua responsável pela identidade.

O Firestore é mantido somente para `news_articles` e como fallback temporário
de rollback. O backend padrão é SQL e não há dual-write:

```bash
flutter run
flutter build apk --release
```

Para um rollback explícito e temporário do domínio:

```bash
flutter run --dart-define=VITTA_DOMAIN_BACKEND=firestore
```

Não use essa flag no APK de produção.

Para executar com notícias no ambiente de desenvolvimento:

```bash
flutter run -d edge --dart-define-from-file=config/news_api.json
```

No Flutter Web, valores de `--dart-define` podem ser inspecionados no código
compilado. O acesso direto à NewsAPI é destinado somente a desenvolvimento e
demonstração local. Uma versão de produção deve usar um backend ou proxy seguro.

## Validação

```bash
dart format .
flutter analyze
flutter test
```

## Getting Started

A few resources if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
