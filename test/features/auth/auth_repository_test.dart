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
}
