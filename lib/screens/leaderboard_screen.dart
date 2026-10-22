import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import '../models/roast.dart';

/// Screen 13 — Global Leaderboard Screen
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedFilter = 0; // 0: Daily, 1: Weekly

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final entries = _selectedFilter == 0 ? appState.dailyLeaderboard : appState.weeklyLeaderboard;

    final first = entries[0];
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;
    final restList = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Global Leaderboard',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Daily / Weekly Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _TabPill(
                        label: 'Daily',
                        isSelected: _selectedFilter == 0,
                        onTap: () => setState(() => _selectedFilter = 0),
                      ),
                      _TabPill(
                        label: 'Weekly',
                        isSelected: _selectedFilter == 1,
                        onTap: () => setState(() => _selectedFilter = 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Top 3 Podium
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Rank 2 (Silver)
                    if (second != null)
                      _PodiumColumn(
                        entry: second,
                        podiumHeight: 90,
                        crownColor: const Color(0xFFC0C0C0),
                        podiumColor: const Color(0xFF1E3A5F),
                        badgeText: '2',
                      ),
                    const SizedBox(width: 14),

                    // Rank 1 (Gold, Center, Tallest)
                    _PodiumColumn(
                      entry: first,
                      podiumHeight: 125,
                      crownColor: AppTheme.accentYellow,
                      podiumColor: const Color(0xFF2E4E78),
                      badgeText: '1',
                      isWinner: true,
                    ),
                    const SizedBox(width: 14),

                    // Rank 3 (Bronze)
                    if (third != null)
                      _PodiumColumn(
                        entry: third,
                        podiumHeight: 70,
                        crownColor: const Color(0xFFCD7F32),
                        podiumColor: const Color(0xFF172B47),
                        badgeText: '3',
                      ),
                  ],
                ),

                const SizedBox(height: 28),

                // Ranks 4+ List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: restList.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = restList[index];
                    final isUser = item.isCurrentUser;
                    final theme = MascotThemeData.of(context);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? theme.primaryAccent.withValues(alpha: 0.16)
                            : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isUser ? theme.primaryAccent : AppTheme.borderSubtle,
                          width: isUser ? 2 : 1,
                        ),
                        boxShadow: isUser
                            ? [
                                BoxShadow(
                                  color: theme.primaryAccent.withValues(alpha: 0.2),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Rank number
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${item.rank}',
                              style: TextStyle(
                                color: isUser ? theme.primaryAccent : AppTheme.textGrey,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Avatar
                          MascotAvatar(
                            size: 38,
                            initials: isUser
                                ? (appState.userName.isNotEmpty
                                    ? appState.userName[0]
                                    : 'U')
                                : (item.username.isNotEmpty
                                    ? item.username[0]
                                    : 'P'),
                            hasGlow: isUser,
                          ),
                          const SizedBox(width: 12),
                          // Username
                          Expanded(
                            child: Text(
                              item.username,
                              style: TextStyle(
                                color: isUser ? theme.primaryAccent : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          // Time
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.time,
                              style: TextStyle(
                                color: isUser ? AppTheme.primaryMint : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Demo Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textDim),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rankings are demo data showing how you compare with other players.',
                          style: TextStyle(color: AppTheme.textDim, fontSize: 11),
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
      ),
    );
  }
}

/// Helper for podium column.
class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final double podiumHeight;
  final Color crownColor;
  final Color podiumColor;
  final String badgeText;
  final bool isWinner;

  const _PodiumColumn({
    required this.entry,
    required this.podiumHeight,
    required this.crownColor,
    required this.podiumColor,
    required this.badgeText,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isWinner)
          Icon(Icons.workspace_premium_rounded, color: crownColor, size: 28)
        else
          const SizedBox(height: 28),
        const SizedBox(height: 4),

        // Avatar
        Container(
          width: isWinner ? 64 : 52,
          height: isWinner ? 64 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: crownColor.withValues(alpha: 0.15),
            border: Border.all(color: crownColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: crownColor.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : 'U',
              style: TextStyle(
                color: crownColor,
                fontSize: isWinner ? 24 : 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Username
        Text(
          entry.username,
          style: TextStyle(
            color: Colors.white,
            fontSize: isWinner ? 13 : 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),

        // Time
        Text(
          entry.time,
          style: TextStyle(
            color: isWinner ? AppTheme.primaryMint : AppTheme.textGrey,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Podium Block
        Container(
          width: isWinner ? 84 : 74,
          height: podiumHeight,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: crownColor.withValues(alpha: 0.3), width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            badgeText,
            style: TextStyle(
              color: crownColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryMint : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.bgDark : AppTheme.textGrey,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
