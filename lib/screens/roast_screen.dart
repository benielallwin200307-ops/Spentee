import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import '../models/transaction.dart';

/// Screen 11 — Today's Roast & Insights Screen
class RoastScreen extends StatefulWidget {
  const RoastScreen({super.key});

  @override
  State<RoastScreen> createState() => _RoastScreenState();
}

class _RoastScreenState extends State<RoastScreen> {
  bool _showInsightDetails = false;

  void _shareRoast(BuildContext context, String roastText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.bgCard,
        content: Row(
          children: [
            const Icon(Icons.share_rounded, color: AppTheme.primaryMint, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Roast ready to share: "$roastText"',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final roast = appState.currentRoast;

    final expenseTxs = appState.transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final bool hasData = expenseTxs.length >= 3;

    String insightText;
    String weekendLabel = 'Fri - Sun Average';
    String weekendVal = '₹0 / day';
    String weekdayLabel = 'Mon - Thu Average';
    String weekdayVal = '₹0 / day';
    String suggestionText;

    if (!hasData) {
      insightText =
          'Add at least 3 transactions to reveal your personalized spending patterns.';
      weekendLabel = 'Transactions Logged';
      weekendVal = '${expenseTxs.length}';
      weekdayLabel = 'Data Needed';
      weekdayVal = '3 minimum';
      suggestionText =
          'Log your daily expenses to unlock tailored insights and savings opportunities.';
    } else {
      double weekendSpend = 0.0;
      double weekdaySpend = 0.0;
      final weekendDays = <String>{};
      final weekdayDays = <String>{};
      final catSpend = <String, double>{};

      for (final tx in expenseTxs) {
        catSpend[tx.category] = (catSpend[tx.category] ?? 0.0) + tx.amount;
        final dStr = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
        if (tx.date.weekday == DateTime.saturday ||
            tx.date.weekday == DateTime.sunday) {
          weekendSpend += tx.amount;
          weekendDays.add(dStr);
        } else {
          weekdaySpend += tx.amount;
          weekdayDays.add(dStr);
        }
      }

      final weekendAvg =
          weekendDays.isNotEmpty ? weekendSpend / weekendDays.length : 0.0;
      final weekdayAvg =
          weekdayDays.isNotEmpty ? weekdaySpend / weekdayDays.length : 0.0;

      weekendLabel = 'Fri - Sun Average';
      weekendVal = '₹${weekendAvg.toStringAsFixed(0)} / day';
      weekdayLabel = 'Mon - Thu Average';
      weekdayVal = '₹${weekdayAvg.toStringAsFixed(0)} / day';

      if (weekendAvg > weekdayAvg && weekdayAvg > 0) {
        final pct = (((weekendAvg - weekdayAvg) / weekdayAvg) * 100).round();
        insightText = 'Your weekend spending is $pct% higher than weekdays.';
      } else if (weekdayAvg > weekendAvg && weekendAvg > 0) {
        final pct = (((weekdayAvg - weekendAvg) / weekendAvg) * 100).round();
        insightText = 'Your weekday spending is $pct% higher than weekends.';
      } else {
        insightText =
            'Your daily spending is balanced between weekdays and weekends.';
      }

      final topCat = catSpend.entries.fold<MapEntry<String, double>?>(
        null,
        (prev, curr) => (prev == null || curr.value > prev.value) ? curr : prev,
      );

      if (topCat != null && topCat.value > 0) {
        final potentialSavings = (topCat.value * 0.15).round();
        suggestionText =
            'Trimming 15% off your ${topCat.key} spend can save ₹$potentialSavings this month.';
      } else {
        suggestionText =
            'Keep tracking daily expenses to build an emergency fund!';
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Today's Roast",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _shareRoast(context, roast.text),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Roast Card (Matching Visual Reference)
                SpenteeCard(
                  padding: const EdgeInsets.all(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B1E38), Color(0xFF22112C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppTheme.accentPink.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Witty Fire Badge Icon
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentPink.withValues(alpha: 0.15),
                              border: Border.all(
                                color: AppTheme.accentPink.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentPink.withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                color: AppTheme.accentPink,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Roast Quote
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  roast.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                PillBadge(
                                  text: roast.category,
                                  backgroundColor: AppTheme.accentPink.withValues(alpha: 0.2),
                                  textColor: AppTheme.accentPink,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action buttons: Share & Next Roast
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppTheme.bgSurface,
                                side: const BorderSide(color: AppTheme.borderSubtle),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => appState.nextRoast(),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'New Roast 🔥',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryMint,
                                foregroundColor: AppTheme.bgDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _shareRoast(context, roast.text),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share_rounded, size: 18, color: AppTheme.bgDark),
                                  SizedBox(width: 6),
                                  Text('Share', style: TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Smart Insight Card
                SpenteeCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Smart Insight',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  insightText,
                                  style: const TextStyle(
                                    color: AppTheme.textGrey,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showInsightDetails = !_showInsightDetails;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgSurface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.borderSubtle),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _showInsightDetails ? 'Hide Details' : 'View Details',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          _showInsightDetails
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Mini Graph Icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.trending_up_rounded,
                              color: AppTheme.accentPurple,
                              size: 28,
                            ),
                          ),
                        ],
                      ),

                      if (_showInsightDetails) ...[
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.borderSubtle, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(weekendLabel, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                            Text(weekendVal, style: const TextStyle(color: AppTheme.accentPink, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(weekdayLabel, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                            Text(weekdayVal, style: const TextStyle(color: AppTheme.primaryMint, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Spending Suggestion Card
                SpenteeCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.savings_rounded,
                          color: AppTheme.accentYellow,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Spending Suggestion',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              suggestionText,
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 12,
                                height: 1.35,
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
