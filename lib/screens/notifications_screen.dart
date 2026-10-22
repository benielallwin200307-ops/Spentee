import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import 'auth_screens.dart';

class _NotificationCardData {
  final String keyName;
  final String title;
  final String subtitle;
  final String badgeAsset;

  const _NotificationCardData({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.badgeAsset,
  });
}

/// Screen 6 — Notification Preferences Screen
/// Recreated with Spentee mascot, bell speech bubble, custom switches, and design fidelity.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color bgNavy = Color(0xFF00111A);
  static const Color mintGreen = Color(0xFF45F59A);

  final List<_NotificationCardData> _items = const [
    _NotificationCardData(
      keyName: 'daily',
      title: 'Daily reminder',
      subtitle: "Add today's expenses",
      badgeAsset: 'Assets/extracted/notif_daily.png',
    ),
    _NotificationCardData(
      keyName: 'weekly',
      title: 'Weekly summary',
      subtitle: 'Your spending report',
      badgeAsset: 'Assets/extracted/notif_weekly.png',
    ),
    _NotificationCardData(
      keyName: 'budget',
      title: 'Budget alerts',
      subtitle: 'Know before you overspend',
      badgeAsset: 'Assets/extracted/notif_budget.png',
    ),
    _NotificationCardData(
      keyName: 'roasts',
      title: 'Fun roasts',
      subtitle: 'Get a daily laugh',
      badgeAsset: 'Assets/extracted/notif_roasts.png',
    ),
  ];

  void _onContinue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final topPadding = mediaQuery.padding.top;
    final appState = AppStateScope.of(context);
    final preferences = appState.notifications;

    // The artwork aspect ratio from reference image is 504 width x 342 height
    final topArtHeight = screenWidth * (342.0 / 504.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: bgNavy,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgNavy,
        body: Stack(
          children: [
            // Dark teal gradient background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF00151C),
                      Color(0xFF00191B),
                      Color(0xFF000F14),
                    ],
                  ),
                ),
              ),
            ),

            // Scrollable content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Top Section: Clean Bell Emblem Header
                    SizedBox(
                      width: double.infinity,
                      height: topArtHeight < 140.0 ? 140.0 : topArtHeight * 0.75,
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: mintGreen.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: mintGreen.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: mintGreen.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.notifications_active_rounded,
                                  color: mintGreen,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          // Subtle back button if navigable
                          if (Navigator.of(context).canPop())
                            Positioned(
                              top: topPadding + 4,
                              left: 12,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Heading: 2 lines
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Stay on track\n',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: 'with ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: 'reminders',
                            style: TextStyle(
                              color: mintGreen,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Choose the notifications you want.',
                      style: TextStyle(
                        color: Color(0xFFC7DBD7),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 18),

                    // 4 Notification Preference Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: List.generate(_items.length, (index) {
                          final item = _items[index];
                          final isEnabled = preferences[item.keyName] ?? true;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => appState.toggleNotification(item.keyName),
                                borderRadius: BorderRadius.circular(22),
                                splashColor: mintGreen.withValues(alpha: 0.1),
                                highlightColor: Colors.transparent,
                                child: Container(
                                  height: 62,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF021B1E),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: const Color(0xFF144144),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Rounded badge icon
                                      Image.asset(
                                        item.badgeAsset,
                                        width: 42,
                                        height: 42,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 14),

                                      // Title & subtitle
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.2,
                                                height: 1.15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.subtitle,
                                              style: const TextStyle(
                                                color: Color(0xFF7FA7A2),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                height: 1.15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Mint Toggle Switch
                                      GestureDetector(
                                        onTap: () => appState.toggleNotification(item.keyName),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 52,
                                          height: 28,
                                          padding: const EdgeInsets.all(2.5),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            color: isEnabled
                                                ? mintGreen
                                                : const Color(0xFF0D2D30),
                                          ),
                                          child: AnimatedAlign(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeInOut,
                                            alignment: isEnabled
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: Container(
                                              width: 23,
                                              height: 23,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isEnabled
                                                    ? Colors.white
                                                    : const Color(0xFF6B8A87),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onContinue(context),
                        child: Container(
                          height: 64,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6DFDB5),
                                Color(0xFF38EE91),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38EE91).withValues(alpha: 0.45),
                                blurRadius: 24,
                                spreadRadius: 3,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  color: Color(0xFF002B21),
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Positioned(
                                right: 24,
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF002B21),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: mediaQuery.padding.bottom + 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
