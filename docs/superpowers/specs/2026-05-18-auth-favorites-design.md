# Auth + Favorites Design Spec

## Overview

Add Supabase authentication and building favorites CRUD to the MQ Navigation Flutter app. Auth gates the entire app behind a login/signup flow. Once authenticated, users can save, view, edit, and remove favourite campus buildings — stored in a dedicated Supabase table with RLS.

## User Flow

```
App Launch
├─ No Supabase session → /auth (Login or Signup)
├─ Has session + onboarding incomplete → /onboarding
└─ Has session + onboarding complete → /home
```

- `/auth` is the only public route
- `/auth/signup` and `/auth/login` are separate named routes (not query params)
- Authenticated users who hit `/auth` are redirected to home/onboarding
- Unauthenticated users who hit any other route land on `/auth`

## Supabase Schema

```sql
create table favorite_buildings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  building_id text not null,
  building_name text not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, building_id)
);

alter table favorite_buildings enable row level security;

create policy "Users can read own favourites"
  on favorite_buildings for select
  using (auth.uid() = user_id);

create policy "Users can create own favourites"
  on favorite_buildings for insert
  with check (auth.uid() = user_id);

create policy "Users can update own favourites"
  on favorite_buildings for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own favourites"
  on favorite_buildings for delete
  using (auth.uid() = user_id);
```

## Architecture

### Feature: `lib/features/auth/`

```
lib/features/auth/
├── domain/
│   └── services/
│       └── auth_service.dart          → Supabase auth wrapper
├── data/
│   └── repositories/
│       └── auth_repository.dart       → Login, signup, logout, reset, session
├── presentation/
│   ├── controllers/
│   │   └── auth_controller.dart       → Riverpod provider for auth state
│   ├── pages/
│   │   ├── login_page.dart            → Email + password login
│   │   └── signup_page.dart           → Email + password + confirm signup
│   └── widgets/
│       └── auth_form.dart             → Shared form widget
```

### Feature extension: `lib/features/map/` (Favorites)

```
lib/features/map/
├── domain/
│   └── entities/
│       └── favorite_building.dart     → Model for favourite building
├── data/
│   ├── datasources/
│   │   └── favorite_building_remote_source.dart  → Supabase queries
│   └── repositories/
│       └── favorite_building_repository.dart     → CRUD operations
├── presentation/
│   ├── controllers/
│   │   └── favorites_controller.dart  → Riverpod provider for favourites
│   ├── pages/
│   │   └── favorites_page.dart        → List view with edit/delete
│   └── widgets/
│       ├── favorite_button.dart       → Heart toggle on building cards
│       └── edit_note_dialog.dart      → Edit note bottom sheet/dialog
```

### Router changes (`app_router.dart`)

- Add `/auth/login` and `/auth/signup` routes outside the StatefulShellRoute
- Modify `redirect` to check `supabase.auth.currentSession` first, then onboarding
- Add `refreshListenable` for session changes

### Shared providers

- `authControllerProvider` — exposes session state, login, signup, logout
- `favoritesControllerProvider` — exposes favourite list, toggle, update, delete

## Auth Screens Design

### Visual (both Login and Signup)
- Background: `MqColors.alabaster` (light) / `MqColors.charcoal900` (dark)
- MQ red branding bar at top
- "Use your account or create one to save favourite buildings." subtitle
- `MqInput` fields with floating labels (Email, Password, Confirm Password)
- Password visibility toggle on password fields
- Primary `MqButton` in `MqColors.red` with loading state text
  - "Signing in…" / "Creating account…" / "Sending reset email…"
- "Forgot password?" link → Supabase password reset
- Toggle link: "Don't have an account? Create one" / "Already have an account? Sign in"
- Error banner below form for:
  - "Email or password is incorrect."
  - "An account already exists for this email."
  - "Password must be at least 8 characters."
  - "Network error. Check your connection and try again."
- Signup page shows password hint: "8+ characters, one number recommended"
- Inputs disabled during loading

### Layout
```
┌─────────────────────────┐
│   [MQ Branding Bar]     │
│                         │
│   Welcome back          │
│   Use your account or   │
│   create one to save    │
│   favourite buildings.  │
│                         │
│   ┌─────────────────┐   │
│   │  Email           │   │
│   ├─────────────────┤   │
│   │  Password        │   │
│   └─────────────────┘   │
│   Forgot password?       │
│                         │
│  ┌─────────────────┐    │
│  │   Sign In       │    │
│  └─────────────────┘    │
│                         │
│  Don't have an account? │
│     Create one →        │
└─────────────────────────┘
```

## Favorites UI Design

### Heart button (Create/Delete)
- ♡ (outline) = not saved
- ❤️ (filled) = saved  
- Button disabled + spinner while request in flight
- Tapping when not saved → INSERT → ❤️ + "Saved to favourites" snackbar
- Tapping when saved → DELETE → ♡ + "Removed from favourites" snackbar
- Duplicate insert is idempotent (unique constraint + ON CONFLICT DO NOTHING)
- Shown on building search results and building detail

### Favourites list page (Read/Update/Delete)
- Entry points: Home dashboard card + Settings menu item
- Lists saved buildings: building name, note, created date
- Tap building → navigate to it on map
- Edit icon on each item → dialog/bottom sheet → save updated note (Update)
- Delete icon/button → confirmation dialog → "Yes, remove" → DELETE (Delete)
- Empty state: "No saved buildings yet. Browse the map to add some."
- Loading state: shimmer placeholder
- Error state: retry button

### Data flow
```
Building heart tap → toggleFavorite(buildingId, buildingName)
  → if not saved: FavoriteBuildingRepository.create()
    → Supabase INSERT (RLS: auth.uid() = user_id)
  → if saved: FavoriteBuildingRepository.delete()
    → Supabase DELETE WHERE id = :id AND user_id = auth.uid()
  → UI updates optimistically via Riverpod state

FavoritesPage → watch(favoritesControllerProvider)
  → FavoriteBuildingRepository.getAll()
    → Supabase SELECT WHERE user_id = auth.uid()
  → ListView with edit/delete actions
```

## Error & State Handling

| State | Behaviour |
|-------|-----------|
| Loading | Button shows spinner + "Signing in…" / list shows shimmer |
| Empty | Friendly illustration + "No saved buildings yet" |
| Error (auth) | Red inline banner with mapped message |
| Error (favourites) | Error card + "Retry" button |
| Offline | "Network error" message; read from local cache if available (stretch) |
| Optimistic | UI updates before network confirms; rollback on failure |

## Files to Create

### New files
1. `lib/features/auth/domain/services/auth_service.dart`
2. `lib/features/auth/data/repositories/auth_repository.dart`
3. `lib/features/auth/presentation/controllers/auth_controller.dart`
4. `lib/features/auth/presentation/pages/login_page.dart`
5. `lib/features/auth/presentation/pages/signup_page.dart`
6. `lib/features/auth/presentation/widgets/auth_form.dart`
7. `lib/features/map/domain/entities/favorite_building.dart`
8. `lib/features/map/data/datasources/favorite_building_remote_source.dart`
9. `lib/features/map/data/repositories/favorite_building_repository.dart`
10. `lib/features/map/presentation/controllers/favorites_controller.dart`
11. `lib/features/map/presentation/pages/favorites_page.dart`
12. `lib/features/map/presentation/widgets/favorite_button.dart`
13. `lib/features/map/presentation/widgets/edit_note_dialog.dart`

### Modified files
1. `lib/app/router/app_router.dart` — add auth routes + session redirect
2. `lib/app/router/route_names.dart` — add auth route names
3. `lib/app/l10n/app_en.arb` — auth + favourites strings
4. `lib/features/home/presentation/pages/home_page.dart` — add favourites card
5. `lib/features/settings/presentation/pages/settings_page.dart` — add favourites entry
6. `README.md` — add auth/favourites docs + test credentials
7. `pubspec.yaml` — if any new deps needed (unlikely)

### Database migration
1. Supabase SQL migration for `favorite_buildings` table + RLS policies

### Test files
1. `test/features/auth/login_page_test.dart` — widget tests
2. `test/features/auth/signup_page_test.dart` — widget tests
3. `test/features/map/favorites_controller_test.dart` — unit tests
4. `test/features/map/favorite_building_repository_test.dart` — unit tests
5. `test/features/map/favorites_page_test.dart` — widget tests

## Rubric Coverage Map

| Rubric Category | Marks | How We Hit It |
|----------------|-------|---------------|
| Auth | 5 | Email/password login, signup, logout, password reset, safe errors, loading states, duplicate detection |
| Remote DB | 10 | `favorite_buildings` table, RLS, data persists across sessions, loading/error states |
| Create & Read | 5 | Heart button creates, favourites page reads with real-time display |
| Update & Delete | 5 | Edit note dialog (update), delete with confirmation dialog |
| Device Service | 5 | Location permission denial UX polish (existing feature) |
| Visual Design | 5 | Auth screens styled with MqColors/MqTypography, consistent with existing app |
| Navigation & UX | 5 | Auth gate + onboarding + shell, intuitive flows |
| Architecture | 10 | Feature-first, clean separation (domain/data/presentation), Riverpod state |
| Code Readability | 5 | Consistent Dart conventions, minimal but useful comments |
| Widget Tests | 10 | Tests for auth screens, favourites page, interactions |
| Unit Tests | 10 | Tests for controller, repository, model serialization |
| Overall | 10 | Cohesive product: auth → favourites → map, feels like a real app |
| **Total** | **80+** | |
