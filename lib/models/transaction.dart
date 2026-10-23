import 'package:flutter/material.dart';

/// Transaction types: Expense, Income, Transfer, Lent, Borrowed, RepaymentReceived, RepaymentMade.
enum TransactionType {
  expense,
  income,
  transfer,
  lent,
  borrowed,
  repaymentReceived,
  repaymentMade,
}

/// A transaction model representing in-memory spending, income, transfers, and debt cash flows.
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
  final String? sourceAccount;
  final String? destinationAccount;
  final String? debtId;
  final String? personName;
  final DateTime updatedAt;
  final bool isDeleted;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.icon,
    required this.categoryColor,
    required this.date,
    this.note = '',
    this.sourceAccount,
    this.destinationAccount,
    this.debtId,
    this.personName,
    DateTime? updatedAt,
    this.isDeleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    IconData? icon,
    Color? categoryColor,
    DateTime? date,
    String? note,
    String? sourceAccount,
    String? destinationAccount,
    String? debtId,
    String? personName,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      categoryColor: categoryColor ?? this.categoryColor,
      date: date ?? this.date,
      note: note ?? this.note,
      sourceAccount: sourceAccount ?? this.sourceAccount,
      destinationAccount: destinationAccount ?? this.destinationAccount,
      debtId: debtId ?? this.debtId,
      personName: personName ?? this.personName,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Identifies whether a category name corresponds to an investment or savings contribution.
  static bool isInvestmentCategory(String category) {
    switch (category.toLowerCase().trim()) {
      case 'gold investment':
      case 'mutual fund / sip':
      case 'mutual funds / sip':
      case 'stocks & etfs':
      case 'savings & deposits':
      case 'retirement investments':
      case 'other investment':
      case 'investments':
        return true;
      default:
        return false;
    }
  }

  /// Returns true if this is an actual investment contribution (deducted from main balance, but not an ordinary expense).
  bool get isInvestment =>
      type == TransactionType.transfer && isInvestmentCategory(category);

  /// Returns true if this is an own-account transfer between user's accounts.
  bool get isOwnAccountTransfer =>
      type == TransactionType.transfer && !isInvestment;

  /// Returns true if this transaction represents money lent to someone.
  bool get isLent => type == TransactionType.lent;

  /// Returns true if this transaction represents money borrowed from someone.
  bool get isBorrowed => type == TransactionType.borrowed;

  /// Returns true if this transaction represents a repayment received on money lent.
  bool get isRepaymentReceived => type == TransactionType.repaymentReceived;

  /// Returns true if this transaction represents a repayment made on borrowed money.
  bool get isRepaymentMade => type == TransactionType.repaymentMade;

  /// Returns true if this transaction is linked to lending, borrowing, or repayment.
  bool get isDebtOrRepayment =>
      isLent || isBorrowed || isRepaymentReceived || isRepaymentMade;

  /// Inflow to spendable balance: earned income, borrowed funds, and repayments received on money lent.
  bool get isCashInflow =>
      type == TransactionType.income ||
      type == TransactionType.borrowed ||
      type == TransactionType.repaymentReceived;

  /// Outflow from spendable balance: consumption expense, investments, money lent out, and repayments made on borrowed funds.
  bool get isCashOutflow =>
      type == TransactionType.expense ||
      isInvestment ||
      type == TransactionType.lent ||
      type == TransactionType.repaymentMade;

  /// Formatted signed amount string (e.g. "+₹250", "-₹250", or "₹250")
  String get displaySignedAmount {
    if (isCashInflow) {
      return '+$formattedAmount';
    } else if (isCashOutflow) {
      return '-$formattedAmount';
    }
    return formattedAmount;
  }

  /// Color representing transaction direction
  Color get displayAmountColor {
    if (type == TransactionType.income ||
        type == TransactionType.repaymentReceived) {
      return const Color(0xFF00E676); // Emerald Green
    } else if (type == TransactionType.borrowed) {
      return const Color(0xFF00E5FF); // Cyan
    } else if (type == TransactionType.lent) {
      return const Color(0xFFFFB300); // Amber
    } else if (type == TransactionType.repaymentMade) {
      return const Color(0xFFFF3366); // Coral Pink
    } else if (isInvestment) {
      return const Color(0xFFFFB300); // Amber
    } else if (type == TransactionType.transfer) {
      return const Color(0xFF2979FF); // Blue
    } else {
      return Colors.white; // Standard expense
    }
  }

  /// Formatted amount string (e.g. "₹250")
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  /// Formatted time (e.g. "12:30 PM")
  String get formattedTime {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  /// Formatted date string (e.g. "Today, 13 Oct 2026")
  String get formattedDate {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
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
      case 'wallet transfer':
        return Icons.wallet_rounded;
      case 'own account transfer':
        return Icons.swap_horiz_rounded;
      case 'gold investment':
        return Icons.monetization_on_rounded;
      case 'mutual fund / sip':
      case 'mutual funds / sip':
        return Icons.auto_graph_rounded;
      case 'stocks & etfs':
        return Icons.trending_up_rounded;
      case 'savings & deposits':
        return Icons.savings_rounded;
      case 'retirement investments':
        return Icons.shield_rounded;
      case 'other investment':
        return Icons.account_balance_wallet_rounded;
      case 'money lent':
        return Icons.arrow_upward_rounded;
      case 'money borrowed':
        return Icons.arrow_downward_rounded;
      case 'repayment received':
        return Icons.call_received_rounded;
      case 'repayment made':
        return Icons.call_made_rounded;
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
      case 'own account transfer':
        return const Color(0xFF2979FF);
      case 'wallet transfer':
        return const Color(0xFF00E5FF);
      case 'gold investment':
        return const Color(0xFFFFB300);
      case 'mutual fund / sip':
      case 'mutual funds / sip':
        return const Color(0xFF00E5FF);
      case 'stocks & etfs':
        return const Color(0xFF00E676);
      case 'savings & deposits':
        return const Color(0xFF10B981);
      case 'retirement investments':
        return const Color(0xFFA855F7);
      case 'other investment':
        return const Color(0xFF8E9DAE);
      case 'money lent':
        return const Color(0xFFFFB300);
      case 'money borrowed':
        return const Color(0xFF00E5FF);
      case 'repayment received':
        return const Color(0xFF00E676);
      case 'repayment made':
        return const Color(0xFFFF3366);
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
      'sourceAccount': sourceAccount,
      'destinationAccount': destinationAccount,
      'debtId': debtId,
      'personName': personName,
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    TransactionType tType = TransactionType.expense;
    final typeStr = json['type'] as String?;
    if (typeStr == 'income') {
      tType = TransactionType.income;
    } else if (typeStr == 'transfer') {
      tType = TransactionType.transfer;
    } else if (typeStr == 'lent') {
      tType = TransactionType.lent;
    } else if (typeStr == 'borrowed') {
      tType = TransactionType.borrowed;
    } else if (typeStr == 'repaymentReceived') {
      tType = TransactionType.repaymentReceived;
    } else if (typeStr == 'repaymentMade') {
      tType = TransactionType.repaymentMade;
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
      sourceAccount: json['sourceAccount'] as String?,
      destinationAccount: json['destinationAccount'] as String?,
      debtId: json['debtId'] as String?,
      personName: json['personName'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
