/// A model representing a real, trackable user savings goal.
class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String category;
  final DateTime createdAt;
  final bool isCompleted;
  final String notes;

  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.category = 'General',
    required this.createdAt,
    this.isCompleted = false,
    this.notes = '',
  });

  /// Progress ratio towards the goal (0.0 to 1.0).
  double get progressRatio {
    if (targetAmount <= 0) return 0.0;
    final ratio = currentAmount / targetAmount;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  /// Remaining amount needed to reach target.
  double get remainingAmount {
    final diff = targetAmount - currentAmount;
    return diff < 0 ? 0.0 : diff;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate?.toIso8601String(),
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String? ?? 'sg_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Savings Goal',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      category: json['category'] as String? ?? 'General',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    DateTime? createdAt,
    bool? isCompleted,
    String? notes,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }
}
