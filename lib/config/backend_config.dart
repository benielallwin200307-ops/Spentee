import 'dart:io';
import 'package:flutter/foundation.dart';

/// Central configuration for Spentee AI Backend URL resolution.
/// Ensures consistent routing across Android Emulator, Physical Devices,
/// Desktop, and Web environments without scattered hardcoded strings.
class BackendConfig {
  BackendConfig._();

  /// Default emulator host alias mapped by QEMU virtual router to Windows host (127.0.0.1)
  static const String emulatorHostUrl = 'http://10.0.2.2:3000';

  /// Default host URL for Desktop, Web, or Physical device via ADB reverse (tcp:3000 -> tcp:3000)
  static const String localHostUrl = 'http://localhost:3000';

  /// Compile-time environment variable override (e.g. --dart-define=SPENTEE_AI_BACKEND_URL=...)
  static const String envUrl = String.fromEnvironment('SPENTEE_AI_BACKEND_URL');

  /// Runtime URL override (for settings, debugging, or unit testing)
  static String? customUrl;

  static bool? _cachedIsAndroidEmulator;

  /// Detects whether the current Android runtime is an emulator.
  static Future<bool> isAndroidEmulator() async {
    if (_cachedIsAndroidEmulator != null) return _cachedIsAndroidEmulator!;
    if (kIsWeb || !Platform.isAndroid) {
      _cachedIsAndroidEmulator = false;
      return false;
    }
    try {
      final qemu = await Process.run('getprop', ['ro.kernel.qemu']);
      if (qemu.stdout.toString().trim() == '1') {
        _cachedIsAndroidEmulator = true;
        return true;
      }
      final chars = await Process.run('getprop', ['ro.build.characteristics']);
      if (chars.stdout.toString().toLowerCase().contains('emulator')) {
        _cachedIsAndroidEmulator = true;
        return true;
      }
      final hardware = await Process.run('getprop', ['ro.hardware']);
      final hw = hardware.stdout.toString().toLowerCase();
      if (hw.contains('goldfish') || hw.contains('ranchu')) {
        _cachedIsAndroidEmulator = true;
        return true;
      }
      final model = await Process.run('getprop', ['ro.product.model']);
      if (model.stdout.toString().toLowerCase().contains('sdk')) {
        _cachedIsAndroidEmulator = true;
        return true;
      }
    } catch (_) {}

    // Default to true on Android debug builds because standard Android workflow uses 10.0.2.2
    _cachedIsAndroidEmulator = true;
    return true;
  }

  /// Synchronous default URL based on compile-time environment and platform.
  /// For Android, defaults to http://10.0.2.2:3000 (never 127.0.0.1).
  static String getDefaultBackendUrl([String? override]) {
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    if (customUrl != null && customUrl!.trim().isNotEmpty) {
      return customUrl!.trim();
    }
    if (envUrl.isNotEmpty) {
      return envUrl.trim();
    }
    if (!kIsWeb && Platform.isAndroid) {
      return emulatorHostUrl;
    }
    return localHostUrl;
  }

  /// Asynchronously resolves the definitive backend URL with environment & hardware inspection.
  /// - Android Emulator: strictly http://10.0.2.2:3000
  /// - Physical Android device: http://localhost:3000 (via ADB reverse) or custom host LAN IP
  /// - Web / Desktop / Tests: http://localhost:3000
  static Future<String> getResolvedBackendUrl([String? override]) async {
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    if (customUrl != null && customUrl!.trim().isNotEmpty) {
      return customUrl!.trim();
    }
    if (envUrl.isNotEmpty) {
      return envUrl.trim();
    }
    if (kIsWeb) {
      return localHostUrl;
    }
    if (Platform.isAndroid) {
      final isEmu = await isAndroidEmulator();
      if (isEmu) {
        return emulatorHostUrl;
      }
      // Physical Android phone: works with ADB reverse port forwarding (adb reverse tcp:3000 tcp:3000)
      return localHostUrl;
    }
    return localHostUrl;
  }
}
