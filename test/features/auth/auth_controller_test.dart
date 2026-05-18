import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mq_navigation/features/auth/data/repositories/auth_repository.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

ProviderContainer makeContainer(AuthRepository repository) {
  return ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    when(() => mockRepository.isAuthenticated).thenReturn(false);
  });

  group('signIn', () {
    test('emits authenticated state on success', () async {
      when(() => mockRepository.isAuthenticated).thenReturn(false);
      when(() => mockRepository.userId).thenReturn('user-1');
      when(
        () => mockRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResult.success());

      final container = makeContainer(mockRepository);
      addTearDown(() => container.dispose());
      final controller = container.read(authControllerProvider.notifier);

      await controller.signIn(email: 'a@b.com', password: 'pass');

      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      expect(container.read(authControllerProvider).userId, 'user-1');
      expect(container.read(authControllerProvider).isLoading, isFalse);
    });

    test('emits error state on failure', () async {
      when(
        () => mockRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => AuthResult.failure('Email or password is incorrect.'),
      );

      final container = makeContainer(mockRepository);
      addTearDown(() => container.dispose());
      final controller = container.read(authControllerProvider.notifier);

      await controller.signIn(email: 'a@b.com', password: 'wrong');

      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
      expect(
        container.read(authControllerProvider).error,
        'Email or password is incorrect.',
      );
      expect(container.read(authControllerProvider).isLoading, isFalse);
    });
  });

  group('signUp', () {
    test('emits authenticated state on success', () async {
      when(() => mockRepository.isAuthenticated).thenReturn(false);
      when(() => mockRepository.userId).thenReturn('user-1');
      when(
        () => mockRepository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResult.success());

      final container = makeContainer(mockRepository);
      addTearDown(() => container.dispose());
      final controller = container.read(authControllerProvider.notifier);

      await controller.signUp(email: 'a@b.com', password: 'pass');

      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      expect(container.read(authControllerProvider).isLoading, isFalse);
    });

    test('emits error state on failure', () async {
      when(
        () => mockRepository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async =>
            AuthResult.failure('An account already exists for this email.'),
      );

      final container = makeContainer(mockRepository);
      addTearDown(() => container.dispose());
      final controller = container.read(authControllerProvider.notifier);

      await controller.signUp(email: 'a@b.com', password: 'pass');

      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
      expect(
        container.read(authControllerProvider).error,
        'An account already exists for this email.',
      );
    });
  });

  group('signOut', () {
    test('resets to initial state', () async {
      when(() => mockRepository.signOut()).thenAnswer((_) async {});
      when(() => mockRepository.isAuthenticated).thenReturn(false);

      final container = makeContainer(mockRepository);
      addTearDown(() => container.dispose());
      final controller = container.read(authControllerProvider.notifier);

      await controller.signOut();

      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    });
  });

  group('clearError', () {
    test('clears error without affecting isLoading', () async {
      when(
        () => mockRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResult.failure('Something went wrong.'));

      final container = makeContainer(mockRepository);
      addTearDown(() => container.dispose());
      final controller = container.read(authControllerProvider.notifier);

      await controller.signIn(email: 'a@b.com', password: 'wrong');
      expect(container.read(authControllerProvider).error, isNotNull);

      controller.clearError();

      expect(container.read(authControllerProvider).error, isNull);
    });

    test('keeps isAuthenticated unchanged after clear', () async {
      when(() => mockRepository.isAuthenticated).thenReturn(true);
      when(() => mockRepository.userId).thenReturn('user-1');

      final container = makeContainer(mockRepository);
      addTearDown(() => container.dispose());
      final controller = container.read(authControllerProvider.notifier);

      controller.clearError();

      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    });
  });

  group('loading state', () {
    test('sets isLoading true during signIn', () async {
      when(() => mockRepository.isAuthenticated).thenReturn(false);
      when(() => mockRepository.userId).thenReturn('user-1');
      when(
        () => mockRepository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 1));
        return AuthResult.success();
      });

      final container = makeContainer(mockRepository);
      addTearDown(() => container.dispose());
      final controller = container.read(authControllerProvider.notifier);

      final future = controller.signIn(email: 'a@b.com', password: 'pass');

      expect(container.read(authControllerProvider).isLoading, isTrue);

      await future;
      expect(container.read(authControllerProvider).isLoading, isFalse);
    });
  });
}
