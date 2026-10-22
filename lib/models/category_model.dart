import 'package:flutter/material.dart';
import 'transaction.dart';

/// Category model representing default or custom categories.
class CategoryItem {
  final String id;
  final String name;
  final bool isExpense;
  final bool isCustom;
  final IconData icon;
  final Color color;
  final DateTime updatedAt;

  CategoryItem({
    required this.id,
    required this.name,
    required this.isExpense,
    this.isCustom = false,
    required this.icon,
    required this.color,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isExpense': isExpense,
      'isCustom': isCustom,
      'colorValue': color.toARGB32(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'General';
    final isExpense = json['isExpense'] as bool? ?? true;
    final isCustom = json['isCustom'] as bool? ?? false;
    final colorVal = json['colorValue'] as int?;

    return CategoryItem(
      id: json['id'] as String? ?? 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isExpense: isExpense,
      isCustom: isCustom,
      icon: Transaction.iconForCategory(name),
      color: colorVal != null ? Color(colorVal) : Transaction.colorForCategory(name),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CategoryItem copyWith({
    String? id,
    String? name,
    bool? isExpense,
    bool? isCustom,
    IconData? icon,
    Color? color,
    DateTime? updatedAt,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isExpense: isExpense ?? this.isExpense,
      isCustom: isCustom ?? this.isCustom,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
