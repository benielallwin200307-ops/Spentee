import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/screens/insights_screen.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Insights Advanced Features Test Suite', () {
    late AppState appState;
    final now = DateTime.now();

    setUp(() {
      appState = AppState();

      // Seed multi-year, multi-month transactions
      // 1. Current month transaction (Nov 2026 or current device month)
      appState.addTransaction(
        Transaction(
          id: 'tx_now_income',
          title: 'Current Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          date: DateTime(now.year, now.month, 1),
          icon: Icons.work,
          categoryColor: Colors.green,
        ),
      );
      appState.addTransaction(
        Transaction(
          id: 'tx_now_expense',
          title: 'Current Grocery',
          amount: 3000.0,
          type: TransactionType.expense,
          category: 'Groceries',
          date: DateTime(now.year, now.month, 1),
          icon: Icons.shopping_basket,
          categoryColor: Colors.orange,
        ),
      );

      // 2. Previous month transaction
      final prevMonthDate = DateTime(now.year, now.month - 1, 15);
      appState.addTransaction(
        Transaction(
          id: 'tx_prev_month_expense',
          title: 'Prev Month Dining',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Food & Drinks',
          date: prevMonthDate,
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
        ),
      );

      // 3. Historical year transaction (2024)
      appState.addTransaction(
        Transaction(
          id: 'tx_2024_expense',
          title: '2024 Purchase',
          amount: 12000.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime(2024, 6, 10),
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
        ),
      );
      appState.addTransaction(
        Transaction(
          id: 'tx_2024_income',
          title: '2024 Bonus',
          amount: 40000.0,
          type: TransactionType.income,
          category: 'Bonus',
          date: DateTime(2024, 6, 1),
          icon: Icons.card_giftcard,
          categoryColor: Colors.teal,
        ),
      );

      // Add budget to support AI insight engine
      appState.addBudget(
        Budget(
          id: 'b_groceries',
          category: 'Groceries',
          limitAmount: 5000.0,
          year: now.year,
          month: now.month,
        ),
      );
    });

    Widget createWidgetUnderTest({AppState? customState}) {
      return AppStateScope(
        state: customState ?? appState,
        child: const MaterialApp(
          home: InsightsScreen(),
        ),
      );
    }

    testWidgets('1. Selecting a previous year updates dashboard data', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open period selector
      await tester.tap(find.byKey(const ValueKey('period_selector_pill')));
      await tester.pumpAndSettle();

      // Tap Year mode tab
      await tester.tap(find.byKey(const ValueKey('tab_year')));
      await tester.pumpAndSettle();

      // Select year 2024
      final year2024Finder = find.byKey(const ValueKey('cal_year_2024'));
      expect(year2024Finder, findsOneWidget);
      await tester.tap(year2024Finder);
      await tester.pumpAndSettle();

      // Dashboard should display 2024 in period pill
      expect(find.text('2024'), findsOneWidget);

      // Income for 2024 was 40,000 and spent was 12,000
      expect(find.textContaining('40,000'), findsWidgets);
      expect(find.textContaining('12,000'), findsWidgets);
    });

    testWidgets('2. Selecting a previous month updates dashboard data', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open period selector
      await tester.tap(find.byKey(const ValueKey('period_selector_pill')));
      await tester.pumpAndSettle();

      // Tap Month mode tab
      await tester.tap(find.byKey(const ValueKey('tab_month')));
      await tester.pumpAndSettle();

      // Navigate to previous year to pick a past month (e.g. June 2024)
      await tester.tap(find.byKey(const ValueKey('cal_prev_btn')));
      await tester.pumpAndSettle();

      // Tap month 6 (June)
      await tester.tap(find.byKey(const ValueKey('cal_month_6')));
      await tester.pumpAndSettle();

      // Verify dashboard shows Jun
      expect(find.textContaining('Jun'), findsWidgets);
    });

    testWidgets('3. Selecting an individual historical date updates dashboard', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open period selector
      await tester.tap(find.byKey(const ValueKey('period_selector_pill')));
      await tester.pumpAndSettle();

      // Already in Day mode by default or tap Day tab
      await tester.tap(find.byKey(const ValueKey('tab_day')));
      await tester.pumpAndSettle();

      // Select day 1
      final day1Finder = find.byKey(const ValueKey('cal_day_1'));
      expect(day1Finder, findsOneWidget);
      await tester.tap(day1Finder);
      await tester.pumpAndSettle();

      // Dashboard should display day format (01 <Month> <Year>)
      expect(find.textContaining('01 '), findsWidgets);
      // For Day 1, income was 50,000 and expense was 3,000
      expect(find.textContaining('50,000'), findsWidgets);
      expect(find.textContaining('3,000'), findsWidgets);
    });

    testWidgets('4. Selecting today shortcut sets period to today', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open period selector
      await tester.tap(find.byKey(const ValueKey('period_selector_pill')));
      await tester.pumpAndSettle();

      // Tap Today shortcut
      await tester.tap(find.byKey(const ValueKey('cal_today_shortcut')));
      await tester.pumpAndSettle();

      // Dialog should dismiss and period pill should show today's date formatted
      final dayStr = now.day.toString().padLeft(2, '0');
      expect(find.textContaining(dayStr), findsWidgets);
    });

    testWidgets('5. Future dates cannot be selected and future navigation disabled', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check header right arrow cannot go into future month
      final pillNextGesture = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(const ValueKey('pill_next_btn')),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(pillNextGesture.onTap, isNull);

      // Open period selector
      await tester.tap(find.byKey(const ValueKey('period_selector_pill')));
      await tester.pumpAndSettle();

      // Next button in calendar dialog should be disabled at current month
      final calNextBtn = tester.widget<IconButton>(find.byKey(const ValueKey('cal_next_btn')));
      expect(calNextBtn.onPressed, isNull);

      // In month view, future months of current year must have onTap null
      await tester.tap(find.byKey(const ValueKey('tab_month')));
      await tester.pumpAndSettle();

      if (now.month < 12) {
        final futureMonth = now.month + 1;
        final futureMonthWidget = tester.widget<GestureDetector>(find.byKey(ValueKey('cal_month_$futureMonth')));
        expect(futureMonthWidget.onTap, isNull);
      }

      // Close dialog
      await tester.tap(find.byKey(const ValueKey('cal_today_shortcut')));
      await tester.pumpAndSettle();
    });

    testWidgets('6 & 7. Swiping backwards and forwards through six-month periods', (tester) async {
      tester.view.physicalSize = const Size(393, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byKey(const ValueKey('monthly_trend_chart')), 200);
      await tester.pumpAndSettle();

      // Initially on latest period: right arrow disabled
      final rightArrowGesture = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(const ValueKey('trend_next_btn')),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(rightArrowGesture.onTap, isNull);

      // Left arrow should be enabled because transactions go back to 2024
      final leftArrowGesture = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(const ValueKey('trend_prev_btn')),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(leftArrowGesture.onTap, isNotNull);

      // Swipe left by dragging to go to previous 6-month period
      await tester.drag(find.byKey(const ValueKey('monthly_trend_chart')), const Offset(-150, 0));
      await tester.pumpAndSettle();

      // Now right arrow should become enabled
      final rightArrowAfterGesture = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(const ValueKey('trend_next_btn')),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(rightArrowAfterGesture.onTap, isNotNull);

      // Swipe right by dragging to return to newer period
      await tester.drag(find.byKey(const ValueKey('monthly_trend_chart')), const Offset(150, 0));
      await tester.pumpAndSettle();

      // Right arrow should be disabled again on the latest period
      final rightArrowBackGesture = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(const ValueKey('trend_next_btn')),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(rightArrowBackGesture.onTap, isNull);

      // Also test tapping the arrow buttons
      await tester.tap(find.byKey(const ValueKey('trend_prev_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trend_next_btn')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<GestureDetector>(find.descendant(
          of: find.byKey(const ValueKey('trend_next_btn')),
          matching: find.byType(GestureDetector),
        )).onTap,
        isNull,
      );
    });

    testWidgets('8. Correct calculations for income and expenses', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // For current month (1 income of 50,000, 1 expense of 3,000)
      expect(find.textContaining('50,000'), findsWidgets);
      expect(find.textContaining('3,000'), findsWidgets);

      // Expense Breakdown should show Groceries 100%
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('9. Accounts with no transactions and accounts with less than 6 months of data', (tester) async {
      // Test 9a: Empty state (0 transactions)
      final emptyState = AppState();
      await tester.pumpWidget(createWidgetUnderTest(customState: emptyState));
      await tester.pumpAndSettle();

      // Should display No data in trend chip and 0 for income/spent without error
      expect(find.text('No data'), findsOneWidget);
      expect(find.textContaining('0'), findsWidgets);

      // Test 9b: Account with exactly 2 months of history
      final twoMonthState = AppState();
      twoMonthState.addTransaction(
        Transaction(
          id: 'tx_m1',
          title: 'Recent Expense',
          amount: 2000.0,
          type: TransactionType.expense,
          category: 'Food & Drinks',
          date: now,
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
        ),
      );
      twoMonthState.addTransaction(
        Transaction(
          id: 'tx_m2',
          title: 'Prev Expense',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime(now.year, now.month - 1, 10),
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(customState: twoMonthState));
      await tester.pumpAndSettle();

      // Should render without error and show available months in trend range
      expect(find.byKey(const ValueKey('monthly_trend_chart')), findsOneWidget);
    });

    testWidgets('10. Responsive layout on all required screen widths (320px to 432px)', (tester) async {
      const viewports = <Size>[
        Size(320, 640),
        Size(360, 740),
        Size(375, 667),
        Size(393, 852),
        Size(432, 960),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final capturedErrors = <FlutterErrorDetails>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) => capturedErrors.add(details);

        try {
          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          final overflows = capturedErrors.where(
            (e) => e.toString().contains('overflowed') || e.toString().contains('RenderFlex'),
          );
          expect(overflows.isEmpty, isTrue,
              reason: 'Found RenderFlex overflow on width ${size.width}: ${overflows.map((e) => e.summary).toList()}');
        } finally {
          FlutterError.onError = previousOnError;
        }
      }
    });
  });
}
