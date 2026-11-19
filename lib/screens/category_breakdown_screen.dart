import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/spentee_loading.dart';
import '../widgets/transaction_details_modal.dart';
import 'edit_transaction_screen.dart';
import 'insights_screen.dart';

/// Screen displaying category-specific transaction breakdown for Insights.
///
/// Features:
/// 1. Category name & icon badge
/// 2. Total amount spent in the category dynamically calculated
/// 3. Number of transactions in the category
/// 4. Individual transactions list with title, date, time, and formatted amount
/// 5. Option to open transaction details modal, edit, or delete transactions
/// 6. Period-aware filtering (Day, Month, Year) matching Insights screen
/// 7. Dynamic reactivity to transaction edits and deletions
/// 8. Polished dark navy design matching Spentee theme with empty and loading states
class CategoryBreakdownScreen extends StatelessWidget {
  final String categoryName;
  final String? categoryId;
  final Color categoryColor;
  final IconData categoryIcon;
  final DateTime selectedPeriod;
  final PeriodMode periodMode;
  final bool isLoading;

  const CategoryBreakdownScreen({
    super.key,
    required this.categoryName,
    this.categoryId,
    required this.categoryColor,
    required this.categoryIcon,
    required this.selectedPeriod,
    required this.periodMode,
    this.isLoading = false,
  });

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Format period label for header badge (e.g. 'Nov 2026', '13 Nov 2026', '2026')
  String get periodLabel {
    switch (periodMode) {
      case PeriodMode.day:
        return '${selectedPeriod.day.toString().padLeft(2, '0')} ${_monthNames[selectedPeriod.month - 1]} ${selectedPeriod.year}';
      case PeriodMode.month:
        return '${_monthNames[selectedPeriod.month - 1]} ${selectedPeriod.year}';
      case PeriodMode.year:
        return '${selectedPeriod.year}';
    }
  }

  /// Format currency with standard Indian Rupee representation (e.g. ₹ 41,606)
  String _formatINR(double amount) {
    if (amount <= 0 && amount > -0.01) return '₹ 0';
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final intPart = absAmount.truncate();
    final hasDecimals = (absAmount - intPart) >= 0.01;
    final decPart = hasDecimals ? (absAmount - intPart).toStringAsFixed(2).substring(1) : '';

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

    return '${isNegative ? '-' : ''}₹ $formatted$decPart';
  }

  /// Check whether transaction matches the selected period
  bool _matchesPeriod(DateTime txDate) {
    switch (periodMode) {
      case PeriodMode.day:
        return txDate.year == selectedPeriod.year &&
            txDate.month == selectedPeriod.month &&
            txDate.day == selectedPeriod.day;
      case PeriodMode.month:
        return txDate.year == selectedPeriod.year &&
            txDate.month == selectedPeriod.month;
      case PeriodMode.year:
        return txDate.year == selectedPeriod.year;
    }
  }

  /// Check whether transaction matches the category via Category ID, name, or aliases
  bool _matchesCategory(Transaction tx, AppState appState) {
    // 1. Match by Category ID if available
    if (categoryId != null && categoryId!.isNotEmpty) {
      for (final c in appState.customCategories) {
        if (c.id == categoryId && c.name.trim().toLowerCase() == tx.category.trim().toLowerCase()) {
          return true;
        }
      }
    }

    // 2. Match exact category name
    final txCat = tx.category.trim().toLowerCase();
    final targetCat = categoryName.trim().toLowerCase();
    if (txCat == targetCat) return true;

    // 3. Match known aliases and parent categories
    if ((targetCat.contains('food') || targetCat.contains('drink')) &&
        (txCat.contains('food') || txCat.contains('drink'))) {
      return true;
    }
    if ((targetCat.contains('travel') || targetCat.contains('transport')) &&
        (txCat.contains('travel') || txCat.contains('transport'))) {
      return true;
    }
    if ((targetCat.contains('bill') || targetCat.contains('utilit')) &&
        (txCat.contains('bill') || txCat.contains('utilit'))) {
      return true;
    }
    if (targetCat.contains('shop') && txCat.contains('shop')) {
      return true;
    }
    if ((targetCat.contains('entertain') || targetCat.contains('game')) &&
        (txCat.contains('entertain') || txCat.contains('game'))) {
      return true;
    }
    if (targetCat.contains('grocer') && txCat.contains('grocer')) {
      return true;
    }
    if ((targetCat.contains('health') || targetCat.contains('medic')) &&
        (txCat.contains('health') || txCat.contains('medic'))) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final allTxs = appState.transactions;

    // Exclude income, transfers, lend/borrow, and repayments. Only include regular expenses.
    final matchingTxs = allTxs.where((tx) {
      if (tx.isDeleted) return false;
      if (tx.type != TransactionType.expense) return false;
      if (!_matchesPeriod(tx.date)) return false;
      return _matchesCategory(tx, appState);
    }).toList();

    // Sort descending by transaction date
    matchingTxs.sort((a, b) => b.date.compareTo(a.date));

    // Dynamic totals
    final double totalSpent = matchingTxs.fold<double>(0.0, (sum, tx) => sum + tx.amount);
    final int txCount = matchingTxs.length;

    return Scaffold(
      backgroundColor: const Color(0xFF001422),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('category_breakdown_back_btn'),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
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
          child: isLoading
              ? const Center(
                  child: SpenteeLoading.full(message: 'Loading breakdown...'),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  children: [
                    // 1. Hero Category Summary Card
                    _buildSummaryCard(context, totalSpent, txCount),

                    const SizedBox(height: 20),

                    // 2. Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions ($txCount)',
                          style: const TextStyle(
                            color: Color(0xFF8E9DAE),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF071928),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0x1F38BDF8),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            periodLabel,
                            style: const TextStyle(
                              color: AppTheme.primaryMint,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 3. Transactions List or Empty State
                    if (matchingTxs.isEmpty)
                      _buildEmptyState()
                    else
                      ...matchingTxs.map((tx) => _buildTransactionItem(context, tx)),
                  ],
                ),
        ),
      ),
    );
  }

  /// 1. Hero Category Summary Card
  Widget _buildSummaryCard(BuildContext context, double totalSpent, int txCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF071928),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0x1F38BDF8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Category Badge & Period Pill
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Expense Breakdown',
                      style: TextStyle(
                        color: const Color(0xFF8E9DAE).withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF04201E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0D5E4D),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.primaryMint,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      periodLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFF0E2B38),
          ),

          const SizedBox(height: 16),

          // Financial Metrics Row: Total Spent & Transaction Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL SPENT',
                      style: TextStyle(
                        color: Color(0xFF8E9DAE),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatINR(totalSpent),
                        key: const ValueKey('category_total_spent_text'),
                        style: TextStyle(
                          color: totalSpent > 0 ? const Color(0xFFFF3366) : Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  txCount == 1 ? '1 transaction' : '$txCount transactions',
                  key: const ValueKey('category_tx_count_chip'),
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Empty State Widget
  Widget _buildEmptyState() {
    return Container(
      key: const ValueKey('category_empty_state'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFF071928),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0x1F38BDF8),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No $categoryName Transactions',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No expenses recorded for $categoryName in $periodLabel.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E9DAE),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Individual Transaction Item
  Widget _buildTransactionItem(BuildContext context, Transaction tx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SpenteeCard(
        key: ValueKey('category_tx_tile_${tx.id}'),
        onTap: () => TransactionDetailsModal.show(context, tx),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 16,
        backgroundColor: const Color(0xFF071928),
        border: Border.all(color: const Color(0x1A38BDF8), width: 1),
        child: Row(
          children: [
            // Category Icon Badge
            CategoryBadge(
              icon: tx.icon,
              color: tx.categoryColor,
              size: 40,
            ),
            const SizedBox(width: 12),

            // Title, Subtitle, Date & Note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_shortDate(tx.date)} • ${tx.formattedTime}',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (tx.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tx.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textDim,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Expense Amount (Coral Pink)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${_formatINR(tx.amount)}',
                  style: const TextStyle(
                    color: Color(0xFFFF3366),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 4),

            // Overflow Options Menu
            _buildOverflowMenu(context, tx),
          ],
        ),
      ),
    );
  }

  /// Overflow options menu for individual transaction
  Widget _buildOverflowMenu(BuildContext context, Transaction tx) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: const Color(0xFF0C1B22),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: AppTheme.textGrey,
          size: 18,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: const Color(0xFF0C1B22),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E3842), width: 1.2),
        ),
        onSelected: (value) async {
          if (value == 'details') {
            TransactionDetailsModal.show(context, tx);
          } else if (value == 'edit') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditTransactionScreen(transaction: tx),
              ),
            );
          } else if (value == 'delete') {
            final confirmed = await TransactionDetailsModal.showDeleteConfirmation(context, tx);
            if (confirmed && context.mounted) {
              final appState = AppStateScope.of(context);
              await appState.deleteTransaction(tx.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0D2526),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primaryMint, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Deleted ${tx.title} (${tx.formattedAmount})',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Details', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: AppTheme.primaryMint, size: 18),
                SizedBox(width: 10),
                Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                SizedBox(width: 10),
                Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}
