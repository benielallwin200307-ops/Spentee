import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'leaderboard_screen.dart';

class _GameCardData {
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final LinearGradient gradient;

  const _GameCardData({
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    required this.gradient,
  });
}

/// Screen 12 — Puzzle Games Screen
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _selectedTabIndex = 0; // 0: Play, 1: Leaderboard, 2: My Stats

  late Timer _countdownTimer;
  int _remainingSeconds = 37530; // ~ 10:25:30

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  String get _formattedCountdown {
    final hours = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  final List<_GameCardData> _games = const [
    _GameCardData(
      title: 'Number Puzzle',
      subtitle: 'Beat your best time',
      gradient: AppTheme.gameOrangeGradient,
      iconWidget: Text('1 2\n3 4', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
    ),
    _GameCardData(
      title: 'Memory Match',
      subtitle: 'Test your memory',
      gradient: AppTheme.gamePurpleGradient,
      iconWidget: Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
    ),
    _GameCardData(
      title: 'Math Rush',
      subtitle: 'Solve and speed up',
      gradient: AppTheme.gameBlueGradient,
      iconWidget: Text('+ + \n+ +', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
    ),
    _GameCardData(
      title: 'Pattern Puzzle',
      subtitle: 'Find the next pattern',
      gradient: AppTheme.gamePinkGradient,
      iconWidget: Icon(Icons.category_rounded, color: Colors.white, size: 30),
    ),
  ];

  void _openPlayableMathRush(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PlayableMathGameSheet(),
    );
  }

  void _openComingSoonDialog(BuildContext context, String gameName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(gameName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryMint.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: AppTheme.primaryMint, size: 34),
            ),
            const SizedBox(height: 14),
            const Text(
              'This game mode is in active development for the next update! Try "Math Rush" or the "Daily Challenge" for a playable demo.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          NeonButton(
            text: 'Got It!',
            onPressed: () => Navigator.pop(ctx),
            height: 44,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Puzzle Games',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, color: AppTheme.accentYellow),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Segment Tabs: Play, Leaderboard, My Stats
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _GameTabPill(
                        label: 'Play',
                        isSelected: _selectedTabIndex == 0,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                      _GameTabPill(
                        label: 'Leaderboard',
                        isSelected: _selectedTabIndex == 1,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                          );
                        },
                      ),
                      _GameTabPill(
                        label: 'My Stats',
                        isSelected: _selectedTabIndex == 2,
                        onTap: () => setState(() => _selectedTabIndex = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_selectedTabIndex == 2) ...[
                  // My Stats Tab Content
                  _buildMyStatsView(),
                ] else ...[
                  // 2x2 Grid of Puzzle Cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      final game = _games[index];
                      return GestureDetector(
                        onTap: () {
                          if (game.title == 'Math Rush' || game.title == 'Number Puzzle') {
                            _openPlayableMathRush(context);
                          } else {
                            _openComingSoonDialog(context, game.title);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: game.gradient,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: game.gradient.colors.first.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: game.iconWidget,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    game.subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // Daily Challenge Card (Matching Visual Reference)
                  SpenteeCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daily Challenge',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: AppTheme.accentCyan, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formattedCountdown,
                                    style: const TextStyle(
                                      color: AppTheme.accentCyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryMint.withValues(alpha: 0.15),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'Assets/extracted/avatar_win.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset('Assets/extracted/mascot_main.png'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Puzzle",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Complete it now and climb the global leaderboard!',
                                    style: TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        NeonButton(
                          text: 'Play Now',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () => _openPlayableMathRush(context),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyStatsView() {
    return Column(
      children: [
        SpenteeCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Player Profile: You',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(title: 'Puzzles Solved', value: '14', color: AppTheme.primaryMint),
                  _StatBox(title: 'Best Speed', value: '00:42', color: AppTheme.accentCyan),
                  _StatBox(title: 'Win Streak', value: '5 Days', color: AppTheme.accentOrange),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppTheme.borderSubtle),
              const SizedBox(height: 12),
              const Text(
                'Financial IQ: Level 4 (Savvy Saver)',
                style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatBox({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }
}

class _GameTabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GameTabPill({
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

/// Interactive Playable Quick Math Demo Game Sheet
class _PlayableMathGameSheet extends StatefulWidget {
  const _PlayableMathGameSheet();

  @override
  State<_PlayableMathGameSheet> createState() => _PlayableMathGameSheetState();
}

class _PlayableMathGameSheetState extends State<_PlayableMathGameSheet> {
  int _score = 0;
  int _qIndex = 0;
  bool _finished = false;

  final List<Map<String, dynamic>> _questions = const [
    {
      'q': '₹250 spent on coffee + ₹80 bus fare = ?',
      'options': ['₹330', '₹350', '₹320', '₹310'],
      'ans': 0,
    },
    {
      'q': 'If you save 20% of ₹25,000, how much do you save?',
      'options': ['₹4,000', '₹5,000', '₹6,000', '₹3,500'],
      'ans': 1,
    },
    {
      'q': 'Cut 3 food deliveries of ₹400 each per month. Total saved?',
      'options': ['₹1,000', '₹1,500', '₹1,200', '₹800'],
      'ans': 2,
    },
  ];

  void _answer(int selectedIndex) {
    if (selectedIndex == _questions[_qIndex]['ans']) {
      _score += 10;
    }
    if (_qIndex < _questions.length - 1) {
      setState(() {
        _qIndex++;
      });
    } else {
      setState(() {
        _finished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Math Rush • Live Demo',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textGrey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_finished) ...[
            Text(
              'Question ${_qIndex + 1} of ${_questions.length}',
              style: const TextStyle(color: AppTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                _questions[_qIndex]['q'],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: List.generate(4, (index) {
                final optionText = (_questions[_qIndex]['options'] as List<String>)[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _answer(index),
                      child: Text(optionText, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }),
            ),
          ] else ...[
            const Icon(Icons.military_tech_rounded, color: AppTheme.accentYellow, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Challenge Complete!',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Score: $_score Points • Solved in 00:38',
              style: const TextStyle(color: AppTheme.primaryMint, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            NeonButton(
              text: 'View on Leaderboard',
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
