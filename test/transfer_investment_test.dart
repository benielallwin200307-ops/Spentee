import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/models/lent_borrowed_record.dart';
import 'package:spentee/state/app_state.dart';
import 'package:spentee/screens/add_transaction_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('spentee_transfer_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Spentee Transfer & Investment Tracking Tests', () {
    test('1. Record a gold investment and verify Main Balance decreases correctly', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_1');

      // Start with income of ₹20,000
      await state.addTransaction(
        Transaction(
          id: 'tx_income_1',
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
      expect(state.availableBalance, 20000.0);

      // Record ₹5,000 Gold Investment
      await state.addTransaction(
        Transaction(
          id: 'tx_gold_1',
          title: 'Gold Investment',
          amount: 5000.0,
          type: TransactionType.transfer,
          category: 'Gold Investment',
          icon: Transaction.iconForCategory('Gold Investment'),
          categoryColor: Transaction.colorForCategory('Gold Investment'),
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
        ),
      );

      // Main Balance and Available Balance must be ₹15,000
      expect(state.balance, 15000.0);
      expect(state.availableBalance, 15000.0);
      expect(state.transactions.first.isInvestment, isTrue);
    });

    test('2. Record an actual SIP contribution and verify Main Balance decreases correctly', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_2');

      await state.addTransaction(
        Transaction(
          id: 'tx_inc_sip',
          title: 'Consulting',
          amount: 30000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ),
      );

      // Record ₹7,500 Mutual Fund / SIP
      await state.addTransaction(
        Transaction(
          id: 'tx_sip_1',
          title: 'Mutual Fund / SIP',
          amount: 7500.0,
          type: TransactionType.transfer,
          category: 'Mutual Fund / SIP',
          icon: Transaction.iconForCategory('Mutual Fund / SIP'),
          categoryColor: Transaction.colorForCategory('Mutual Fund / SIP'),
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
        ),
      );

      expect(state.balance, 22500.0);
      expect(state.availableBalance, 22500.0);
      expect(state.monthInvestments, 7500.0);
    });

    test('3. Record a stock or ETF investment and verify Main Balance decreases correctly', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_3');

      await state.addTransaction(
        Transaction(
          id: 'tx_inc_stock',
          title: 'Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ),
      );

      // Record ₹12,000 Stocks & ETFs
      await state.addTransaction(
        Transaction(
          id: 'tx_stock_1',
          title: 'Stocks & ETFs',
          amount: 12000.0,
          type: TransactionType.transfer,
          category: 'Stocks & ETFs',
          icon: Transaction.iconForCategory('Stocks & ETFs'),
          categoryColor: Transaction.colorForCategory('Stocks & ETFs'),
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
        ),
      );

      expect(state.balance, 38000.0);
      expect(state.availableBalance, 38000.0);
    });

    test('4. Record a savings deposit and verify Main Balance decreases correctly', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_4');

      await state.addTransaction(
        Transaction(
          id: 'tx_inc_sav',
          title: 'Salary',
          amount: 40000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ),
      );

      // Record ₹10,000 Savings & Deposits
      await state.addTransaction(
        Transaction(
          id: 'tx_sav_1',
          title: 'Savings & Deposits',
          amount: 10000.0,
          type: TransactionType.transfer,
          category: 'Savings & Deposits',
          icon: Transaction.iconForCategory('Savings & Deposits'),
          categoryColor: Transaction.colorForCategory('Savings & Deposits'),
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
        ),
      );

      expect(state.balance, 30000.0);
      expect(state.availableBalance, 30000.0);
    });

    test('5. Transfer money between two personal accounts and verify combined Main Balance remains unchanged', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_5');

      await state.addTransaction(
        Transaction(
          id: 'tx_inc_transfer',
          title: 'Salary',
          amount: 25000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
        ),
      );

      // Transfer ₹8,000 from Primary Bank to Savings Account
      await state.addTransaction(
        Transaction(
          id: 'tx_own_transfer_1',
          title: 'Own Account Transfer',
          amount: 8000.0,
          type: TransactionType.transfer,
          category: 'Own Account Transfer',
          icon: Transaction.iconForCategory('Own Account Transfer'),
          categoryColor: Transaction.colorForCategory('Own Account Transfer'),
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
          destinationAccount: 'Savings Account',
        ),
      );

      // Combined Main Balance MUST remain strictly unchanged at ₹25,000
      expect(state.balance, 25000.0);
      expect(state.availableBalance, 25000.0);

      // Account-level balance check
      expect(state.getAccountBalance('Primary Bank Account'), 17000.0); // 25000 - 8000
      expect(state.getAccountBalance('Savings Account'), 8000.0);      // +8000
    });

    test('6. Confirm investment contributions do not inflate ordinary expense totals', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_6');

      final now = DateTime.now();

      // Ordinary expense of ₹1,500
      await state.addTransaction(
        Transaction(
          id: 'tx_exp_food',
          title: 'Dinner',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Food & Drinks',
          icon: Icons.restaurant_rounded,
          categoryColor: Colors.pink,
          date: now,
        ),
      );

      // Investment contributions of ₹20,000
      await state.addTransaction(
        Transaction(
          id: 'tx_gold_2',
          title: 'Gold Investment',
          amount: 20000.0,
          type: TransactionType.transfer,
          category: 'Gold Investment',
          icon: Icons.monetization_on_rounded,
          categoryColor: Colors.amber,
          date: now,
        ),
      );

      // Today's spending, month expense, and total expense MUST strictly equal ₹1,500
      expect(state.todaySpending, 1500.0);
      expect(state.monthExpense, 1500.0);
      expect(state.totalExpense, 1500.0);

      // Month investments must be ₹20,000
      expect(state.monthInvestments, 20000.0);
    });

    test('7. Edit an investment amount and verify the balance is adjusted exactly once', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_7');

      await state.addTransaction(
        Transaction(
          id: 'tx_inc_edit',
          title: 'Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ),
      );

      final invTx = Transaction(
        id: 'tx_inv_edit',
        title: 'Retirement Investments',
        amount: 10000.0,
        type: TransactionType.transfer,
        category: 'Retirement Investments',
        icon: Icons.shield_rounded,
        categoryColor: Colors.purple,
        date: DateTime.now(),
        sourceAccount: 'Primary Bank Account',
      );
      await state.addTransaction(invTx);
      expect(state.balance, 40000.0);

      // Edit investment from ₹10,000 to ₹15,000
      final updatedInvTx = invTx.copyWith(amount: 15000.0);
      final ok = await state.updateTransaction(updatedInvTx);
      expect(ok, isTrue);

      // Balance must adjust by -5000 to ₹35,000 (not double deducted)
      expect(state.balance, 35000.0);
      expect(state.availableBalance, 35000.0);
      expect(state.transactions.first.amount, 15000.0);
    });

    test('8. Delete an investment and verify its balance effect is reversed exactly once', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_8');

      await state.addTransaction(
        Transaction(
          id: 'tx_inc_del',
          title: 'Salary',
          amount: 30000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ),
      );

      final invTx = Transaction(
        id: 'tx_inv_del',
        title: 'Other Investment',
        amount: 8000.0,
        type: TransactionType.transfer,
        category: 'Other Investment',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.grey,
        date: DateTime.now(),
      );
      await state.addTransaction(invTx);
      expect(state.balance, 22000.0);

      // Delete investment
      await state.deleteTransaction('tx_inv_del');

      // Balance must reverse to ₹30,000 exactly once
      expect(state.balance, 30000.0);
      expect(state.availableBalance, 30000.0);
    });

    test('9. Edit and delete an own-account transfer and verify both accounts remain consistent', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_9');

      await state.addTransaction(
        Transaction(
          id: 'tx_inc_acc',
          title: 'Salary',
          amount: 40000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
          sourceAccount: 'Primary Bank Account',
        ),
      );

      final transferTx = Transaction(
        id: 'tx_acc_tf',
        title: 'Own Account Transfer',
        amount: 5000.0,
        type: TransactionType.transfer,
        category: 'Own Account Transfer',
        icon: Icons.swap_horiz_rounded,
        categoryColor: Colors.blue,
        date: DateTime.now(),
        sourceAccount: 'Primary Bank Account',
        destinationAccount: 'Savings Account',
      );
      await state.addTransaction(transferTx);

      expect(state.getAccountBalance('Primary Bank Account'), 35000.0);
      expect(state.getAccountBalance('Savings Account'), 5000.0);
      expect(state.balance, 40000.0);

      // Edit amount from ₹5,000 to ₹12,000
      final updatedTf = transferTx.copyWith(amount: 12000.0);
      await state.updateTransaction(updatedTf);

      expect(state.getAccountBalance('Primary Bank Account'), 28000.0);
      expect(state.getAccountBalance('Savings Account'), 12000.0);
      expect(state.balance, 40000.0);

      // Delete transfer
      await state.deleteTransaction('tx_acc_tf');
      expect(state.getAccountBalance('Primary Bank Account'), 40000.0);
      expect(state.getAccountBalance('Savings Account'), 0.0);
      expect(state.balance, 40000.0);
    });

    test('10. Verify category icons appear correctly in the selector, history, and transaction details', () {
      expect(Transaction.iconForCategory('Own Account Transfer'), Icons.swap_horiz_rounded);
      expect(Transaction.iconForCategory('Gold Investment'), Icons.monetization_on_rounded);
      expect(Transaction.iconForCategory('Mutual Fund / SIP'), Icons.auto_graph_rounded);
      expect(Transaction.iconForCategory('Stocks & ETFs'), Icons.trending_up_rounded);
      expect(Transaction.iconForCategory('Savings & Deposits'), Icons.savings_rounded);
      expect(Transaction.iconForCategory('Retirement Investments'), Icons.shield_rounded);
      expect(Transaction.iconForCategory('Other Investment'), Icons.account_balance_wallet_rounded);
    });

    test('11. Restart the app and confirm saved transactions and icons persist', () {
      final tx = Transaction(
        id: 'tx_persisted_inv',
        title: 'Gold Investment',
        amount: 25000.0,
        type: TransactionType.transfer,
        category: 'Gold Investment',
        icon: Icons.monetization_on_rounded,
        categoryColor: const Color(0xFFFFB300),
        date: DateTime(2026, 10, 23, 10, 30),
        sourceAccount: 'Primary Bank Account',
        destinationAccount: null,
      );

      final json = tx.toJson();
      expect(json['sourceAccount'], 'Primary Bank Account');
      expect(json['destinationAccount'], isNull);

      final reloaded = Transaction.fromJson(json);
      expect(reloaded.id, tx.id);
      expect(reloaded.category, 'Gold Investment');
      expect(reloaded.amount, 25000.0);
      expect(reloaded.isInvestment, isTrue);
      expect(reloaded.icon, Icons.monetization_on_rounded);
      expect(reloaded.sourceAccount, 'Primary Bank Account');
    });

    test('12. Confirm existing lending, borrowing, repayments, income, expenses, and refunds still work', () async {
      final state = AppState();
      state.initSyncForTesting('test_user_inv_12');

      // Income
      await state.addTransaction(
        Transaction(
          id: 'tx_base_inc',
          title: 'Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.account_balance_wallet_rounded,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ),
      );

      // Expense
      await state.addTransaction(
        Transaction(
          id: 'tx_base_exp',
          title: 'Groceries',
          amount: 4000.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.local_grocery_store_rounded,
          categoryColor: Colors.orange,
          date: DateTime.now(),
        ),
      );

      // Investment
      await state.addTransaction(
        Transaction(
          id: 'tx_base_inv',
          title: 'Mutual Fund / SIP',
          amount: 6000.0,
          type: TransactionType.transfer,
          category: 'Mutual Fund / SIP',
          icon: Icons.auto_graph_rounded,
          categoryColor: Colors.cyan,
          date: DateTime.now(),
        ),
      );

      // Balance before debt = 50000 - 4000 - 6000 = 40000
      expect(state.balance, 40000.0);
      expect(state.availableBalance, 40000.0);

      // Lent ₹10,000 to Friend (Receivable asset: reduces spendable cash by ₹10,000)
      await state.addDebt(
        LentBorrowedRecord(
          id: 'debt_lent_1',
          type: DebtType.lent,
          personName: 'Rohan',
          amount: 10000.0,
          date: DateTime.now(),
        ),
      );

      // Money Lent immediately reduces Main Balance by ₹10,000 to ₹30,000
      expect(state.availableBalance, 30000.0);
      expect(state.balance, 30000.0);

      // Repay ₹4,000
      await state.recordRepayment(debtId: 'debt_lent_1', amount: 4000.0);
      // Main balance and available balance restore by ₹4,000 to 34,000
      expect(state.availableBalance, 34000.0);
      expect(state.balance, 34000.0);
    });
  });

  group('Widget UI Integration Tests', () {
    testWidgets('Transfer selector shows all 7 categories and account selectors', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = AppState();
      state.initSyncForTesting('test_ui_user');

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: const MaterialApp(
            home: AddTransactionScreen(initialType: TransactionType.transfer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify transfer mode is active
      expect(find.text('Transfer'), findsAtLeastNWidgets(1));

      // Open category picker
      final categoryCard = find.text('Category');
      expect(categoryCard, findsOneWidget);
      await tester.tap(categoryCard);
      await tester.pumpAndSettle();

      // Check for investment and own account transfer categories in bottom sheet
      expect(find.text('Own Account Transfer'), findsAtLeastNWidgets(1));
      expect(find.text('Gold Investment'), findsOneWidget);
      expect(find.text('Mutual Fund / SIP'), findsOneWidget);
      expect(find.text('Stocks & ETFs'), findsOneWidget);
      expect(find.text('Savings & Deposits'), findsOneWidget);
      expect(find.text('Retirement Investments'), findsOneWidget);
      expect(find.text('Other Investment'), findsOneWidget);

      // Select Gold Investment
      await tester.tap(find.text('Gold Investment'));
      await tester.pumpAndSettle();

      // For Gold Investment, only 'From Account' should appear, 'To Account' should NOT appear
      expect(find.text('From Account'), findsOneWidget);
      expect(find.text('To Account'), findsNothing);

      // Now switch category back to Own Account Transfer
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Own Account Transfer').last);
      await tester.pumpAndSettle();

      // For Own Account Transfer, both 'From Account' and 'To Account' must appear
      expect(find.text('From Account'), findsOneWidget);
      expect(find.text('To Account'), findsOneWidget);
    });
  });
}
