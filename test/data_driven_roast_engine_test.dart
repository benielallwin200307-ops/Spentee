import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/roast.dart';
import 'package:spentee/models/savings_goal.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/services/roast_engine.dart';
import 'package:spentee/services/roast_library.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  group('Spentee Data-Driven Personalized Roast Engine Tests', () {
    final now = DateTime.now();

    test('1. Library contains at least 50 unique data-driven templates with placeholders', () {
      final templates = RoastLibrary.dataDrivenTemplates;
      expect(templates.length, greaterThanOrEqualTo(50));

      final uniqueIds = <String>{};
      for (final tmpl in templates) {
        expect(uniqueIds.contains(tmpl.id), isFalse, reason: 'Duplicate template ID: ${tmpl.id}');
        uniqueIds.add(tmpl.id);

        expect(tmpl.text.trim().isNotEmpty, isTrue);
        expect(tmpl.mascotEmoji.isNotEmpty, isTrue);
        expect(tmpl.category.isNotEmpty, isTrue);
      }
    });

    test('2. Real-data calculations: category totals for today, this week, and this month', () {
      final today = DateTime(now.year, now.month, 25, 12, 0);
      final fiveDaysAgo = today.subtract(const Duration(days: 5));
      final fifteenDaysAgo = today.subtract(const Duration(days: 15));

      final txs = [
        Transaction(
          id: 't1',
          title: 'Lunch',
          amount: 350.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.fastfood,
          categoryColor: Colors.orange,
          date: today,
        ),
        Transaction(
          id: 't2',
          title: 'Groceries',
          amount: 1200.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.shopping_basket,
          categoryColor: Colors.orange,
          date: fiveDaysAgo,
        ),
        Transaction(
          id: 't3',
          title: 'Dinner Buffet',
          amount: 800.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.orange,
          date: fifteenDaysAgo,
        ),
        Transaction(
          id: 't4',
          title: 'Bus Pass',
          amount: 500.0,
          type: TransactionType.expense,
          category: 'Transport',
          icon: Icons.directions_bus,
          categoryColor: Colors.blue,
          date: today,
        ),
      ];

      final calc = RoastCalculationData.compute(
        transactions: txs,
        referenceDate: today,
      );

      expect(calc.todayExpense, 850.0); // 350 + 500
      expect(calc.categorySumsToday['Food & Dining'], 350.0);
      expect(calc.categorySumsToday['Transport'], 500.0);

      expect(calc.thisWeekExpense, 2050.0); // 350 + 1200 + 500
      expect(calc.categorySumsWeek['Food & Dining'], 1550.0);

      expect(calc.thisMonthExpense, 2850.0); // 350 + 1200 + 800 + 500
      expect(calc.categorySumsMonth['Food & Dining'], 2350.0);
      expect(calc.categorySumsMonth['Transport'], 500.0);
    });

    test('3. Strictly excludes internal transfers from expense calculations', () {
      final today = DateTime(now.year, now.month, now.day, 10, 0);
      final txs = [
        Transaction(
          id: 'tx_transfer_1',
          title: 'Transfer to Savings Account',
          amount: 15000.0,
          type: TransactionType.transfer,
          category: 'Transfer',
          icon: Icons.swap_horiz,
          categoryColor: Colors.blueGrey,
          date: today,
        ),
        Transaction(
          id: 'tx_transfer_2',
          title: 'Self Wallet Top-up',
          amount: 5000.0,
          type: TransactionType.expense,
          category: 'Internal Transfer',
          note: 'Bank to wallet transfer',
          icon: Icons.account_balance_wallet,
          categoryColor: Colors.blueGrey,
          date: today,
        ),
        Transaction(
          id: 'tx_real_expense',
          title: 'Dinner with friends',
          amount: 600.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.orange,
          date: today,
        ),
      ];

      final calc = RoastCalculationData.compute(
        transactions: txs,
        referenceDate: today,
      );

      // Total expense must only reflect genuine consumption, strictly excluding 20,000 in transfers
      expect(calc.todayExpense, 600.0);
      expect(calc.thisMonthExpense, 600.0);
      expect(calc.validExpenseCount, 1);
    });

    test('4. Excludes money lent/borrowed/repaid and tracks refunds', () {
      final today = DateTime(now.year, now.month, now.day, 11, 0);
      final txs = [
        Transaction(
          id: 'lent_1',
          title: 'Lent to Rahul',
          amount: 4000.0,
          type: TransactionType.expense,
          category: 'Loans',
          note: 'Loan given until Friday',
          icon: Icons.handshake,
          categoryColor: Colors.amber,
          date: today,
        ),
        Transaction(
          id: 'refund_1',
          title: 'Amazon Returned Item Refund',
          amount: 1200.0,
          type: TransactionType.income,
          category: 'Refund',
          icon: Icons.replay,
          categoryColor: Colors.green,
          date: today,
        ),
        Transaction(
          id: 'real_exp',
          title: 'Coffee Beans',
          amount: 450.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.coffee,
          categoryColor: Colors.brown,
          date: today,
        ),
      ];

      final calc = RoastCalculationData.compute(
        transactions: txs,
        referenceDate: today,
      );

      expect(calc.todayExpense, 450.0);
      expect(calc.totalRefunds, 1200.0);
    });

    test('5. Budget warning & overrun calculation: accurately calculates spent, percentage, remaining', () {
      final testBudget = Budget(
        id: 'b_food',
        category: 'Food & Dining',
        limitAmount: 5000.0,
        year: now.year,
        month: now.month,
      );

      // Case A: Near limit (>= 80% utilization)
      final nearLimitTxs = [
        Transaction(
          id: 'tx_nl_1',
          title: 'Groceries',
          amount: 3000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.shopping_basket,
          categoryColor: Colors.orange,
          date: now,
        ),
        Transaction(
          id: 'tx_nl_2',
          title: 'Restaurant',
          amount: 1200.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.orange,
          date: now,
        ),
        Transaction(
          id: 'tx_nl_3',
          title: 'Metro',
          amount: 200.0,
          type: TransactionType.expense,
          category: 'Transport',
          icon: Icons.subway,
          categoryColor: Colors.blue,
          date: now,
        ),
      ];

      final roastWarning = DynamicRoastEngine.generateRoast(
        transactions: nearLimitTxs,
        budgets: [testBudget],
        language: 'English',
      );

      expect(roastWarning.situation, RoastCategory.budgetOverrun);
      expect(roastWarning.text, isNotEmpty);
      // Placeholders must be populated without raw braces
      expect(roastWarning.text.contains('{amount}'), isFalse);
      expect(roastWarning.text.contains('{percentage}'), isFalse);
      expect(roastWarning.text.contains('{budget_remaining}'), isFalse);

      // Case B: Overrun (> 100% utilization)
      final overrunTxs = [
        ...nearLimitTxs,
        Transaction(
          id: 'tx_over_1',
          title: 'Fine Dining Feast',
          amount: 1500.0, // Spent 5700 on 5000 limit
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.wine_bar,
          categoryColor: Colors.purple,
          date: now,
        ),
      ];

      final roastOverrun = DynamicRoastEngine.generateRoast(
        transactions: overrunTxs,
        budgets: [testBudget],
        language: 'English',
      );

      expect(roastOverrun.situation, RoastCategory.budgetOverrun);
      expect(roastOverrun.text.toLowerCase().contains('budget') ||
          roastOverrun.text.toLowerCase().contains('limit') ||
          roastOverrun.text.toLowerCase().contains('crushed') ||
          roastOverrun.text.toLowerCase().contains('smashed'), isTrue);
    });

    test('6. Period comparisons: detects when spending dropped vs previous week or month', () {
      final today = DateTime(now.year, now.month, 20);
      final lastMonthDay = DateTime(now.month == 1 ? now.year - 1 : now.year, now.month == 1 ? 12 : now.month - 1, 15);

      final txs = [
        // Previous month had heavy expenses: 10,000
        Transaction(
          id: 'pm_1',
          title: 'Old Gadget',
          amount: 10000.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.devices,
          categoryColor: Colors.deepPurple,
          date: lastMonthDay,
        ),
        // This month spending is only 2,500 (75% drop)
        Transaction(
          id: 'tm_1',
          title: 'Modest Groceries',
          amount: 800.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.shopping_bag,
          categoryColor: Colors.orange,
          date: today,
        ),
        Transaction(
          id: 'tm_2',
          title: 'Bus Pass',
          amount: 700.0,
          type: TransactionType.expense,
          category: 'Transport',
          icon: Icons.directions_bus,
          categoryColor: Colors.blue,
          date: today,
        ),
        Transaction(
          id: 'tm_3',
          title: 'Electric Bill',
          amount: 1000.0,
          type: TransactionType.expense,
          category: 'Bills',
          icon: Icons.flash_on,
          categoryColor: Colors.yellow,
          date: today,
        ),
      ];

      final matching = DynamicRoastEngine.getMatchingRoasts(
        transactions: txs,
        referenceDate: today,
      );

      final improvedCandidate = matching.firstWhere(
        (r) => r.situation == RoastCategory.spendingImproved,
        orElse: () => matching.first,
      );

      expect(improvedCandidate.situation, RoastCategory.spendingImproved);
      expect(improvedCandidate.text.contains('{percentage}'), isFalse);
      expect(improvedCandidate.text.contains('{amount}'), isFalse);
    });

    test('7. Frequent small purchases (<= 150) are tracked and trigger micro-purchase roasts', () {
      final txs = [
        Transaction(
          id: 'sm_1',
          title: 'Chai',
          amount: 20.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.coffee,
          categoryColor: Colors.brown,
          date: now,
        ),
        Transaction(
          id: 'sm_2',
          title: 'Snack Biscuit',
          amount: 30.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.cookie,
          categoryColor: Colors.brown,
          date: now,
        ),
        Transaction(
          id: 'sm_3',
          title: 'Bottled Water',
          amount: 20.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.water_drop,
          categoryColor: Colors.cyan,
          date: now,
        ),
        Transaction(
          id: 'sm_4',
          title: 'Parking Ticket',
          amount: 50.0,
          type: TransactionType.expense,
          category: 'Transport',
          icon: Icons.local_parking,
          categoryColor: Colors.blueGrey,
          date: now,
        ),
        Transaction(
          id: 'sm_5',
          title: 'Ice Cream Cup',
          amount: 60.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.icecream,
          categoryColor: Colors.pink,
          date: now,
        ),
      ];

      final calc = RoastCalculationData.compute(transactions: txs);
      expect(calc.smallPurchasesCount, 5);
      expect(calc.smallPurchasesAmount, 180.0);

      final matching = DynamicRoastEngine.getMatchingRoasts(
        transactions: txs,
        language: 'English',
      );

      final microRoast = matching.firstWhere((r) => r.situation == RoastCategory.microPurchases);
      expect(microRoast.situation, RoastCategory.microPurchases);
      expect(microRoast.text.contains('5'), isTrue); // count interpolated
      expect(microRoast.text.contains('{count}'), isFalse);
    });

    test('8. Anti-repetition: avoids repeating recent roast IDs', () {
      final shoppingTxs = [
        Transaction(
          id: 's1',
          title: 'Sneakers',
          amount: 3000.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 's2',
          title: 'Hoodie',
          amount: 2000.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 's3',
          title: 'Belt',
          amount: 500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
      ];

      final firstRoast = DynamicRoastEngine.generateRoast(
        transactions: shoppingTxs,
      );

      final secondRoast = DynamicRoastEngine.generateRoast(
        transactions: shoppingTxs,
        previousRoastId: firstRoast.id,
        previousRoastText: firstRoast.text,
        recentRoastIds: [firstRoast.id],
      );

      expect(secondRoast.id != firstRoast.id, isTrue);
    });

    test('9. Positive saving & disciplined frugal behaviour produces encouraging roasts', () {
      final frugalTxs = [
        Transaction(
          id: 'inc_1',
          title: 'Monthly Salary',
          amount: 80000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.money,
          categoryColor: Colors.green,
          date: now,
        ),
        Transaction(
          id: 'exp_1',
          title: 'Electricity Bill',
          amount: 1200.0,
          type: TransactionType.expense,
          category: 'Bills',
          icon: Icons.flash_on,
          categoryColor: Colors.amber,
          date: now,
        ),
        Transaction(
          id: 'exp_2',
          title: 'Basic Groceries',
          amount: 2500.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.shopping_cart,
          categoryColor: Colors.orange,
          date: now,
        ),
        Transaction(
          id: 'exp_3',
          title: 'Internet Plan',
          amount: 999.0,
          type: TransactionType.expense,
          category: 'Internet',
          icon: Icons.wifi,
          categoryColor: Colors.blue,
          date: now,
        ),
      ];

      final goals = [
        SavingsGoal(
          id: 'g1',
          title: 'Emergency Fund',
          targetAmount: 50000.0,
          currentAmount: 50000.0,
          createdAt: now,
        ),
      ];

      final matching = DynamicRoastEngine.getMatchingRoasts(
        transactions: frugalTxs,
        savingsGoals: goals,
        language: 'English',
      );

      expect(
        matching.any((r) =>
            r.situation == RoastCategory.goalReached ||
            r.situation == RoastCategory.improvingSavings ||
            r.situation == RoastCategory.disciplinedFrugal),
        isTrue,
      );
    });

    test('10. AppState stability: currentRoast is cached across simple reads and refreshes on mutation', () {
      final appState = AppState();

      // Read current roast multiple times
      final r1 = appState.currentRoast;
      final r2 = appState.currentRoast;
      expect(identical(r1, r2), isTrue);

      // Trigger mutation
      appState.refreshRoast();
      final r3 = appState.currentRoast;
      expect(r3.text.isNotEmpty, isTrue);
    });
  });
}
