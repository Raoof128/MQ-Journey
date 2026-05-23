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

    // The form now uses the existing short-form l10n keys (which are
    // already translated in every ARB) rather than the `auth*` prefixed
    // keys (which were English placeholders in most locales).
    expect(find.text(l10n.email), findsOneWidget);
    expect(find.text(l10n.password), findsOneWidget);
    // "Sign In" still appears twice — as the page title (l10n.authLoginTitle)
    // and as the button label (l10n.signIn). They happen to render the
    // same English text but are different translation keys.
    expect(find.text(l10n.signIn), findsAtLeastNWidgets(1));
    expect(find.text('${l10n.noAccount} '), findsOneWidget);
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
    await tester.tap(find.widgetWithText(MqButton, l10n.signIn));
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
    await tester.tap(find.widgetWithText(MqButton, l10n.signIn));
    await tester.pump();

    expect(find.text(errorMsg), findsOneWidget);
  });
}
