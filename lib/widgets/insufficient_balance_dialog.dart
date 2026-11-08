import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Clean, user-friendly dialog informing the user that an expense exceeds their available balance.
class InsufficientBalanceDialog extends StatelessWidget {
  final double availableBalance;
  final double expenseAmount;
  final double remainingRequired;

  const InsufficientBalanceDialog({
    super.key,
    required this.availableBalance,
    required this.expenseAmount,
    required this.remainingRequired,
  });

  /// Displays the Insufficient Balance dialog.
  static Future<void> show(
    BuildContext context, {
    required double availableBalance,
    required double expenseAmount,
  }) {
    final remaining = (expenseAmount - availableBalance).clamp(0.0, double.infinity);
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => InsufficientBalanceDialog(
        availableBalance: availableBalance,
        expenseAmount: expenseAmount,
        remainingRequired: remaining,
      ),
    );
  }

  static String formatCurrency(double amount) {
    if (amount < 0) amount = 0;
    final isInt = (amount.truncateToDouble() == amount);
    final str = isInt ? amount.toInt().toString() : amount.toStringAsFixed(2);
    final parts = str.split('.');
    final withCommas = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '₹${parts.length > 1 ? '$withCommas.${parts[1]}' : withCommas}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0C1B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFF1E3842), width: 1.2),
      ),
      contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentPink.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.accentPink,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Insufficient Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You don't have enough available balance for this transaction.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF88A8B6),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF071319),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E3842), width: 1),
            ),
            child: Column(
              children: [
                _buildRow(
                  label: 'Available Balance',
                  value: formatCurrency(availableBalance),
                  valueColor: Colors.white,
                ),
                const SizedBox(height: 10),
                _buildRow(
                  label: 'Expense Amount',
                  value: formatCurrency(expenseAmount),
                  valueColor: Colors.white,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFF1E3842), height: 1),
                ),
                _buildRow(
                  label: 'Remaining Required',
                  value: formatCurrency(remainingRequired),
                  valueColor: AppTheme.accentPink,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMint,
                foregroundColor: const Color(0xFF00241D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? const Color(0xFFB0C4DE) : const Color(0xFF88A8B6),
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

