import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import 'splash_screen.dart';

/// Screen 15 — Profile Settings Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 20),

                // Profile Header Card
                SpenteeCard(
                  padding: const EdgeInsets.all(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C2740), Color(0xFF081A28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: AppTheme.primaryMint.withValues(alpha: 0.2),
                      width: 1),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.primaryMint, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryMint.withValues(alpha: 0.25),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            appState.selectedMascot == 'female'
                                ? 'Assets/extracted/female_main.png'
                                : 'Assets/extracted/mascot_main.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AppTheme.bgElevated,
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppTheme.primaryMint,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alex',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'alex@example.com',
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primaryMint.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.primaryMint
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                '✨ Level 4 • Savvy Saver',
                                style: TextStyle(
                                  color: AppTheme.primaryMint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Settings sections
                _ProfileSection(
                  title: 'Finance',
                  items: [
                    _ProfileItem(
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppTheme.primaryMint,
                      label: 'Manage Budget',
                      onTap: () => _showComingSoon(context, 'Manage Budget'),
                    ),
                    _ProfileItem(
                      icon: Icons.category_rounded,
                      color: AppTheme.accentPurple,
                      label: 'Categories',
                      onTap: () => _showComingSoon(context, 'Categories'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ProfileSection(
                  title: 'App Settings',
                  items: [
                    _ProfileItem(
                      icon: Icons.notifications_rounded,
                      color: AppTheme.accentOrange,
                      label: 'Reminders',
                      onTap: () => _showComingSoon(context, 'Reminders'),
                    ),
                    _ProfileItem(
                      icon: Icons.language_rounded,
                      color: AppTheme.accentCyan,
                      label: 'Language',
                      trailing: Text(
                        appState.selectedLanguage,
                        style: const TextStyle(
                          color: AppTheme.primaryMint,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _showComingSoon(context, 'Language'),
                    ),
                    _ProfileItem(
                      icon: Icons.brightness_2_rounded,
                      color: AppTheme.accentBlue,
                      label: 'Theme',
                      trailing: const Text(
                        'Dark',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => _showComingSoon(context, 'Theme'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ProfileSection(
                  title: 'Support',
                  items: [
                    _ProfileItem(
                      icon: Icons.help_outline_rounded,
                      color: AppTheme.accentYellow,
                      label: 'Help & Support',
                      onTap: () => _showComingSoon(context, 'Help & Support'),
                    ),
                    _ProfileItem(
                      icon: Icons.info_outline_rounded,
                      color: AppTheme.textGrey,
                      label: 'About Spentee',
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Logout Button
                GestureDetector(
                  onTap: () => _onLogout(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppTheme.accentPink.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: AppTheme.accentPink, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: AppTheme.accentPink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Footer branding
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 28,
                        child: Image.asset(
                          'Assets/spentee_splash_wordmark.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                            'Spentee',
                            style: TextStyle(
                              color: AppTheme.primaryMint,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Version 1.0.0 • Your AI Money Companion',
                        style: TextStyle(
                          color: AppTheme.textDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'About Spentee',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Spentee — Your AI Money Companion\n\nTrack every rupee without the stress. Get roasted (with love), play financial puzzles, and build smart money habits.',
              style:
                  TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                  color: AppTheme.primaryMint,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ],
        ),
        actions: [
          NeonButton(
            text: 'Close',
            onPressed: () => Navigator.pop(ctx),
            height: 44,
          ),
        ],
      ),
    );
  }

  void _onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout?',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your data will be cleared. Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textGrey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout',
                style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileItem> items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textGrey,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        SpenteeCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    title: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: item.trailing ??
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.textDim,
                          size: 14,
                        ),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppTheme.borderSubtle,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final Color color;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileItem({
    required this.icon,
    required this.color,
    required this.label,
    this.trailing,
    this.onTap,
  });
}
