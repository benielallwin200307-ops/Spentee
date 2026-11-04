/// Central application configuration for Spentee.
/// Supplies dynamically configured version, build metadata, and platform details.
class AppConfig {
  AppConfig._();

  /// Application Name.
  static const String appName = 'Spentee';

  /// Application Tagline.
  static const String appTagline = 'Your AI Money Companion';

  /// Dynamic version string configurable at compile-time via --dart-define=APP_VERSION=...
  /// Defaults to canonical app version 1.0.0.
  static String version = const String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// Dynamic build number configurable at compile-time via --dart-define=APP_BUILD_NUMBER=...
  /// Defaults to 1.
  static String buildNumber = const String.fromEnvironment(
    'APP_BUILD_NUMBER',
    defaultValue: '1',
  );

  /// Storage architecture.
  static const String storage = 'Local-First Storage';

  /// Cloud Synchronization provider.
  static const String cloudSync = 'Firebase';

  /// Target platform.
  static const String platform = 'Android';

  /// Official copyright statement.
  static const String copyright = '© 2026 Spentee. All rights reserved.';
}

