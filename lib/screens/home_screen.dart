import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'roast_screen.dart';

/// Screen 7 — Home Dashboard
class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenAnalytics;
  final VoidCallback? onOpenChat;
  final VoidCallback? onOpenGames;

  const HomeScreen({
    super.key,
    this.onOpenAnalytics,
    this.onOpenChat,
    this.onOpenGames,
  });

  void _openAddTransaction(BuildContext context, TransactionType initialType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: initialType),
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context) {
    final controller = TextEditingController(text: '30000');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CategoryBadge(
                  icon: Icons.savings_rounded,
                  color: AppTheme.accentOrange,
                  size: 40,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Set Monthly Budget',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textGrey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Set a target spending limit for this month to receive smart warnings before overspending.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppTheme.primaryMint, fontSize: 20, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: AppTheme.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            NeonButton(
              text: 'Save Budget Target',
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.bgCard,
                    content: Text(
                      'Monthly budget updated to ₹${controller.text}!',
                      style: const TextStyle(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
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

    final totalBalanceStr = '₹${appState.balance.toStringAsFixed(appState.balance.truncateToDouble() == appState.balance ? 0 : 2)}';
    final todaySpentStr = '₹${appState.todaySpending.toStringAsFixed(appState.todaySpending.truncateToDouble() == appState.todaySpending ? 0 : 2)}';

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
                // Top Header: Logo + Mascot Avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 38,
                      child: Image.asset(
                        'Assets/Spentee Green Splash Logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text(
                          'Spentee',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    MascotAvatar(
                      size: 44,
                      imagePath: avatarImg,
                      hasGlow: true,
                      onTap: () => _showCharacterSelectionSheet(context, appState),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total Balance Card
                SpenteeCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                              totalBalanceStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.shield_rounded, size: 14, color: AppTheme.primaryMint),
                                SizedBox(width: 4),
                                Text(
                                  'Protected • Local Mode',
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
                      // Mascot Illustration on Right
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryMint.withValues(alpha: 0.15),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            appState.selectedMascot == 'female'
                                ? 'Assets/extracted/female_happy.png'
                                : 'Assets/extracted/avatar_happy.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset('Assets/extracted/mascot_main.png'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 4 Action Shortcuts Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ActionShortcutButton(
                      icon: Icons.add_card_rounded,
                      iconColor: AppTheme.accentPink,
                      label: 'Add\nExpense',
                      onTap: () => _openAddTransaction(context, TransactionType.expense),
                    ),
                    _ActionShortcutButton(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppTheme.primaryMint,
                      label: 'Add\nIncome',
                      onTap: () => _openAddTransaction(context, TransactionType.income),
                    ),
                    _ActionShortcutButton(
                      icon: Icons.swap_horiz_rounded,
                      iconColor: AppTheme.accentBlue,
                      label: 'Transfer /\nSent',
                      onTap: () => _openAddTransaction(context, TransactionType.transfer),
                    ),
                    _ActionShortcutButton(
                      icon: Icons.savings_rounded,
                      iconColor: AppTheme.accentOrange,
                      label: 'Set\nBudget',
                      onTap: () => _showSetBudgetDialog(context),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Today's Roast Callout Banner
                SpenteeCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  backgroundColor: const Color(0xFF16152B),
                  border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.4), width: 1),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RoastScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPink.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('🔥', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  "Today's Roast",
                                  style: TextStyle(
                                    color: AppTheme.accentPink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "• Tap to view",
                                  style: TextStyle(
                                    color: AppTheme.textDim,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appState.currentRoast.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textGrey, size: 14),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Today's Spending Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Spending",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todaySpentStr,
                          style: const TextStyle(
                            color: AppTheme.primaryMint,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: onOpenAnalytics,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: const Row(
                          children: [
                            Text(
                              'View all',
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textGrey, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Recent Transactions List
                if (appState.transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    alignment: Alignment.center,
                    child: const Text(
                      'No transactions yet. Add your first spending!',
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appState.transactions.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = appState.transactions[index];
                      return SpenteeCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  tx.type == TransactionType.income
                                      ? '+${tx.formattedAmount}'
                                      : tx.type == TransactionType.transfer
                                          ? tx.formattedAmount
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

/// Helper for the 4 action shortcut buttons.
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
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
          ),
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
          color: isSelected ? AppTheme.primaryMint.withValues(alpha: 0.15) : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryMint : Colors.transparent,
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
                child: Image.asset(imagePath, fit: BoxFit.cover),
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
