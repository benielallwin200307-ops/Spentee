import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Notification IDs — keep them stable so cancel works correctly.
class NotifId {
  static const int daily = 1;
  static const int weekly = 2;
  static const int roasts = 3;
  // Budget alerts are fired imperatively via showBudgetAlert(); no fixed ID.
  static const int budgetBase = 100;
}

/// Notification channel IDs.
class _Channel {
  static const String reminders = 'spentee_reminders';
  static const String budget = 'spentee_budget';
  static const String roasts = 'spentee_roasts';
}

/// Singleton service that wraps flutter_local_notifications.
/// Call [NotificationService.init()] once at app start-up.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;
  bool get isInitialised => _initialised;

  @visibleForTesting
  void setInitialisedForTesting([bool val = false]) {
    _initialised = val;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Initialisation
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialised) return;

    try {
      // Set up timezone data.
      tz.initializeTimeZones();
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone()
            .timeout(const Duration(seconds: 3));
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (_) {
        // Fall back to UTC if timezone detection fails or times out.
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {}
      }

      // Android initialisation — use the launcher icon.
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings settings =
          InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      _initialised = true;
      // Create notification channels (Android 8+).
      await _createChannels();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Request Android 13+ POST_NOTIFICATIONS permission.
  /// Returns true if permission is granted (or not needed).
  Future<bool> requestPermission() async {
    if (!_initialised) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    try {
      final canExact = await android.canScheduleExactNotifications();
      if (canExact == false) {
        await android.requestExactAlarmsPermission();
      }
    } catch (_) {}
    return granted ?? false;
  }

  Future<AndroidScheduleMode> _determineScheduleMode() async {
    if (!_initialised) return AndroidScheduleMode.inexactAllowWhileIdle;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      try {
        final canExact = await android.canScheduleExactNotifications();
        if (canExact == true) {
          return AndroidScheduleMode.exactAllowWhileIdle;
        }
      } catch (_) {}
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _createChannels() async {
    if (!_initialised) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _Channel.reminders,
      'Spending Reminders',
      description: 'Daily and weekly spending log reminders',
      importance: Importance.high,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _Channel.budget,
      'Budget Alerts',
      description: 'Alerts when a budget threshold is reached',
      importance: Importance.high,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _Channel.roasts,
      'AI Roast & Motivation',
      description: 'Daily motivational messages from your Spentee companion',
      importance: Importance.defaultImportance,
    ));
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation can be wired up here in future iterations.
    debugPrint('Notification tapped: ${response.id}');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Schedule helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the next TZDateTime that matches [hour]:[minute] in local tz.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now.add(const Duration(seconds: 5)))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Returns the next Sunday at [hour]:[minute].
  tz.TZDateTime _nextSundayAt(int hour, int minute) {
    tz.TZDateTime dt = _nextInstanceOf(hour, minute);
    // DateTime.sunday == 7
    while (dt.weekday != DateTime.sunday) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Public schedule / cancel API
  // ──────────────────────────────────────────────────────────────────────────

  /// Schedule the Daily Spending Log notification at [timeStr] ("HH:MM").
  Future<void> scheduleDailyReminder(String timeStr) async {
    if (!_initialised) return;
    await cancel(NotifId.daily);
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 20;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final scheduleMode = await _determineScheduleMode();

    try {
      await _plugin.zonedSchedule(
        NotifId.daily,
        '💸 Daily Spending Log',
        'Take a moment to record today\'s expenses and stay on budget!',
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _Channel.reminders,
            'Spending Reminders',
            channelDescription: 'Daily spending log reminder',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('NotificationService: daily reminder scheduled at $timeStr (mode: $scheduleMode)');
    } catch (e) {
      debugPrint('NotificationService: fallback inexact schedule daily: $e');
      await _plugin.zonedSchedule(
        NotifId.daily,
        '💸 Daily Spending Log',
        'Take a moment to record today\'s expenses and stay on budget!',
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _Channel.reminders,
            'Spending Reminders',
            channelDescription: 'Daily spending log reminder',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Schedule the Weekly Spending Summary every Sunday at 09:00.
  Future<void> scheduleWeeklyReminder() async {
    if (!_initialised) return;
    await cancel(NotifId.weekly);
    final scheduleMode = await _determineScheduleMode();

    try {
      await _plugin.zonedSchedule(
        NotifId.weekly,
        '📊 Weekly Spending Summary',
        'Your Spentee AI weekly cash-flow breakdown is ready!',
        _nextSundayAt(9, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _Channel.reminders,
            'Spending Reminders',
            channelDescription: 'Weekly summary reminder',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint('NotificationService: weekly reminder scheduled (mode: $scheduleMode)');
    } catch (e) {
      debugPrint('NotificationService: fallback inexact schedule weekly: $e');
      await _plugin.zonedSchedule(
        NotifId.weekly,
        '📊 Weekly Spending Summary',
        'Your Spentee AI weekly cash-flow breakdown is ready!',
        _nextSundayAt(9, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _Channel.reminders,
            'Spending Reminders',
            channelDescription: 'Weekly summary reminder',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Schedule the daily AI Roast & Motivation notification at 08:30.
  Future<void> scheduleRoastReminder() async {
    if (!_initialised) return;
    await cancel(NotifId.roasts);
    final scheduleMode = await _determineScheduleMode();

    try {
      await _plugin.zonedSchedule(
        NotifId.roasts,
        '🔥 Spentee AI Roast',
        'Your daily dose of financial motivation (and mild roasting) is here!',
        _nextInstanceOf(8, 30),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _Channel.roasts,
            'AI Roast & Motivation',
            channelDescription: 'Daily AI roast notification',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('NotificationService: roast reminder scheduled (mode: $scheduleMode)');
    } catch (e) {
      debugPrint('NotificationService: fallback inexact schedule roast: $e');
      await _plugin.zonedSchedule(
        NotifId.roasts,
        '🔥 Spentee AI Roast',
        'Your daily dose of financial motivation (and mild roasting) is here!',
        _nextInstanceOf(8, 30),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _Channel.roasts,
            'AI Roast & Motivation',
            channelDescription: 'Daily AI roast notification',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Fire an immediate budget threshold alert (not repeating).
  Future<void> showBudgetAlert({
    required String categoryName,
    required int percent,
  }) async {
    if (!_initialised) return;
    final id = NotifId.budgetBase + categoryName.hashCode.abs() % 100;
    await _plugin.show(
      id,
      percent >= 100
          ? '🚨 Budget Exceeded: $categoryName'
          : '⚠️ Budget Warning: $categoryName',
      percent >= 100
          ? 'You have exceeded your $categoryName budget!'
          : 'You have used $percent% of your $categoryName budget.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _Channel.budget,
          'Budget Alerts',
          channelDescription: 'Budget threshold alert',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
    debugPrint('NotificationService: budget alert for $categoryName at $percent%');
  }

  /// Cancel a single notification by ID.
  Future<void> cancel(int id) async {
    if (!_initialised) return;
    await _plugin.cancel(id);
  }

  /// Cancel all Spentee notifications.
  Future<void> cancelAll() async {
    if (!_initialised) return;
    await _plugin.cancelAll();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Reschedule from saved preferences (called at boot / app start)
  // ──────────────────────────────────────────────────────────────────────────

  /// Re-applies notification schedule from persisted preferences.
  /// Pass the [notifications] map and [notificationTime] from AppState.
  Future<void> rescheduleAll({
    required Map<String, bool> notifications,
    required String notificationTime,
  }) async {
    if (!_initialised) return;
    final daily = notifications['daily'] ?? false;
    final weekly = notifications['weekly'] ?? false;
    final roasts = notifications['roasts'] ?? false;

    if (daily) {
      await scheduleDailyReminder(notificationTime);
    } else {
      await cancel(NotifId.daily);
    }

    if (weekly) {
      await scheduleWeeklyReminder();
    } else {
      await cancel(NotifId.weekly);
    }

    if (roasts) {
      await scheduleRoastReminder();
    } else {
      await cancel(NotifId.roasts);
    }

    // Budget alerts are fired imperatively when budgets are checked; no
    // persistent scheduling required here.
    debugPrint('NotificationService: rescheduleAll complete');
  }
}

