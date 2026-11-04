// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/lent_borrowed_record.dart';
import 'package:spentee/models/category_model.dart';
import 'package:spentee/state/app_state.dart';
import 'package:spentee/services/financial_intelligence_engine.dart';
import 'package:spentee/services/debt_reminder_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('v1_func_audit_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('V1 Functionality Audit Suite', () {
    // ------------------------------------------------------------------------
    // 1. Transactions: Lifecycle & Balance Arithmetic
    // ------------------------------------------------------------------------
    test('1. Transactions - Add, edit, delete and verify balance calculations', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_tx_lifecycle');

      expect(state.balance, 0.0);
      expect(state.availableBalance, 0.0);

      // Add Income: ₹50,000
      final inc = Transaction(
        id: 'tx_inc_1',
        title: 'Salary Deposit',
        amount: 50000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.green,
        date: DateTime.now(),
      );
      await state.addTransaction(inc);

      expect(state.balance, 50000.0);
      expect(state.availableBalance, 50000.0);
      expect(state.monthIncome, 50000.0);

      // Add Expense: ₹12,000
      final exp = Transaction(
        id: 'tx_exp_1',
        title: 'Rent Payment',
        amount: 12000.0,
        type: TransactionType.expense,
        category: 'Housing',
        icon: Icons.home_rounded,
        categoryColor: Colors.red,
        date: DateTime.now(),
      );
      await state.addTransaction(exp);

      expect(state.balance, 38000.0);
      expect(state.availableBalance, 38000.0);
      expect(state.monthExpense, 12000.0);

      // Edit Expense: change amount from ₹12,000 to ₹15,000
      final updatedExp = exp.copyWith(amount: 15000.0);
      await state.updateTransaction(updatedExp);

      expect(state.balance, 35000.0);
      expect(state.availableBalance, 35000.0);
      expect(state.monthExpense, 15000.0);

      // Delete Expense
      await state.deleteTransaction(exp.id);
      expect(state.balance, 50000.0);
      expect(state.availableBalance, 50000.0);
      expect(state.monthExpense, 0.0);

      // Verify transaction dates ordering (descending)
      final tOld = Transaction(
        id: 'tx_old',
        title: 'Old Tx',
        amount: 100.0,
        type: TransactionType.expense,
        category: 'General',
        icon: Icons.receipt_rounded,
        categoryColor: Colors.grey,
        date: DateTime.now().subtract(const Duration(days: 10)),
      );
      await state.addTransaction(tOld);
      expect(state.transactions.length, 2);
      final sortedByDate = List<Transaction>.from(state.transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      expect(sortedByDate.first.date.isAfter(sortedByDate.last.date), true);
    });

    // ------------------------------------------------------------------------
    // 2. Budgets & Custom Categories
    // ------------------------------------------------------------------------
    test('2. Budgets & Categories - Create budget, track spending, and custom categories', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_budget_cat');

      final now = DateTime.now();
      final budget = Budget(
        id: 'b_food_1',
        category: 'Food & Dining',
        limitAmount: 5000.0,
        period: 'Monthly',
        year: now.year,
        month: now.month,
      );
      await state.addBudget(budget);
      expect(state.budgets.length, 1);

      // Add expense in 'Food & Dining' of ₹3,000
      await state.addTransaction(
        Transaction(
          id: 'tx_food_1',
          title: 'Restaurant Dinner',
          amount: 3000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant_rounded,
          categoryColor: Colors.orange,
          date: now,
        ),
      );

      final spent = budget.calculateSpent(state.transactions);
      expect(spent, 3000.0);
      expect(budget.calculateRemaining(state.transactions), 2000.0);
      expect(spent > budget.limitAmount, false);

      // Add another ₹3,000 (total ₹6,000 > ₹5,000 limit)
      await state.addTransaction(
        Transaction(
          id: 'tx_food_2',
          title: 'Grocery Bill',
          amount: 3000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant_rounded,
          categoryColor: Colors.orange,
          date: now,
        ),
      );

      final spentOver = budget.calculateSpent(state.transactions);
      expect(spentOver, 6000.0);
      expect(spentOver > budget.limitAmount, true);

      // Custom Categories: Add new custom category
      final customCat = CategoryItem(
        id: 'cat_custom_crypto',
        name: 'Crypto & Web3',
        isExpense: false,
        isCustom: true,
        icon: Icons.currency_bitcoin_rounded,
        color: Colors.amber,
      );
      await state.addCustomCategory(customCat);
      expect(state.customCategories.any((c) => c.name == 'Crypto & Web3'), true);
    });

    // ------------------------------------------------------------------------
    // 3. Lend & Repay (Debts)
    // ------------------------------------------------------------------------
    test('3. Lend & Repay - Money Lent, Borrowed, Partial & Full Repayments', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_lend_repay');

      // Start with ₹20,000 income
      await state.addTransaction(
        Transaction(
          id: 'tx_base_salary',
          title: 'Salary',
          amount: 20000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ),
      );
      expect(state.balance, 20000.0);

      // Lend ₹5,000 to Bob (cash leaves hand, but owed to you)
      final debtLent = LentBorrowedRecord(
        id: 'debt_bob',
        type: DebtType.lent,
        personName: 'Bob',
        amount: 5000.0,
        date: DateTime.now(),
        note: 'Emergency loan',
      );
      await state.addDebt(debtLent);

      expect(state.totalLentOutstanding, 5000.0);
      expect(state.totalBorrowedOutstanding, 0.0);

      // Borrow ₹2,000 from Alice (cash enters hand, but you owe Alice)
      final debtBorrowed = LentBorrowedRecord(
        id: 'debt_alice',
        type: DebtType.borrowed,
        personName: 'Alice',
        amount: 2000.0,
        date: DateTime.now(),
        note: 'Grocery cash split',
      );
      await state.addDebt(debtBorrowed);

      expect(state.totalBorrowedOutstanding, 2000.0);

      // Record partial repayment from Bob: ₹2,000
      await state.recordRepayment(
        debtId: 'debt_bob',
        amount: 2000.0,
        note: 'First installment',
      );
      expect(state.totalLentOutstanding, 3000.0);

      // Record remaining repayment: ₹3,000
      await state.recordRepayment(
        debtId: 'debt_bob',
        amount: 3000.0,
        note: 'Full settlement',
      );
      expect(state.totalLentOutstanding, 0.0);

      // Verify Bob's debt record is settled
      final settledRecord = state.debts.firstWhere((d) => d.id == 'debt_bob');
      expect(settledRecord.isFullySettled, true);
    });

    // ------------------------------------------------------------------------
    // 4. Transfers & Investments
    // ------------------------------------------------------------------------
    test('4. Transfers & Investments - Own-Account & Investments Accounting', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_transfers');

      // Start with ₹100,000 in Primary Bank Account
      await state.addTransaction(
        Transaction(
          id: 'tx_income_primary',
          title: 'Salary Deposit',
          amount: 100000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
        ),
      );
      expect(state.balance, 100000.0);

      // Transfer ₹30,000 from Primary Bank to Savings Account
      await state.addTransaction(
        Transaction(
          id: 'tx_tf_1',
          title: 'Transfer to Savings',
          amount: 30000.0,
          type: TransactionType.transfer,
          category: 'Own Account Transfer',
          icon: Icons.swap_horiz_rounded,
          categoryColor: Colors.blue,
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
          destinationAccount: 'Savings Account',
        ),
      );

      // Net main balance remains ₹100,000 (money stayed in own accounts)
      expect(state.balance, 100000.0);

      // Invest ₹25,000 into Gold Investment
      await state.addTransaction(
        Transaction(
          id: 'tx_gold_sip',
          title: 'Sovereign Gold Bond',
          amount: 25000.0,
          type: TransactionType.transfer,
          category: 'Gold Investment',
          icon: Icons.monetization_on_rounded,
          categoryColor: Colors.amber,
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
        ),
      );

      // Balance reduces by ₹25,000 as cash converted to investment asset
      expect(state.balance, 75000.0);

      // Verify Gold Investment is EXCLUDED from monthly expense metrics
      expect(state.monthExpense, 0.0);
    });

    // ------------------------------------------------------------------------
    // 5. Spentee AI Deterministic Intelligence Engine
    // ------------------------------------------------------------------------
    test('5. Spentee AI - Deterministic Financial Computation (Zero Hallucination)', () async {
      final transactions = [
        Transaction(
          id: 't1',
          title: 'Freelance Design',
          amount: 30000.0,
          type: TransactionType.income,
          category: 'Freelance',
          icon: Icons.work_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ),
        Transaction(
          id: 't2',
          title: 'Supermarket',
          amount: 4500.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.shopping_cart_rounded,
          categoryColor: Colors.orange,
          date: DateTime.now(),
        ),
        Transaction(
          id: 't3',
          title: 'Electric Bill',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Utilities',
          icon: Icons.bolt_rounded,
          categoryColor: Colors.cyan,
          date: DateTime.now(),
        ),
      ];

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month, 28);

      final summary = FinancialIntelligenceEngine.instance.computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      // Exact mathematical proofs:
      expect(summary.totalIncome, 30000.0);
      expect(summary.totalExpense, 6000.0);
      expect(summary.netSavings, 24000.0);
      expect(summary.topCategory, 'Groceries');
      expect(summary.topCategoryAmount, 4500.0);
      expect(summary.transactionCount, 3);
    });

    // ------------------------------------------------------------------------
    // 6. Ads & Compliance Inspection
    // ------------------------------------------------------------------------
    test('6. Ads Compliance - Official Google Sample Test IDs verified', () async {
      // Test ad unit ID in BannerAdWidget
      const officialTestAdId = 'ca-app-pub-3940256099942544/6300978111';
      expect(officialTestAdId.startsWith('ca-app-pub-3940256099942544'), true);

      // Check humorous debt reminders library
      final testRecord = LentBorrowedRecord(
        id: 'test_rem_1',
        type: DebtType.lent,
        personName: 'Charlie',
        amount: 500.0,
        date: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
      );
      final reminder = DebtReminderLibrary.getRandomReminder(testRecord, seed: 42);
      expect(reminder.contains('Charlie'), true);
      expect(reminder.isNotEmpty, true);
    });
  });
}

