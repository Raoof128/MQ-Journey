import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/auth/data/repositories/auth_repository.dart';
import 'package:mq_navigation/features/auth/domain/services/auth_service.dart';

/// Provides the AuthRepository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = Supabase.instance.client;
  final authService = AuthService(supabase: supabase);
  return AuthRepository(authService: authService);
});

/// Set to `true` by [AuthController.signUp] when account creation succeeded
/// but email confirmation is still required.  [LoginPage] watches this provider
/// to show the "check your email" success banner.  Reset to `false` when the
/// user dismisses the banner or successfully signs in.
final pendingEmailVerificationProvider =
    NotifierProvider<_PendingEmailVerificationNotifier, bool>(
      _PendingEmailVerificationNotifier.new,
    );

class _PendingEmailVerificationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;
}

/// Tracks auth UI state — login status, loading, and error messages.
/// Named AuthScreenState to avoid conflict with supabase_flutter's AuthState.
class AuthController extends Notifier<AuthScreenState> {
  @override
  AuthScreenState build() {
    ref.onDispose(() => _disposed = true);
    final repository = _repository;
    if (repository.isAuthenticated) {
      return AuthScreenState.authenticated(userId: repository.userId!);
    }
    return AuthScreenState.initial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  bool _disposed = false;

  Future<void> signIn({required String email, required String password}) async {
    final repository = _repository;
    state = state.copyWith(isLoading: true, error: null);
    final result = await repository.signIn(email: email, password: password);
    if (_disposed) return;
    if (result.success) {
      state = AuthScreenState.authenticated(userId: repository.userId!);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    final repository = _repository;
    state = state.copyWith(isLoading: true, error: null);
    final result = await repository.signUp(email: email, password: password);
    if (_disposed) return;
    if (result.success) {
      final userId = repository.userId;
      if (userId != null) {
        // Email confirmations disabled — session granted immediately.
        state = AuthScreenState.authenticated(userId: userId);
      } else {
        // Email confirmation required — user created but no session yet.
        state = AuthScreenState.pendingVerification();
      }
      ref.read(pendingEmailVerificationProvider.notifier).set(true);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    if (_disposed) return;
    state = AuthScreenState.initial();
  }

  /// Sends a Supabase password-reset email.
  ///
  /// Returns `null` on success, or a user-facing error string on failure.
  /// The caller is responsible for showing a success/error message.
  Future<String?> resetPassword({required String email}) async {
    final result = await _repository.resetPassword(email: email);
    return result.success ? null : result.error;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthScreenState>(AuthController.new);

/// Auth screen UI state model.
class AuthScreenState {
  const AuthScreenState._({
    required this.isAuthenticated,
    required this.isLoading,
    this.isPendingVerification = false,
    this.userId,
    this.error,
  });

  factory AuthScreenState.initial() =>
      const AuthScreenState._(isAuthenticated: false, isLoading: false);

  factory AuthScreenState.authenticated({required String userId}) =>
      AuthScreenState._(
        isAuthenticated: true,
        isLoading: false,
        userId: userId,
      );

  /// Sign-up succeeded but email confirmation is required before login.
  factory AuthScreenState.pendingVerification() => const AuthScreenState._(
    isAuthenticated: false,
    isLoading: false,
    isPendingVerification: true,
  );

  final bool isAuthenticated;
  final bool isLoading;
  final bool isPendingVerification;
  final String? userId;
  final String? error;

  AuthScreenState copyWith({
    bool? isLoading,
    String? error,
    bool? isPendingVerification,
  }) {
    return AuthScreenState._(
      isAuthenticated: isAuthenticated,
      userId: userId,
      isLoading: isLoading ?? this.isLoading,
      isPendingVerification:
          isPendingVerification ?? this.isPendingVerification,
      error: error,
    );
  }
}
