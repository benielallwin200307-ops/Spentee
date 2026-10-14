import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import 'main_shell.dart';

class _NotificationItemData {
  final String keyName;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _NotificationItemData({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}

/// Screen 6 — Notification Preferences Screen
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<_NotificationItemData> _items = const [
    _NotificationItemData(
      keyName: 'daily',
      title: 'Daily reminder',
      subtitle: "Add today's expenses",
      icon: Icons.calendar_today_rounded,
      iconColor: AppTheme.accentPink,
    ),
    _NotificationItemData(
      keyName: 'weekly',
      title: 'Weekly summary',
      subtitle: 'Your spending report',
      icon: Icons.pie_chart_outline_rounded,
      iconColor: AppTheme.accentPurple,
    ),
    _NotificationItemData(
      keyName: 'budget',
      title: 'Budget alerts',
      subtitle: 'Know before you overspend',
      icon: Icons.shield_outlined,
      iconColor: AppTheme.accentOrange,
    ),
    _NotificationItemData(
      keyName: 'roasts',
      title: 'Fun roasts',
      subtitle: 'Get a daily laugh',
      icon: Icons.local_fire_department_rounded,
      iconColor: AppTheme.accentPink,
    ),
    _NotificationItemData(
      keyName: 'puzzles',
      title: 'Puzzle reminders',
      subtitle: "Don't miss daily challenges",
      icon: Icons.extension_rounded,
      iconColor: AppTheme.accentCyan,
    ),
  ];

  void _onContinue(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final preferences = appState.notifications;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Stay on track\nwith reminders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose the notifications you want.',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              // Notification toggles list
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isEnabled = preferences[item.keyName] ?? false;

                    return SpenteeCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderRadius: 18,
                      child: Row(
                        children: [
                          CategoryBadge(
                            icon: item.icon,
                            color: item.iconColor,
                            size: 44,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(
                                    color: AppTheme.textGrey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isEnabled,
                            activeTrackColor: AppTheme.primaryMint,
                            activeThumbColor: AppTheme.bgDark,
                            inactiveTrackColor: AppTheme.bgElevated,
                            inactiveThumbColor: AppTheme.textDim,
                            onChanged: (_) {
                              appState.toggleNotification(item.keyName);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: NeonButton(
                  text: 'Continue',
                  onPressed: () => _onContinue(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
