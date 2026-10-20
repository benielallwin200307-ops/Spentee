import 'package:flutter/material.dart';

/// The direction of the loan:
/// - lent: Money the user gave to a friend and expects back (Receivable Asset).
/// - borrowed: Money the user received from someone and must repay (Payable Liability).
enum DebtType {
  lent,
  borrowed,
}

/// The settlement status of the loan.
enum DebtStatus {
  pending,
  partiallyRepaid,
  overdue,
  settled,
}

/// A single repayment installment record.
class RepaymentRecord {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  const RepaymentRecord({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory RepaymentRecord.fromJson(Map<String, dynamic> json) {
    return RepaymentRecord(
      id: json['id'] as String? ?? 'rep_${DateTime.now().millisecondsSinceEpoch}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: json['note'] as String? ?? '',
    );
  }
}

/// A comprehensive model for tracking money lent to or borrowed from people.
class LentBorrowedRecord {
  final String id;
  final DebtType type;
  final String personName;
  final double amount;
  final DateTime date;
  final DateTime? dueDate;
  final String note;
  final List<RepaymentRecord> repayments;

  const LentBorrowedRecord({
    required this.id,
    required this.type,
    required this.personName,
    required this.amount,
    required this.date,
    this.dueDate,
    this.note = '',
    this.repayments = const [],
  });

  /// Total sum of all recorded repayments.
  double get repaidAmount {
    double total = 0.0;
    for (final r in repayments) {
      total += r.amount;
    }
    return total;
  }

  /// Outstanding balance still owed or to collect.
  double get outstandingAmount {
    final remaining = amount - repaidAmount;
    return remaining < 0.001 ? 0.0 : remaining;
  }

  /// Progress ratio towards complete repayment (0.0 to 1.0).
  double get progressRatio {
    if (amount <= 0) return 1.0;
    final ratio = repaidAmount / amount;
    return ratio > 1.0 ? 1.0 : (ratio < 0.0 ? 0.0 : ratio);
  }

  /// Whether the debt has been fully settled.
  bool get isFullySettled => outstandingAmount <= 0.0;

  /// Whether the repayment is overdue (due date has passed and balance > 0).
  bool get isOverdue {
    if (isFullySettled || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today.isAfter(due);
  }

  /// Number of days overdue (positive integer if overdue, else 0).
  int get daysOverdue {
    if (!isOverdue || dueDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today.difference(due).inDays;
  }

  /// Number of days remaining until due date (0 if due today, negative if overdue).
  int get daysUntilDue {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  /// Current status computed deterministically.
  DebtStatus get status {
    if (isFullySettled) return DebtStatus.settled;
    if (isOverdue) return DebtStatus.overdue;
    if (repaidAmount > 0.0) return DebtStatus.partiallyRepaid;
    return DebtStatus.pending;
  }

  /// Status display label.
  String get statusLabel {
    switch (status) {
      case DebtStatus.settled:
        return 'Fully Settled';
      case DebtStatus.overdue:
        return 'Overdue ($daysOverdue d)';
      case DebtStatus.partiallyRepaid:
        return 'Partially Repaid';
      case DebtStatus.pending:
        return 'Pending';
    }
  }

  /// Status color for UI badges.
  Color get statusColor {
    switch (status) {
      case DebtStatus.settled:
        return const Color(0xFF00E676); // Green
      case DebtStatus.overdue:
        return const Color(0xFFFF3366); // Neon Red/Pink
      case DebtStatus.partiallyRepaid:
        return const Color(0xFF00E5FF); // Cyan
      case DebtStatus.pending:
        return const Color(0xFFFFB300); // Amber
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'personName': personName,
      'amount': amount,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'note': note,
      'repayments': repayments.map((r) => r.toJson()).toList(),
    };
  }

  factory LentBorrowedRecord.fromJson(Map<String, dynamic> json) {
    DebtType dType = DebtType.lent;
    if (json['type'] == 'borrowed') {
      dType = DebtType.borrowed;
    }

    final reps = <RepaymentRecord>[];
    if (json['repayments'] is List) {
      for (final item in json['repayments'] as List) {
        if (item is Map<String, dynamic>) {
          reps.add(RepaymentRecord.fromJson(item));
        }
      }
    }

    return LentBorrowedRecord(
      id: json['id'] as String? ?? 'debt_${DateTime.now().millisecondsSinceEpoch}',
      type: dType,
      personName: json['personName'] as String? ?? 'Friend',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      note: json['note'] as String? ?? '',
      repayments: reps,
    );
  }

  LentBorrowedRecord copyWith({
    String? id,
    DebtType? type,
    String? personName,
    double? amount,
    DateTime? date,
    DateTime? dueDate,
    String? note,
    List<RepaymentRecord>? repayments,
  }) {
    return LentBorrowedRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      repayments: repayments ?? this.repayments,
    );
  }
}
