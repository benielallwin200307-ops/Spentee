import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/budget.dart';
import '../models/roast.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import 'roast_engine.dart';
import 'roast_library.dart';

/// Notification IDs — keep them stable so cancel works correctly.
class NotifId {
  static const int daily = 1;
  static const int weekly = 2;
  static const int roasts = 3; // Legacy ID / Morning Roast
  static const int roastMorning = 3;
  static const int roastEvening = 4;
  // Legacy schedules to explicitly cancel
  static const int legacyRoast2PM = 14;
  static const int legacyRoast9PM = 21;
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

  /// Schedule the Daily Spending Log reminder.
  /// Scheduled every day at [timeStr] ("HH:MM"), defaulting to 22:00 (10:00 PM).
  /// Notification message: "Today, have you added your expenses? 💚"
  Future<void> scheduleDailyReminder([String timeStr = '22:00']) async {
    if (!_initialised) return;
    await cancel(NotifId.daily);
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 22;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final scheduleMode = await _determineScheduleMode();

    const title = 'Daily Reminder';
    const body = 'Today, have you added your expenses? 💚';

    try {
      await _plugin.zonedSchedule(
        NotifId.daily,
        title,
        body,
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
      debugPrint('NotificationService: daily reminder scheduled at $hour:$minute (mode: $scheduleMode)');
    } catch (e) {
      debugPrint('NotificationService: fallback inexact schedule daily: $e');
      await _plugin.zonedSchedule(
        NotifId.daily,
        title,
        body,
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

  /// Cancel all scheduled roast reminders and legacy schedules (2:00 PM, 9:00 PM).
  Future<void> cancelRoastReminders() async {
    if (!_initialised) return;
    await cancel(NotifId.roastMorning);
    await cancel(NotifId.roastEvening);
    await cancel(NotifId.legacyRoast2PM);
    await cancel(NotifId.legacyRoast9PM);
  }

  /// Backward-compatible single method delegating to dual daily roast scheduling.
  Future<void> scheduleRoastReminder({
    List<Transaction> transactions = const [],
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    String language = 'English',
    RoastIntensity intensity = RoastIntensity.savage,
    List<String> recentRoastIds = const [],
  }) async {
    await scheduleRoastReminders(
      transactions: transactions,
      budgets: budgets,
      savingsGoals: savingsGoals,
      language: language,
      intensity: intensity,
      recentRoastIds: recentRoastIds,
    );
  }

  /// Schedules exactly 2 daily AI Roast notifications:
  /// - Morning Roast at 10:00 AM (10:00)
  /// - Evening Roast at 6:00 PM (18:00)
  ///
  /// Removes existing schedules at 2:00 PM (14:00) and 9:00 PM (21:00).
  /// Displays a personalised roast based on real financial activity,
  /// supporting all 6 app languages, avoiding recent roasts, and
  /// enforcing data sufficiency so users without enough data receive
  /// safe onboarding roasts rather than fabricated spending roasts.
  Future<void> scheduleRoastReminders({
    List<Transaction> transactions = const [],
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    String language = 'English',
    RoastIntensity intensity = RoastIntensity.savage,
    List<String> recentRoastIds = const [],
  }) async {
    if (!_initialised) return;

    // 1. Remove legacy schedules (2:00 PM, 9:00 PM) and existing roast notifications
    await cancelRoastReminders();

    final scheduleMode = await _determineScheduleMode();
    final canonLang = RoastLibrary.normalizeLanguage(language);

    // 2. Generate Morning Roast (10:00 AM)
    final morningRoast = DynamicRoastEngine.generateRoast(
      transactions: transactions,
      budgets: budgets,
      savingsGoals: savingsGoals,
      language: canonLang,
      intensity: intensity,
      recentRoastIds: recentRoastIds,
    );

    // 3. Generate Evening Roast (6:00 PM = 18:00), avoiding duplicate of morning roast
    final eveningHistory = [...recentRoastIds];
    if (morningRoast.id.isNotEmpty) {
      eveningHistory.add(morningRoast.id);
    }
    final eveningRoast = DynamicRoastEngine.generateRoast(
      transactions: transactions,
      budgets: budgets,
      savingsGoals: savingsGoals,
      language: canonLang,
      intensity: intensity,
      previousRoastId: morningRoast.id,
      previousRoastText: morningRoast.text,
      recentRoastIds: eveningHistory,
    );

    // Schedule 10:00 AM notification
    await _scheduleSingleRoast(
      id: NotifId.roastMorning,
      title: '🔥 Spentee AI Roast',
      body: morningRoast.text,
      hour: 10,
      minute: 0,
      scheduleMode: scheduleMode,
    );

    // Schedule 6:00 PM (18:00) notification
    await _scheduleSingleRoast(
      id: NotifId.roastEvening,
      title: '🔥 Spentee AI Roast',
      body: eveningRoast.text,
      hour: 18,
      minute: 0,
      scheduleMode: scheduleMode,
    );

    debugPrint('NotificationService: scheduled 2 daily roasts at 10:00 AM and 6:00 PM ($canonLang)');
  }

  Future<void> _scheduleSingleRoast({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required AndroidScheduleMode scheduleMode,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOf(hour, minute),
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
    } catch (e) {
      debugPrint('NotificationService: fallback inexact single roast ($id): $e');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOf(hour, minute),
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
  /// Pass the [notifications] map and [notificationTime] from AppState,
  /// along with optional user financial context to personalize roasts.
  Future<void> rescheduleAll({
    required Map<String, bool> notifications,
    required String notificationTime,
    List<Transaction> transactions = const [],
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    String language = 'English',
    RoastIntensity intensity = RoastIntensity.savage,
    List<String> recentRoastIds = const [],
  }) async {
    if (!_initialised) return;
    final daily = notifications['daily'] ?? false;
    final weekly = notifications['weekly'] ?? false;
    final roasts = notifications['roasts'] ?? false;

    // Explicitly clean up legacy schedules (2:00 PM and 9:00 PM)
    await cancel(NotifId.legacyRoast2PM);
    await cancel(NotifId.legacyRoast9PM);

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
      await scheduleRoastReminders(
        transactions: transactions,
        budgets: budgets,
        savingsGoals: savingsGoals,
        language: language,
        intensity: intensity,
        recentRoastIds: recentRoastIds,
      );
    } else {
      await cancelRoastReminders();
    }

    // Budget alerts are fired imperatively when budgets are checked; no
    // persistent scheduling required here.
    debugPrint('NotificationService: rescheduleAll complete');
  }
}

