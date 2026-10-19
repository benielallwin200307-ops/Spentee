import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import 'transactions_screen.dart';

/// Data model for category expense breakdown
class _CategoryBreakdown {
  final String label;
  final double amount;
  final double ratio;
  final String percent;
  final Color color;
  final IconData icon;

  const _CategoryBreakdown({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.percent,
    required this.color,
    required this.icon,
  });
}

/// Month trend data point for the 6-month comparison chart
class _MonthTrendData {
  final DateTime date;
  final String label;
  final double income;
  final double expense;

  const _MonthTrendData({
    required this.date,
    required this.label,
    required this.income,
    required this.expense,
  });
}

/// Screen 13 — Spentee Insights Screen
/// Redesigned to closely match the reference fintech design.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  // Default reporting period: October 2026 (matching reference and app timeline)
  late DateTime _selectedPeriod;

  final List<String> _monthNames = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Prefer October 2026 if current year is 2026, or current month/year
    if (now.year == 2026) {
      _selectedPeriod = DateTime(2026, 10, 1);
    } else {
      _selectedPeriod = DateTime(now.year, now.month, 1);
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month + 1, 1);
    });
  }

  void _selectMonth(DateTime date) {
    setState(() {
      _selectedPeriod = DateTime(date.year, date.month, 1);
    });
  }

  /// Format an amount into standard Indian Rupee format (e.g. ₹ 50,000 or ₹ 12,480)
  String _formatINR(double amount, {bool showDecimals = false, bool spaceAfterSymbol = false}) {
    if (amount <= 0 && amount > -0.01) return spaceAfterSymbol ? '₹ 0' : '₹0';
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final intPart = absAmount.truncate();
    final decPart = showDecimals ? (absAmount - intPart).toStringAsFixed(2).substring(1) : '';

    final str = intPart.toString();
    String formatted;
    if (str.length <= 3) {
      formatted = str;
    } else {
      final lastThree = str.substring(str.length - 3);
      final remaining = str.substring(0, str.length - 3);
      final buffer = StringBuffer();

      for (int i = 0; i < remaining.length; i++) {
        if (i > 0 && (remaining.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(remaining[i]);
      }
      buffer.write(',');
      buffer.write(lastThree);
      formatted = buffer.toString();
    }

    final symbol = spaceAfterSymbol ? '₹ ' : '₹';
    return '${isNegative ? '-' : ''}$symbol$formatted$decPart';
  }

  /// Format short numbers for chart Y-axis (e.g. 60K, 40K, 0)
  String _formatCompact(double value) {
    if (value <= 0) return '0';
    if (value >= 100000) {
      final l = (value / 100000).toStringAsFixed(1).replaceAll('.0', '');
      return '${l}L';
    }
    if (value >= 1000) {
      final k = (value / 1000).toStringAsFixed(0);
      return '${k}K';
    }
    return value.toStringAsFixed(0);
  }

  /// Map category name to icon
  IconData _iconForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('dining') || cat.contains('drink')) {
      return Icons.restaurant_rounded;
    }
    if (cat.contains('shop')) {
      return Icons.shopping_bag_rounded;
    }
    if (cat.contains('transport') || cat.contains('cab') || cat.contains('car') || cat.contains('fuel')) {
      return Icons.directions_car_rounded;
    }
    if (cat.contains('bill') || cat.contains('utilit') || cat.contains('electric') || cat.contains('wifi')) {
      return Icons.receipt_long_rounded;
    }
    if (cat.contains('entertain') || cat.contains('game') || cat.contains('movie')) {
      return Icons.sports_esports_rounded;
    }
    if (cat.contains('grocer')) {
      return Icons.local_grocery_store_rounded;
    }
    if (cat.contains('health') || cat.contains('medical')) {
      return Icons.medical_services_rounded;
    }
    return Icons.more_horiz_rounded;
  }

  /// Map category name to curated color
  Color _colorForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') || cat.contains('dining') || cat.contains('drink')) {
      return const Color(0xFFFF3366); // Neon pink/coral
    }
    if (cat.contains('shop')) {
      return const Color(0xFFD946EF); // Magenta / vibrant purple
    }
    if (cat.contains('transport') || cat.contains('cab') || cat.contains('car') || cat.contains('fuel')) {
      return const Color(0xFF00E5FF); // Vibrant cyan
    }
    if (cat.contains('bill') || cat.contains('utilit') || cat.contains('electric') || cat.contains('wifi')) {
      return const Color(0xFFFF9100); // Warm amber / orange
    }
    if (cat.contains('entertain') || cat.contains('game') || cat.contains('movie')) {
      return const Color(0xFFA855F7); // Purple accent
    }
    if (cat.contains('grocer')) {
      return const Color(0xFF10B981);
    }
    return const Color(0xFF00E676); // Mint green for Others
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final allTxs = appState.transactions;

    final targetYear = _selectedPeriod.year;
    final targetMonth = _selectedPeriod.month;

    // Filter transactions for currently selected month
    final monthTxs = allTxs.where((tx) {
      return tx.date.year == targetYear && tx.date.month == targetMonth;
    }).toList();

    // Calculate current month's income & expenses
    double totalIncome = 0.0;
    double totalSpent = 0.0;
    final categoryTotals = <String, double>{};

    for (final tx in monthTxs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalSpent += tx.amount;
        final catKey = tx.category.trim();
        categoryTotals[catKey] = (categoryTotals[catKey] ?? 0.0) + tx.amount;
      }
    }

    // Previous month comparison
    final prevPeriod = DateTime(targetYear, targetMonth - 1, 1);
    final prevMonthTxs = allTxs.where((tx) {
      return tx.date.year == prevPeriod.year && tx.date.month == prevPeriod.month;
    }).toList();

    double prevIncome = 0.0;
    double prevSpent = 0.0;
    for (final tx in prevMonthTxs) {
      if (tx.type == TransactionType.income) {
        prevIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        prevSpent += tx.amount;
      }
    }

    // Percentage change vs last month
    int incomeChangePercent = 0;
    if (prevIncome > 0) {
      incomeChangePercent = (((totalIncome - prevIncome) / prevIncome) * 100).round();
    }
    int spentChangePercent = 0;
    if (prevSpent > 0) {
      spentChangePercent = (((totalSpent - prevSpent) / prevSpent) * 100).round();
    }

    // Compute category breakdown list sorted descending
    final List<_CategoryBreakdown> categories = [];
    if (totalSpent > 0) {
      final sortedKeys = categoryTotals.keys.toList()
        ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

      for (final cat in sortedKeys) {
        final amount = categoryTotals[cat]!;
        final ratio = amount / totalSpent;
        final percent = '${(ratio * 100).round()}%';
        categories.add(_CategoryBreakdown(
          label: cat,
          amount: amount,
          ratio: ratio,
          percent: percent,
          color: _colorForCategory(cat),
          icon: _iconForCategory(cat),
        ));
      }
    }

    // Compute 6-Month Trend Data
    final List<_MonthTrendData> sixMonthTrends = [];
    for (int i = 5; i >= 0; i--) {
      final mDate = DateTime(targetYear, targetMonth - i, 1);
      final mTransactions = allTxs.where((tx) {
        return tx.date.year == mDate.year && tx.date.month == mDate.month;
      });

      double mInc = 0.0;
      double mExp = 0.0;
      for (final tx in mTransactions) {
        if (tx.type == TransactionType.income) {
          mInc += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          mExp += tx.amount;
        }
      }

      sixMonthTrends.add(_MonthTrendData(
        date: mDate,
        label: _monthNames[mDate.month - 1],
        income: mInc,
        expense: mExp,
      ));
    }

    final monthLabel = '${_monthNames[targetMonth - 1]} $targetYear';

    return Scaffold(
      backgroundColor: const Color(0xFF001422),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF03222B),
              Color(0xFF001422),
              Color(0xFF001422),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Title, Subtitle & Month Selector Pill)
                _buildHeader(monthLabel),

                const SizedBox(height: 14),

                // 2. Summary Cards (Total Income & Total Spent side by side)
                _buildSummaryCards(
                  totalIncome: totalIncome,
                  totalSpent: totalSpent,
                  incomeChangePercent: incomeChangePercent,
                  spentChangePercent: spentChangePercent,
                  hasPrevIncome: prevIncome > 0,
                  hasPrevSpent: prevSpent > 0,
                ),

                const SizedBox(height: 14),

                // 3. Expense Breakdown Card with Donut Chart
                _buildExpenseBreakdownCard(
                  totalSpent: totalSpent,
                  categories: categories,
                ),

                const SizedBox(height: 14),

                // 4. AI Insight Card with Original Spentee Mascot
                _buildAiInsightCard(
                  totalSpent: totalSpent,
                  categories: categories,
                ),

                const SizedBox(height: 14),

                // 5. Monthly Trend Card (Grouped Bar Chart)
                _buildMonthlyTrendCard(
                  trends: sixMonthTrends,
                  selectedDate: _selectedPeriod,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. Header Widget ───────────────────────────────────────────────────────
  Widget _buildHeader(String monthLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Insights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Understand your money better.',
              style: TextStyle(
                color: Color(0xFF8E9DAE),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        // Pill-shaped Month Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF04201E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF0D5E4D),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.08),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MonthArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: _prevMonth,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.calendar_today_rounded,
                color: AppTheme.primaryMint,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                monthLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 4),
              _MonthArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: _nextMonth,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 2. Summary Cards Widget ───────────────────────────────────────────────
  Widget _buildSummaryCards({
    required double totalIncome,
    required double totalSpent,
    required int incomeChangePercent,
    required int spentChangePercent,
    required bool hasPrevIncome,
    required bool hasPrevSpent,
  }) {
    final incomeSign = incomeChangePercent >= 0 ? '+' : '';
    final incomeTrendText = hasPrevIncome
        ? '$incomeSign$incomeChangePercent% from last month'
        : '+0% from last month';

    final spentSign = spentChangePercent >= 0 ? '+' : '';
    final spentTrendText = hasPrevSpent
        ? '$spentSign$spentChangePercent% from last month'
        : (totalSpent > 0 ? '+0% from last month' : 'No spends recorded');

    return Row(
      children: [
        // Total Income Card (Green Theme)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06291C), Color(0xFF031610)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primaryMint.withValues(alpha: 0.28),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMint.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppTheme.primaryMint,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Income',
                      style: TextStyle(
                        color: Color(0xFF9FB0C0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatINR(totalIncome, spaceAfterSymbol: true),
                          style: const TextStyle(
                            color: AppTheme.primaryMint,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Mini Green Sparkline Bars
                    _buildMiniSparkline(
                      heights: [6, 11, 16, 21],
                      color: AppTheme.primaryMint.withValues(alpha: 0.75),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: AppTheme.primaryMint,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        incomeTrendText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8E9DAE),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Total Spent Card (Pink/Red Theme)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E0D1B), Color(0xFF190610)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.accentPink.withValues(alpha: 0.28),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentPink.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.accentPink.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppTheme.accentPink,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Spent',
                      style: TextStyle(
                        color: Color(0xFF9FB0C0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatINR(totalSpent, spaceAfterSymbol: true),
                          style: const TextStyle(
                            color: AppTheme.accentPink,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Mini Pink Sparkline Bars
                    _buildMiniSparkline(
                      heights: [18, 14, 11, 7],
                      color: AppTheme.accentPink.withValues(alpha: 0.75),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      spentChangePercent <= 0
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: AppTheme.accentPink,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        spentTrendText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8E9DAE),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniSparkline({
    required List<double> heights,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: heights.map((h) {
        return Container(
          margin: const EdgeInsets.only(left: 3),
          width: 3.5,
          height: h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }

  // ─── 3. Expense Breakdown Card ─────────────────────────────────────────────
  Widget _buildExpenseBreakdownCard({
    required double totalSpent,
    required List<_CategoryBreakdown> categories,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF071928),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0x1F38BDF8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Expense Breakdown + View Details Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Expense Breakdown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TransactionsScreen(),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: const [
                      Text(
                        'View details',
                        style: TextStyle(
                          color: AppTheme.primaryMint,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.primaryMint,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Donut Chart & Category Legend
          if (totalSpent == 0 || categories.isEmpty)
            _buildEmptyBreakdownState()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Donut Chart on Left
                SizedBox(
                  width: 142,
                  height: 142,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(142, 142),
                        painter: _DonutChartPainter(
                          categories: categories,
                          totalAmount: totalSpent,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatINR(totalSpent),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Total Spent',
                            style: TextStyle(
                              color: Color(0xFF8E9DAE),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Category Items on Right
                Expanded(
                  child: Column(
                    children: categories.take(6).map((cat) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.5),
                        child: Row(
                          children: [
                            // Circular icon with matching category color
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                cat.icon,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Category name
                            Expanded(
                              child: Text(
                                cat.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Percentage
                            Text(
                              cat.percent,
                              style: const TextStyle(
                                color: Color(0xFF8E9DAE),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Amount
                            Text(
                              _formatINR(cat.amount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyBreakdownState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0F263A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x2B38BDF8), width: 1),
            ),
            child: const Icon(
              Icons.pie_chart_outline_rounded,
              color: Color(0xFF8E9DAE),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No expenses recorded for this month',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap the central + button to log expenses and view insights.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8E9DAE),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. AI Insight Card ───────────────────────────────────────────────────
  Widget _buildAiInsightCard({
    required double totalSpent,
    required List<_CategoryBreakdown> categories,
  }) {
    // Determine dynamic rule-based insights
    String insightTitle = 'No spending recorded this month.';
    String insightSubtitle = 'Log your daily spends to receive smart money-saving tips!';
    String savingsHighlight = '';

    if (totalSpent > 0 && categories.isNotEmpty) {
      final topCat = categories.first;
      final percentStr = topCat.percent;
      final catName = topCat.label.toLowerCase();

      if (catName.contains('food') || catName.contains('dining') || catName.contains('drink')) {
        insightTitle = 'You spent $percentStr on food this month.';
        insightSubtitle = 'By cooking at home a few more times, you could save ';
        final potentialSavings = math.max(2000, ((topCat.amount * 0.45) / 500).round() * 500);
        savingsHighlight = '${_formatINR(potentialSavings.toDouble())}+!';
      } else if (catName.contains('shop')) {
        insightTitle = 'You spent $percentStr on shopping this month.';
        insightSubtitle = 'Trying the 72-hour delay rule could save you ';
        final potentialSavings = math.max(1000, ((topCat.amount * 0.20) / 500).round() * 500);
        savingsHighlight = '${_formatINR(potentialSavings.toDouble())}+!';
      } else if (catName.contains('transport') || catName.contains('cab')) {
        insightTitle = 'Transport accounted for $percentStr of spends.';
        insightSubtitle = 'Opting for transit passes or carpools could save ';
        final potentialSavings = math.max(500, ((topCat.amount * 0.20) / 250).round() * 250);
        savingsHighlight = '${_formatINR(potentialSavings.toDouble())}+!';
      } else if (catName.contains('bill') || catName.contains('utilit')) {
        insightTitle = 'Bills made up $percentStr of your budget.';
        insightSubtitle = 'Reviewing recurring subscriptions could save ';
        final potentialSavings = math.max(500, ((topCat.amount * 0.15) / 250).round() * 250);
        savingsHighlight = '${_formatINR(potentialSavings.toDouble())}+!';
      } else {
        insightTitle = 'Top spend was ${topCat.label} at $percentStr.';
        insightSubtitle = 'Trimming small impulse purchases could save ';
        final potentialSavings = math.max(500, ((topCat.amount * 0.15) / 250).round() * 250);
        savingsHighlight = '${_formatINR(potentialSavings.toDouble())}+!';
      }
    }

    final theme = MascotThemeData.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: theme.bannerGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.subtleBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryAccent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mascot Artwork
              SizedBox(
                width: 122,
                child: Image.asset(
                  theme.insightsMascotAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.isFemale
                        ? const Color(0xFF1E0817)
                        : const Color(0xFF031E18),
                    child: Icon(
                      Icons.smart_toy_rounded,
                      color: theme.primaryAccent,
                      size: 40,
                    ),
                  ),
                ),
              ),

              // Insight Observation and Suggestion
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // AI Insight Label with Sparkle
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: theme.primaryAccent,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'AI Insight',
                            style: TextStyle(
                              color: theme.primaryAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Observation Heading
                      Text(
                        insightTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Suggestion Subtitle with Highlighted Savings
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Color(0xFFB0C0D0),
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                          children: [
                            TextSpan(text: insightSubtitle),
                            if (savingsHighlight.isNotEmpty)
                              TextSpan(
                                text: savingsHighlight,
                                style: TextStyle(
                                  color: theme.primaryAccent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chevron Right indicator
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8E9DAE),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 5. Monthly Trend Card ─────────────────────────────────────────────────
  Widget _buildMonthlyTrendCard({
    required List<_MonthTrendData> trends,
    required DateTime selectedDate,
  }) {
    // Find maximum income or expense to calibrate Y-axis
    double maxVal = 0.0;
    for (final t in trends) {
      if (t.income > maxVal) maxVal = t.income;
      if (t.expense > maxVal) maxVal = t.expense;
    }
    if (maxVal <= 0) maxVal = 60000.0;

    // Scale to clean step (e.g. 60K, 40K, 20K, 0)
    final double step = (maxVal / 3).ceilToDouble();
    final double chartMax = math.max(60000.0, step * 3);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF071928),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0x1F38BDF8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Monthly Trend title and Last 6 Months Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Trend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F263A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0x2B38BDF8),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Last 6 Months',
                      style: TextStyle(
                        color: Color(0xFF8E9DAE),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8E9DAE),
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bar Chart with Y-axis and Grouped Bars
          SizedBox(
            height: 145,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis Labels
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatCompact(chartMax),
                        style: const TextStyle(
                          color: Color(0xFF6B7D90),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatCompact(chartMax * 2 / 3),
                        style: const TextStyle(
                          color: Color(0xFF6B7D90),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatCompact(chartMax / 3),
                        style: const TextStyle(
                          color: Color(0xFF6B7D90),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        '0',
                        style: TextStyle(
                          color: Color(0xFF6B7D90),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Grouped Bars Area
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const chartBarMaxHeight = 105.0;

                      return Stack(
                        children: [
                          // Faint horizontal guide lines
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                              Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                              Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                              Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                            ],
                          ),

                          // Bars Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: trends.map((trend) {
                              final isCurrentSelected = trend.date.year == selectedDate.year &&
                                  trend.date.month == selectedDate.month;

                              final incHeight = chartMax > 0
                                  ? (trend.income / chartMax * chartBarMaxHeight).clamp(4.0, chartBarMaxHeight)
                                  : 4.0;
                              final expHeight = chartMax > 0
                                  ? (trend.expense / chartMax * chartBarMaxHeight).clamp(4.0, chartBarMaxHeight)
                                  : 4.0;

                              return GestureDetector(
                                onTap: () => _selectMonth(trend.date),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: isCurrentSelected
                                      ? BoxDecoration(
                                          color: const Color(0xFF0E2C3D).withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0x3338BDF8),
                                            width: 1,
                                          ),
                                        )
                                      : null,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Grouped bars: Income (Green) & Expense (Pink)
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // Income Bar
                                          Container(
                                            width: 13.5,
                                            height: incHeight,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF33FF99),
                                                  Color(0xFF00E676),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(3.5),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 3.5),
                                          // Expense Bar
                                          Container(
                                            width: 13.5,
                                            height: expHeight,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFFF5277),
                                                  Color(0xFFFF3366),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(3.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Month Label (with pill badge for selected month)
                                      if (isCurrentSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF04121F),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            trend.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          trend.label,
                                          style: const TextStyle(
                                            color: Color(0xFF8E9DAE),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Legend (Green Dot Income, Pink Dot Expense)
          Row(
            children: [
              _LegendDot(
                color: AppTheme.primaryMint,
                label: 'Income',
              ),
              const SizedBox(width: 18),
              _LegendDot(
                color: AppTheme.accentPink,
                label: 'Expense',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Auxiliary Helper Widgets ─────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E9DAE),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          color: AppTheme.primaryMint,
          size: 19,
        ),
      ),
    );
  }
}

/// Custom Donut Chart Painter with clean arc gaps and anti-aliasing
class _DonutChartPainter extends CustomPainter {
  final List<_CategoryBreakdown> categories;
  final double totalAmount;

  _DonutChartPainter({
    required this.categories,
    required this.totalAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0 || categories.isEmpty) {
      // Draw empty background circle
      final paint = Paint()
        ..color = const Color(0xFF132B42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        (size.width - 22) / 2,
        paint,
      );
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 22.0;
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    double startAngle = -math.pi / 2;
    const double gapAngle = 0.05; // Gap between slices

    for (final cat in categories) {
      final sweepAngle = 2 * math.pi * cat.ratio;
      paint.color = cat.color;

      if (sweepAngle > gapAngle) {
        canvas.drawArc(rect, startAngle, sweepAngle - gapAngle, false, paint);
      } else {
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      }
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.totalAmount != totalAmount ||
        oldDelegate.categories != categories;
  }
}
