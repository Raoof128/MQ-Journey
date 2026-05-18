import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/auth/data/repositories/auth_repository.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mq_navigation/features/favorites/data/repositories/favorite_building_repository.dart';
import 'package:mq_navigation/features/favorites/domain/entities/favorite_building.dart';
import 'package:mq_navigation/features/favorites/presentation/controllers/favorites_controller.dart';
import 'package:mq_navigation/features/map/presentation/pages/favorites_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFavoriteBuildingRepository extends Mock
    implements FavoriteBuildingRepository {}

final _now = DateTime.now();

final _sampleFav = FavoriteBuilding(
  id: 'fav-1',
  userId: 'user-1',
  buildingId: 'BLD',
  buildingName: 'Library',
  note: null,
  createdAt: _now,
  updatedAt: _now,
);

final _sampleFav2 = FavoriteBuilding(
  id: 'fav-2',
  userId: 'user-1',
  buildingId: 'SCI',
  buildingName: 'Science Building',
  note: null,
  createdAt: _now,
  updatedAt: _now,
);

Widget buildApp({
  required AuthRepository authRepository,
  required FavoriteBuildingRepository favRepository,
}) {
  final router = GoRouter(
    initialLocation: '/favorites',
    routes: [
      GoRoute(path: '/favorites', builder: (_, __) => FavoritesPage()),
      GoRoute(
        path: '/map/building/:buildingId',
        builder: (_, state) => Scaffold(
          body: Text('Building ${state.pathParameters['buildingId']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      favoriteBuildingRepositoryProvider.overrideWithValue(favRepository),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockFavoriteBuildingRepository mockFavRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockFavRepo = MockFavoriteBuildingRepository();
    when(() => mockAuthRepo.userId).thenReturn('user-1');
  });

  testWidgets('shows loading indicator immediately', (tester) async {
    // The load is called in initState via postFrameCallback.
    // Since the controller starts with isLoading=false, the loading
    // spinner only shows while load() is in-flight. We test that
    // the spinner appears by not completing the fetchAll future.
    late Completer<void> neverComplete;
    neverComplete = Completer<void>();
    when(() => mockFavRepo.fetchAll(userId: any(named: 'userId'))).thenAnswer(
      (_) => neverComplete.future.then((_) => FavoritesResult.success([])),
    );

    await tester.pumpWidget(
      buildApp(authRepository: mockAuthRepo, favRepository: mockFavRepo),
    );
    // First pump: build, postFrameCallback schedules load
    await tester.pump();
    // Second pump: load starts, isLoading transitions through true
    await tester.pump();

    // The load is in-flight so isLoading should be true
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    when(() => mockFavRepo.fetchAll(userId: any(named: 'userId'))).thenAnswer(
      (_) async => FavoritesResult.failure('Could not load favorites.'),
    );

    await tester.pumpWidget(
      buildApp(authRepository: mockAuthRepo, favRepository: mockFavRepo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Could not load favorites.'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });

  testWidgets('shows empty state when no favorites', (tester) async {
    when(
      () => mockFavRepo.fetchAll(userId: any(named: 'userId')),
    ).thenAnswer((_) async => FavoritesResult.success([]));

    await tester.pumpWidget(
      buildApp(authRepository: mockAuthRepo, favRepository: mockFavRepo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });

  testWidgets('shows list of favorited buildings', (tester) async {
    when(() => mockFavRepo.fetchAll(userId: any(named: 'userId'))).thenAnswer(
      (_) async => FavoritesResult.success([_sampleFav, _sampleFav2]),
    );

    await tester.pumpWidget(
      buildApp(authRepository: mockAuthRepo, favRepository: mockFavRepo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Science Building'), findsOneWidget);
    expect(find.text('BLD'), findsOneWidget);
    expect(find.text('SCI'), findsOneWidget);
  });

  testWidgets('retry button reloads on error state', (tester) async {
    when(() => mockFavRepo.fetchAll(userId: any(named: 'userId'))).thenAnswer(
      (_) async => FavoritesResult.failure('Could not load favorites.'),
    );

    await tester.pumpWidget(
      buildApp(authRepository: mockAuthRepo, favRepository: mockFavRepo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Could not load favorites.'), findsOneWidget);

    when(
      () => mockFavRepo.fetchAll(userId: any(named: 'userId')),
    ).thenAnswer((_) async => FavoritesResult.success([_sampleFav]));

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Library'), findsOneWidget);
  });
}
