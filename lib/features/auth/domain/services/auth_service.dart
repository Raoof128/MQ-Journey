import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase auth operations for testability.
class AuthService {
  AuthService({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;

  bool get isAuthenticated => currentSession != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    // emailRedirectTo tells Supabase where to send the user after they click
    // the confirmation link in their inbox.
    //
    // • Web (Chrome / any browser): use the app's current origin so the PKCE
    //   confirmation code lands on a URL that Flutter web can handle.
    //   supabase_flutter auto-exchanges the ?code= param on startup.
    //   ⚠️  This origin must also be added to the Supabase dashboard under
    //       Authentication → URL Configuration → Redirect URLs.
    //
    // • Native (iOS / Android / macOS / Windows): use the registered custom
    //   URI scheme so the OS opens the app directly.
    final emailRedirectTo = kIsWeb
        ? '${Uri.base.scheme}://${Uri.base.host}'
              '${Uri.base.hasPort ? ':${Uri.base.port}' : ''}'
              '/auth/callback'
        : 'io.mqjourney://callback';

    return _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: emailRedirectTo,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    // redirectTo ensures the password-reset link deep-links back into the app.
    // Without this, the link in the email is a bare Supabase URL that the OS
    // cannot route to the app.
    final redirectTo = kIsWeb
        ? '${Uri.base.scheme}://${Uri.base.host}'
              '${Uri.base.hasPort ? ':${Uri.base.port}' : ''}'
              '/auth/callback'
        : 'io.mqjourney://callback';

    await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<UserResponse> updatePassword({required String newPassword}) async {
    return _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
