import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'add_transaction_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

/// The Main Shell widget holding the persistent Bottom Navigation Bar and primary screens.
/// Bottom Nav: Home | Insights | + (Add) | Spentee AI | Profile
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      // Center Add button opens AddTransactionScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              const AddTransactionScreen(initialType: TransactionType.expense),
        ),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Map nav indices skipping 2 (Add button)
    final screens = [
      HomeScreen(
        onOpenInsights: () => setState(() => _currentIndex = 1),
        onOpenChallenges: () => setState(() => _currentIndex = 3),
        onOpenProfile: () => setState(() => _currentIndex = 4),
      ),
      const InsightsScreen(),
      const SizedBox.shrink(), // Placeholder for center Add button
      const ChatScreen(),
      const ProfileScreen(),
    ];

    final theme = MascotThemeData.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF061220),
          border: const Border(
            top: BorderSide(color: Color(0x1F38BDF8), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: _currentIndex == 0,
                    onTap: () => _onTabSelected(0),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Insights',
                    isSelected: _currentIndex == 1,
                    onTap: () => _onTabSelected(1),
                  ),
                ),
                // Raised Center '+' Button with radiant glow
                GestureDetector(
                  onTap: () => _onTabSelected(2),
                  child: Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryAccent.withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppTheme.bgDark,
                      size: 32,
                    ),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Spentee AI',
                    isSelected: _currentIndex == 3,
                    onTap: () => _onTabSelected(3),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: _currentIndex == 4,
                    onTap: () => _onTabSelected(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MascotThemeData.of(context);
    final color = isSelected ? theme.primaryAccent : AppTheme.textGrey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
