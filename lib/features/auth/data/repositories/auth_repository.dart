import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_journey/features/auth/domain/services/auth_service.dart';

class AuthRepository {
  AuthRepository({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  bool get isAuthenticated => _authService.isAuthenticated;
  String? get userId => _authService.currentUser?.id;
  String? get userEmail => _authService.currentUser?.email;
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
      return AuthResult.failure(
        'Network error. Check your connection and try again.',
      );
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
      );

      // **Silent existing-user detection** — mirrors the same check the
      // working Syllabus Sync signup uses on the Node side.
      //
      // supabase_flutter's `signUp()` has a well-known quirk: when the
      // email is already registered AND confirmed, Supabase returns a
      // *successful* `AuthResponse` (no exception thrown) but:
      //   • `response.user` is non-null
      //   • `response.user.identities` is the empty list
      //   • NO confirmation email is sent
      //
      // Without this check the controller would flip
      // `pendingEmailVerificationProvider` to `true` and show the green
      // "Account created! Check your email…" banner — but no email is
      // ever delivered, so the user is stranded. This was the primary
      // user-facing bug we were chasing: signup appearing to succeed
      // while nothing happens server-side.
      //
      // We surface a clear, actionable "already registered" error
      // instead. (Compared to the more enumeration-resistant generic
      // success used by Syllabus Sync, we prioritise UX here — this is
      // a personal-scale student app, not a public service that needs
      // to defend against email enumeration.)
      final user = response.user;
      if (user != null && user.identities != null && user.identities!.isEmpty) {
        return AuthResult.failure(
          'An account already exists for this email. Please sign in instead.',
        );
      }

      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure(
        'Network error. Check your connection and try again.',
      );
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
      return AuthResult.failure(
        'Network error. Check your connection and try again.',
      );
    }
  }

  Future<AuthResult> updatePassword({required String newPassword}) async {
    try {
      await _authService.updatePassword(newPassword: newPassword);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure(
        'Network error. Check your connection and try again.',
      );
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
  factory AuthResult.failure(String error) =>
      AuthResult._(success: false, error: error);
}
