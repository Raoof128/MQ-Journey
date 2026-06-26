import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mq_journey/app/l10n/generated/app_localizations.dart';
import 'package:mq_journey/features/auth/data/repositories/auth_repository.dart';
import 'package:mq_journey/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mq_journey/features/auth/presentation/pages/reset_password_page.dart';
import 'package:mq_journey/shared/widgets/mq_button.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    when(() => mockRepository.isAuthenticated).thenReturn(true);
    when(() => mockRepository.userId).thenReturn('user-123');
  });

  Widget buildTestApp() {
    final router = GoRouter(
      initialLocation: '/auth/reset-password',
      routes: [
        GoRoute(
          path: '/auth/reset-password',
          builder: (_, _) => const ResetPasswordPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (_, _) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets('renders reset password page fields', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(ResetPasswordPage));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.newPassword), findsOneWidget);
    expect(find.text(l10n.confirmNewPassword), findsOneWidget);
    expect(find.widgetWithText(MqButton, l10n.resetPassword), findsOneWidget);
  });

  testWidgets('shows validation error for weak password', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(ResetPasswordPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(find.byType(TextFormField).at(0), 'short');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.widgetWithText(MqButton, l10n.resetPassword));
    await tester.pump();

    expect(find.text(l10n.authErrorWeakPassword), findsOneWidget);
  });

  testWidgets('shows validation error for password mismatch', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(ResetPasswordPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(find.byType(TextFormField).at(0), 'pass12345');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass54321');
    await tester.tap(find.widgetWithText(MqButton, l10n.resetPassword));
    await tester.pump();

    expect(find.text(l10n.authErrorPasswordsDoNotMatch), findsOneWidget);
  });

  testWidgets('calls updatePassword on success', (tester) async {
    when(
      () =>
          mockRepository.updatePassword(newPassword: any(named: 'newPassword')),
    ).thenAnswer((_) async => AuthResult.success());

    await tester.pumpWidget(buildTestApp());
    await tester.pump();

    final BuildContext context = tester.element(find.byType(ResetPasswordPage));
    final l10n = AppLocalizations.of(context)!;

    await tester.enterText(find.byType(TextFormField).at(0), 'pass12345');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass12345');
    await tester.tap(find.widgetWithText(MqButton, l10n.resetPassword));
    await tester.pump();

    verify(
      () => mockRepository.updatePassword(newPassword: 'pass12345'),
    ).called(1);
  });
}
