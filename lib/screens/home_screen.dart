import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'roast_screen.dart';

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

  void _showCharacterSelectionSheet(BuildContext context, AppState state) {
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
              'Choose Your Mascot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your financial partner to personalize roasts and advice',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureMapOption(
                  name: 'Alex (Default)',
                  imagePath: 'Assets/extracted/mascot_main.png',
                  isSelected: state.selectedMascot == 'male',
                  onTap: () {
                    state.setSelectedMascot('male');
                    Navigator.pop(ctx);
                  },
                ),
                GestureMapOption(
                  name: 'Sam',
                  imagePath: 'Assets/extracted/female_main.png',
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
    final avatarImg = appState.selectedMascot == 'female'
        ? 'Assets/extracted/female_main.png'
        : 'Assets/extracted/mascot_main.png';

    final balanceStr =
        '₹ ${appState.balance.toStringAsFixed(appState.balance.truncateToDouble() == appState.balance ? 0 : 2)}';
    final todaySpentStr =
        '₹${appState.todaySpending.toStringAsFixed(appState.todaySpending.truncateToDouble() == appState.todaySpending ? 0 : 2)}';

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Hi, Alex! ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
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
                    MascotAvatar(
                      size: 46,
                      imagePath: avatarImg,
                      hasGlow: true,
                      onTap: () =>
                          _showCharacterSelectionSheet(context, appState),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── Total Balance Card ─────────────────────────────────────
                SpenteeCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2C4A), Color(0xFF091C30)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppTheme.primaryMint.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Balance',
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
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.visibility_outlined,
                                    size: 14, color: AppTheme.textGrey),
                                const SizedBox(width: 4),
                                const Text(
                                  'Local Mode • Secure',
                                  style: TextStyle(
                                    color: AppTheme.primaryMint,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Mascot illustration
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryMint.withValues(alpha: 0.12),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            appState.selectedMascot == 'female'
                                ? 'Assets/extracted/female_happy.png'
                                : 'Assets/extracted/avatar_happy.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'Assets/extracted/mascot_main.png',
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.face_rounded,
                                      color: AppTheme.primaryMint, size: 36),
                            ),
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
                        icon: Icons.qr_code_scanner_rounded,
                        iconColor: AppTheme.accentBlue,
                        label: 'Scan\nBill',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Bill scanner coming soon! 📷'),
                              backgroundColor: AppTheme.bgCard,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
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
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
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
                    padding: const EdgeInsets.all(28),
                    alignment: Alignment.center,
                    child: const Text(
                      'No transactions yet.\nAdd your first spending!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textGrey),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx.formattedTime,
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              tx.type == TransactionType.income
                                  ? '+${tx.formattedAmount}'
                                  : tx.formattedAmount,
                              style: TextStyle(
                                color: tx.type == TransactionType.income
                                    ? AppTheme.primaryMint
                                    : tx.type == TransactionType.transfer
                                        ? AppTheme.accentBlue
                                        : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD6E2F0),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper for mascot selection modal.
class GestureMapOption extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const GestureMapOption({
    super.key,
    required this.name,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryMint.withValues(alpha: 0.15)
              : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryMint : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(imagePath, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.face_rounded,
                            color: AppTheme.primaryMint, size: 32)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryMint : Colors.white,
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
