import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authControllerProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.registerSuccessMessage)));
      context.go('/login');
    } else {
      final message = ref.read(authControllerProvider).errorMessage ?? l10n.genericAuthError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authControllerProvider.select((s) => s.isLoading));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person_add_alt_1, size: 56, color: AppColors.orange),
                  const SizedBox(height: 16),
                  Text(l10n.registerTitle, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    l10n.registerSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                      return isValid ? null : l10n.emailValidationError;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) =>
                        (value?.length ?? 0) >= 6 ? null : l10n.passwordValidationError,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (value) =>
                        value == _passwordController.text ? null : l10n.confirmPasswordValidationError,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.registerButton),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: isLoading ? null : () => context.go('/login'),
                      child: Text('${l10n.haveAccountPrompt} ${l10n.loginButton}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
