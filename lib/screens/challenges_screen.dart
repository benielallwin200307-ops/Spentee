import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'leaderboard_screen.dart';

class _ChallengeData {
  final String title;
  final String subtitle;
  final int points;
  final IconData icon;
  final Color color;
  final bool completed;
  const _ChallengeData({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.icon,
    required this.color,
    this.completed = false,
  });
}

/// Screen 14 — Challenges Screen
/// Daily / Weekly / Leaderboard tabs matching the reference storyboard.
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  int _tabIndex = 0; // 0: Daily, 1: Weekly, 2: Leaderboard

  final List<String> _tabs = const ['Daily', 'Weekly', 'Leaderboard'];

  final _ChallengeData _todayChallenge = const _ChallengeData(
    title: 'No Spend Day',
    subtitle: 'Try not to spend on food today. Can you do it?',
    points: 50,
    icon: Icons.block_rounded,
    color: AppTheme.primaryMint,
  );

  final List<_ChallengeData> _otherChallenges = const [
    _ChallengeData(
      title: 'Save ₹500',
      subtitle: 'Save ₹500 this week',
      points: 50,
      icon: Icons.savings_rounded,
      color: AppTheme.accentCyan,
    ),
    _ChallengeData(
      title: 'Track 5 Expenses',
      subtitle: 'Add 5 expenses today',
      points: 30,
      icon: Icons.receipt_long_rounded,
      color: AppTheme.accentPurple,
    ),
    _ChallengeData(
      title: 'Stay in Budget',
      subtitle: 'Keep daily spend under ₹500',
      points: 40,
      icon: Icons.shield_rounded,
      color: AppTheme.accentOrange,
      completed: true,
    ),
  ];

  final List<_ChallengeData> _weeklyChallenges = const [
    _ChallengeData(
      title: 'Zero Food Delivery',
      subtitle: 'Avoid food delivery for 7 days',
      points: 150,
      icon: Icons.delivery_dining_rounded,
      color: AppTheme.accentPink,
    ),
    _ChallengeData(
      title: 'Save 20% of income',
      subtitle: 'Save at least 20% of weekly income',
      points: 200,
      icon: Icons.trending_up_rounded,
      color: AppTheme.primaryMint,
    ),
    _ChallengeData(
      title: 'Track Every Rupee',
      subtitle: 'Log every expense for 7 days',
      points: 100,
      icon: Icons.fact_check_rounded,
      color: AppTheme.accentCyan,
      completed: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Challenges',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            color: AppTheme.accentOrange, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '5 Day Streak',
                          style: TextStyle(
                            color: AppTheme.accentOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = index == _tabIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (index == 2) {
                            // Navigate to leaderboard
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const LeaderboardScreen()),
                            );
                            return;
                          }
                          setState(() => _tabIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryMint
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.bgDark
                                  : AppTheme.textGrey,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: _tabIndex == 0
                    ? _buildDailyTab()
                    : _buildWeeklyTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today's Challenge Hero Card
        const Text(
          "Today's Challenge",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SpenteeCard(
          padding: const EdgeInsets.all(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryMint.withValues(alpha: 0.18),
              AppTheme.primaryMint.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
              color: AppTheme.primaryMint.withValues(alpha: 0.4), width: 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_todayChallenge.icon,
                        color: AppTheme.primaryMint, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _todayChallenge.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _todayChallenge.subtitle,
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PillBadge(
                    text: '+${_todayChallenge.points}',
                    icon: Icons.star_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              NeonButton(
                text: 'Start Challenge',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '🏆 Challenge started! Good luck today.'),
                      backgroundColor: AppTheme.bgCard,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Other Challenges',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        ..._otherChallenges.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChallengeTile(challenge: c),
            )),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWeeklyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Challenges',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._weeklyChallenges.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChallengeTile(challenge: c),
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  final _ChallengeData challenge;

  const _ChallengeTile({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return SpenteeCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: challenge.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(challenge.icon, color: challenge.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  challenge.subtitle,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          challenge.completed
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMint.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.primaryMint,
                    size: 16,
                  ),
                )
              : PillBadge(
                  text: '+${challenge.points}',
                  icon: Icons.star_rounded,
                ),
        ],
      ),
    );
  }
}
