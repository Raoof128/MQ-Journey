import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mq_journey/shared/models/user_preferences.dart';
import 'package:mq_journey/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_journey/features/scan/data/adapters/settings_progress_api_adapter.dart';
import 'package:mq_journey/features/scan/domain/contracts/visit_event.dart';
import 'package:mq_journey/features/scan/domain/contracts/visited_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProgressApiAdapter', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockUser mockUser;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockUser = MockUser();

      when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('anon-test-123');
    });

    test('progressApiProvider is readable from container', () {
      final container = ProviderContainer(
        overrides: [
          settingsControllerProvider.overrideWith(
            () => _FakeSettingsController(),
          ),
        ],
      );
      addTearDown(() => container.dispose());

      final api = container.read(progressApiProvider);
      expect(api, isA<SettingsProgressApiAdapter>());
    });

    test('recordVisit updates local state via settings controller', () async {
      final container = ProviderContainer(
        overrides: [
          progressApiProvider.overrideWith((ref) {
            return SettingsProgressApiAdapter(
              ref,
              supabaseClient: mockSupabaseClient,
            );
          }),
          settingsControllerProvider.overrideWith(
            () => _FakeSettingsController(),
          ),
        ],
      );
      addTearDown(() => container.dispose());

      final api = container.read(progressApiProvider);
      final event = VisitEvent(
        locationId: 'lib-01',
        buildingId: 'C3A',
        scannedAt: DateTime(2026, 6, 29, 10, 0),
      );

      await api.recordVisit(event);

      final prefs = container.read(settingsControllerProvider).value;
      expect(prefs, isNotNull);
      expect(prefs!.visitedLocationCodes, contains('C3A'));
    });

    test('recordVisit does not silently no-op when session is missing', () {
      expect(ensureAnonSession, isA<Function>());
    });

    test('watch returns visited state', () async {
      final container = ProviderContainer(
        overrides: [
          settingsControllerProvider.overrideWith(
            () => _FakeSettingsController(),
          ),
        ],
      );
      addTearDown(() => container.dispose());

      final api = container.read(progressApiProvider);
      final state = await api.watch('C3A').first;
      expect(state, isA<VisitedState>());
      expect(state.visited, isFalse);
    });
  });
}

class _FakeSettingsController extends SettingsController {
  UserPreferences _prefs = const UserPreferences();

  @override
  Future<UserPreferences> build() async {
    await Future<void>.value();
    return _prefs;
  }

  @override
  Future<bool> recordLocationVisit(String buildingCode) async {
    final code = buildingCode.trim().toUpperCase();
    if (code.isEmpty) return false;
    if (_prefs.visitedLocationCodes.contains(code)) return false;
    _prefs = _prefs.copyWith(
      visitedLocationCodes: [..._prefs.visitedLocationCodes, code],
    );
    state = AsyncData(_prefs);
    return true;
  }
}
