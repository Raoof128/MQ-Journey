import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/features/auth/domain/services/auth_service.dart';

class AuthRepository {
  AuthRepository({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  bool get isAuthenticated => _authService.isAuthenticated;
  String? get userId => _authService.currentUser?.id;
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signIn(email: email, password: password);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure('Network error. Check your connection and try again.');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signUp(email: email, password: password);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure('Network error. Check your connection and try again.');
    }
  }

  Future<void> signOut() => _authService.signOut();

  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _authService.resetPassword(email: email);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure('Network error. Check your connection and try again.');
    }
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Email or password is incorrect.';
    }
    if (msg.contains('user already registered')) {
      return 'An account already exists for this email.';
    }
    if (msg.contains('weak password') || msg.contains('password length')) {
      return 'Password must be at least 8 characters.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    return 'Something went wrong. Please try again.';
  }
}

class AuthResult {
  const AuthResult._({required this.success, this.error});
  final bool success;
  final String? error;

  factory AuthResult.success() => const AuthResult._(success: true);
  factory AuthResult.failure(String error) => AuthResult._(success: false, error: error);
}
