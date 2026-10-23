import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';
import '../widgets/transaction_details_modal.dart';

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
    String subtitle = tx.category;
    if (tx.personName != null && tx.personName!.isNotEmpty) {
      subtitle = '${tx.category} • ${tx.personName}';
    } else if (tx.isOwnAccountTransfer && tx.sourceAccount != null && tx.destinationAccount != null) {
      subtitle = '${tx.sourceAccount} → ${tx.destinationAccount}';
    } else if (tx.sourceAccount != null && tx.sourceAccount!.isNotEmpty) {
      subtitle = '${tx.category} • ${tx.sourceAccount}';
    }

    return SpenteeCard(
      onTap: () => TransactionDetailsModal.show(context, tx),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 11,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx.displaySignedAmount,
                style: TextStyle(
                  color: tx.displayAmountColor,
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
          const SizedBox(width: 4),
          _buildMenu(context),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: const Color(0xFF0C1B22),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: AppTheme.textGrey,
          size: 20,
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
            final confirmed =
                await TransactionDetailsModal.showDeleteConfirmation(context, tx);
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
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.primaryMint, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Deleted ${tx.title} (${tx.formattedAmount})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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
          const PopupMenuItem<String>(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.visibility_rounded,
                    color: AppTheme.primaryMint, size: 18),
                SizedBox(width: 12),
                Text('View Details',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded,
                    color: AppTheme.accentCyan, size: 18),
                SizedBox(width: 12),
                Text('Edit Transaction',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 18),
                SizedBox(width: 12),
                Text('Delete Transaction',
                    style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
