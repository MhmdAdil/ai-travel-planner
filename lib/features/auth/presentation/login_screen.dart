import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authControllerProvider.notifier).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!success && mounted) {
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
                  const Icon(Icons.travel_explore, size: 56, color: AppColors.teal),
                  const SizedBox(height: 16),
                  Text(l10n.loginTitle, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginSubtitle,
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
                    autofillHints: const [AutofillHints.password],
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.loginButton),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: isLoading ? null : () => context.go('/register'),
                      child: Text('${l10n.noAccountPrompt} ${l10n.registerButton}'),
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
