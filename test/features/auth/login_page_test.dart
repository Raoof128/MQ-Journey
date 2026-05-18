import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/auth/data/repositories/auth_repository.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mq_navigation/features/auth/presentation/pages/login_page.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    when(() => mockRepository.isAuthenticated).thenReturn(false);
  });

  Widget buildTestApp({Widget? child}) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child ?? const LoginPage(),
      ),
    );
  }

  testWidgets('renders email and password fields', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(LoginPage));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.authEmailLabel), findsOneWidget);
    expect(find.text(l10n.authPasswordLabel), findsOneWidget);
    // Use findsAtLeastNWidgets(2) because "Sign In" appears as both page title and button label
    expect(find.text(l10n.authSignInButton), findsAtLeastNWidgets(2));
    expect(find.text('${l10n.authNoAccount} '), findsOneWidget);
    expect(find.text(l10n.authCreateOne), findsOneWidget);
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

    final BuildContext context = tester.element(find.byType(LoginPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
    // Targeted tap on the MqButton to avoid ambiguity with the title text
    await tester.tap(find.widgetWithText(MqButton, l10n.authSignInButton));
    await tester.pump();

    verify(
      () => mockRepository.signIn(email: 'a@b.com', password: 'pass123'),
    ).called(1);
  });

  testWidgets('shows error banner on auth failure', (tester) async {
    const errorMsg = 'Email or password is incorrect.';
    when(
      () => mockRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResult.failure(errorMsg));

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(LoginPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(MqButton, l10n.authSignInButton));
    await tester.pump();

    expect(find.text(errorMsg), findsOneWidget);
  });
}
