import 'package:flutter/material.dart';

/// Transaction types: Expense, Income, Transfer.
enum TransactionType {
  expense,
  income,
  transfer,
}

/// A transaction model representing in-memory spending, income, or transfers.
class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final IconData icon;
  final Color categoryColor;
  final DateTime date;
  final String note;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.icon,
    required this.categoryColor,
    required this.date,
    this.note = '',
  });

  /// Formatted amount string (e.g. "₹250")
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  /// Formatted time (e.g. "12:30 PM")
  String get formattedTime {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  /// Formatted date string (e.g. "Today, 13 Oct 2026")
  String get formattedDate {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthName = months[date.month - 1];
    if (isToday) {
      return 'Today, ${date.day} $monthName ${date.year}';
    }
    return '${date.day} $monthName ${date.year}';
  }
}
