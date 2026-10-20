import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Centralized date restriction utility for Spentee.
/// Guarantees that users cannot pick or store future dates, tomorrow,
/// or navigate to upcoming months in any calendar.
class DateRestriction {
  DateRestriction._();

  /// Normalized local today (year, month, day at 00:00:00) using device timezone.
  static DateTime get localToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Normalized local end of today (year, month, day at 23:59:59.999).
  static DateTime get localEndOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  /// Earliest historical date allowed in transaction pickers (Jan 1, 2020).
  static final DateTime defaultFirstDate = DateTime(2020, 1, 1);

  /// Checks whether [date] is today or in the past according to the device's local calendar.
  /// Ignores time components by comparing day-level dates.
  static bool isTodayOrPast(DateTime date) {
    final today = localToday;
    final dateOnly = DateTime(date.year, date.month, date.day);
    return !dateOnly.isAfter(today);
  }

  /// Checks whether [date] is in the future (tomorrow or later).
  static bool isFuture(DateTime date) => !isTodayOrPast(date);

  /// Checks whether a year and month is after the current month.
  static bool isMonthInFuture(int year, int month) {
    final now = DateTime.now();
    if (year > now.year) return true;
    if (year == now.year && month > now.month) return true;
    return false;
  }

  /// Restricts a month to not exceed the current device month.
  static DateTime clampToCurrentMonth(DateTime monthDate) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    if (monthDate.isAfter(currentMonthStart)) {
      return currentMonthStart;
    }
    return DateTime(monthDate.year, monthDate.month, 1);
  }

  /// Displays a strictly restricted date picker where:
  /// - The maximum selectable date is today.
  /// - Future months cannot be navigated to.
  /// - Tomorrow and all future days in the current month are disabled.
  /// - All historical dates down to [firstDate] (default 2020) remain selectable.
  static Future<DateTime?> showRestrictedDatePicker(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    Color? primaryColor,
    Color? surfaceColor,
  }) async {
    final today = localToday;
    final effectiveFirst = firstDate ?? defaultFirstDate;

    // Clamp initialDate so it never exceeds today or precedes firstDate
    DateTime effectiveInitial = initialDate;
    if (effectiveInitial.isAfter(today)) {
      effectiveInitial = today;
    }
    if (effectiveInitial.isBefore(effectiveFirst)) {
      effectiveInitial = effectiveFirst;
    }

    return await showDatePicker(
      context: context,
      initialDate: effectiveInitial,
      firstDate: effectiveFirst,
      lastDate: today,
      selectableDayPredicate: (date) => isTodayOrPast(date),
      builder: (context, child) {
        final themePrimary = primaryColor ?? AppTheme.primaryMint;
        final themeSurface = surfaceColor ?? const Color(0xFF0B1920);

        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: themePrimary,
              onPrimary: const Color(0xFF030B15),
              surface: themeSurface,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: themeSurface,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
