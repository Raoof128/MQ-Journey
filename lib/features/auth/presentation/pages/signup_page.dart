import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mq_navigation/features/auth/presentation/widgets/auth_form.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  static const _backgroundAsset = 'assets/images/login_background.png';

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (password != confirm) {
      setState(() => _confirmPasswordError = l10n.authErrorPasswordsDoNotMatch);
      return;
    }
    setState(() => _confirmPasswordError = null);
    ref
        .read(authControllerProvider.notifier)
        .signUp(email: _emailController.text.trim(), password: password);
  }

  @override
  Widget build(BuildContext context) {
    // Navigate to login page when signup succeeds and email confirmation is
    // required.  The pendingEmailVerificationProvider is already set to true by
    // the controller before isPendingVerification flips, so LoginPage will show
    // the green "check your inbox" banner as soon as it mounts.
    ref.listen<AuthScreenState>(authControllerProvider, (prev, next) {
      if (next.isPendingVerification &&
          !(prev?.isPendingVerification ?? false) &&
          context.mounted) {
        // Reset signup state so pressing "Back" to signup later starts fresh.
        ref.read(authControllerProvider.notifier).clearError();
        context.go('/auth/login');
      }
    });

    final authState = ref.watch(authControllerProvider);
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
                SignupPage._backgroundAsset,
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
                    Image.asset(
                      'assets/images/mq_logo.png',
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.explore,
                        size: 56,
                        color: MqColors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      l10n.authSignupTitle,
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
                      confirmPasswordController: _confirmPasswordController,
                      obscurePassword: _obscurePassword,
                      obscureConfirmPassword: _obscureConfirmPassword,
                      onToggleObscurePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onToggleObscureConfirmPassword: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      isSignup: true,
                      isLoading: authState.isLoading,
                    ),

                    if (_confirmPasswordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _confirmPasswordError!,
                          style: const TextStyle(
                            color: MqColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    MqButton(
                      label: l10n.authSignUpButton,
                      onPressed: _submit,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${l10n.authHasAccount} ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        GestureDetector(
                          onTap: authState.isLoading
                              ? null
                              : () => context.go('/auth/login'),
                          child: Text(
                            l10n.authSignInInstead,
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
