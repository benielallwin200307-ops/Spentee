import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class _CategoryData {
  final String label;
  final String percent;
  final double ratio;
  final Color color;
  final IconData icon;
  const _CategoryData({
    required this.label,
    required this.percent,
    required this.ratio,
    required this.color,
    required this.icon,
  });
}

/// Screen 13 — Insights Screen
/// Shows donut chart, income vs expense summary, and category breakdown.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _monthIndex = 9; // October 2026 (0-indexed)

  final List<String> _months = const [
    'Jan 2026', 'Feb 2026', 'Mar 2026', 'Apr 2026',
    'May 2026', 'Jun 2026', 'Jul 2026', 'Aug 2026',
    'Sep 2026', 'Oct 2026', 'Nov 2026', 'Dec 2026',
  ];

  final List<_CategoryData> _categories = const [
    _CategoryData(
      label: 'Food & Dining',
      percent: '38%',
      ratio: 0.38,
      color: AppTheme.accentPink,
      icon: Icons.restaurant_rounded,
    ),
    _CategoryData(
      label: 'Shopping',
      percent: '25%',
      ratio: 0.25,
      color: AppTheme.accentPurple,
      icon: Icons.shopping_bag_rounded,
    ),
    _CategoryData(
      label: 'Transport',
      percent: '12%',
      ratio: 0.12,
      color: AppTheme.accentCyan,
      icon: Icons.directions_car_rounded,
    ),
    _CategoryData(
      label: 'Bills & Utilities',
      percent: '10%',
      ratio: 0.10,
      color: AppTheme.accentOrange,
      icon: Icons.receipt_long_rounded,
    ),
    _CategoryData(
      label: 'Entertainment',
      percent: '8%',
      ratio: 0.08,
      color: AppTheme.accentBlue,
      icon: Icons.movie_rounded,
    ),
    _CategoryData(
      label: 'Others',
      percent: '7%',
      ratio: 0.07,
      color: Color(0xFF10B981),
      icon: Icons.more_horiz_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Month Nav
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Row(
                      children: [
                        _MonthNavBtn(
                          icon: Icons.chevron_left_rounded,
                          onTap: () {
                            if (_monthIndex > 0) {
                              setState(() => _monthIndex--);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _months[_monthIndex],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _MonthNavBtn(
                          icon: Icons.chevron_right_rounded,
                          onTap: () {
                            if (_monthIndex < _months.length - 1) {
                              setState(() => _monthIndex++);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Income vs Expense summary cards
                Row(
                  children: [
                    Expanded(
                      child: SpenteeCard(
                        padding: const EdgeInsets.all(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D2D1A), Color(0xFF091C11)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                            color: AppTheme.primaryMint.withValues(alpha: 0.3),
                            width: 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryMint
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: AppTheme.primaryMint,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Total Income',
                                  style: TextStyle(
                                    color: AppTheme.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '₹ 50,000',
                              style: TextStyle(
                                color: AppTheme.primaryMint,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '+0% from last month',
                              style: TextStyle(
                                color: AppTheme.textDim,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SpenteeCard(
                        padding: const EdgeInsets.all(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D0D1A), Color(0xFF1C0911)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                            color: AppTheme.accentPink.withValues(alpha: 0.3),
                            width: 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentPink
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: AppTheme.accentPink,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Total Spent',
                                  style: TextStyle(
                                    color: AppTheme.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '₹ 12,480',
                              style: TextStyle(
                                color: AppTheme.accentPink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '-12% from last month',
                              style: TextStyle(
                                color: AppTheme.textDim,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Donut chart section
                SpenteeCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Expense Breakdown',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Donut chart
                          SizedBox(
                            width: 130,
                            height: 130,
                            child: CustomPaint(
                              painter: _DonutChartPainter(
                                categories: _categories,
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹12,480',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Legend
                          Expanded(
                            child: Column(
                              children: _categories
                                  .map((cat) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: cat.color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                cat.label,
                                                style: const TextStyle(
                                                  color: AppTheme.textGrey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              cat.percent,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // AI Insight Card
                SpenteeCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF0F1E3A),
                  border: Border.all(
                      color: AppTheme.accentBlue.withValues(alpha: 0.3),
                      width: 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'Assets/extracted/avatar_ai.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.smart_toy_rounded,
                                    color: AppTheme.accentBlue, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Insight',
                              style: TextStyle(
                                color: AppTheme.accentBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'You spent 38% on food this month. By cooking at home a few more times, you could save ₹2,000 more!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
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

class _MonthNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.textGrey, size: 18),
      ),
    );
  }
}

/// Custom donut chart painter
class _DonutChartPainter extends CustomPainter {
  final List<_CategoryData> categories;

  _DonutChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 22.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;

    for (final cat in categories) {
      final sweepAngle = 2 * math.pi * cat.ratio;
      paint.color = cat.color;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.04, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
