import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/common/app_buttons.dart';
import '../../../widgets/common/app_text_field.dart';
import '../viewmodels/auth_view_model.dart';
import 'auth_scaffold.dart';
import 'widgets/auth_error_banner.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authViewModelProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    // Navigation is driven by the router redirect on auth-state change.
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final isBusy = auth.isLoading;
    return AuthScaffold(
      title: AppStrings.loginTitle,
      subtitle: AppStrings.loginSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.hasError) ...[
              AuthErrorBanner(error: auth.error),
              const SizedBox(height: AppSizes.lg),
            ],
            AppTextField(
              label: AppStrings.emailLabel,
              controller: _emailController,
              hint: AppStrings.emailHint,
              validator: AppValidators.email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: AppStrings.passwordLabel,
              controller: _passwordController,
              hint: AppStrings.passwordHint,
              validator: AppValidators.password,
              obscure: _obscure,
              obscureToggle: true,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              prefixIcon: Icons.lock_outline_rounded,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSizes.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                child: const Text(AppStrings.forgotPasswordTitle),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            AppPrimaryButton(
              label: AppStrings.signIn,
              loading: isBusy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.noAccount,
                    style: Theme.of(context).textTheme.bodyMedium),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text(AppStrings.signUp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
