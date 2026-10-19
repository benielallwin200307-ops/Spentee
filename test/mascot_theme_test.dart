import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/theme/mascot_theme.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mascot & Theme System Unit Tests', () {
    test('1. MascotThemeData.male provides correct neon mint tokens and male assets', () {
      const theme = MascotThemeData.male;

      expect(theme.type, MascotType.male);
      expect(theme.isMale, isTrue);
      expect(theme.isFemale, isFalse);
      expect(theme.primaryAccent, const Color(0xFF00E676));

      // Asset mapping
      expect(theme.getAvatarAsset(MascotExpression.main), 'Assets/extracted/mascot_main.png');
      expect(theme.getAvatarAsset(MascotExpression.happy), 'Assets/extracted/avatar_happy.png');
      expect(theme.getAvatarAsset(MascotExpression.roast), 'Assets/extracted/avatar_roast.png');
      expect(theme.getAvatarAsset(MascotExpression.ai), 'Assets/extracted/avatar_ai.png');
      expect(theme.getAvatarAsset(MascotExpression.think), 'Assets/extracted/avatar_think.png');
      expect(theme.getAvatarAsset(MascotExpression.win), 'Assets/extracted/avatar_win.png');
      expect(theme.getAvatarAsset(MascotExpression.chill), 'Assets/extracted/avatar_chill.png');

      expect(theme.chatBannerAsset, 'Assets/extracted/chat_banner_mascot.png');
      expect(theme.chatAiBubbleAsset, 'Assets/extracted/chat_ai_avatar_hd.png');
      expect(theme.insightsMascotAsset, 'Assets/extracted/ai_insight_mascot.png');
    });

    test('2. MascotThemeData.female provides correct rose pink tokens and female assets', () {
      const theme = MascotThemeData.female;

      expect(theme.type, MascotType.female);
      expect(theme.isFemale, isTrue);
      expect(theme.isMale, isFalse);
      expect(theme.primaryAccent, const Color(0xFFFF528E));

      // Asset mapping
      expect(theme.getAvatarAsset(MascotExpression.main), 'Assets/extracted/female_main.png');
      expect(theme.getAvatarAsset(MascotExpression.happy), 'Assets/extracted/female_happy.png');
      expect(theme.getAvatarAsset(MascotExpression.roast), 'Assets/extracted/female_roast.png');
      expect(theme.getAvatarAsset(MascotExpression.ai), 'Assets/extracted/female_ai.png');
      expect(theme.getAvatarAsset(MascotExpression.think), 'Assets/extracted/female_think.png');
      expect(theme.getAvatarAsset(MascotExpression.win), 'Assets/extracted/female_win.png');
      expect(theme.getAvatarAsset(MascotExpression.chill), 'Assets/extracted/female_chill.png');

      expect(theme.chatBannerAsset, 'Assets/extracted/female_main.png');
      expect(theme.chatAiBubbleAsset, 'Assets/extracted/female_ai.png');
      expect(theme.insightsMascotAsset, 'Assets/extracted/female_main.png');
    });

    test('3. Canonical female image assets exist on disk without overwriting male assets', () {
      final requiredAssets = [
        'Assets/extracted/mascot_main.png',
        'Assets/extracted/avatar_happy.png',
        'Assets/extracted/avatar_roast.png',
        'Assets/extracted/avatar_ai.png',
        'Assets/extracted/avatar_think.png',
        'Assets/extracted/avatar_win.png',
        'Assets/extracted/avatar_chill.png',
        'Assets/extracted/female_main.png',
        'Assets/extracted/female_happy.png',
        'Assets/extracted/female_roast.png',
        'Assets/extracted/female_ai.png',
        'Assets/extracted/female_think.png',
        'Assets/extracted/female_win.png',
        'Assets/extracted/female_chill.png',
      ];

      for (final asset in requiredAssets) {
        final file = File(asset);
        expect(file.existsSync(), isTrue, reason: 'Asset missing: $asset');
      }
    });

    test('4. AppState switching updates mascotTheme reactively and preserves data', () {
      final state = AppState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      final initialBalance = state.balance;
      final initialTxCount = state.transactions.length;

      // Default should be male or loaded
      state.setSelectedMascot('female', uid: 'test_user_123');
      expect(state.selectedMascot, 'female');
      expect(state.isFemaleMascot, isTrue);
      expect(state.mascotTheme.primaryAccent, const Color(0xFFFF528E));
      expect(notifyCount, greaterThan(0));

      // Financial data untouched
      expect(state.balance, equals(initialBalance));
      expect(state.transactions.length, equals(initialTxCount));

      // Switch back to male
      state.setSelectedMascot('male', uid: 'test_user_123');
      expect(state.selectedMascot, 'male');
      expect(state.isFemaleMascot, isFalse);
      expect(state.mascotTheme.primaryAccent, const Color(0xFF00E676));

      expect(state.balance, equals(initialBalance));
      expect(state.transactions.length, equals(initialTxCount));
    });

    test('5. Per-user profile mapping stores and restores mascot selection independently', () {
      final state = AppState();

      state.setSelectedMascot('female', uid: 'alice_uid');
      state.setSelectedMascot('male', uid: 'bob_uid');

      expect(state.getSavedMascotForUser('alice_uid'), 'female');
      expect(state.getSavedMascotForUser('bob_uid'), 'male');
    });
  });
}
