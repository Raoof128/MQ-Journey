# MQ Journey — Repository Map

## 1. Overview

MQ Journey is a Flutter mobile app for Macquarie University's Open Day, providing campus navigation with an illustrated `flutter_map`-based campus map, building search, QR code scanning for Open Day trail locations, indoor 360° previews (Pannellum via WebView), Open Day schedule/session browsing, a "Your Day" itinerary planner, gamified visit tracking, 35-language i18n, transit (TfNSW metro) departures, campus safety toolkit, and push notifications via FCM. The app uses Supabase as its backend with anonymous-only auth and RLS.

## 2. Tech Stack & Versions

| Package | Version | Purpose |
|---|---|---|
| Dart SDK | `^3.11.0` | Language SDK floor |
| Flutter | SDK dep | UI framework |
| `supabase_flutter` | `^2.12.0` | Backend (auth, DB, realtime, RLS) |
| `firebase_core` | `^4.2.0` | Firebase bootstrap (FCM) |
| `flutter_riverpod` | `^3.2.1` | State management (AsyncNotifier, FutureProvider, Provider.family, StreamProvider) |
| `go_router` | `^17.1.0` | Declarative routing with StatefulShellRoute (3-tab) |
| `intl` | `^0.20.2` | i18n + ARB codegen |
| `flutter_map` | `^8.3.0` | Illustrated 2D campus map (CrsSimple, non-geographic) |
| `flutter_map_tile_caching` | `^10.1.1` | Offline map tile caching |
| `latlong2` | `^0.9.1` | LatLng/bounds types for flutter_map |
| `geolocator` | `^14.0.2` | GPS location |
| `permission_handler` | `^12.0.1` | Runtime permissions |
| `flutter_secure_storage` | `^10.0.0` | Encrypted key-value (iOS Keychain / Android Keystore) |
| `firebase_messaging` | `^16.1.2` | FCM push notifications |
| `flutter_local_notifications` | `^21.0.0` | Local notification scheduling |
| `mobile_scanner` | `^7.0.0` | QR/barcode scanner (camera) |
| `flutter_inappwebview` | `^6.1.5` | In-app WebView for Pannellum indoor 360° |
| `flutter_compass` | `^0.8.1` | Device compass heading |
| `torch_light` | `^1.1.0` | Flashlight toggle (safety toolkit) |
| `url_launcher` | `^6.3.1` | Phone, maps, street view external links |
| `share_plus` | `^12.0.2` | Share sheet (meet point URIs) |
| `app_links` | `^7.0.0` | Deep-link handling |
| `connectivity_plus` | `^7.0.0` | Network connectivity monitoring |
| `http` | `^1.4.0` | TfNSW API client |
| `logger` | `^2.5.0` | Structured logging |
| `icalendar_parser` | `^2.1.0` | iCal timetable parsing |
| `shared_preferences` | `^2.5.0` | Desktop/web fallback for SecureStorage |
| `timezone` | `^0.11.0` | Timezone DB (tzdata) |
| `mocktail` | `^1.0.4` | (dev) Test mocking |
| `flutter_lints` | `^6.0.0` | (dev) Lint rules |

## 3. Top-Level Layout

```
mq_journey/
├── AGENT.md                         # Agent rules (constraints, conventions)
├── CHANGELOG.md                     # Change log (Raouf: entries)
├── l10n.yaml                        # ARB config → lib/app/l10n/generated/
├── pubspec.yaml                     # Dependencies, assets, SDK floor ^3.11.0
├── analysis_options.yaml            # Lint rules (flutter_lints, prefer_single_quotes, etc.)
├── scripts/
│   ├── check.sh                     # 12-step CI gate (pub get → analyze → test → l10n → privacy → secrets → build)
│   ├── run.sh                       # .env-driven launcher with platform config injection
│   └── sync_supabase_secrets.sh     # Pushes .env keys → supabase secrets
├── assets/
│   ├── data/                        # JSON data files (buildings, campus_overlay_meta, open_day, open_day_trail)
│   ├── images/                      # app_logo, mq_logo, campus_background, login_background
│   ├── maps/                        # mq-campus.png, overlay_*.png (accessibility, parking, permits, water)
│   └── web/                         # indoor_viewer.html (Pannellum)
├── lib/
│   ├── main.dart                    # Entry: bootstrap(() => MqJourneyApp())
│   ├── app/
│   │   ├── bootstrap/               # bootstrap.dart (sync init) + app_initialization.dart (async Riverpod provider)
│   │   ├── router/                  # app_router.dart (GoRouter), route_names.dart, app_shell.dart (3-tab shell)
│   │   ├── theme/                   # MQ design tokens (colors, typography, spacing, animations)
│   │   └── l10n/                    # 35 ARB files + generated/ output
│   ├── core/
│   │   ├── config/                  # EnvConfig (--dart-define)
│   │   ├── error/                   # AppException, ErrorBoundary
│   │   ├── logging/                 # AppLogger
│   │   ├── network/                 # ConnectivityService, session_guard.dart
│   │   ├── security/                # SecureStorageService (Keychain + SharedPreferences fallback)
│   │   └── utils/                   # Result<T>, MqHaptics
│   ├── shared/
│   │   ├── widgets/                 # MqButton, MqCard, MqInput, MqBottomSheet, MqAppBar, GlassPane, MqTactileButton
│   │   ├── models/                  # UserPreferences (all persisted prefs)
│   │   └── extensions/              # BuildContext extensions (isDarkMode, textTheme, etc.)
│   └── features/
│       ├── auth/                    # Auth (pruned to anonymous-only)
│       ├── deep_link/               # Deep link contract (/open parser)
│       ├── home/                    # HomePage, OnboardingPage
│       ├── map/                     # Campus map (flutter_map), building search, routing, compass mode
│       ├── notifications/           # FCM + local notification scheduling
│       ├── open_day/                # Open Day data, personalisation, gamification, sessions
│       ├── safety/                  # Safety toolkit (emergency contacts, AED, shuttle, flashlight)
│       ├── scan/                    # QR scanner, indoor preview, location card, trail/buildings/indoor repos
│       ├── settings/                # Settings controller + repository (all local prefs persisted)
│       ├── favorites/               # Favorite buildings (Supabase-backed)
│       ├── timetable/               # iCal timetable parsing
│       └── transit/                 # TfNSW metro departures
├── test/
│   ├── app/                        # Theme + route name tests
│   ├── core/                       # Config, exception, error_boundary, result tests
│   ├── shared/                     # Widget tests
│   ├── features/                   # Per-feature test subdirs
│   └── widget_test.dart            # Smoke test
├── supabase/
│   ├── migrations/                 # SQL migrations (initial_schema, RLS, open_day_stamps, etc.)
│   └── functions/                  # Edge Functions (cleanup-cron, etc.)
```

## 4. Architecture & Conventions

### Layering
Every feature follows `domain/ → data/ → presentation/`:
- **`domain/`**: Pure Dart entities, services, abstract interfaces (contracts), value types. Zero Flutter/Riverpod imports.
- **`data/`**: `repositories/` (implement domain contracts), `datasources/` (JSON assets, Supabase, FCM), `services/` (offline maps, TfNSW), `adapters/` (bridge domain contracts to existing providers), `mappers/` (projection codec).
- **`presentation/`**: `pages/` (ConsumerWidget/ConsumerStatefulWidget), `widgets/` (reusable UI), `controllers/` (AsyncNotifier).

### State management
- **Riverpod 3.x**: `AsyncNotifierProvider` for async-mutable state (SettingsController, MapController). `FutureProvider` for one-shot loads (openDayDataProvider, trailManifestProvider). `Provider` for sync-derivations (selectedBachelorProvider, suggestedStopsProvider). `Provider.family` for parameterised providers (locationLiveStatusProvider, indoorManifestProvider). `StreamProvider.family` for reactive streams (visitedStateProvider). `Provider` (not `AsyncNotifier`) for abstract-interface wiring (progressApiProvider, scheduleProvider).
- Controllers are `AsyncNotifier` subclasses. The `build()` method loads initial state and starts side-effect listeners. Mutation methods read current state via `state.value`, produce new state via `state = AsyncData(...)`, and use copyWith pattern.
- All state objects are `@immutable` with `==`/`hashCode` overrides for Riverpod reactivity.

### Error handling
- `AsyncValue.error` channel for data-provider errors (Open Day data, map loading).
- `MapStateError` enum for location/routing errors surfaced as map banner.
- `SettingsController._save()` rolls back state on persistence failure.
- `ErrorBoundary` wraps the full app at bootstrap.
- `AppLogger.error/warning/info/debug` structured logging.

### Naming
- snake_case filenames matching class name.
- Providers: `fooProvider`, `fooControllerProvider`.
- Route names: `RouteNames.camelCase` constants.
- ARB keys: `camelCase` with area prefix (e.g. `home_scanQrCta`, `openDay_privacyStrip`).
- DB columns: lowercase_snake_case.
- Test files: mirror lib path with `_test.dart` suffix.

### Worked example: Open Day Live Status for a scanned location

```
Route: /location/:locationId  (route_names.dart:25)
  → LocationCardPage (scan/presentation/pages/location_card_page.dart:14)
    → watches locationContentProvider(locationId) (scan_providers.dart:37-39)
    → watches scheduleProvider (scan_providers.dart:41-46)
    → watches visitedStateProvider(locationId) (scan_providers.dart:50-53)
      → progressApiProvider.watch() (settings_progress_api_adapter.dart:51-66)
        → reads settingsControllerProvider.value.visitedLocationCodes
    → schedule.liveNow(locationId) delegates to...
      → OpenDayScheduleProviderAdapter (open_day_schedule_provider_adapter.dart:17-23)
        → OpenDayPersonalisation.liveStatusForLocation() (open_day_personalisation.dart:93-103)
          → OpenDayEvent (open_day_data.dart:55-100)
    → _ActionButtons uses myDayApiProvider.addToDay() (my_day_api.dart:3-5)
```

## 5. Routing Map

| Route Name | Path | Params | Builds Widget | File:Line |
|---|---|---|---|---|
| `home` | `/home` | — | `HomePage` | `app_router.dart:151-154` |
| `map` | `/map` | `?building`, `?q`, `?lat`, `?lng` | `MapPage` | `app_router.dart:162-171` |
| `buildingDetail` | `/map/building/:buildingId` | `buildingId` | `MapPage` | `app_router.dart:173-179` |
| `indoorPreview` | `/map/building/:buildingId/indoor` | `buildingId` | `IndoorPreviewPage` | `app_router.dart:181-186` |
| `settings` | `/settings` | `?section` | `SettingsPage` | `app_router.dart:193-199` |
| `scan` | `/scan` | — | `ScanPage` | `app_router.dart:131-134` |
| `locationDetail` | `/location/:locationId` | `locationId` | `LocationCardPage` | `app_router.dart:137-142` |
| `notifications` | `/notifications` | — | `NotificationsPage` | `app_router.dart:92-95` |
| `openDay` | `/open-day` | — | `OpenDayPage` | `app_router.dart:101-104` |
| `yourDay` | `/your-day` | — | `YourDayPage` | `app_router.dart:106-109` |
| `onboarding` | `/onboarding` | — | `OnboardingPage` | `app_router.dart:111-114` |
| `safetyToolkit` | `/safety` | — | `SafetyToolkitPage` | `app_router.dart:119-122` |
| `favorites` | `/favorites` | — | `FavoritesPage` | `app_router.dart:125-128` |
| `meet` | `/meet` | `?lat`, `?lng` | redirects → `/map` | `app_router.dart:80-90` |
| `/open` | `/open` | `destination`, `q`, `lat`, `lng` | redirects → map routes | `app_router.dart:63-77` |

**Shell structure**: 3-tab `StatefulShellRoute.indexedStack` — Home, Map, Settings (`app_shell.dart:17-51`). Notifications, Safety, Open Day, Favorites, Scan sit **outside** the shell (full-screen routes).

## 6. Feature Inventory

### `auth/` (pruned)
- **Purpose**: Anonymous-only auth (login/signup/reset removed).
- **Key symbols**: `AuthService` (`auth_service.dart:1`), `AuthRepository` (`auth_repository.dart:34`), `AuthController` (`auth_controller.dart:17`).
- **Relevance to QR work**: `AuthService.signInAnonymously()` is used by session guard — not needed for scan directly.

### `deep_link/`
- **Purpose**: `/open` URL parser contract for sister apps.
- **Key symbols**: `parseMqNavDeepLink()` (`deep_link_contract.dart:72`), `DeepLinkBuilding`, `DeepLinkSearch`, `DeepLinkMeetAt`.
- **Relevance**: Not directly.

### `home/`
- **Purpose**: Welcome hub with hero section (MQ logo + QR CTA button), Open Day personalised sections, metro countdown, quick access tiles.
- **Key symbols**: `HomePage` (`home_page.dart:34`), `OnboardingPage` (`onboarding_page.dart:28`).
- **QR relevance**: `HomePage._HeroSection` renders the QR CTA button → `context.goNamed(RouteNames.scan)` at `home_page.dart:682`.

### `map/`
- **Purpose**: Illustrated campus map (flutter_map + CrsSimple), 153 buildings, search, route planning, compass mode.
- **Key symbols**: `MapPage` (`map_page.dart:21`), `MapController` (`map_controller.dart:174`), `CampusMapView` (`campus_map_view.dart:30`), `Building` (`building.dart:1`), `MapState` (`map_controller.dart:26`).
- **QR relevance**: `CampusMapView.selectedBuilding` param (`campus_map_view.dart:46`) and `widget.onSelectBuilding` callback. The `RouteNames.map` + `?building=` query param is used to focus on a building from `LocationCardPage` actions (`location_card_page.dart:77-83`).

### `scan/`
- **Purpose**: QR scanning, indoor preview, location detail cards. **This IS the QR feature.**
- **Key symbols**: `ScanPage` (`scan_page.dart:11`), `LocationCardPage` (`location_card_page.dart:14`), `IndoorPreviewPage` (`indoor_preview_page.dart`), `progressApiProvider` (domain/contracts/progress_api.dart → `settings_progress_api_adapter.dart:69`), `scheduleProvider` (`scan_providers.dart:41`).
- **Layers**:
  - `domain/contracts/`: `VisitEvent`, `ScheduleProvider`, `ProgressApi`, `MyDayApi`, `VisitedState`, `LocationContent`, `ScheduleSlot`, `MyDayEntry`
  - `domain/models/`: `TrailManifest`, `IndoorManifest`, `BuildingsRegistry`
  - `data/repositories/`: `TrailRepository`, `IndoorRepository`, `BuildingsRepository` (all read from assets/)
  - `data/adapters/`: `SettingsProgressApiAdapter`, `OpenDayScheduleProviderAdapter`
  - `providers/`: `scan_providers.dart` — wires everything together
  - `domain/fakes/`: `FakeLocationContent`, `FakeMyDayApi`, `FakeProgressApi`, `FakeScheduleProvider`

### `settings/`
- **Purpose**: Theme, locale, notification, commute, Open Day preferences. Owns `UserPreferences` persistence via `SecureStorageService`.
- **Key symbols**: `SettingsController` (`settings_controller.dart:17`), `settingsControllerProvider` (`settings_controller.dart:12`), `LocalSettingsRepository` (`settings_repository.dart:45`).
- **QR relevance**: `SettingsController.recordLocationVisit()` (`settings_controller.dart:179`) is the core visit-recording method. `UserPreferences.visitedLocationCodes` stores visited building codes (`user_preferences.dart:75`).

### `open_day/`
- **Purpose**: Open Day schedule, study interest selection, personalised suggestions, gamification, "Your Day" itinerary.
- **Key symbols**: `OpenDayPersonalisation` (`open_day_personalisation.dart:40`), `OpenDayGamification` (`open_day_gamification.dart:16`), `openDayDataProvider` (`open_day_providers.dart:20`), `locationLiveStatusProvider` (`open_day_providers.dart:127`), `visitProgressProvider` (`open_day_providers.dart:140`).
- **QR relevance**: `liveStatusForLocation()` (`open_day_personalisation.dart:93`) powers QR location schedule chips. `visitProgressProvider` drives gamification. `OpenDayEvent.buildingCode` links events to buildings.

### `favorites/`
- **Purpose**: Supabase-backed favorite buildings.
- **Key symbols**: `FavoritesController`, `FavoriteBuilding`.
- **Relevance**: Not directly needed for QR, but uses `sessionGuardProvider` pattern.

### `notifications/`
- **Purpose**: FCM push + local study prompts.
- **Key symbols**: `NotificationsController`, `NotificationScheduler`, `FcmService`.
- **Relevance**: Not directly.

### `safety/`
- **Purpose**: Emergency contacts, AED locations, security shuttle, flashlight.
- **Relevance**: Standalone feature, no QR connection.

### `timetable/`
- **Purpose**: iCal timetable parsing.
- **Relevance**: Minimal — not related to QR.

### `transit/`
- **Purpose**: TfNSW metro departure display on Home.
- **Relevance**: None.

## 7. Data & Persistence

### Supabase
- **Client setup**: `Supabase.initialize()` in `app_initialization.dart:48-55` with PKCE auth flow.
- **Anonymous auth**: `auth.signInAnonymously()` called silently on launch (`app_initialization.dart:63`); retried on write via `sessionGuardProvider` (`session_guard.dart:8-34`).
- **Tables referenced**:
  - `open_day_stamps`: `user_id UUID`, `location_id TEXT`, `scanned_at TIMESTAMPTZ`, `created_at TIMESTAMPTZ`, `UNIQUE(user_id, location_id)`. RLS: user can SELECT/INSERT own stamps. Migration: `20260629000000_add_open_day_stamps.sql`.
  - `favorite_buildings`: User's saved buildings (via `FavoritesController`).
  - Notification-related tables (via `NotificationRemoteSource`).
  - Various schema tables (units, todos, events, profiles, etc.) — not relevant to QR.
- **Edge Functions**: `cleanup-cron` for orphaned anonymous users.

### Local persistence
- **`SecureStorageService`** (`secure_storage_service.dart:17`): Wraps `flutter_secure_storage` on iOS/Android, falls back to `SharedPreferences` on desktop/web. Key-value with string serialization.
- **All `UserPreferences` keys** (defined in `settings_repository.dart:8-32`): settings.theme_mode, settings.locale_code, settings.open_day.bachelor_id, settings.open_day.visited_codes (comma-joined list), etc.
- **`recordLocationVisit()`** (`settings_controller.dart:179-192`): trims/uppercases `buildingCode`, returns `false` if already visited (idempotent), appends to `visitedLocationCodes` and persists.
- **Data wipe**: `SettingsRepository.wipeAllLocalData()` → `SecureStorageService.deleteAll()`.

### Asset data files (read-only, bundled with app)
- `assets/data/buildings.json` → `BuildingsRepository` / `BuildingRegistrySource`
- `assets/data/open_day.json` → `openDayDataProvider`
- `assets/data/open_day_trail.json` → `TrailRepository` (QR trail)
- `assets/data/campus_overlay_meta.json` → `CampusOverlayMeta`
- `assets/data/mq_campus_locations.csv` → Location datasource
- `assets/data/indoor/{buildingId}.json` → `IndoorRepository`

## 8. i18n

| Config | Value |
|---|---|
| ARB directory | `lib/app/l10n/` (`l10n.yaml:1`) |
| Template file | `app_en.arb` (`l10n.yaml:2`) |
| Output dir | `lib/app/l10n/generated/` (`l10n.yaml:4`) |
| Locale count | 35 (en + 34 translations) |
| RTL locales | `ar`, `fa`, `he`, `ur` (confirmed in AGENT.md:13) |
| Untranslated tracking | `.dart_tool/untranslated.json` (`l10n.yaml:5`) |

Strings accessed via `AppLocalizations.of(context)!.keyName`. Key naming: `camelCase` with area prefix (e.g. `home_scanQrCta`, `openDay_privacyStrip`, `compassHeading({degrees})`).

## 9. Assets

| Path | Type | Loader |
|---|---|---|
| `assets/data/buildings.json` | JSON | `rootBundle.loadString()` via `BuildingRegistrySource` |
| `assets/data/open_day.json` | JSON | `rootBundle.loadString()` via `openDayDataProvider` |
| `assets/data/open_day_trail.json` | JSON | `rootBundle.loadString()` via `TrailRepository` |
| `assets/data/campus_overlay_meta.json` | JSON | `rootBundle.loadString()` via `CampusOverlayMeta` loader |
| `assets/data/mq_campus_locations.csv` | CSV | `LocationSource` |
| `assets/data/indoor/{id}.json` | JSON | `rootBundle.loadString()` via `IndoorRepository` |
| `assets/images/app_logo.png` | Image | `Image.asset` |
| `assets/images/mq_logo.png` | Image | `Image.asset` (home hero, auth pages) |
| `assets/images/campus_background.jpg` | Image | `Image.asset` (home page background) |
| `assets/images/login_background.png` | Image | `Image.asset` (splash, auth pages) |
| `assets/maps/mq-campus.png` | Image | `flutter_map` raster tile layer |
| `assets/maps/overlay_*.png` (4 files) | Image | Campus overlay layers |
| `assets/web/indoor_viewer.html` | HTML | `InAppWebView` for Pannellum 360° |
| `assets/tripplanner_v1_swag_efa11_20251002.yml` | YAML | Trip planner data (unreferenced?) |

## 10. Quality Gates

`scripts/check.sh` runs 12 steps:

| # | Step | Command | Notes |
|---|---|---|---|
| 1 | Dependencies | `flutter pub get` | |
| 2 | Format check/fix | `dart format` on `lib test tools scripts integration_test` | `--fix` auto-formats |
| 3 | Static analysis | `flutter analyze --no-fatal-infos` | |
| 4 | Tests | `flutter test` | Full suite |
| 5 | l10n generation | `flutter gen-l10n` | |
| 6 | l10n untranslated check | `.dart_tool/untranslated.json` | Non-blocking warning |
| 7 | Privacy guard | Grep blocks `firebase_analytics`, `google_analytics`, `appsflyer`, `amplitude`, `mixpanel`, `segment`, `sentry_flutter`, `facebook_app_events` in pubspec |
| 8 | Secret scan | Grep lib/test/scripts for `sk-*` and `AIza*` patterns | |
| 9 | No-stale-name guard | Grep `mq_navigation` in `lib test scripts pubspec.yaml` | Catches old names |
| 10 | No-login-route guard | Grep `/auth/login`, `/auth/signup`, `signInWithPassword` | Catches login re-introduction |
| 11 | No-Google guard | Grep `google_maps_flutter\|maps.googleapis.com\|GMSServices\|GOOGLE_MAPS_API_KEY` (pre-existing failure expected) |
| 12 | Build | `flutter build apk --debug` | Skipped with `--quick` |

**Run locally**: `./scripts/check.sh` (full) or `./scripts/check.sh --quick`. `./scripts/run.sh` launches with `--dart-define-from-file=.env`.

## 11. Reuse Map for the QR Feature

| Capability Needed | Existing Symbol | File:Line | Reusable? |
|---|---|---|---|
| **Visit recording** | `SettingsController.recordLocationVisit(String buildingCode)` → `Future<bool>` | `settings_controller.dart:179-192` | **Directly reusable.** Idempotent, returns `true` on new visit. |
| **Persisted visited set** | `UserPreferences.visitedLocationCodes` → `List<String>` | `user_preferences.dart:75` | **Directly reusable.** Persisted via SecureStorage as comma-joined string. `UserPreferences.hasVisited(code)` at line 84. |
| **Gamification / XP** | `OpenDayGamification.progress()` → `VisitProgress` | `open_day_gamification.dart:30-54` | **Directly reusable.** Called by `visitProgressProvider` (`open_day_providers.dart:140-151`). Fixed 50 XP per visit. |
| **Per-location schedule** | `OpenDayPersonalisation.liveStatusForLocation(all, buildingCode, now)` → `OpenDayLiveStatus` | `open_day_personalisation.dart:93-103` | **Directly reusable.** Also exposed as `locationLiveStatusProvider` (`open_day_providers.dart:127-135`). |
| **Map widget** | `CampusMapView` (flutter_map + CrsSimple) | `campus_map_view.dart:30-357` | **Directly reusable.** Takes `selectedBuilding: Building?` input at line 46. |
| **Map building input** | `MapPage.initialBuildingId` → `String?` | `map_page.dart:30` | **Directly reusable.** Pass building ID via GoRouter query param `?building=`. Used by `LocationCardPage` at `location_card_page.dart:77-80`. |
| **Home QR CTA button** | `_HeroSection` → `FilledButton` with `Icons.qr_code_scanner_rounded` → `context.goNamed(RouteNames.scan)` | `home_page.dart:678-707` | **Directly reusable.** Points to `/scan`. |
| **Scan route** | `RouteNames.scan = 'scan'` → path `/scan` → `ScanPage` | `route_names.dart:24`, `app_router.dart:131-134` | **Already exists.** |
| **Location detail route** | `RouteNames.locationDetail = 'location-detail'` → path `/location/:locationId` → `LocationCardPage` | `route_names.dart:25`, `app_router.dart:137-142` | **Already exists.** |
| **Indoor preview route** | `RouteNames.indoorPreview = 'indoor-preview'` → path `/map/building/:buildingId/indoor` → `IndoorPreviewPage` | `route_names.dart:26`, `app_router.dart:181-186` | **Already exists.** |
| **Scan-to-visit flow** | `ScanPage._onDetectBarcode` parses QR, validates via `trailManifestProvider`, records `VisitEvent` via `progressApiProvider`, navigates to `/location/$locationId` | `scan_page.dart:49-80` | **Already exists.** |
| **Supabase stamp upsert** | `SettingsProgressApiAdapter._enqueueStampUpsert` writes to `open_day_stamps` table | `settings_progress_api_adapter.dart:36-48` | **Already exists.** `onConflict: 'user_id,location_id'` with `ignoreDuplicates: true`. |

## 12. Gaps & Risks for the QR Plan

- [ ] **No `url_launcher` import in scan feature yet** — but it IS already in pubspec.yaml at line 48. The scan pages don't use it directly (the map page does via `MapController.openStreetView`).
- [ ] **`FakeLocationContent` is used in production** — `locationContentProvider` (`scan_providers.dart:37-39`) reads from `fakeLocationContentProvider`. Needs a real implementation backed by `BuildingsRegistry` + `OpenDayEvent` data.
- [ ] **`FakeMyDayApi` is used in production** — `myDayApiProvider` (`scan_providers.dart:48`) returns `FakeMyDayApi`. Needs a real adapter, likely wiring to `SettingsController.toggleSavedOpenDayEvent()`.
- [ ] **`assets/web/indoor_viewer.html` now exists** (created: `assets/web/indoor_viewer.html`). CHANGELOG follow-up from Task 12 said to create it — confirmed present.
- [ ] **`assets/data/open_day_trail.json` now exists** — trail manifest for QR validation.
- [ ] **`assets/data/indoor/` directory may be empty** — no indoor JSON files found yet (each building's indoor graph is loaded on demand).
- [ ] **Route `/scan` is registered** — no gaps there.
- [ ] **The QR plan assumes a "stamps" table** — `open_day_stamps` migration exists (`20260629000000_add_open_day_stamps.sql`) and `SettingsProgressApiAdapter` writes to it. Confirmed.

## 13. Open Questions / UNVERIFIED

- **`assets/data/indoor/` contents**: The `IndoorRepository.load(buildingId)` reads from `assets/data/indoor/{buildingId}.json` but the actual files may not exist yet per the CHANGELOG follow-up.
- **`FakeLocationContent` data source**: The fake returns content for which location IDs? Not verified — may need real data from `BuildingsRegistry`.
- **Desktop build**: `flutter build windows --release` has MSVC coroutine workaround, but actual Windows CI is unverified.
- **Google Maps guard**: The `no-google` guard in `check.sh` has a pre-existing failure (`AGENT.md` line 127). The app uses `flutter_map`, not `google_maps_flutter`, but there may be stale references.
- **Real test count**: AGENT.md mentions `295` tests at one point, `320+` at another. The actual count depends on latest commits. Run `flutter test` to get current.

---

## TL;DR for the next agent

1. **Feature-first, 3-layer architecture** — domain (pure Dart) → data (repos, adapters, datasources) → presentation (Riverpod controllers, ConsumerWidget pages).
2. **Riverpod 3.x everywhere** — `AsyncNotifierProvider` for mutable state, `Provider.family` for parameterised reads, `FutureProvider` for one-shot loads. All state objects `@immutable` with `==`/`hashCode`.
3. **QR scanning already works** — `/scan` → `ScanPage` → validates vs `TrailManifest` → records `VisitEvent` → navigates to `/location/:id` → `LocationCardPage`. Extend the fakes/providers, don't rebuild.
4. **Visit tracking is two-tier** — local via `SettingsController.recordLocationVisit()` (SecureStorage) + durable via `open_day_stamps` Supabase table (RLS on `user_id`). Gamification is derived from `visitedLocationCodes`.
5. **No real login** — anonymous-only Supabase sessions minted on launch. All writes use retry guard (`sessionGuardProvider`). No server secrets in the binary.
