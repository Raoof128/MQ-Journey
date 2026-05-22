import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/features/map/data/repositories/map_repository_impl.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/presentation/pages/map_page.dart';
import 'package:mq_navigation/features/map/data/datasources/location_source.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';

class _FakeSettingsController extends SettingsController {
  @override
  Future<UserPreferences> build() async =>
      const UserPreferences(defaultRenderer: MapRendererType.campus);
}

class _FakeMapRepository implements MapRepository {
  _FakeMapRepository({required this.buildings});

  final List<Building> buildings;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}

  @override
  Future<LocationPermissionState> ensureLocationPermission() async {
    return LocationPermissionState.granted;
  }

  @override
  Future<List<Building>> getBuildings({bool forceRefresh = false}) async {
    return buildings;
  }

  @override
  Future<LocationSample?> getCurrentLocation() async {
    return const LocationSample(latitude: -33.77388, longitude: 151.11275);
  }

  @override
  Future<MapRoute> getRoute({
    required MapRendererType renderer,
    required LocationSample origin,
    required Building destination,
    required TravelMode travelMode,
  }) async {
    return MapRoute(
      travelMode: travelMode,
      distanceMeters: 100,
      durationSeconds: 60,
      encodedPolyline: '',
      instructions: const [],
    );
  }

  @override
  Stream<LocationSample> watchLocation() => const Stream.empty();
}

void main() {
  final buildingA = Building.fromJson({
    'id': 'BLD-A',
    'code': 'BLDA',
    'name': 'Building A',
    'location': {'lat': -33.775, 'lng': 151.113},
    'category': 'academic',
  });

  final buildingB = Building.fromJson({
    'id': 'BLD-B',
    'code': 'BLDB',
    'name': 'Building B',
    'location': {'lat': -33.776, 'lng': 151.114},
    'category': 'academic',
  });

  late _FakeMapRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeMapRepository(buildings: [buildingA, buildingB]);
  });

  Widget buildTestApp({required GoRouter router}) {
    return ProviderScope(
      overrides: [
        mapRepositoryProvider.overrideWithValue(fakeRepository),
        settingsControllerProvider.overrideWith(
          () => _FakeSettingsController(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets(
    'MapPage parses meet coordinates, selects meet point, keeps path as /map, and preserves selection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/map',
        routes: [
          GoRoute(
            path: '/map',
            name: RouteNames.map,
            builder: (context, state) => MapPage(
              initialSearchQuery: state.uri.queryParameters['q'],
              meetLat: double.tryParse(state.uri.queryParameters['lat'] ?? ''),
              meetLng: double.tryParse(state.uri.queryParameters['lng'] ?? ''),
            ),
            routes: [
              GoRoute(
                path: 'building/:buildingId',
                name: RouteNames.buildingDetail,
                builder: (context, state) => MapPage(
                  initialBuildingId: state.pathParameters['buildingId'],
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final element = tester.element(find.byType(MapPage));
      final container = ProviderScope.containerOf(element);

      // Navigate to meet coordinates
      router.go('/map?lat=-33.77380&lng=151.11260');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Expect a meet point building to be selected
      final selected = container
          .read(mapControllerProvider)
          .value!
          .selectedBuilding;
      expect(selected, isNotNull);
      expect(selected!.id, startsWith('meet_'));
      expect(selected.latitude, equals(-33.77380));
      expect(selected.longitude, equals(151.11260));

      // Route path should remain /map (with query params) rather than pushing buildingDetail path
      expect(router.routeInformationProvider.value.uri.path, equals('/map'));

      // Re-trigger pump to ensure post-frame callback back-navigation detector does not clear it
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        container.read(mapControllerProvider).value!.selectedBuilding?.id,
        startsWith('meet_'),
      );
    },
  );

  testWidgets('MapPage selects building via query param and keeps /map path', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/map',
      routes: [
        GoRoute(
          path: '/map',
          name: RouteNames.map,
          builder: (context, state) => MapPage(
            initialBuildingId: state.uri.queryParameters['building'],
            initialSearchQuery: state.uri.queryParameters['q'],
            meetLat: double.tryParse(state.uri.queryParameters['lat'] ?? ''),
            meetLng: double.tryParse(state.uri.queryParameters['lng'] ?? ''),
          ),
          routes: [
            GoRoute(
              path: 'building/:buildingId',
              name: RouteNames.buildingDetail,
              builder: (context, state) => MapPage(
                initialBuildingId: state.pathParameters['buildingId'],
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(buildTestApp(router: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final element = tester.element(find.byType(MapPage));
    final container = ProviderScope.containerOf(element);

    // Navigate to select building via query param
    router.go('/map?building=BLD-A');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Expect Building A to be selected
    final selected = container
        .read(mapControllerProvider)
        .value!
        .selectedBuilding;
    expect(selected, isNotNull);
    expect(selected!.id, equals('BLD-A'));
    expect(selected.code, equals('BLDA'));

    // Route path should remain /map (with query params) rather than pushing buildingDetail path
    expect(router.routeInformationProvider.value.uri.path, equals('/map'));

    // Verify selection is preserved after re-pump (post-frame back-navigation
    // detector should not clear it because building query param is present)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      container.read(mapControllerProvider).value!.selectedBuilding?.id,
      equals('BLD-A'),
    );
  });

  testWidgets(
    'MapPage selects building and loads route preview when preview=route query param is set',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/map',
        routes: [
          GoRoute(
            path: '/map',
            name: RouteNames.map,
            builder: (context, state) => MapPage(
              initialBuildingId: state.uri.queryParameters['building'],
              autoPreviewRoute: state.uri.queryParameters['preview'] == 'route',
              initialSearchQuery: state.uri.queryParameters['q'],
              meetLat: double.tryParse(state.uri.queryParameters['lat'] ?? ''),
              meetLng: double.tryParse(state.uri.queryParameters['lng'] ?? ''),
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final element = tester.element(find.byType(MapPage));
      final container = ProviderScope.containerOf(element);

      // Navigate to select building and start navigation via query param
      router.go('/map?building=BLD-A&preview=route');
      await tester.pump();
      // Wait for the async post-frame callback (loadRoute)
      await tester.pump(const Duration(milliseconds: 200));

      final mapState = container.read(mapControllerProvider).value!;
      expect(mapState.selectedBuilding?.id, equals('BLD-A'));
      expect(mapState.route, isNotNull);
      expect(mapState.isNavigating, isFalse);
    },
  );

  testWidgets(
    'MapPage loads route preview on building already selected when preview=route is set',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = GoRouter(
        initialLocation: '/map',
        routes: [
          GoRoute(
            path: '/map',
            name: RouteNames.map,
            builder: (context, state) => MapPage(
              initialBuildingId: state.uri.queryParameters['building'],
              autoPreviewRoute: state.uri.queryParameters['preview'] == 'route',
              initialSearchQuery: state.uri.queryParameters['q'],
              meetLat: double.tryParse(state.uri.queryParameters['lat'] ?? ''),
              meetLng: double.tryParse(state.uri.queryParameters['lng'] ?? ''),
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final element = tester.element(find.byType(MapPage));
      final container = ProviderScope.containerOf(element);

      // First navigate to select the building without previewing the route
      router.go('/map?building=BLD-A');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      var mapState = container.read(mapControllerProvider).value!;
      expect(mapState.selectedBuilding?.id, equals('BLD-A'));
      expect(mapState.route, isNull);
      expect(mapState.isNavigating, isFalse);

      // Now navigate with preview=route on the already selected building
      router.go('/map?building=BLD-A&preview=route');
      await tester.pump();
      // Wait for the async post-frame callback to trigger loadRoute
      await tester.pump(const Duration(milliseconds: 200));

      mapState = container.read(mapControllerProvider).value!;
      expect(mapState.selectedBuilding?.id, equals('BLD-A'));
      expect(mapState.route, isNotNull);
      expect(mapState.isNavigating, isFalse);
    },
  );
}
