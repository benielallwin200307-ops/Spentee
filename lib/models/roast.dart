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

/// Chat message model for Spentee AI conversation.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasPlanCard;
  final Map<String, dynamic>? planData;
  final List<String>? actionButtons;
  final bool? isHelpful;
  final bool? isUnhelpful;
  final bool isError;
  final String? attachmentName;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.hasPlanCard = false,
    this.planData,
    this.actionButtons,
    this.isHelpful,
    this.isUnhelpful,
    this.isError = false,
    this.attachmentName,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? hasPlanCard,
    Map<String, dynamic>? planData,
    List<String>? actionButtons,
    bool? isHelpful,
    bool? isUnhelpful,
    bool? isError,
    String? attachmentName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      hasPlanCard: hasPlanCard ?? this.hasPlanCard,
      planData: planData ?? this.planData,
      actionButtons: actionButtons ?? this.actionButtons,
      isHelpful: isHelpful ?? this.isHelpful,
      isUnhelpful: isUnhelpful ?? this.isUnhelpful,
      isError: isError ?? this.isError,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'hasPlanCard': hasPlanCard,
      'planData': planData,
      'actionButtons': actionButtons,
      'isHelpful': isHelpful,
      'isUnhelpful': isUnhelpful,
      'isError': isError,
      'attachmentName': attachmentName,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      hasPlanCard: json['hasPlanCard'] as bool? ?? false,
      planData: json['planData'] is Map<String, dynamic>
          ? json['planData'] as Map<String, dynamic>
          : null,
      actionButtons: (json['actionButtons'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      isHelpful: json['isHelpful'] as bool?,
      isUnhelpful: json['isUnhelpful'] as bool?,
      isError: json['isError'] as bool? ?? false,
      attachmentName: json['attachmentName'] as String?,
    );
  }
}

/// A saved chat session for local conversation history.
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String? ??
          'session_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Conversation',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
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
