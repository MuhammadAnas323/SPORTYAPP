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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authViewModelProvider.notifier).resetPassword(
          email: _emailController.text.trim(),
        );
    if (ok && mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final isBusy = auth.isLoading;
    return AuthScaffold(
      title: AppStrings.forgotPasswordTitle,
      subtitle: AppStrings.forgotPasswordSubtitle,
      child: _done
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 64,
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  AppStrings.passwordResetSent,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSizes.xl),
                AppPrimaryButton(
                  label: AppStrings.backToLogin,
                  onPressed: () => context.pop(),
                ),
              ],
            )
          : Form(
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
                  const SizedBox(height: AppSizes.xl),
                  AppPrimaryButton(
                    label: AppStrings.resetPassword,
                    loading: isBusy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
