import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/screens/insights_screen.dart';
import 'package:spentee/screens/category_breakdown_screen.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Interactive Category Breakdown Test Suite', () {
    late AppState appState;
    final now = DateTime.now();

    setUp(() async {
      appState = AppState();

      // Seed varied transactions for testing
      // 1. Food & Drinks expenses in current month
      await appState.addTransaction(
        Transaction(
          id: 'tx_food_1',
          title: 'Dinner at Bistro',
          amount: 2500.0,
          type: TransactionType.expense,
          category: 'Food & Drinks',
          date: DateTime(now.year, now.month, 5, 20, 30),
          icon: Icons.restaurant_rounded,
          categoryColor: const Color(0xFFFF3366),
          note: 'Celebration dinner',
        ),
      );
      await appState.addTransaction(
        Transaction(
          id: 'tx_food_2',
          title: 'Coffee & Snacks',
          amount: 450.0,
          type: TransactionType.expense,
          category: 'Food & Drinks',
          date: DateTime(now.year, now.month, 8, 11, 15),
          icon: Icons.restaurant_rounded,
          categoryColor: const Color(0xFFFF3366),
        ),
      );

      // 2. Shopping expense in current month
      await appState.addTransaction(
        Transaction(
          id: 'tx_shop_1',
          title: 'New Sneakers',
          amount: 4999.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime(now.year, now.month, 10, 15, 0),
          icon: Icons.shopping_bag_rounded,
          categoryColor: const Color(0xFFD946EF),
        ),
      );

      // 3. Shopping expense in previous month (to verify date filtering)
      await appState.addTransaction(
        Transaction(
          id: 'tx_shop_prev',
          title: 'Winter Jacket',
          amount: 8000.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: DateTime(now.year, now.month - 1, 15, 14, 0),
          icon: Icons.shopping_bag_rounded,
          categoryColor: const Color(0xFFD946EF),
        ),
      );

      // 4. Income transaction in current month (must be excluded from category breakdown)
      await appState.addTransaction(
        Transaction(
          id: 'tx_income_1',
          title: 'Monthly Salary',
          amount: 60000.0,
          type: TransactionType.income,
          category: 'Salary',
          date: DateTime(now.year, now.month, 1, 9, 0),
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: const Color(0xFF00E676),
        ),
      );

      // 5. Transfer / Investment transaction (must be excluded)
      await appState.addTransaction(
        Transaction(
          id: 'tx_transfer_1',
          title: 'SIP Mutual Fund',
          amount: 5000.0,
          type: TransactionType.transfer,
          category: 'Mutual Fund / SIP',
          date: DateTime(now.year, now.month, 3, 10, 0),
          icon: Icons.trending_up_rounded,
          categoryColor: const Color(0xFFFFB300),
        ),
      );

      // 6. Lent / Borrowed transaction (must be excluded)
      await appState.addTransaction(
        Transaction(
          id: 'tx_lent_1',
          title: 'Loan to John',
          amount: 2000.0,
          type: TransactionType.lent,
          category: 'Lend & Repay',
          date: DateTime(now.year, now.month, 4, 12, 0),
          icon: Icons.handshake_rounded,
          categoryColor: const Color(0xFFFFB300),
        ),
      );
    });

    Widget createTestApp(Widget child, {AppState? customState}) {
      return AppStateScope(
        state: customState ?? appState,
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('1. Tapping an expense category in Insights opens CategoryBreakdownScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const InsightsScreen()));
      await tester.pumpAndSettle();

      // Find Food & Drinks category item in Expense Breakdown
      final foodItemFinder = find.byKey(const ValueKey('category_breakdown_item_Food & Drinks'));
      expect(foodItemFinder, findsOneWidget);

      // Tap on Food & Drinks
      await tester.tap(foodItemFinder);
      await tester.pumpAndSettle();

      // Verify CategoryBreakdownScreen is opened with category name
      expect(find.byType(CategoryBreakdownScreen), findsOneWidget);
      expect(find.text('Food & Drinks'), findsWidgets);
    });

    testWidgets('2. Category breakdown displays correct totals, counts, and individual transactions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          CategoryBreakdownScreen(
            categoryName: 'Food & Drinks',
            categoryId: 'cat_food',
            categoryColor: const Color(0xFFFF3366),
            categoryIcon: Icons.restaurant_rounded,
            selectedPeriod: DateTime(now.year, now.month, 1),
            periodMode: PeriodMode.month,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Category Title and Subtitle
      expect(find.text('Food & Drinks'), findsWidgets);
      expect(find.text('Expense Breakdown'), findsOneWidget);

      // Total spent = 2500 + 450 = 2950
      expect(find.byKey(const ValueKey('category_total_spent_text')), findsOneWidget);
      expect(find.text('₹ 2,950'), findsOneWidget);

      // Number of transactions = 2
      expect(find.byKey(const ValueKey('category_tx_count_chip')), findsOneWidget);
      expect(find.text('2 transactions'), findsOneWidget);

      // Individual transactions are visible
      expect(find.text('Dinner at Bistro'), findsOneWidget);
      expect(find.text('-₹ 2,500'), findsOneWidget);
      expect(find.text('Celebration dinner'), findsOneWidget);

      expect(find.text('Coffee & Snacks'), findsOneWidget);
      expect(find.text('-₹ 450'), findsOneWidget);

      // Excluded transactions from other categories or types must not appear
      expect(find.text('New Sneakers'), findsNothing);
      expect(find.text('Monthly Salary'), findsNothing);
      expect(find.text('SIP Mutual Fund'), findsNothing);
      expect(find.text('Loan to John'), findsNothing);
    });

    testWidgets('3. Respects date filters (Month mode filters out other months)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Open Shopping for current month
      await tester.pumpWidget(
        createTestApp(
          CategoryBreakdownScreen(
            categoryName: 'Shopping',
            categoryId: 'cat_shopping',
            categoryColor: const Color(0xFFD946EF),
            categoryIcon: Icons.shopping_bag_rounded,
            selectedPeriod: DateTime(now.year, now.month, 1),
            periodMode: PeriodMode.month,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only New Sneakers (₹ 4,999) from current month should appear
      expect(find.text('New Sneakers'), findsOneWidget);
      expect(find.text('₹ 4,999'), findsOneWidget);
      expect(find.text('1 transaction'), findsOneWidget);

      // Winter Jacket (from previous month) should NOT appear
      expect(find.text('Winter Jacket'), findsNothing);
    });

    testWidgets('4. Dynamic recalculation when a transaction is deleted', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          CategoryBreakdownScreen(
            categoryName: 'Food & Drinks',
            categoryId: 'cat_food',
            categoryColor: const Color(0xFFFF3366),
            categoryIcon: Icons.restaurant_rounded,
            selectedPeriod: DateTime(now.year, now.month, 1),
            periodMode: PeriodMode.month,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 transactions'), findsOneWidget);
      expect(find.text('₹ 2,950'), findsOneWidget);

      // Delete one of the transactions (runAsync for real I/O inside testWidgets)
      await tester.runAsync(() async {
        await appState.deleteTransaction('tx_food_2');
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Re-evaluated dynamically: count = 1, total = 2500
      expect(find.text('1 transaction'), findsOneWidget);
      expect(find.text('₹ 2,500'), findsOneWidget);
      expect(find.text('Coffee & Snacks'), findsNothing);
      expect(find.text('Dinner at Bistro'), findsOneWidget);
    });

    testWidgets('5. Dynamic recalculation when a transaction is edited', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          CategoryBreakdownScreen(
            categoryName: 'Shopping',
            categoryId: 'cat_shopping',
            categoryColor: const Color(0xFFD946EF),
            categoryIcon: Icons.shopping_bag_rounded,
            selectedPeriod: DateTime(now.year, now.month, 1),
            periodMode: PeriodMode.month,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('₹ 4,999'), findsOneWidget);

      // Edit the transaction amount to 6000 (runAsync for real I/O inside testWidgets)
      final existingTx = appState.transactions.firstWhere((t) => t.id == 'tx_shop_1');
      final updatedTx = existingTx.copyWith(amount: 6000.0);
      await tester.runAsync(() async {
        await appState.updateTransaction(updatedTx);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Re-evaluated dynamically
      expect(find.text('₹ 6,000'), findsOneWidget);
    });

    testWidgets('6. Displays polished empty state when no transactions exist in period', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Open Bills category (no transactions seeded)
      await tester.pumpWidget(
        createTestApp(
          CategoryBreakdownScreen(
            categoryName: 'Bills & Utilities',
            categoryId: 'cat_bills',
            categoryColor: const Color(0xFFFF9100),
            categoryIcon: Icons.receipt_long_rounded,
            selectedPeriod: DateTime(now.year, now.month, 1),
            periodMode: PeriodMode.month,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Total spent = 0, count = 0
      expect(find.text('₹ 0'), findsOneWidget);
      expect(find.text('0 transactions'), findsOneWidget);

      // Empty state visible
      expect(find.byKey(const ValueKey('category_empty_state')), findsOneWidget);
      expect(find.text('No Bills & Utilities Transactions'), findsOneWidget);
    });

    testWidgets('7. Back button navigates back cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const InsightsScreen()));
      await tester.pumpAndSettle();

      // Tap on Food & Drinks
      final foodItemFinder = find.byKey(const ValueKey('category_breakdown_item_Food & Drinks'));
      await tester.tap(foodItemFinder);
      await tester.pumpAndSettle();

      expect(find.byType(CategoryBreakdownScreen), findsOneWidget);

      // Tap back button
      final backBtn = find.byKey(const ValueKey('category_breakdown_back_btn'));
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Back to Insights screen
      expect(find.byType(CategoryBreakdownScreen), findsNothing);
      expect(find.byType(InsightsScreen), findsOneWidget);
    });

    testWidgets('8. Displays loading state when isLoading is true', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          CategoryBreakdownScreen(
            categoryName: 'Food & Drinks',
            categoryId: 'cat_food',
            categoryColor: const Color(0xFFFF3366),
            categoryIcon: Icons.restaurant_rounded,
            selectedPeriod: DateTime(now.year, now.month, 1),
            periodMode: PeriodMode.month,
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading breakdown...'), findsOneWidget);
    });
  });
}
