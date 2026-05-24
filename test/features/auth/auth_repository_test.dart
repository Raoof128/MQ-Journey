import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/features/auth/domain/services/auth_service.dart';
import 'package:mq_navigation/features/auth/data/repositories/auth_repository.dart';

class MockAuthService extends Mock implements AuthService {}

final _fakeResponse = AuthResponse(user: null, session: null);

void main() {
  late MockAuthService mockAuthService;
  late AuthRepository authRepository;

  setUp(() {
    mockAuthService = MockAuthService();
    authRepository = AuthRepository(authService: mockAuthService);
  });

  group('signIn', () {
    test('returns success on valid credentials', () async {
      when(
        () => mockAuthService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _fakeResponse);

      final result = await authRepository.signIn(
        email: 'a@b.com',
        password: 'pass123',
      );

      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    test('returns friendly message on invalid credentials', () async {
      when(
        () => mockAuthService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException('Invalid login credentials', statusCode: '400'),
      );

      final result = await authRepository.signIn(
        email: 'a@b.com',
        password: 'wrong',
      );

      expect(result.success, isFalse);
      expect(result.error, 'Email or password is incorrect.');
    });

    test('returns friendly message on duplicate signup', () async {
      when(
        () => mockAuthService.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException('User already registered', statusCode: '422'),
      );

      final result = await authRepository.signUp(
        email: 'a@b.com',
        password: 'pass123',
      );

      expect(result.success, isFalse);
      expect(result.error, 'An account already exists for this email.');
    });

    test('returns "already registered" when Supabase silently returns '
        'an existing-confirmed user (empty identities list)', () async {
      // Reproduces the silent-existing-user bug we caught comparing
      // MQ Navigation against the working Syllabus Sync signup. When
      // a confirmed email is re-submitted to `supabase_flutter.signUp`,
      // it returns a non-null `User` whose `identities` list is empty
      // and sends NO confirmation email. The repository must detect
      // this and surface a real error instead of letting the UI flash
      // the misleading "Account created! Check your email…" banner.
      final existingUser = User(
        id: 'existing-user-id',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        email: 'a@b.com',
        createdAt: DateTime.now().toIso8601String(),
        identities: const [],
      );
      when(
        () => mockAuthService.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => AuthResponse(user: existingUser, session: null),
      );

      final result = await authRepository.signUp(
        email: 'a@b.com',
        password: 'pass123',
      );

      expect(result.success, isFalse);
      expect(
        result.error,
        'An account already exists for this email. Please sign in instead.',
      );
    });

    test('returns friendly message on weak password', () async {
      when(
        () => mockAuthService.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException(
          'Password length should be at least 8 characters',
          statusCode: '422',
        ),
      );

      final result = await authRepository.signUp(
        email: 'a@b.com',
        password: '123',
      );

      expect(result.success, isFalse);
      expect(result.error, 'Password must be at least 8 characters.');
    });
  });

  group('isAuthenticated', () {
    test('delegates to auth service', () {
      when(() => mockAuthService.isAuthenticated).thenReturn(true);
      expect(authRepository.isAuthenticated, isTrue);

      when(() => mockAuthService.isAuthenticated).thenReturn(false);
      expect(authRepository.isAuthenticated, isFalse);
    });
  });

  group('signOut', () {
    test('delegates to auth service', () async {
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      await authRepository.signOut();

      verify(() => mockAuthService.signOut()).called(1);
    });
  });

  group('error mapping', () {
    test('returns email not confirmed message', () async {
      when(
        () => mockAuthService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException('Email not confirmed', statusCode: '400'),
      );

      final result = await authRepository.signIn(
        email: 'a@b.com',
        password: 'pass123',
      );

      expect(result.success, isFalse);
      expect(result.error, 'Please verify your email before signing in.');
    });

    test('returns catch-all message for unknown error', () async {
      when(
        () => mockAuthService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Some unknown error', statusCode: '500'));

      final result = await authRepository.signIn(
        email: 'a@b.com',
        password: 'pass123',
      );

      expect(result.success, isFalse);
      expect(result.error, 'Something went wrong. Please try again.');
    });

    test('returns network error on non-AuthException in signIn', () async {
      when(
        () => mockAuthService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('SocketException: connection refused'));

      final result = await authRepository.signIn(
        email: 'a@b.com',
        password: 'pass123',
      );

      expect(result.success, isFalse);
      expect(
        result.error,
        'Network error. Check your connection and try again.',
      );
    });

    test('returns network error on non-AuthException in signUp', () async {
      when(
        () => mockAuthService.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('SocketException: connection refused'));

      final result = await authRepository.signUp(
        email: 'a@b.com',
        password: 'pass123',
      );

      expect(result.success, isFalse);
      expect(
        result.error,
        'Network error. Check your connection and try again.',
      );
    });
  });
}
