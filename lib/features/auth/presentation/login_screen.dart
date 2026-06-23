import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/presentation/widgets/auth_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  AuthRepository get _authRepository =>
      widget.authRepository ?? FirebaseAuthRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on FirebaseAuthException catch (error) {
      setState(() => _errorMessage = _authErrorMessage(error));
    } catch (_) {
      setState(
        () => _errorMessage = 'Nao foi possivel entrar. Tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBadge(),
            const SizedBox(height: 18),
            const Text(
              'Suas vacinas,\nnum so lugar.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                height: 1.08,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Acesso seguro com criptografia de ponta a ponta.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'userexample@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Senha',
                    hintText: 'Minimo 6 caracteres',
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFFDAD6)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 18),
                  AuthPrimaryButton(
                    onPressed: _isLoading ? null : _signIn,
                    icon: Icons.fingerprint,
                    label: _isLoading ? 'Entrando...' : 'Entrar',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 46),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  'Novo por aqui?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.46),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () =>
                            Navigator.of(context).pushNamed(AppRoutes.register),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Termos de uso e Privacidade.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Informe o email.';
  }
  if (!email.contains('@') || !email.contains('.')) {
    return 'Informe um email valido.';
  }
  return null;
}

String? _validatePassword(String? value) {
  if ((value ?? '').isEmpty) {
    return 'Informe a senha.';
  }
  if ((value ?? '').length < 6) {
    return 'A senha deve ter pelo menos 6 caracteres.';
  }
  return null;
}

String _authErrorMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'invalid-email' => 'Email invalido.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email ou senha invalidos.',
    'network-request-failed' => 'Falha de conexao. Verifique sua internet.',
    _ => error.message ?? 'Erro de autenticacao. Tente novamente.',
  };
}
