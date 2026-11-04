import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'roast_screen.dart';
import 'lent_borrowed_screen.dart';
import 'edit_transaction_screen.dart';
import '../widgets/transaction_details_modal.dart';
import '../ads/banner_ad_widget.dart';

/// Screen 9 — Home / Dashboard Screen
/// Matches the reference storyboard: greeting, balance card, 3 shortcut buttons,
/// AI summary banner, and recent transactions with "See all" link.
class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenInsights;
  final VoidCallback? onOpenChallenges;
  final VoidCallback? onOpenProfile;

  const HomeScreen({
    super.key,
    this.onOpenInsights,
    this.onOpenChallenges,
    this.onOpenProfile,
  });

  void _openAddTransaction(BuildContext context, TransactionType initialType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: initialType),
      ),
    );
  }

  void _openAllTransactions(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
    );
  }

  void _showThemeSelectionSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Theme Accent',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your preferred color accent for charts and highlights',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureMapOption(
                  name: 'Neon Mint',
                  color: const Color(0xFF00E676),
                  icon: Icons.eco_rounded,
                  isSelected: state.selectedMascot == 'male',
                  onTap: () {
                    state.setSelectedMascot('male');
                    Navigator.pop(ctx);
                  },
                ),
                GestureMapOption(
                  name: 'Radiant Pink',
                  color: const Color(0xFFFF528E),
                  icon: Icons.favorite_rounded,
                  isSelected: state.selectedMascot == 'female',
                  onTap: () {
                    state.setSelectedMascot('female');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final theme = appState.mascotTheme;

    final availBal = appState.availableBalance;
    final balanceStr =
        '₹ ${availBal.toStringAsFixed(availBal.truncateToDouble() == availBal ? 0 : 2)}';
    final todaySpentStr =
        '₹${appState.todaySpending.toStringAsFixed(appState.todaySpending.truncateToDouble() == appState.todaySpending ? 0 : 2)}';
    final incomeStr =
        '₹${appState.monthIncome.toStringAsFixed(appState.monthIncome.truncateToDouble() == appState.monthIncome ? 0 : 2)}';

    // Show only the 3 most recent transactions on home
    final recentTxs = appState.transactions.take(3).toList();

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
                // ─── Top Header: Greeting + Mascot Avatar ───────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Hi, ${appState.userName}! ',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Text('👋', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                          const Text(
                            "Let's make today count.",
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MascotAvatar(
                      size: 46,
                      initials: appState.userName.isNotEmpty
                          ? appState.userName[0]
                          : 'A',
                      hasGlow: true,
                      onTap: onOpenProfile ??
                          () => _showThemeSelectionSheet(context, appState),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── Available Balance Card ─────────────────────────────────
                SpenteeCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  gradient: theme.cardGradient,
                  border: Border.all(
                    color: theme.subtleBorder,
                    width: 1.5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available Balance',
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              balanceStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded,
                                        size: 13, color: AppTheme.primaryMint),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Income: $incomeStr',
                                      style: const TextStyle(
                                        color: AppTheme.primaryMint,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.arrow_downward_rounded,
                                        size: 13, color: AppTheme.accentPink),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Spent: $todaySpentStr',
                                      style: const TextStyle(
                                        color: AppTheme.accentPink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility_outlined,
                                    size: 14, color: AppTheme.textGrey),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Local Mode • Secure',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.primaryAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Balance metric indicator
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.backgroundBadge,
                          border: Border.all(
                            color: theme.subtleBorder,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryAccent.withValues(alpha: 0.2),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: theme.primaryAccent,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── 3 Action Shortcut Buttons ─────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionShortcutButton(
                        icon: Icons.add_card_rounded,
                        iconColor: AppTheme.accentPink,
                        label: 'Add\nExpense',
                        onTap: () => _openAddTransaction(
                            context, TransactionType.expense),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionShortcutButton(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: AppTheme.primaryMint,
                        label: 'Add\nIncome',
                        onTap: () => _openAddTransaction(
                            context, TransactionType.income),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionShortcutButton(
                        icon: Icons.handshake_rounded,
                        iconColor: AppTheme.accentBlue,
                        label: 'Lend\n& Repay',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LentBorrowedScreen()),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── AI Summary Banner ──────────────────────────────────────
                SpenteeCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  backgroundColor: const Color(0xFF0F1E3A),
                  border: Border.all(
                      color: AppTheme.accentBlue.withValues(alpha: 0.35),
                      width: 1),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RoastScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentBlue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.accentBlue,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You've spent $todaySpentStr today.",
                              style: const TextStyle(
                                color: AppTheme.accentPink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appState.currentRoast.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.textGrey, size: 13),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ─── Recent Transactions ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent Transactions',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openAllTransactions(context),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          'See all',
                          style: TextStyle(
                            color: AppTheme.primaryMint,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (appState.transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 28),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: AppTheme.borderSubtle, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryAccent.withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: theme.primaryAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No transactions yet.\nAdd your first transaction.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => _openAddTransaction(
                              context, TransactionType.expense),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: theme.primaryAccent,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          icon: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: theme.primaryAccent,
                          ),
                          label: Text(
                            'Add Transaction',
                            style: TextStyle(
                              color: theme.primaryAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentTxs.length,
                    separatorBuilder: (_, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = recentTxs[index];
                      return SpenteeCard(
                        onTap: () => TransactionDetailsModal.show(context, tx),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            CategoryBadge(
                              icon: tx.icon,
                              color: tx.categoryColor,
                              size: 40,
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
                                    tx.personName != null && tx.personName!.isNotEmpty
                                        ? '${tx.personName} • ${tx.formattedTime}'
                                        : tx.formattedTime,
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              tx.displaySignedAmount,
                              style: TextStyle(
                                color: tx.displayAmountColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _buildTransactionMenu(context, tx),
                          ],
                        ),
                      );
                    },
                  ),

                BannerAdWidget(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionMenu(BuildContext context, Transaction tx) {
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

/// Helper for the 3 action shortcut buttons.
class _ActionShortcutButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionShortcutButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD6E2F0),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper for theme selection modal.
class GestureMapOption extends StatelessWidget {
  final String name;
  final String? imagePath;
  final Color? color;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const GestureMapOption({
    super.key,
    required this.name,
    this.imagePath,
    this.color,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primaryMint;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF14333F),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: 0.2),
                border: Border.all(
                  color: isSelected ? activeColor : activeColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  icon ?? Icons.palette_rounded,
                  color: activeColor,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
