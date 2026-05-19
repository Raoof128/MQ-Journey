import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/core/error/error_boundary.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/map/data/services/offline_maps_service.dart';
import 'package:mq_navigation/features/notifications/data/datasources/fcm_service.dart';

/// Initialises all critical services before the widget tree mounts.
///
/// Uses [runZonedGuarded] to catch any asynchronous errors that escape the
/// normal Flutter framework boundaries. This ensures errors during early startup
/// or background processes are logged correctly rather than crashing silently.
///
/// **Boot order — why this order matters:**
/// 1. WidgetsFlutterBinding  — required before any platform-channel call.
/// 2. Timezones              — pure Dart, no platform needed.
/// 3. Error handlers         — must be early so any SDK errors land here.
/// 4. EnvConfig.validate     — fast synchronous check; throws before any network.
/// 5. Firebase (optional)    — FCM background handler is registered here when
///                             Firebase is available.  If GoogleService-Info.plist
///                             (iOS) or google-services.json (Android) is absent,
///                             this step is silently skipped; the rest of the app
///                             continues normally on Supabase alone.
///                             A 5-second timeout prevents a hang when the plist
///                             is absent but the SDK still tries to reach servers.
/// 6. Supabase               — primary backend; may restore a cached session.
///                             A 10-second timeout prevents an indefinite block
///                             when the token-refresh network call stalls (e.g.
///                             on first standalone launch without cable / on a
///                             slow cell connection). supabase_flutter sets the
///                             singleton before any async work, so Supabase.instance
///                             is safe to use even when we time out — the GoRouter
///                             redirect simply treats the absent session as
///                             unauthenticated and sends the user to login.
/// 7. Offline maps backend   — ObjectBox FFI; non-critical, guarded by 8 s timeout.
/// 8. runApp                 — widget tree mounts; Riverpod providers start up.
Future<void> bootstrap(Widget Function() appBuilder) async {
  // Catch errors outside the Flutter framework.
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialise the timezone database so that any code calling
      // tz.getLocation() (e.g. OpenDayTime) works on all platforms,
      // including web where LocalNotificationsService is never initialised.
      tz.initializeTimeZones();

      // Install global error handlers.
      installErrorHandlers();
      // Validate required env vars.
      EnvConfig.validate();

      if (!kIsWeb) {
        try {
          // Firebase is used exclusively for FCM push notifications.
          // MQ Navigation's primary backend is Supabase; Firebase is optional.
          // If the native Firebase config file is absent (GoogleService-Info.plist
          // on iOS, google-services.json on Android), initializeApp() may hang
          // instead of throwing in AOT/Release mode — the 5-second timeout
          // ensures we always proceed. FcmService checks Firebase.apps.isNotEmpty
          // before touching any FCM API, so no FirebaseException can escape into
          // the widget tree.
          await Firebase.initializeApp().timeout(
            const Duration(seconds: 5),
          );
          FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler,
          );
          AppLogger.info('Firebase initialised');
        } catch (error, stackTrace) {
          AppLogger.warning(
            'Firebase initialisation skipped. FCM push notifications unavailable.',
            error,
            stackTrace,
          );
        }
      }

      // Initialise Supabase — the app's primary backend.
      //
      // WHY THIS CAN HANG IN RELEASE MODE:
      // supabase_flutter reads any cached session from the Keychain, then makes
      // a network call to refresh an expired access token before returning.
      // Without a cable/debugger the device uses its own network path and that
      // HTTP request can stall indefinitely on a weak or unavailable connection.
      // iOS's watchdog (~20 s) would eventually kill the process, but by then
      // the native red launch screen has been visible for the user for the entire
      // wait — because runApp() is never reached.
      //
      // The 10-second timeout is safe: supabase_flutter assigns Supabase._instance
      // synchronously before any async session work, so Supabase.instance is
      // usable even when we time out. The GoRouter redirect treats a missing
      // session as unauthenticated → /auth/login, which is the correct fallback.
      try {
        await Supabase.initialize(
          url: EnvConfig.supabaseUrl,
          anonKey: EnvConfig.supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        ).timeout(const Duration(seconds: 10));
        AppLogger.info('Supabase initialised', EnvConfig.appEnv);
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Supabase initialisation stalled — proceeding without cached session. '
          'User will be redirected to login if not authenticated.',
          error,
          stackTrace,
        );
      }

      // ObjectBox / FMTC initialisation is non-critical: the app functions
      // perfectly with online-only map tiles if it fails. We run it BEFORE
      // runApp so the tile provider is ready on first map render, but the
      // 8-second timeout in initializeBackend() ensures that a corrupted or
      // slow ObjectBox store cannot delay the first frame past iOS's watchdog
      // threshold (~20 s). Any native-level crash inside ObjectBox that bypasses
      // Dart's try/catch would still land in the zone error handler below.
      await const OfflineMapsService().initializeBackend();

      // Start the app wrapped in Riverpod's ProviderScope for state management
      // and a top-level ErrorBoundary to catch rendering exceptions.
      runApp(ProviderScope(child: ErrorBoundary(child: appBuilder())));
    },
    (error, stack) {
      AppLogger.error('Unhandled zone error', error, stack);
    },
  );
}
