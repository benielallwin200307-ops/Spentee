// ignore_for_file: non_const_argument_for_const_parameter
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
  final bool isDeleted;
  final String? userId;

  CategoryItem({
    required this.id,
    required this.name,
    required this.isExpense,
    this.isCustom = false,
    required this.icon,
    required this.color,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.userId,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isExpense': isExpense,
      'isCustom': isCustom,
      'colorValue': color.toARGB32(),
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      if (userId != null) 'userId': userId,
    };
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'General';
    final isExpense = json['isExpense'] as bool? ?? true;
    final isCustom = json['isCustom'] as bool? ?? false;
    final colorVal = json['colorValue'] as int?;
    final iconCodePoint = json['iconCodePoint'] as int?;
    final iconFontFamily = json['iconFontFamily'] as String?;
    final iconFontPackage = json['iconFontPackage'] as String?;

    final IconData icon;
    if (iconCodePoint != null) {
      icon = IconData(
        iconCodePoint,
        fontFamily: iconFontFamily ?? 'MaterialIcons',
        fontPackage: iconFontPackage,
      );
    } else if (isCustom) {
      icon = Icons.label_rounded;
    } else {
      icon = Transaction.iconForCategory(name);
    }

    return CategoryItem(
      id: json['id'] as String? ?? 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isExpense: isExpense,
      isCustom: isCustom,
      icon: icon,
      color: colorVal != null ? Color(colorVal) : Transaction.colorForCategory(name),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      userId: json['userId'] as String?,
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
    bool? isDeleted,
    String? userId,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isExpense: isExpense ?? this.isExpense,
      isCustom: isCustom ?? this.isCustom,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      userId: userId ?? this.userId,
    );
  }
}
