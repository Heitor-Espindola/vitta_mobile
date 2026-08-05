import 'package:flutter/material.dart';
import 'package:vitta_mobile/features/auth/domain/validators/gmail_validator.dart';
import 'package:vitta_mobile/features/auth/presentation/controllers/password_reset_controller.dart';

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({required this.controller, super.key});

  final PasswordResetController controller;

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _emailController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final success = await widget.controller.sendPasswordReset(
      _emailController.text,
    );
    if (success && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.controller.isLoading;
    return PopScope(
      canPop: !isLoading,
      child: AlertDialog(
        title: const Text('Recuperar senha'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Informe o Gmail cadastrado. Enviaremos um link para você criar uma nova senha.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('password-reset-email'),
                  controller: _emailController,
                  enabled: !isLoading,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Gmail',
                    hintText: 'seuemail@gmail.com',
                  ),
                  validator: validateGmail,
                  onFieldSubmitted: (_) => isLoading ? null : _submit(),
                ),
                if (widget.controller.lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.controller.lastError!,
                    key: const Key('password-reset-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('password-reset-submit'),
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar link'),
          ),
        ],
      ),
    );
  }
}
