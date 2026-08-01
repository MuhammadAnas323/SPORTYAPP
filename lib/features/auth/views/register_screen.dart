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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authViewModelProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final isBusy = auth.isLoading;
    return AuthScaffold(
      title: AppStrings.registerTitle,
      subtitle: AppStrings.registerSubtitle,
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
              label: AppStrings.nameLabel,
              controller: _nameController,
              hint: AppStrings.nameHint,
              validator: AppValidators.name,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: AppStrings.emailLabel,
              controller: _emailController,
              hint: AppStrings.emailHint,
              validator: AppValidators.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
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
            const SizedBox(height: AppSizes.xl),
            AppPrimaryButton(
              label: AppStrings.createAccount,
              loading: isBusy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.haveAccount,
                    style: Theme.of(context).textTheme.bodyMedium),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(AppStrings.signIn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
