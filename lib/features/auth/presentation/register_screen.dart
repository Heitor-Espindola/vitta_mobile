import 'package:flutter/material.dart';
import 'package:vitta_mobile/core/input_formatters/cpf_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/date_input_formatter.dart';
import 'package:vitta_mobile/core/input_formatters/name_input_formatter.dart';
import 'package:vitta_mobile/app/routes.dart';
import 'package:vitta_mobile/core/config/domain_repository_factory.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/core/validators/birth_date_validator.dart';
import 'package:vitta_mobile/core/validators/cpf_validator.dart';
import 'package:vitta_mobile/core/validators/full_name_validator.dart';
import 'package:vitta_mobile/core/validators/password_validator.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/validators/gmail_validator.dart';
import 'package:vitta_mobile/features/auth/presentation/auth_error_mapper.dart';
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
  final _passwordConfirmationController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirmation = true;
  String? _errorMessage;

  AuthRepository get _authRepository =>
      widget.authRepository ?? DomainRepositoryFactory.auth();

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
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
        cpf: cpfDigitsOnly(_cpfController.text),
        birthDate: parseBrazilianDate(_birthDateController.text)!,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
    } catch (error) {
      setState(() => _errorMessage = mapSignUpError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final parsed = parseBirthDate(_birthDateController.text);
    final selected = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: parsed ?? DateTime(today.year - 18, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (selected != null) {
      _birthDateController.text = formatBrazilianDate(selected);
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
              'É rápido e seguro',
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
                    inputFormatters: [NameInputFormatter()],
                    validator: validateFullName,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _cpfController,
                    label: 'CPF',
                    hintText: '000.000.000-00',
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfInputFormatter()],
                    validator: validateCpf,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _birthDateController,
                    label: 'Data de nascimento',
                    hintText: 'dd/mm/aaaa',
                    keyboardType: TextInputType.number,
                    inputFormatters: [DateInputFormatter()],
                    validator: validateBirthDate,
                    suffixIcon: IconButton(
                      tooltip: 'Selecionar data',
                      onPressed: _isLoading ? null : _pickBirthDate,
                      icon: const Icon(Icons.calendar_month),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _emailController,
                    label: 'E-mail',
                    hintText: 'userexample@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: validateGmail,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Senha',
                    hintText: 'Crie uma senha forte',
                    obscureText: _obscurePassword,
                    validator: validateStrongPassword,
                    onChanged: (_) => setState(() {}),
                    suffixIcon: IconButton(
                      key: const Key('register-password-visibility'),
                      tooltip: _obscurePassword
                          ? 'Mostrar senha'
                          : 'Ocultar senha',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFDCE8F3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _PasswordStrengthIndicator(
                    strength: passwordStrength(_passwordController.text),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    passwordRequirements,
                    style: TextStyle(
                      color: Color(0xFFB8C9D8),
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _passwordConfirmationController,
                    label: 'Confirmar senha',
                    hintText: 'Digite a senha novamente',
                    obscureText: _obscurePasswordConfirmation,
                    validator: (value) => validatePasswordConfirmation(
                      value,
                      _passwordController.text,
                    ),
                    suffixIcon: IconButton(
                      key: const Key(
                        'register-password-confirmation-visibility',
                      ),
                      tooltip: _obscurePasswordConfirmation
                          ? 'Mostrar confirmação de senha'
                          : 'Ocultar confirmação de senha',
                      onPressed: () => setState(
                        () => _obscurePasswordConfirmation =
                            !_obscurePasswordConfirmation,
                      ),
                      icon: Icon(
                        _obscurePasswordConfirmation
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFDCE8F3),
                      ),
                    ),
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
                    'Ao continuar você concorda com nossos Termos e Política de Privacidade.',
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

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final (activeSegments, color, label) = switch (strength) {
      PasswordStrength.empty => (0, const Color(0xFF7A8C9E), ''),
      PasswordStrength.weak => (1, const Color(0xFFFF5C5C), 'Senha fraca'),
      PasswordStrength.medium => (2, const Color(0xFFFFC928), 'Senha média'),
      PasswordStrength.strong => (3, const Color(0xFF37D67A), 'Senha forte'),
    };

    return Semantics(
      label: label.isEmpty ? 'Força da senha' : label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index < activeSegments;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                  child: AnimatedContainer(
                    key: Key('password-strength-segment-$index'),
                    duration: const Duration(milliseconds: 220),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? color
                          : Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
              child: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}
