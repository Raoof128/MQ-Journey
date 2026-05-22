import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mq_navigation/features/auth/presentation/widgets/auth_form.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const _backgroundAsset = 'assets/images/login_background.png';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    ref
        .read(authControllerProvider.notifier)
        .signIn(email: email, password: password);
  }

  /// Shows a dialog that asks for the user's email and sends a Supabase
  /// password-reset link. Pre-fills the email field if the user has
  /// already typed one into the main form.
  Future<void> _showForgotPasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    try {
      final submitted = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.authForgotPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.forgotPasswordDesc),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.reset),
            ),
          ],
        ),
      );
      if (submitted == null || submitted.isEmpty || !mounted) return;

      final error = await ref
          .read(authControllerProvider.notifier)
          .resetPassword(email: submitted);

      if (!mounted) return;
      final message = error ?? l10n.authResetEmailSent;
      final isError = error != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? MqColors.error : MqColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clear the pending verification banner once the user successfully signs in
    // (router navigates away, but belt-and-suspenders reset here too).
    ref.listen<AuthScreenState>(authControllerProvider, (_, next) {
      if (next.isAuthenticated) {
        ref.read(pendingEmailVerificationProvider.notifier).set(false);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final pendingVerification = ref.watch(pendingEmailVerificationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? MqColors.charcoal900 : MqColors.alabaster,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Image.asset(
                LoginPage._backgroundAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Dark scrim for text readability
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 4,
                      color: MqColors.red,
                      margin: const EdgeInsets.only(bottom: 32),
                    ),
                    const Icon(Icons.explore, size: 56, color: MqColors.red),
                    const SizedBox(height: 8),
                    Text(
                      l10n.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.authLoginTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.authSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Signup success — email confirmation pending ──────────
                    if (pendingVerification)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.authVerifyEmailMessage,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(
                                    pendingEmailVerificationProvider.notifier,
                                  )
                                  .set(false),
                              child: const Icon(
                                Icons.close,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Auth error ───────────────────────────────────────────
                    if (authState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: MqColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: MqColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: MqColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: const TextStyle(
                                  color: MqColors.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(authControllerProvider.notifier)
                                  .clearError(),
                              child: const Icon(
                                Icons.close,
                                color: MqColors.error,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                    AuthForm(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      onToggleObscurePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      isLoading: authState.isLoading,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : _showForgotPasswordDialog,
                        child: Text(
                          l10n.authForgotPassword,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    MqButton(
                      label: l10n.authSignInButton,
                      onPressed: _submit,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${l10n.authNoAccount} ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        GestureDetector(
                          onTap: authState.isLoading
                              ? null
                              : () => context.go('/auth/signup'),
                          child: Text(
                            l10n.authCreateOne,
                            style: const TextStyle(
                              color: MqColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
