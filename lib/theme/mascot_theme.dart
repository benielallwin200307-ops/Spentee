import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../state/app_state.dart';

/// Supported mascot character genders
enum MascotType {
  male,
  female;

  String get id => name;
  String get displayName => this == MascotType.female ? 'Female' : 'Male';
}

/// Canonical character expressions across Spentee
enum MascotExpression {
  main,
  happy,
  roast,
  ai,
  think,
  win,
  chill,
}

/// Central design tokens, colors, gradients, and asset paths for the active mascot theme.
class MascotThemeData {
  final MascotType type;
  final Color primaryAccent;
  final Color primaryGlow;
  final Color primaryDark;
  final Color subtleBorder;
  final Color backgroundBadge;
  final LinearGradient cardGradient;
  final LinearGradient bannerGradient;
  final LinearGradient roastCardGradient;

  const MascotThemeData({
    required this.type,
    required this.primaryAccent,
    required this.primaryGlow,
    required this.primaryDark,
    required this.subtleBorder,
    required this.backgroundBadge,
    required this.cardGradient,
    required this.bannerGradient,
    required this.roastCardGradient,
  });

  bool get isFemale => type == MascotType.female;
  bool get isMale => type == MascotType.male;

  /// Default Male Mascot Theme (Original Neon Mint & Teal-Navy)
  static const MascotThemeData male = MascotThemeData(
    type: MascotType.male,
    primaryAccent: AppTheme.primaryMint,
    primaryGlow: Color(0xFF33FF99),
    primaryDark: Color(0xFF00B359),
    subtleBorder: Color(0x3800E676),
    backgroundBadge: Color(0x1F00E676),
    cardGradient: LinearGradient(
      colors: [Color(0xFF0F2C4A), Color(0xFF091C30)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    bannerGradient: LinearGradient(
      colors: [Color(0xFF04241C), Color(0xFF063327), Color(0xFF03221B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    roastCardGradient: LinearGradient(
      colors: [Color(0xFF3E1E34), Color(0xFF1E132B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Female Mascot Theme (Radiant Rose Pink & Midnight Plum/Berry Navy)
  static const MascotThemeData female = MascotThemeData(
    type: MascotType.female,
    primaryAccent: Color(0xFFFF528E),
    primaryGlow: Color(0xFFFF7AA8),
    primaryDark: Color(0xFFD81B60),
    subtleBorder: Color(0x4DFF528E),
    backgroundBadge: Color(0x26FF528E),
    cardGradient: LinearGradient(
      colors: [Color(0xFF28112A), Color(0xFF160918)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    bannerGradient: LinearGradient(
      colors: [Color(0xFF260D1E), Color(0xFF2E1024), Color(0xFF160612)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    roastCardGradient: LinearGradient(
      colors: [Color(0xFF3E122A), Color(0xFF200717)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Convenient helper to get active theme from context
  static MascotThemeData of(BuildContext context) {
    return AppStateScope.of(context).mascotTheme;
  }

  /// Resolve character image asset based on the current mascot selection
  String getAvatarAsset(MascotExpression expression) {
    if (isFemale) {
      switch (expression) {
        case MascotExpression.main:
          return 'Assets/extracted/female_main.png';
        case MascotExpression.happy:
          return 'Assets/extracted/female_happy.png';
        case MascotExpression.roast:
          return 'Assets/extracted/female_roast.png';
        case MascotExpression.ai:
          return 'Assets/extracted/female_ai.png';
        case MascotExpression.think:
          return 'Assets/extracted/female_think.png';
        case MascotExpression.win:
          return 'Assets/extracted/female_win.png';
        case MascotExpression.chill:
          return 'Assets/extracted/female_chill.png';
      }
    } else {
      switch (expression) {
        case MascotExpression.main:
          return 'Assets/extracted/mascot_main.png';
        case MascotExpression.happy:
          return 'Assets/extracted/avatar_happy.png';
        case MascotExpression.roast:
          return 'Assets/extracted/avatar_roast.png';
        case MascotExpression.ai:
          return 'Assets/extracted/avatar_ai.png';
        case MascotExpression.think:
          return 'Assets/extracted/avatar_think.png';
        case MascotExpression.win:
          return 'Assets/extracted/avatar_win.png';
        case MascotExpression.chill:
          return 'Assets/extracted/avatar_chill.png';
      }
    }
  }

  /// AI Chat Welcome Banner illustration asset
  String get chatBannerAsset {
    return isFemale
        ? 'Assets/extracted/female_main.png'
        : 'Assets/extracted/chat_banner_mascot.png';
  }

  /// AI Message avatar in chat timeline
  String get chatAiBubbleAsset {
    return isFemale
        ? 'Assets/extracted/female_ai.png'
        : 'Assets/extracted/chat_ai_avatar_hd.png';
  }

  /// Fallback AI Message avatar
  String get chatAiBubbleFallbackAsset {
    return isFemale
        ? 'Assets/extracted/female_main.png'
        : 'Assets/extracted/chat_ai_avatar.png';
  }

  /// AI Insight Card illustration in Insights screen
  String get insightsMascotAsset {
    return isFemale
        ? 'Assets/extracted/female_main.png'
        : 'Assets/extracted/ai_insight_mascot.png';
  }
}
