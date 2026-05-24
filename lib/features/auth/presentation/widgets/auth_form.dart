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

    // Localisation strategy:
    //
    // The shorter `email` / `password` / `confirmPassword` l10n keys are
    // already properly translated in every supported ARB. The newer
    // `authEmailLabel` / `authPasswordLabel` / `authConfirmPasswordLabel`
    // were added later and still carry English placeholder values in
    // most non-English ARBs — meaning users in any locale other than
    // English (and Persian, which we just translated) see "Email" /
    // "Password" / "Confirm password" in English on this form.
    //
    // Routing this form through the existing short keys fixes ~8 strings
    // × ~35 locales in one go without requiring a translator pass on
    // every individual ARB.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MqInput(
          label: l10n.email,
          hint: 'you@example.com',
          controller: emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !isLoading,
        ),
        const SizedBox(height: 16),
        MqInput(
          label: l10n.password,
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
            padding: const EdgeInsets.only(top: 6, left: 16),
            // **Readability fix**: this helper text used to use
            // `colorScheme.onSurfaceVariant` which renders as a low-opacity
            // grey. On the SignupPage the form sits over a darkened blurred
            // background, so the grey came out almost invisible (see the
            // user-reported screenshot). We now use white-tinted text at
            // 88% opacity with a subtle shadow for the dark background and
            // fall back to a darker tint when the surface is light. The
            // outer Stack scrim (`Colors.black54`) is the dominant context,
            // hence the brighter default.
            child: Text(
              l10n.authPasswordHint,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.88)
                    : Colors.white.withValues(alpha: 0.92),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
              ),
            ),
          ),
        if (isSignup) ...[
          const SizedBox(height: 16),
          MqInput(
            label: l10n.confirmPassword,
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
