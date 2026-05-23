import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
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
        home: child ?? const SignupPage(),
      ),
    );
  }

  testWidgets('renders email, password, and confirm password fields', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(SignupPage));
    final l10n = AppLocalizations.of(context)!;

    // The form now uses the existing short-form l10n keys (which are
    // already translated in every ARB) rather than the `auth*` prefixed
    // keys (which were English placeholders in most locales).
    expect(find.text(l10n.email), findsOneWidget);
    expect(find.text(l10n.password), findsWidgets);
    expect(find.text(l10n.confirmPassword), findsOneWidget);
    expect(find.text(l10n.signUp), findsWidgets);
    expect(find.text('${l10n.authHasAccount} '), findsOneWidget);
  });

  testWidgets('shows error when passwords do not match', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(SignupPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await tester.tap(find.widgetWithText(MqButton, l10n.signUp));
    await tester.pump();

    expect(find.text(l10n.authErrorPasswordsDoNotMatch), findsOneWidget);
  });

  testWidgets('calls signUp on valid submit', (tester) async {
    when(
      () => mockRepository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResult.success());
    when(() => mockRepository.userId).thenReturn('user-1');

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(SignupPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass1234');
    await tester.enterText(find.byType(TextFormField).at(2), 'pass1234');
    await tester.tap(find.widgetWithText(MqButton, l10n.signUp));
    await tester.pump();

    verify(
      () => mockRepository.signUp(email: 'a@b.com', password: 'pass1234'),
    ).called(1);
  });
}
