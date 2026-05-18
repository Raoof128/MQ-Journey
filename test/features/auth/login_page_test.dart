import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mq_navigation/features/auth/data/repositories/auth_repository.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mq_navigation/features/auth/presentation/pages/login_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    when(() => mockRepository.isAuthenticated).thenReturn(false);
  });

  Widget buildTestApp() {
    return MaterialApp(
      home: ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
        child: const LoginPage(),
      ),
    );
  }

  testWidgets('renders email and password fields', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget);
  });

  testWidgets('calls signIn on submit', (tester) async {
    when(
      () => mockRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResult.success());
    when(() => mockRepository.userId).thenReturn('user-1');

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    verify(
      () => mockRepository.signIn(email: 'a@b.com', password: 'pass123'),
    ).called(1);
  });

  testWidgets('shows error banner on auth failure', (tester) async {
    when(
      () => mockRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => AuthResult.failure('Email or password is incorrect.'),
    );

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });
}
