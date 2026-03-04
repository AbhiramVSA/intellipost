/// Centralized configuration for the app.
///
/// In production, these values should come from environment variables
/// or a build-time configuration system.
class AppConfig {
  static const String apiBaseUrl = 'http://44.222.223.134';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60);
}
