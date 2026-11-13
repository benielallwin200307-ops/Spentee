import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import 'transactions_screen.dart';
import '../utils/date_restriction.dart';
import '../services/financial_intelligence_engine.dart';
import 'chat_screen.dart';

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

/// Period selection mode for the Insights screen
enum _PeriodMode { day, month, year }

/// Screen 13 — Spentee Insights Screen
/// Redesigned to closely match the reference fintech design.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  // ── State fields ──────────────────────────────────────────────────────────
  late DateTime _selectedPeriod;
  _PeriodMode _periodMode = _PeriodMode.month;
  int _trendPage = 0; // 0 = latest 6 months, positive = older windows
  final PageController _trendPageController = PageController(initialPage: 0);
  double _chartDragDistance = 0.0;

  final List<String> _monthNames = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedPeriod = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _trendPageController.dispose();
    super.dispose();
  }

  // ── Period navigation ──────────────────────────────────────────────────────

  bool get _canGoNextPeriod {
    final now = DateTime.now();
    switch (_periodMode) {
      case _PeriodMode.day:
        return _selectedPeriod.isBefore(DateRestriction.localToday);
      case _PeriodMode.month:
        return _selectedPeriod.year < now.year ||
            (_selectedPeriod.year == now.year && _selectedPeriod.month < now.month);
      case _PeriodMode.year:
        return _selectedPeriod.year < now.year;
    }
  }

  void _prevPeriod() {
    setState(() {
      switch (_periodMode) {
        case _PeriodMode.day:
          _selectedPeriod = _selectedPeriod.subtract(const Duration(days: 1));
          break;
        case _PeriodMode.month:
          _selectedPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month - 1, 1);
          break;
        case _PeriodMode.year:
          _selectedPeriod = DateTime(_selectedPeriod.year - 1, 1, 1);
          break;
      }
    });
  }

  void _nextPeriod() {
    if (!_canGoNextPeriod) return;
    setState(() {
      switch (_periodMode) {
        case _PeriodMode.day:
          _selectedPeriod = _selectedPeriod.add(const Duration(days: 1));
          break;
        case _PeriodMode.month:
          _selectedPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month + 1, 1);
          break;
        case _PeriodMode.year:
          _selectedPeriod = DateTime(_selectedPeriod.year + 1, 1, 1);
          break;
      }
    });
  }

  void _selectMonth(DateTime date) {
    setState(() {
      _selectedPeriod = DateRestriction.clampToCurrentMonth(date);
      _periodMode = _PeriodMode.month;
    });
  }

  // ── Trend page navigation ─────────────────────────────────────────────────

  bool _canGoOlderTrend(List<Transaction> allTxs) {
    if (allTxs.isEmpty) return false;
    final earliestTxDate = allTxs.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestMonth = DateTime(earliestTxDate.year, earliestTxDate.month, 1);
    final now = DateTime.now();
    final baseMonth = DateTime(now.year, now.month - (_trendPage * 6), 1);
    final currentWindowStart = DateTime(baseMonth.year, baseMonth.month - 5, 1);
    return currentWindowStart.isAfter(earliestMonth);
  }

  bool get _canGoNewerTrend => _trendPage > 0;

  void _olderTrend(List<Transaction> allTxs) {
    if (!_canGoOlderTrend(allTxs)) return;
    setState(() { _trendPage++; });
  }

  void _newerTrend() {
    if (!_canGoNewerTrend) return;
    setState(() { _trendPage--; });
  }

  String _getTrendRangeLabel(List<_MonthTrendData> trends) {
    if (trends.isEmpty) {
      return 'No data';
    }
    final first = trends.first;
    final last = trends.last;
    if (trends.length == 1) {
      return '${first.label} ${first.date.year}';
    }
    if (first.date.year == last.date.year) {
      return '${first.label} – ${last.label} ${last.date.year}';
    }
    return '${first.label} ${first.date.year} – ${last.label} ${last.date.year}';
  }

  // ── Period picker dialog ──────────────────────────────────────────────────

  void _showPeriodPicker() async {
    final selection = await showDialog<_CalendarSelection>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => _InsightCalendarDialog(
        initialDate: _selectedPeriod,
        initialMode: _periodMode,
      ),
    );

    if (selection != null && mounted) {
      setState(() {
        _selectedPeriod = selection.date;
        _periodMode = selection.mode;
      });
    }
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

  // Period label based on current mode
  String get _periodLabel {
    switch (_periodMode) {
      case _PeriodMode.day:
        return '${_selectedPeriod.day.toString().padLeft(2, '0')} ${_monthNames[_selectedPeriod.month - 1]} ${_selectedPeriod.year}';
      case _PeriodMode.month:
        return '${_monthNames[_selectedPeriod.month - 1]} ${_selectedPeriod.year}';
      case _PeriodMode.year:
        return '${_selectedPeriod.year}';
    }
  }

  List<Transaction> _filterTxs(List<Transaction> allTxs) {
    switch (_periodMode) {
      case _PeriodMode.day:
        return allTxs.where((tx) => tx.date.year == _selectedPeriod.year && tx.date.month == _selectedPeriod.month && tx.date.day == _selectedPeriod.day).toList();
      case _PeriodMode.month:
        return allTxs.where((tx) => tx.date.year == _selectedPeriod.year && tx.date.month == _selectedPeriod.month).toList();
      case _PeriodMode.year:
        return allTxs.where((tx) => tx.date.year == _selectedPeriod.year).toList();
    }
  }

  List<_MonthTrendData> _generateSixMonthTrends(List<Transaction> allTxs) {
    if (allTxs.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final earliestTxDate = allTxs.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestMonth = DateTime(earliestTxDate.year, earliestTxDate.month, 1);

    // Determine the most recent month to display based on trend page (0 = latest)
    // Each page shifts back by 6 months
    final baseMonth = DateTime(now.year, now.month - (_trendPage * 6), 1);
    final List<_MonthTrendData> trends = [];
    for (int i = 5; i >= 0; i--) {
      final mDate = DateTime(baseMonth.year, baseMonth.month - i, 1);
      // Guard against future months
      if (mDate.isAfter(now)) continue;
      // For accounts with less history, display only available months
      if (mDate.isBefore(earliestMonth)) continue;

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
      trends.add(_MonthTrendData(
        date: mDate,
        label: _monthNames[mDate.month - 1],
        income: mInc,
        expense: mExp,
      ));
    }
    return trends;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final allTxs = appState.transactions;

    // final targetYear = _selectedPeriod.year; // removed, not needed
    // final targetMonth = _selectedPeriod.month; // removed, not needed

    // Filter transactions for the currently selected period based on mode
    final List<Transaction> periodTxs = _filterTxs(allTxs);

    // Calculate current period's income & expenses
    double totalIncome = 0.0;
    double totalSpent = 0.0;
    final categoryTotals = <String, double>{};

    for (final tx in periodTxs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalSpent += tx.amount;
        final catKey = tx.category.trim();
        categoryTotals[catKey] = (categoryTotals[catKey] ?? 0.0) + tx.amount;
      }
    }

    // Previous period comparison
    DateTime prevPeriod;
    switch (_periodMode) {
      case _PeriodMode.day:
        prevPeriod = _selectedPeriod.subtract(const Duration(days: 1));
        break;
      case _PeriodMode.month:
        prevPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month - 1, 1);
        break;
      case _PeriodMode.year:
        prevPeriod = DateTime(_selectedPeriod.year - 1, 1, 1);
        break;
    }
    final prevPeriodTxs = allTxs.where((tx) {
      switch (_periodMode) {
        case _PeriodMode.day:
          return tx.date.year == prevPeriod.year && tx.date.month == prevPeriod.month && tx.date.day == prevPeriod.day;
        case _PeriodMode.month:
          return tx.date.year == prevPeriod.year && tx.date.month == prevPeriod.month;
        case _PeriodMode.year:
          return tx.date.year == prevPeriod.year;
      }
    }).toList();

    double prevIncome = 0.0;
    double prevSpent = 0.0;
    for (final tx in prevPeriodTxs) {
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

    // Compute 6-Month Trend Data (with pagination)
    final List<_MonthTrendData> sixMonthTrends = _generateSixMonthTrends(allTxs);

    final monthLabel = _periodLabel;

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
                  appState: appState,
                  totalSpent: totalSpent,
                  categories: categories,
                ),

                const SizedBox(height: 14),

                // 5. Monthly Trend Card (Grouped Bar Chart with Swipe)
                _buildMonthlyTrendCard(
                  trends: sixMonthTrends,
                  selectedDate: _selectedPeriod,
                  allTxs: allTxs,
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF8E9DAE),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Pill-shaped Period Selector — tap to open calendar picker
        GestureDetector(
          key: const ValueKey('period_selector_pill'),
          onTap: _showPeriodPicker,
          child: Container(
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
                  key: const ValueKey('pill_prev_btn'),
                  icon: Icons.chevron_left_rounded,
                  onTap: _prevPeriod,
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
                  key: const ValueKey('pill_next_btn'),
                  icon: Icons.chevron_right_rounded,
                  isEnabled: _canGoNextPeriod,
                  onTap: _canGoNextPeriod ? _nextPeriod : null,
                ),
              ],
            ),
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
                    const Flexible(
                      child: Text(
                        'Total Income',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF9FB0C0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
                    const Flexible(
                      child: Text(
                        'Total Spent',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF9FB0C0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 18, vertical: 16),
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
              const Expanded(
                child: Text(
                  'Expense Breakdown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Amount
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _formatINR(cat.amount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
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
    required AppState appState,
    required double totalSpent,
    required List<_CategoryBreakdown> categories,
  }) {
    // Determine dynamic personalized insights from the engine
    final insights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
      transactions: appState.transactions,
      budgets: appState.budgets,
      referenceDate: _selectedPeriod,
    );

    final insightTitle = insights.quickInsightTitle;
    final insightSubtitle = insights.quickInsightSubtitle;

    final theme = MascotThemeData.of(context);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => const ChatScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                // Clean Fintech Analytics Icon Badge
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 14, bottom: 14),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryAccent.withValues(alpha: 0.15),
                        border: Border.all(
                          color: theme.primaryAccent.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryAccent.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.insights_rounded,
                          color: theme.primaryAccent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Insight Observation and Suggestion
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 8, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // AI Insight Label with Sparkle
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: theme.primaryAccent,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'AI Insight • Hiro',
                                style: TextStyle(
                                  color: theme.primaryAccent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Suggestion Subtitle
                        Text(
                          insightSubtitle,
                          style: const TextStyle(
                            color: Color(0xFFB0C0D0),
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Chevron Right indicator
                const Padding(
                  padding: EdgeInsets.only(right: 8),
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
      ),
    );
  }

  // ─── 5. Monthly Trend Card ─────────────────────────────────────────────────
  Widget _buildMonthlyTrendCard({
    required List<_MonthTrendData> trends,
    required DateTime selectedDate,
    required List<Transaction> allTxs,
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

    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 18, vertical: 16),
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
          // Header Row: Monthly Trend title and swipeable period range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Monthly Trend',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Swipe navigation: older ← range → newer
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MonthArrowButton(
                    key: const ValueKey('trend_prev_btn'),
                    icon: Icons.chevron_left_rounded,
                    isEnabled: _canGoOlderTrend(allTxs),
                    onTap: _canGoOlderTrend(allTxs) ? () => _olderTrend(allTxs) : null,
                  ),
                  Container(
                    key: const ValueKey('trend_range_chip'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F263A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x2B38BDF8),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _getTrendRangeLabel(trends),
                      style: const TextStyle(
                        color: Color(0xFF8E9DAE),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _MonthArrowButton(
                    key: const ValueKey('trend_next_btn'),
                    icon: Icons.chevron_right_rounded,
                    isEnabled: _canGoNewerTrend,
                    onTap: _canGoNewerTrend ? _newerTrend : null,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bar Chart with Y-axis and Grouped Bars (swipe left=older, right=newer)
          GestureDetector(
            key: const ValueKey('monthly_trend_chart'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) {
              _chartDragDistance = 0.0;
            },
            onHorizontalDragUpdate: (details) {
              _chartDragDistance += details.primaryDelta ?? 0.0;
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0.0;
              if (velocity < -150 || _chartDragDistance < -35) {
                // swipe left → go older
                if (_canGoOlderTrend(allTxs)) {
                  _olderTrend(allTxs);
                }
              } else if (velocity > 150 || _chartDragDistance > 35) {
                // swipe right → go newer
                if (_canGoNewerTrend) {
                  _newerTrend();
                }
              }
              _chartDragDistance = 0.0;
            },
            child: SizedBox(
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
                      final isNarrow = constraints.maxWidth < 250;
                      final barWidth = isNarrow ? 8.5 : 11.5;
                      final barGap = isNarrow ? 1.5 : 2.5;
                      final groupPadH = isNarrow ? 1.0 : 2.5;
                      final labelFontSize = isNarrow ? 9.5 : 10.5;
                      final selectedPadH = isNarrow ? 4.0 : 7.0;

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
                                  padding: EdgeInsets.symmetric(horizontal: groupPadH, vertical: 2),
                                  decoration: isCurrentSelected
                                      ? BoxDecoration(
                                          color: const Color(0xFF0E2C3D).withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(8),
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
                                            width: barWidth,
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
                                                top: Radius.circular(3),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: barGap),
                                          // Expense Bar
                                          Container(
                                            width: barWidth,
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
                                          padding: EdgeInsets.symmetric(horizontal: selectedPadH, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF04121F),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            trend.label,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: labelFontSize,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          trend.label,
                                          style: TextStyle(
                                            color: const Color(0xFF8E9DAE),
                                            fontSize: labelFontSize,
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
        ), // end GestureDetector chart wrapper

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
  final VoidCallback? onTap;
  final bool isEnabled;

  const _MonthArrowButton({
    super.key,
    required this.icon,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          color: isEnabled
              ? AppTheme.primaryMint
              : const Color(0xFF1B4A45).withValues(alpha: 0.4),
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

// ─── Advanced Calendar Selection Dialog ──────────────────────────────────────

class _CalendarSelection {
  final DateTime date;
  final _PeriodMode mode;

  const _CalendarSelection({required this.date, required this.mode});
}

class _InsightCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final _PeriodMode initialMode;

  const _InsightCalendarDialog({
    required this.initialDate,
    required this.initialMode,
  });

  @override
  State<_InsightCalendarDialog> createState() => _InsightCalendarDialogState();
}

class _InsightCalendarDialogState extends State<_InsightCalendarDialog> {
  late _PeriodMode _mode;
  late int _viewYear;
  late int _viewMonth;
  late DateTime _selectedDate;

  final List<String> _monthNames = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final List<String> _weekdays = const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedDate = widget.initialDate;
    _viewYear = widget.initialDate.year;
    _viewMonth = widget.initialDate.month;
  }

  bool get _canGoNext {
    final now = DateTime.now();
    switch (_mode) {
      case _PeriodMode.day:
        return _viewYear < now.year || (_viewYear == now.year && _viewMonth < now.month);
      case _PeriodMode.month:
        return _viewYear < now.year;
      case _PeriodMode.year:
        return false;
    }
  }

  void _prev() {
    setState(() {
      switch (_mode) {
        case _PeriodMode.day:
          if (_viewMonth == 1) {
            _viewYear--;
            _viewMonth = 12;
          } else {
            _viewMonth--;
          }
          break;
        case _PeriodMode.month:
          _viewYear--;
          break;
        case _PeriodMode.year:
          _viewYear -= 10;
          break;
      }
    });
  }

  void _next() {
    if (!_canGoNext) return;
    setState(() {
      switch (_mode) {
        case _PeriodMode.day:
          if (_viewMonth == 12) {
            _viewYear++;
            _viewMonth = 1;
          } else {
            _viewMonth++;
          }
          break;
        case _PeriodMode.month:
          _viewYear++;
          break;
        case _PeriodMode.year:
          _viewYear += 10;
          break;
      }
    });
  }

  void _selectToday() {
    final now = DateTime.now();
    Navigator.of(context).pop(
      _CalendarSelection(
        date: DateTime(now.year, now.month, now.day),
        mode: _PeriodMode.day,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Dialog(
      backgroundColor: const Color(0xFF071928),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x2B38BDF8), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Title & Today Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Period',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  key: const ValueKey('cal_today_shortcut'),
                  onTap: _selectToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF04201E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryMint.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: AppTheme.primaryMint, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Today',
                          style: TextStyle(
                            color: AppTheme.primaryMint,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mode Selector Tabs (Day, Month, Year)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF04121F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1F38BDF8), width: 0.8),
              ),
              child: Row(
                children: [
                  _buildTab('Day', _PeriodMode.day, const ValueKey('tab_day')),
                  _buildTab('Month', _PeriodMode.month, const ValueKey('tab_month')),
                  _buildTab('Year', _PeriodMode.year, const ValueKey('tab_year')),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Navigation Header (< Nov 2026 >)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  key: const ValueKey('cal_prev_btn'),
                  icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primaryMint),
                  onPressed: _prev,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  _mode == _PeriodMode.day
                      ? '${_monthNames[_viewMonth - 1]} $_viewYear'
                      : (_mode == _PeriodMode.month ? '$_viewYear' : 'Select Year'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  key: const ValueKey('cal_next_btn'),
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: _canGoNext
                        ? AppTheme.primaryMint
                        : const Color(0xFF1B4A45).withValues(alpha: 0.3),
                  ),
                  onPressed: _canGoNext ? _next : null,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Content per mode
            if (_mode == _PeriodMode.day) _buildDayGrid(now),
            if (_mode == _PeriodMode.month) _buildMonthGrid(now),
            if (_mode == _PeriodMode.year) _buildYearGrid(now),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, _PeriodMode mode, Key key) {
    final isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: () {
          setState(() {
            _mode = mode;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryMint : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF001422) : const Color(0xFF8E9DAE),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayGrid(DateTime now) {
    final firstWeekday = DateTime(_viewYear, _viewMonth, 1).weekday; // 1 = Mon
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    final totalCells = (firstWeekday - 1) + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // Weekday header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekdays
              .map((d) => SizedBox(
                    width: 34,
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: Color(0xFF6B7D90),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        // Days Grid
        ...List.generate(rows, (r) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (c) {
                final cellIndex = r * 7 + c;
                final dayNum = cellIndex - (firstWeekday - 1) + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox(width: 34, height: 34);
                }

                final date = DateTime(_viewYear, _viewMonth, dayNum);
                final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
                final isSelected = _selectedDate.year == date.year &&
                    _selectedDate.month == date.month &&
                    _selectedDate.day == date.day &&
                    widget.initialMode == _PeriodMode.day;
                final isToday = now.year == date.year && now.month == date.month && now.day == date.day;

                return GestureDetector(
                  key: ValueKey('cal_day_$dayNum'),
                  onTap: isFuture
                      ? null
                      : () {
                          Navigator.of(context).pop(
                            _CalendarSelection(date: date, mode: _PeriodMode.day),
                          );
                        },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryMint
                          : (isToday ? AppTheme.primaryMint.withValues(alpha: 0.15) : Colors.transparent),
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: AppTheme.primaryMint, width: 1)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        color: isFuture
                            ? const Color(0xFF2A3C4D)
                            : (isSelected ? const Color(0xFF001422) : Colors.white),
                        fontSize: 12.5,
                        fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthGrid(DateTime now) {
    return Column(
      children: List.generate(4, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: List.generate(3, (col) {
              final month = row * 3 + col + 1;
              final isFuture = _viewYear > now.year || (_viewYear == now.year && month > now.month);
              final isSelected = _selectedDate.year == _viewYear &&
                  _selectedDate.month == month &&
                  widget.initialMode == _PeriodMode.month;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    key: ValueKey('cal_month_$month'),
                    onTap: isFuture
                        ? null
                        : () {
                            Navigator.of(context).pop(
                              _CalendarSelection(
                                date: DateTime(_viewYear, month, 1),
                                mode: _PeriodMode.month,
                              ),
                            );
                          },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryMint
                            : const Color(0xFF04121F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryMint
                              : (isFuture
                                  ? const Color(0xFF13222F)
                                  : const Color(0x1F38BDF8)),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _monthNames[month - 1],
                        style: TextStyle(
                          color: isFuture
                            ? const Color(0xFF2A3C4D)
                            : (isSelected ? const Color(0xFF001422) : Colors.white),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildYearGrid(DateTime now) {
    final years = <int>[];
    for (int y = now.year; y >= 2020; y--) {
      years.add(y);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: years.map((year) {
        final isSelected = _selectedDate.year == year && widget.initialMode == _PeriodMode.year;
        final isFuture = year > now.year;

        return GestureDetector(
          key: ValueKey('cal_year_$year'),
          onTap: isFuture
              ? null
              : () {
                  Navigator.of(context).pop(
                    _CalendarSelection(
                      date: DateTime(year, 1, 1),
                      mode: _PeriodMode.year,
                    ),
                  );
                },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryMint : const Color(0xFF04121F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primaryMint : const Color(0x1F38BDF8),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$year',
              style: TextStyle(
                color: isFuture
                    ? const Color(0xFF2A3C4D)
                    : (isSelected ? const Color(0xFF001422) : Colors.white),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
