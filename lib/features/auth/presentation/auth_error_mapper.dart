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
      _ => error.message ?? 'Erro de autenticação (${error.code}).',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'O login foi autenticado, mas o Firestore recusou o acesso ao perfil '
            '(permission-denied). As regras publicadas estão incompatíveis com '
            'esta versão do aplicativo.',
      'invalid-auth-link' =>
        'O vínculo entre a autenticação e o perfil está inválido '
            '(invalid-auth-link).',
      'unavailable' =>
        'O perfil está temporariamente indisponível no Firestore '
            '(unavailable).',
      _ =>
        'Falha ao carregar o perfil no Firestore (${error.code}). '
            '${error.message ?? ''}',
    };
  }
  return 'Não foi possível entrar: ${error.runtimeType}.';
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
      _ => authError.message ?? 'Erro no Firebase Auth (${authError.code}).',
    },
    FirebaseException firestoreError => switch (firestoreError.code) {
      'permission-denied' =>
        'O Firebase Auth iniciou o cadastro, mas o Firestore recusou os '
            'dados (permission-denied). A conta temporária foi removida. As '
            'regras publicadas estão incompatíveis com esta versão do aplicativo.',
      _ =>
        'Falha ao gravar o cadastro no Firestore '
            '(${firestoreError.code}). ${firestoreError.message ?? ''}',
    },
    _ => 'Não foi possível criar a conta: ${original.runtimeType}.',
  };

  if (!compensationFailed) return message;
  return '$message A remoção compensatória da conta Auth também falhou; '
      'é necessária revisão administrativa.';
}
