import 'package:flutter/material.dart';

/// A humorous spending roast model.
class RoastItem {
  final String text;
  final String category;
  final String mascotEmoji;

  const RoastItem({
    required this.text,
    required this.category,
    this.mascotEmoji = '😎',
  });
}

/// Chat message model for Spentee AI demo conversation.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasPlanCard;
  final Map<String, dynamic>? planData;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.hasPlanCard = false,
    this.planData,
  });
}

/// A puzzle leaderboard entry.
class LeaderboardEntry {
  final int rank;
  final String username;
  final String time;
  final String avatarPath;
  final bool isCurrentUser;
  final Color medalColor;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.time,
    required this.avatarPath,
    this.isCurrentUser = false,
    this.medalColor = Colors.grey,
  });
}
