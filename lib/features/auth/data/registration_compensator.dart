/// Mantém a causa original de uma falha de cadastro mesmo quando a limpeza da
/// conta recém-criada também falha.
class RegistrationCompensationException implements Exception {
  const RegistrationCompensationException({
    required this.cause,
    required this.causeStackTrace,
    required this.compensationError,
    required this.compensationStackTrace,
  });

  final Object cause;
  final StackTrace causeStackTrace;
  final Object compensationError;
  final StackTrace compensationStackTrace;

  @override
  String toString() =>
      'Falha no cadastro: $cause. A compensação também falhou: '
      '$compensationError.';
}

abstract final class RegistrationCompensator {
  static Future<T> run<T>({
    required Future<T> Function() operation,
    required Future<void> Function() compensate,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      try {
        await compensate();
      } catch (compensationError, compensationStackTrace) {
        throw RegistrationCompensationException(
          cause: error,
          causeStackTrace: stackTrace,
          compensationError: compensationError,
          compensationStackTrace: compensationStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
