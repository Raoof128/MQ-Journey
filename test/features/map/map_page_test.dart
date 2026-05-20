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
    'MapPage selects building on initialization and updates on didUpdateWidget',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/map',
        routes: [
          GoRoute(
            path: '/map',
            name: RouteNames.map,
            builder: (context, state) => MapPage(
              initialBuildingId: state.uri.queryParameters['buildingId'],
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

      // Verify MapPage loaded and controller initialized
      final element = tester.element(find.byType(MapPage));
      final container = ProviderScope.containerOf(element);

      // Initial state: no building selected
      var mapState = container.read(mapControllerProvider).value!;
      expect(mapState.selectedBuilding, isNull);

      // Navigate to building A
      router.goNamed(
        RouteNames.buildingDetail,
        pathParameters: {'buildingId': 'BLD-A'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Expect building A to be selected now
      mapState = container.read(mapControllerProvider).value!;
      expect(mapState.selectedBuilding?.id, equals('BLD-A'));

      // Navigate to building B
      router.goNamed(
        RouteNames.buildingDetail,
        pathParameters: {'buildingId': 'BLD-B'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Expect building B to be selected now (didUpdateWidget triggered)
      mapState = container.read(mapControllerProvider).value!;
      expect(mapState.selectedBuilding?.id, equals('BLD-B'));

      // Deselect (simulate clearing selection in controller)
      container.read(mapControllerProvider.notifier).clearSelection();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // GoRouter path should sync back to /map
      expect(router.routeInformationProvider.value.uri.path, equals('/map'));

      // Navigate to building A again
      router.goNamed(
        RouteNames.buildingDetail,
        pathParameters: {'buildingId': 'BLD-A'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        container.read(mapControllerProvider).value!.selectedBuilding?.id,
        equals('BLD-A'),
      );

      // Simulate back navigation to /map
      router.goNamed(RouteNames.map);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Selected building should be cleared and no navigation loop should push it back
      expect(
        container.read(mapControllerProvider).value!.selectedBuilding,
        isNull,
      );
      expect(router.routeInformationProvider.value.uri.path, equals('/map'));
    },
  );

  testWidgets(
    'MapPage parses meet coordinates, selects meet point, keeps path as /map, and preserves selection',
    (tester) async {
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
}
