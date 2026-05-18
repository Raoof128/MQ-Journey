import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mq_navigation/features/auth/data/repositories/auth_repository.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mq_navigation/features/auth/presentation/pages/signup_page.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';

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
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const SignupPage(),
      ),
    );
  }

  testWidgets('renders email, password, and confirm password fields', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsWidgets);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Already have an account? '), findsOneWidget);
  });

  testWidgets('shows error when passwords do not match', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await tester.tap(find.widgetWithText(MqButton, 'Create Account'));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('calls signUp on valid submit', (tester) async {
    when(() => mockRepository.signUp(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => AuthResult.success());
    when(() => mockRepository.userId).thenReturn('user-1');

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass1234');
    await tester.enterText(find.byType(TextFormField).at(2), 'pass1234');
    await tester.tap(find.widgetWithText(MqButton, 'Create Account'));
    await tester.pump();

    verify(() => mockRepository.signUp(email: 'a@b.com', password: 'pass1234')).called(1);
  });
}
