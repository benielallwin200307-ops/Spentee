import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import '../models/transaction.dart';

class _CategoryStat {
  final String title;
  final String amount;
  final String percentStr;
  final double ratio;
  final Color color;
  final IconData icon;

  const _CategoryStat({
    required this.title,
    required this.amount,
    required this.percentStr,
    required this.ratio,
    required this.color,
    required this.icon,
  });
}

/// Screen 9 — Analytics / Reports Screen
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedFilter = 2; // 0: Daily, 1: Weekly, 2: Monthly, 3: Yearly
  int _monthIndex = 9; // October (0-indexed: 9)

  final List<String> _filters = const ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> _months = const [
    'January 2026', 'February 2026', 'March 2026', 'April 2026',
    'May 2026', 'June 2026', 'July 2026', 'August 2026',
    'September 2026', 'October 2026', 'November 2026', 'December 2026'
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final targetMonth = _monthIndex + 1;
    const targetYear = 2026;

    // Filter genuine expense transactions for the selected month
    final monthExpenses = appState.transactions.where((t) {
      if (t.type != TransactionType.expense) return false;
      return t.date.year == targetYear && t.date.month == targetMonth;
    }).toList();

    // Previous month for trend comparison
    final prevMonth = targetMonth == 1 ? 12 : targetMonth - 1;
    final prevYear = targetMonth == 1 ? targetYear - 1 : targetYear;
    final prevExpenses = appState.transactions.where((t) {
      if (t.type != TransactionType.expense) return false;
      return t.date.year == prevYear && t.date.month == prevMonth;
    }).toList();

    double totalSpending = 0.0;
    for (final t in monthExpenses) {
      totalSpending += t.amount;
    }

    double prevSpending = 0.0;
    for (final t in prevExpenses) {
      prevSpending += t.amount;
    }

    int trendPercent = 0;
    bool isSpendingDown = true;
    if (prevSpending > 0) {
      final delta = totalSpending - prevSpending;
      trendPercent = ((delta / prevSpending) * 100).abs().round();
      isSpendingDown = delta <= 0;
    }

    // Weekly breakdown for bar chart
    final List<double> weeklyValues = [0.0, 0.0, 0.0, 0.0];
    for (final t in monthExpenses) {
      final day = t.date.day;
      if (day <= 7) {
        weeklyValues[0] += t.amount;
      } else if (day <= 14) {
        weeklyValues[1] += t.amount;
      } else if (day <= 21) {
        weeklyValues[2] += t.amount;
      } else {
        weeklyValues[3] += t.amount;
      }
    }

    // Category breakdown
    final Map<String, double> categoryTotals = {};
    for (final t in monthExpenses) {
      final cat = t.category.trim().isEmpty ? 'General' : t.category.trim();
      categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + t.amount;
    }

    final List<_CategoryStat> categoryStats = [];
    categoryTotals.forEach((cat, amt) {
      final ratio = totalSpending > 0 ? (amt / totalSpending) : 0.0;
      final percentStr = '${(ratio * 100).round()}%';
      final formattedAmt =
          '₹${amt.toStringAsFixed(amt.truncateToDouble() == amt ? 0 : 2)}';
      categoryStats.add(
        _CategoryStat(
          title: cat,
          amount: formattedAmt,
          percentStr: percentStr,
          ratio: ratio,
          color: Transaction.colorForCategory(cat),
          icon: Transaction.iconForCategory(cat),
        ),
      );
    });

    // Sort categories by highest amount
    categoryStats.sort((a, b) => b.ratio.compareTo(a.ratio));

    final totalSpendingStr =
        '₹${totalSpending.toStringAsFixed(totalSpending.truncateToDouble() == totalSpending ? 0 : 2)}';

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
                // Title
                const Text(
                  'Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                // Period Filter Pills
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: List.generate(_filters.length, (index) {
                      final isSelected = index == _selectedFilter;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryMint : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _filters[index],
                              style: TextStyle(
                                color: isSelected ? AppTheme.bgDark : AppTheme.textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // Month Selector Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textGrey, size: 16),
                      onPressed: () {
                        setState(() {
                          if (_monthIndex > 0) _monthIndex--;
                        });
                      },
                    ),
                    Text(
                      _months[_monthIndex],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textGrey, size: 16),
                      onPressed: () {
                        setState(() {
                          if (_monthIndex < _months.length - 1) _monthIndex++;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Spending Total Card with Trend
                SpenteeCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Spending',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (prevSpending > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isSpendingDown ? AppTheme.primaryMint : AppTheme.accentPink).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSpendingDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: isSpendingDown ? AppTheme.primaryMint : AppTheme.accentPink,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$trendPercent% vs last month',
                                    style: TextStyle(
                                      color: isSpendingDown ? AppTheme.primaryMint : AppTheme.accentPink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalSpendingStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bar Chart Representation
                      _SimpleBarChart(weeklyValues: weeklyValues),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Category Breakdown Header
                const Text(
                  'Category Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Category Breakdown List or Empty State
                if (categoryStats.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.borderSubtle, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: const [
                        Icon(Icons.pie_chart_outline_rounded,
                            color: AppTheme.textDim, size: 40),
                        SizedBox(height: 10),
                        Text(
                          'No spending recorded for this period.',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryStats.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = categoryStats[index];
                      return SpenteeCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        borderRadius: 16,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CategoryBadge(icon: item.icon, color: item.color, size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  item.amount,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    item.percentStr,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.ratio,
                                backgroundColor: AppTheme.bgSurface,
                                valueColor: AlwaysStoppedAnimation<Color>(item.color),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

/// Sleek dynamic bar chart reflecting real weekly totals.
class _SimpleBarChart extends StatelessWidget {
  final List<double> weeklyValues;
  const _SimpleBarChart({required this.weeklyValues});

  final List<String> weekLabels = const ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
  final List<LinearGradient> barGradients = const [
    LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0284C7)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Color(0xFFFF3366), Color(0xFFBE185D)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF6B21A8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    LinearGradient(colors: [Color(0xFF00E676), Color(0xFF047857)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
  ];

  @override
  Widget build(BuildContext context) {
    double maxVal = 0.0;
    for (final v in weeklyValues) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal <= 0) maxVal = 1000.0;

    const double chartHeight = 150;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y-Axis markers
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(maxVal / 1000).toStringAsFixed(1)}K', style: const TextStyle(color: AppTheme.textDim, fontSize: 10)),
                  Text('${(maxVal * 0.66 / 1000).toStringAsFixed(1)}K', style: const TextStyle(color: AppTheme.textDim, fontSize: 10)),
                  Text('${(maxVal * 0.33 / 1000).toStringAsFixed(1)}K', style: const TextStyle(color: AppTheme.textDim, fontSize: 10)),
                  const Text('0', style: TextStyle(color: AppTheme.textDim, fontSize: 10)),
                ],
              ),
              const SizedBox(width: 12),

              // Bars Container
              Expanded(
                child: Stack(
                  children: [
                    // Grid background lines
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (_) => const Divider(color: AppTheme.borderSubtle, height: 1),
                      ),
                    ),

                    // Actual Bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(weeklyValues.length, (index) {
                        final val = weeklyValues[index];
                        final ratio = (val / maxVal).clamp(0.0, 1.0);
                        final barHeight = val > 0 ? (ratio * chartHeight).clamp(6.0, chartHeight) : 4.0;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 32,
                              height: barHeight,
                              decoration: BoxDecoration(
                                gradient: val > 0 ? barGradients[index] : null,
                                color: val == 0 ? AppTheme.bgSurface : null,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                boxShadow: val > 0
                                    ? [
                                        BoxShadow(
                                          color: barGradients[index].colors.first.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, -2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // X-Axis labels
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: weekLabels.map((lbl) {
              return Expanded(
                child: Center(
                  child: Text(
                    lbl,
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
