/// Named route constants used throughout the app.
abstract final class RouteNames {
  static const String meet = 'meet';
  static const String notifications = 'notifications';
  static const String openDay = 'open-day';
  static const String onboarding = 'onboarding';

  // Shell tabs
  static const String home = 'home';
  static const String map = 'map';
  static const String settings = 'settings';

  // Detail screens (pushed on top of shell)
  static const String buildingDetail = 'building-detail';

  // Safety
  static const String safetyToolkit = 'safety';

  // Auth
  static const String auth = 'auth';
  static const String login = 'login';
  static const String signup = 'signup';
  /// Web-only route that handles the Supabase email-confirmation PKCE redirect.
  static const String authCallback = 'auth-callback';

  // Favorites
  static const String favorites = 'favorites';
}
