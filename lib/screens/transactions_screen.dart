import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';

/// Screen 12 — Transactions List Screen
/// Shows all transactions with All / Expense / Income filter tabs.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _filterIndex = 0; // 0: All, 1: Expense, 2: Income

  final List<String> _filters = const ['All', 'Expense', 'Income'];

  List<Transaction> _filtered(List<Transaction> txs) {
    if (_filterIndex == 1) {
      return txs.where((t) => t.type == TransactionType.expense).toList();
    } else if (_filterIndex == 2) {
      return txs.where((t) => t.type == TransactionType.income).toList();
    }
    return txs;
  }

  /// Group transactions by date string
  Map<String, List<Transaction>> _grouped(List<Transaction> txs) {
    final map = <String, List<Transaction>>{};
    for (final tx in txs) {
      final dateKey = _formatDateGroup(tx.date);
      map.putIfAbsent(dateKey, () => []).add(tx);
    }
    return map;
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today, ${_shortDate(date)}';
    if (d == yesterday) return 'Yesterday, ${_shortDate(date)}';
    return _shortDate(date);
  }

  String _shortDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final filtered = _filtered(appState.transactions);
    final grouped = _grouped(filtered);
    final groupedKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded,
                color: AppTheme.primaryMint, size: 26),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter tabs
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: List.generate(_filters.length, (index) {
                    final isSelected = index == _filterIndex;
                    Color activeColor = AppTheme.primaryMint;
                    if (index == 1) activeColor = AppTheme.accentPink;
                    if (index == 2) activeColor = AppTheme.accentCyan;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _filterIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.bgDark
                                  : AppTheme.textGrey,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Transactions list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryMint.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppTheme.primaryMint,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add your first transaction\nusing the + button above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: groupedKeys.length,
                      itemBuilder: (context, groupIndex) {
                        final dateKey = groupedKeys[groupIndex];
                        final groupTxs = grouped[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date group header
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                dateKey,
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // Transactions for this date
                            ...groupTxs.map((tx) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _TransactionTile(tx: tx),
                                )),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;

    return SpenteeCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          CategoryBadge(
            icon: tx.icon,
            color: tx.categoryColor,
            size: 42,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.category,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 11,
                  ),
                ),
                if (tx.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.note,
                    style: const TextStyle(
                      color: AppTheme.textDim,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isIncome
                    ? '+${tx.formattedAmount}'
                    : isTransfer
                        ? tx.formattedAmount
                        : tx.formattedAmount,
                style: TextStyle(
                  color: isIncome
                      ? AppTheme.primaryMint
                      : isTransfer
                          ? AppTheme.accentBlue
                          : AppTheme.accentPink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tx.formattedTime,
                style: const TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
