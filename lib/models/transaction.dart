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

  static IconData iconForCategory(String category) {
    switch (category.toLowerCase().trim()) {
      case 'food & drinks':
      case 'food & dining':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills & utilities':
        return Icons.receipt_long_rounded;
      case 'entertainment':
        return Icons.sports_esports_rounded;
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'health & care':
        return Icons.medical_services_rounded;
      case 'salary':
        return Icons.account_balance_wallet_rounded;
      case 'freelance':
        return Icons.laptop_mac_rounded;
      case 'investments':
        return Icons.trending_up_rounded;
      case 'gift / bonus':
        return Icons.card_giftcard_rounded;
      case 'bank transfer':
        return Icons.account_balance_rounded;
      case 'sent to friend':
        return Icons.person_rounded;
      case 'savings vault':
        return Icons.lock_clock_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  static Color colorForCategory(String category) {
    switch (category.toLowerCase().trim()) {
      case 'food & drinks':
      case 'food & dining':
        return const Color(0xFFFF3366);
      case 'transport':
        return const Color(0xFF00E5FF);
      case 'shopping':
        return const Color(0xFFA855F7);
      case 'bills & utilities':
        return const Color(0xFFFF9100);
      case 'entertainment':
        return const Color(0xFF2979FF);
      case 'groceries':
        return const Color(0xFF10B981);
      case 'health & care':
        return const Color(0xFFEF4444);
      case 'salary':
      case 'savings vault':
        return const Color(0xFF00E676);
      case 'freelance':
        return const Color(0xFF00E5FF);
      case 'investments':
      case 'sent to friend':
        return const Color(0xFFA855F7);
      case 'gift / bonus':
        return const Color(0xFFFF9100);
      case 'bank transfer':
        return const Color(0xFF2979FF);
      default:
        return const Color(0xFF8E9DAE);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'categoryColor': categoryColor.toARGB32(),
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    TransactionType tType = TransactionType.expense;
    final typeStr = json['type'] as String?;
    if (typeStr == 'income') {
      tType = TransactionType.income;
    } else if (typeStr == 'transfer') {
      tType = TransactionType.transfer;
    }

    final cat = json['category'] as String? ?? 'General';
    final colorVal = json['categoryColor'] as int?;
    final color = colorVal != null ? Color(colorVal) : colorForCategory(cat);
    final icon = iconForCategory(cat);

    return Transaction(
      id: json['id'] as String? ??
          'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? cat,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: tType,
      category: cat,
      icon: icon,
      categoryColor: color,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: json['note'] as String? ?? '',
    );
  }
}
