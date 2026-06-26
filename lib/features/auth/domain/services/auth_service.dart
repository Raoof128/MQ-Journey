import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentSession != null;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signInAnonymously() {
    return _supabase.auth.signInAnonymously();
  }
}
