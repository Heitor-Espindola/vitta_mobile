import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/validators/gmail_validator.dart';
import 'package:vitta_mobile/features/auth/presentation/widgets/auth_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  AuthRepository get _authRepository =>
      widget.authRepository ?? FirebaseAuthRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        cpf: _cpfController.text,
        birthDate: parseBrazilianDate(_birthDateController.text)!,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
    } on FirebaseAuthException catch (error) {
      setState(() => _errorMessage = _authErrorMessage(error));
    } catch (_) {
      setState(() => _errorMessage = 'Nao foi possivel criar a conta agora.');
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Criar sua conta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                height: 1.08,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'E rapido e seguro',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 54),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _nameController,
                    label: 'Nome completo',
                    hintText: 'Como aparece no documento',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Informe o nome.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _cpfController,
                    label: 'CPF',
                    hintText: '000.000.000-00',
                    keyboardType: TextInputType.number,
                    validator: _validateCpf,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _birthDateController,
                    label: 'Data de nascimento',
                    hintText: 'dd/mm/aaaa',
                    keyboardType: TextInputType.datetime,
                    validator: _validateBirthDate,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Gmail',
                    hintText: 'userexample@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: validateGmail,
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 8),
                  AuthPrimaryButton(
                    onPressed: _isLoading ? null : _signUp,
                    label: _isLoading ? 'Cadastrando...' : 'Criar conta',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ao continuar voce concorda com nossos Termos e Politica de Privacidade.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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

String? _validateCpf(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return 'Informe o CPF.';
  }
  if (digits.length != 11) {
    return 'Informe um CPF valido.';
  }
  return null;
}

String? _validateBirthDate(String? value) {
  final date = parseBrazilianDate(value ?? '');
  if (date == null) {
    return 'Informe a data em dd/mm/aaaa.';
  }
  if (date.isAfter(DateTime.now())) {
    return 'Informe uma data valida.';
  }
  return null;
}

String _authErrorMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'email-already-in-use' => 'Este email ja esta em uso.',
    'invalid-email' => 'Email invalido.',
    'weak-password' => 'A senha informada e muito fraca.',
    'network-request-failed' => 'Falha de conexao. Verifique sua internet.',
    _ => error.message ?? 'Erro ao criar conta. Tente novamente.',
  };
}
