import 'package:firebase_auth/firebase_auth.dart';

const passwordResetNeutralMessage =
    'Se houver uma conta associada a este Gmail, enviaremos um link para redefinir a senha.';

String mapPasswordResetError(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Não foi possível enviar o link agora. Tente novamente.';
  }
  return switch (error.code) {
    'invalid-email' => 'Digite um Gmail válido.',
    'too-many-requests' =>
      'Muitas solicitações. Aguarde alguns minutos e tente novamente.',
    'network-request-failed' =>
      'Não foi possível conectar. Verifique sua internet.',
    'operation-not-allowed' =>
      'A recuperação de senha não está disponível no momento.',
    'internal-error' =>
      'Não foi possível enviar o link agora. Tente novamente.',
    _ => 'Não foi possível enviar o link agora. Tente novamente.',
  };
}

String mapSignInError(FirebaseAuthException error) => switch (error.code) {
  'invalid-email' => 'Gmail inválido.',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' => 'Gmail ou senha inválidos.',
  'network-request-failed' => 'Falha de conexão. Verifique sua internet.',
  _ => 'Erro de autenticação. Tente novamente.',
};
