import 'transaction.dart';

/// A category-level budget model for tracking monthly and periodic spending goals.
class Budget {
  final String id;
  final String category;
  final double limitAmount;
  final String period; // 'Monthly'
  final int year;
  final int month;
  final DateTime updatedAt;
  final bool isDeleted;

  Budget({
    required this.id,
    required this.category,
    required this.limitAmount,
    this.period = 'Monthly',
    required this.year,
    required this.month,
    DateTime? updatedAt,
    this.isDeleted = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Calculate the spent amount in this budget category for the given month from saved transactions.
  double calculateSpent(List<Transaction> transactions) {
    double spent = 0.0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense &&
          tx.category.toLowerCase().trim() == category.toLowerCase().trim() &&
          tx.date.year == year &&
          tx.date.month == month) {
        spent += tx.amount;
      }
    }
    return spent;
  }

  /// Remaining budget amount.
  double calculateRemaining(List<Transaction> transactions) {
    final remaining = limitAmount - calculateSpent(transactions);
    return remaining < 0 ? 0.0 : remaining;
  }

  /// Percentage of budget used (0.0 to 1.0+).
  double calculateRatio(List<Transaction> transactions) {
    if (limitAmount <= 0) return 0.0;
    final ratio = calculateSpent(transactions) / limitAmount;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'limitAmount': limitAmount,
      'period': period,
      'year': year,
      'month': month,
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String? ?? 'b_${DateTime.now().millisecondsSinceEpoch}',
      category: json['category'] as String? ?? 'General',
      limitAmount: (json['limitAmount'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] as String? ?? 'Monthly',
      year: json['year'] as int? ?? DateTime.now().year,
      month: json['month'] as int? ?? DateTime.now().month,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Budget copyWith({
    String? id,
    String? category,
    double? limitAmount,
    String? period,
    int? year,
    int? month,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      period: period ?? this.period,
      year: year ?? this.year,
      month: month ?? this.month,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
