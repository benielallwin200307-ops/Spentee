import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Screen for managing notifications, spending reminders, budget alerts, and AI roasts.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (_) {}
    return timeStr;
  }

  Future<void> _pickTime(BuildContext context, AppState appState) async {
    int initialHour = 20;
    int initialMinute = 0;
    try {
      final parts = appState.notificationTime.split(':');
      if (parts.length >= 2) {
        initialHour = int.parse(parts[0]);
        initialMinute = int.parse(parts[1]);
      }
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryMint,
              onPrimary: Color(0xFF03161C),
              surface: Color(0xFF0B1F27),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0B1F27),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      appState.setNotificationTime(timeStr);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Daily reminder set to ${_formatTime(timeStr)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF0C2A34),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final notifs = appState.notifications;

    final isDaily = notifs['daily'] ?? true;
    final isWeekly = notifs['weekly'] ?? true;
    final isBudget = notifs['budget'] ?? true;
    final isRoasts = notifs['roasts'] ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFF030D11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF092027),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF133C47)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reminders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stay on Track',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Configure notifications to build healthy spending habits effortlessly.',
                style: TextStyle(
                  color: Color(0xFF6C8C96),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Daily Reminder Card
              _ReminderCard(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFFFFB300),
                iconBg: const Color(0xFF2C220E),
                title: 'Daily Spending Log',
                subtitle: 'A gentle evening nudge to record today\'s expenses.',
                value: isDaily,
                onChanged: (val) => appState.setNotification('daily', val),
                child: isDaily
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: InkWell(
                          onTap: () => _pickTime(context, appState),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF061B22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryMint.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_filled_rounded,
                                      size: 18,
                                      color: AppTheme.primaryMint,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Reminder Time',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _formatTime(appState.notificationTime),
                                      style: const TextStyle(
                                        color: AppTheme.primaryMint,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.edit_rounded,
                                      size: 16,
                                      color: AppTheme.textGrey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 16),

              // Section 2: Weekly Summary
              _ReminderCard(
                icon: Icons.calendar_view_week_rounded,
                iconColor: const Color(0xFF00E5FF),
                iconBg: const Color(0xFF082C38),
                title: 'Weekly Spending Summary',
                subtitle:
                    'Receive an AI breakdown of your weekly cash flow every Sunday.',
                value: isWeekly,
                onChanged: (val) => appState.setNotification('weekly', val),
              ),

              const SizedBox(height: 16),

              // Section 3: Budget Alert
              _ReminderCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFFF5252),
                iconBg: const Color(0xFF331418),
                title: 'Budget Threshold Warnings',
                subtitle:
                    'Instant alert when any category exceeds 80% or 100% of its budget limit.',
                value: isBudget,
                onChanged: (val) => appState.setNotification('budget', val),
              ),

              const SizedBox(height: 16),

              // Section 4: Daily AI Roast & Motivation
              _ReminderCard(
                icon: Icons.auto_awesome_rounded,
                iconColor: AppTheme.primaryMint,
                iconBg: const Color(0xFF0B2E28),
                title: 'AI Roast & Daily Motivation',
                subtitle:
                    'Witty remarks and savings encouragement from your companion mascot.',
                value: isRoasts,
                onChanged: (val) => appState.setNotification('roasts', val),
              ),

              const SizedBox(height: 28),

              // Info Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF071922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF133642)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: AppTheme.primaryMint,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your notification preferences are securely saved on your device and respect Android system Do Not Disturb settings.',
                        style: TextStyle(
                          color: Color(0xFF88A8B4),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? child;

  const _ReminderCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF081820),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? AppTheme.primaryMint.withValues(alpha: 0.25)
              : const Color(0xFF122C38),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7C9BA6),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                activeThumbColor: AppTheme.primaryMint,
                activeTrackColor: AppTheme.primaryMint.withValues(alpha: 0.35),
                inactiveThumbColor: const Color(0xFF6A8691),
                inactiveTrackColor: const Color(0xFF0E232B),
                onChanged: onChanged,
              ),
            ],
          ),
          ?child,
        ],
      ),
    );
  }
}
