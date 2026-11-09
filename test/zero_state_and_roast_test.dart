import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/screens/home_screen.dart';
import 'package:spentee/services/roast_engine.dart';
import 'package:spentee/services/roast_library.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  group('Spentee Task 5: Zero-State & Dynamic Roasts Unit Tests', () {
    test('1. New account begins with true zero-data state', () {
      final state = AppState();

      // Ensure no sample amounts (₹12,450, ₹12,092, ₹250, ₹50,000) are hardcoded
      expect(state.balance, 0.0);
      expect(state.todaySpending, 0.0);
      expect(state.monthIncome, 0.0);
      expect(state.totalIncome, 0.0);
      expect(state.transactions, isEmpty);
      expect(state.budgets, isEmpty);
      expect(state.savingsGoals, isEmpty);
    });

    test('2. Insufficient transaction history displays friendly onboarding roast', () {
      final state = AppState();

      // 0 transactions
      expect(
        state.currentRoast.text,
        RoastLibrary.getOnboardingRoast('English').text,
      );
      expect(state.currentRoast.category, 'Welcome to Spentee');

      // 1 transaction (still insufficient history < 3)
      final roast1 = DynamicRoastEngine.generateRoast(
        transactions: [
          Transaction(
            id: 'tx_single',
            title: 'Coffee',
            amount: 150.0,
            type: TransactionType.expense,
            category: 'Food & Dining',
            icon: Icons.coffee,
            categoryColor: Colors.brown,
            date: DateTime.now(),
          ),
        ],
      );
      expect(
        roast1.text,
        RoastLibrary.getInsufficientHistoryRoast('English').text,
      );
    });

    test('3. Existing account with transactions accurately reflects saved data', () async {
      final state = AppState();
      final now = DateTime.now();

      // Add income
      await state.addTransaction(
        Transaction(
          id: 'tx_sal',
          title: 'Salary Credit',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet,
          categoryColor: Colors.green,
          date: now,
        ),
      );

      // Add expense
      await state.addTransaction(
        Transaction(
          id: 'tx_exp',
          title: 'Grocery Supplies',
          amount: 4500.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.shopping_basket,
          categoryColor: Colors.pink,
          date: now,
        ),
      );

      // Add internal transfer (strictly excluded from earnings and purchases)
      await state.addTransaction(
        Transaction(
          id: 'tx_transfer',
          title: 'Vault Transfer',
          amount: 2000.0,
          type: TransactionType.transfer,
          category: 'Vault',
          icon: Icons.sync_alt,
          categoryColor: Colors.blue,
          date: now,
        ),
      );

      expect(state.transactions.length, 3);
      expect(state.balance, 45500.0); // 50000 - 4500 (transfer does not modify balance here)
      expect(state.monthIncome, 50000.0); // Transfer strictly excluded
      expect(state.todaySpending, 4500.0); // Transfer strictly excluded
    });

    test('4. Dynamic roast engine targets food spending when food is dominant', () {
      final now = DateTime.now();
      final foodDominantTxs = [
        Transaction(
          id: 'tx_1',
          title: 'Dinner at Bistro',
          amount: 3200.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 'tx_2',
          title: 'Groceries',
          amount: 2800.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 'tx_3',
          title: 'Metro Pass',
          amount: 400.0,
          type: TransactionType.expense,
          category: 'Transport',
          icon: Icons.directions_car,
          categoryColor: Colors.cyan,
          date: now,
        ),
      ];

      final roast = DynamicRoastEngine.generateRoast(
        transactions: foodDominantTxs,
      );

      // Must identify food habits
      expect(
        roast.category == 'Dining Habits' ||
            roast.category == 'Foodie Life' ||
            roast.category == 'Delivery Spree',
        isTrue,
      );
      expect(roast.text.toLowerCase().contains('food'), isTrue);
    });

    test('5. Dynamic roast engine targets shopping when retail therapy is dominant', () {
      final now = DateTime.now();
      final shoppingTxs = [
        Transaction(
          id: 'tx_1',
          title: 'Winter Jacket',
          amount: 4500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 'tx_2',
          title: 'Sneakers',
          amount: 3200.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 'tx_3',
          title: 'Coffee',
          amount: 200.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.coffee,
          categoryColor: Colors.pink,
          date: now,
        ),
      ];

      final roast = DynamicRoastEngine.generateRoast(
        transactions: shoppingTxs,
      );

      expect(
        roast.category == 'Shopping' ||
            roast.category == 'Retail Therapy' ||
            roast.category == 'Wardrobe Expansion',
        isTrue,
      );
      expect(roast.text.toLowerCase().contains('shopping') || roast.text.toLowerCase().contains('retail'), isTrue);
    });

    test('6. Anti-repetition avoids repeating the exact same roast back-to-back', () {
      final now = DateTime.now();
      final shoppingTxs = [
        Transaction(
          id: 'tx_1',
          title: 'Winter Jacket',
          amount: 4500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 'tx_2',
          title: 'Sneakers',
          amount: 3200.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 'tx_3',
          title: 'Coffee',
          amount: 200.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.coffee,
          categoryColor: Colors.pink,
          date: now,
        ),
      ];

      final firstRoast = DynamicRoastEngine.generateRoast(
        transactions: shoppingTxs,
      );

      final secondRoast = DynamicRoastEngine.generateRoast(
        transactions: shoppingTxs,
        previousRoastText: firstRoast.text,
      );

      // When multiple matching candidate roasts are available, it picks a different one
      expect(secondRoast.text != firstRoast.text, isTrue);
    });

    test('7. Roast operations are strictly read-only and never alter financial balances', () async {
      final state = AppState();
      final now = DateTime.now();

      await state.addTransaction(
        Transaction(
          id: 'tx_1',
          title: 'Salary',
          amount: 10000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.money,
          categoryColor: Colors.green,
          date: now,
        ),
      );

      final balanceBefore = state.balance;
      final txCountBefore = state.transactions.length;

      // Exercise roast generation multiple times
      state.refreshRoast();
      state.nextRoast();
      state.nextRoast();
      final current = state.currentRoast;
      expect(current.text.isNotEmpty, isTrue);

      // Verify zero mutation of financial metrics
      expect(state.balance, balanceBefore);
      expect(state.transactions.length, txCountBefore);
    });
  });

  group('Spentee Home Screen Zero-State Widget Tests', () {
    testWidgets('8. Home screen renders genuine zero-data dashboard and empty state',
        (WidgetTester tester) async {
      final state = AppState();

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify Total Balance zero state
      expect(find.text('₹ 0'), findsOneWidget);

      // Verify Income: ₹0 and Spent: ₹0 in metrics strip
      expect(find.text('Income: ₹0'), findsOneWidget);
      expect(find.text('Spent: ₹0'), findsWidgets);

      // Verify Recent Transactions empty state
      expect(
        find.text('No transactions yet.\nAdd your first transaction.'),
        findsOneWidget,
      );

      // Verify friendly onboarding roast
      expect(
        find.textContaining("Give me some transactions first. I can't roast an empty wallet! 👛✨"),
        findsOneWidget,
      );
    });
  });
}
