import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_journey/features/auth/domain/services/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockGoTrue;
  late AuthService authService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockGoTrue = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockGoTrue);
    authService = AuthService(supabase: mockSupabase);
  });

  group('AuthService', () {
    test('signIn calls signInWithPassword', () async {
      final fakeResponse = AuthResponse(user: null, session: null);
      when(
        () => mockGoTrue.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => fakeResponse);

      await authService.signIn(email: 'a@b.com', password: 'pass123');

      verify(
        () => mockGoTrue.signInWithPassword(
          email: 'a@b.com',
          password: 'pass123',
        ),
      ).called(1);
    });

    test('signUp calls signUp', () async {
      final fakeResponse = AuthResponse(user: null, session: null);
      when(
        () => mockGoTrue.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenAnswer((_) async => fakeResponse);

      await authService.signUp(email: 'a@b.com', password: 'pass123');

      verify(
        () => mockGoTrue.signUp(
          email: 'a@b.com',
          password: 'pass123',
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).called(1);
    });

    test('signOut calls signOut', () async {
      when(() => mockGoTrue.signOut()).thenAnswer((_) async {});

      await authService.signOut();

      verify(() => mockGoTrue.signOut()).called(1);
    });

    test('resetPassword calls resetPasswordForEmail', () async {
      when(
        () => mockGoTrue.resetPasswordForEmail(
          any(),
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenAnswer((_) async {});

      await authService.resetPassword(email: 'a@b.com');

      verify(
        () => mockGoTrue.resetPasswordForEmail(
          'a@b.com',
          redirectTo: any(named: 'redirectTo'),
        ),
      ).called(1);
    });

    test('isAuthenticated returns true when session exists', () {
      when(() => mockGoTrue.currentSession).thenReturn(MockSession());
      expect(authService.isAuthenticated, isTrue);
    });

    test('isAuthenticated returns false when no session', () {
      when(() => mockGoTrue.currentSession).thenReturn(null);
      expect(authService.isAuthenticated, isFalse);
    });
  });
}
