import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitta_mobile/features/auth/data/registration_compensator.dart';

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

String mapSignInError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Gmail inválido.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Gmail ou senha inválidos.',
      'network-request-failed' => 'Falha de conexão. Verifique sua internet.',
      'profile-not-found' =>
        'A autenticação foi concluída, mas o perfil não foi encontrado.',
      _ => 'Não foi possível entrar agora. Tente novamente.',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Não foi possível acessar seu perfil agora. Tente novamente.',
      'invalid-auth-link' =>
        'Não foi possível localizar seu perfil. Tente entrar novamente.',
      'unavailable' =>
        'Seu perfil está temporariamente indisponível. Tente novamente.',
      _ => 'Não foi possível carregar seu perfil agora. Tente novamente.',
    };
  }
  return 'Não foi possível entrar agora. Tente novamente.';
}

String mapSignUpError(Object error) {
  final original = error is RegistrationCompensationException
      ? error.cause
      : error;
  final compensationFailed = error is RegistrationCompensationException;

  final message = switch (original) {
    FirebaseAuthException authError => switch (authError.code) {
      'email-already-in-use' => 'Este e-mail já está em uso.',
      'invalid-email' => 'E-mail inválido.',
      'weak-password' => 'A senha informada é muito fraca.',
      'cpf-already-in-use' => 'Este CPF já está cadastrado.',
      'network-request-failed' => 'Falha de conexão. Verifique sua internet.',
      _ => 'Não foi possível criar a conta agora. Tente novamente.',
    },
    FirebaseException firestoreError => switch (firestoreError.code) {
      'permission-denied' =>
        'Não foi possível concluir o cadastro. Tente novamente.',
      _ => 'Não foi possível salvar o cadastro agora. Tente novamente.',
    },
    _ => 'Não foi possível criar a conta agora. Tente novamente.',
  };

  if (!compensationFailed) return message;
  return '$message Se o problema persistir, procure o suporte.';
}
