import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/screens/insights_screen.dart';
import 'package:spentee/screens/chat_screen.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BUG-01: InsightsScreen Responsive Width Verification Suite', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
      final now = DateTime.now();

      // Seed representative transactions across multiple categories
      appState.addTransaction(
        Transaction(
          id: 'tx_food_1',
          title: 'Zomato Biryani Order',
          amount: 850.0,
          type: TransactionType.expense,
          category: 'Food & Drinks',
          date: now,
          icon: Icons.restaurant,
          categoryColor: Colors.orange,
        ),
      );
      appState.addTransaction(
        Transaction(
          id: 'tx_shop_1',
          title: 'Shopping Weekend',
          amount: 2200.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: now,
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
        ),
      );
      appState.addTransaction(
        Transaction(
          id: 'tx_sal_1',
          title: 'Monthly Salary',
          amount: 60000.0,
          type: TransactionType.income,
          category: 'Salary',
          date: now,
          icon: Icons.work,
          categoryColor: Colors.green,
        ),
      );

      // Seed a budget to produce rich insight observations
      appState.addBudget(
        Budget(
          id: 'b_food',
          category: 'Food & Drinks',
          limitAmount: 5000.0,
          year: now.year,
          month: now.month,
        ),
      );
    });

    const testViewports = <String, Size>{
      'Ultra-Compact (320x640)': Size(320, 640),
      'Small (360x740)': Size(360, 740),
      'Compact (375x667)': Size(375, 667),
      'Standard (393x852)': Size(393, 852),
      'Large (432x960)': Size(432, 960),
    };

    for (final entry in testViewports.entries) {
      final label = entry.key;
      final size = entry.value;

      testWidgets('Verify InsightsScreen renders without overflow on $label', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final capturedErrors = <FlutterErrorDetails>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint('DEBUG OVERFLOW DETAILS: ${details.toString()}');
          capturedErrors.add(details);
        };

        try {
          await tester.pumpWidget(
            AppStateScope(
              state: appState,
              child: const MaterialApp(
                home: InsightsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Assert zero RenderFlex overflows occurred
          final overflows = capturedErrors.where(
            (e) => e.toString().contains('overflowed') || e.toString().contains('RenderFlex'),
          );
          expect(overflows.isEmpty, isTrue,
              reason: 'Found RenderFlex overflow on $label: ${overflows.map((e) => e.summary).toList()}');

          // Verify AI Insight card content is rendered properly
          expect(find.text('AI Insight • Hiro'), findsOneWidget);
          expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
          expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
          expect(find.byIcon(Icons.chevron_right_rounded), findsAtLeastNWidgets(1));
        } finally {
          FlutterError.onError = previousOnError;
        }
      });
    }

    testWidgets('Verify tapping AI Insight card navigates to ChatScreen', (tester) async {
      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the AI Insight card
      await tester.tap(find.text('AI Insight • Hiro'));
      await tester.pumpAndSettle();

      // Verify ChatScreen was pushed
      expect(find.byType(ChatScreen), findsOneWidget);
    });
  });
}
