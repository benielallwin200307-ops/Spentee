import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/roast.dart';
import 'package:spentee/screens/roast_screen.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoastScreen Share Button Removal Test Suite', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    testWidgets('1. Verify Share button and share icons are completely removed from RoastScreen', (tester) async {
      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: RoastScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no "Share" text widget exists on screen
      expect(find.text('Share'), findsNothing, reason: 'Share button label must be removed');

      // Verify no share icons exist in AppBar or roast card
      expect(find.byIcon(Icons.share_rounded), findsNothing, reason: 'Icons.share_rounded must be removed');
      expect(find.byIcon(Icons.share_outlined), findsNothing, reason: 'Icons.share_outlined must be removed');
      expect(find.byIcon(Icons.share), findsNothing, reason: 'Icons.share must be removed');

      // Verify "New Roast 🔥" button is present and prominent
      expect(find.text('New Roast 🔥'), findsOneWidget, reason: 'New Roast button must remain present');

      // Verify 3-tier intensity selector is present
      expect(find.text('Friendly 😊'), findsOneWidget);
      expect(find.text('Savage 🔥'), findsOneWidget);
      expect(find.text('Brutal 💀'), findsOneWidget);

      // Verify Smart Insight and Spending Suggestion sections are preserved
      expect(find.text('Smart Insight'), findsOneWidget);
      expect(find.text('Spending Suggestion'), findsOneWidget);
    });

    testWidgets('2. Tapping New Roast button cycles roast without errors', (tester) async {
      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: RoastScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialRoast = appState.currentRoast.text;
      expect(initialRoast.isNotEmpty, isTrue);

      // Tap "New Roast 🔥"
      await tester.tap(find.text('New Roast 🔥'));
      await tester.pumpAndSettle();

      // Verify appState still has a valid roast
      expect(appState.currentRoast.text.isNotEmpty, isTrue);
    });

    testWidgets('3. Intensity selector updates intensity without regression', (tester) async {
      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: RoastScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Brutal
      await tester.tap(find.text('Brutal 💀'));
      await tester.pumpAndSettle();
      expect(appState.roastIntensity, equals(RoastIntensity.brutal));

      // Switch to Friendly
      await tester.tap(find.text('Friendly 😊'));
      await tester.pumpAndSettle();
      expect(appState.roastIntensity, equals(RoastIntensity.friendly));
    });
  });
}
