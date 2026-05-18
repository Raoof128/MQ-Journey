import 'package:flutter/material.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/shared/widgets/mq_input.dart';

class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    this.confirmPasswordController,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.onToggleObscurePassword,
    this.onToggleObscureConfirmPassword,
    this.isSignup = false,
    this.isLoading = false,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback? onToggleObscurePassword;
  final VoidCallback? onToggleObscureConfirmPassword;
  final bool isSignup;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MqInput(
          label: l10n.authEmailLabel,
          hint: 'you@example.com',
          controller: emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        MqInput(
          label: l10n.authPasswordLabel,
          controller: passwordController,
          prefixIcon: Icons.lock_outlined,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: onToggleObscurePassword,
          ),
          obscureText: obscurePassword,
          autofillHints: const [AutofillHints.password],
          enabled: !isLoading,
        ),
        if (isSignup)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 16),
            child: Text(
              l10n.authPasswordHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        if (isSignup) ...[
          const SizedBox(height: 16),
          MqInput(
            label: l10n.authConfirmPasswordLabel,
            controller: confirmPasswordController,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: onToggleObscureConfirmPassword,
            ),
            obscureText: obscureConfirmPassword,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !isLoading,
          ),
        ],
      ],
    );
  }
}

