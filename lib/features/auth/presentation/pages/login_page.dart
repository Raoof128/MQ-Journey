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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? MqColors.charcoal900 : MqColors.alabaster,
      body: SafeArea(
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
                    color: isDark ? Colors.white : MqColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.authLoginTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? Colors.white : MqColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? MqColors.contentSecondaryDark
                        : MqColors.contentSecondary,
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
                  obscurePassword: _obscurePassword,
                  onToggleObscurePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  isLoading: authState.isLoading,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authState.isLoading ? null : () {},
                    child: Text(l10n.authForgotPassword),
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
                        color: isDark
                            ? MqColors.contentSecondaryDark
                            : MqColors.contentSecondary,
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
    );
  }
}
