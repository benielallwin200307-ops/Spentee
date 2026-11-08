import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/state/app_state.dart';
import 'package:spentee/screens/add_transaction_screen.dart';
import 'package:spentee/screens/edit_transaction_screen.dart';
import 'package:spentee/widgets/insufficient_balance_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Insufficient Balance Validation - Model Layer', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('Available: ₹5,000 | Expense: ₹3,000 -> Allowed', () async {
      // Setup ₹5,000 income
      await appState.addTransaction(Transaction(
        id: 'inc_1',
        title: 'Salary',
        amount: 5000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.attach_money,
        categoryColor: Colors.green,
        date: DateTime.now(),
      ));

      expect(appState.availableBalance, 5000.0);
      expect(appState.canAffordExpense(3000.0), isTrue);

      final allowed = await appState.addTransaction(
        Transaction(
          id: 'exp_1',
          title: 'Groceries',
          amount: 3000.0,
          type: TransactionType.expense,
          category: 'Food',
          icon: Icons.fastfood,
          categoryColor: Colors.orange,
          date: DateTime.now(),
        ),
        enforceBalanceValidation: true,
      );

      expect(allowed, isTrue);
      expect(appState.availableBalance, 2000.0);
      expect(appState.transactions.length, 2);
    });

    test('Available: ₹5,000 | Expense: ₹5,000 -> Allowed (exact balance)', () async {
      await appState.addTransaction(Transaction(
        id: 'inc_2',
        title: 'Salary',
        amount: 5000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.attach_money,
        categoryColor: Colors.green,
        date: DateTime.now(),
      ));

      expect(appState.canAffordExpense(5000.0), isTrue);

      final allowed = await appState.addTransaction(
        Transaction(
          id: 'exp_2',
          title: 'Shopping',
          amount: 5000.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.blue,
          date: DateTime.now(),
        ),
        enforceBalanceValidation: true,
      );

      expect(allowed, isTrue);
      expect(appState.availableBalance, 0.0);
    });

    test('Available: ₹5,000 | Expense: ₹5,001 -> Rejected', () async {
      await appState.addTransaction(Transaction(
        id: 'inc_3',
        title: 'Salary',
        amount: 5000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.attach_money,
        categoryColor: Colors.green,
        date: DateTime.now(),
      ));

      expect(appState.canAffordExpense(5001.0), isFalse);

      final allowed = await appState.addTransaction(
        Transaction(
          id: 'exp_3',
          title: 'Luxury',
          amount: 5001.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.blue,
          date: DateTime.now(),
        ),
        enforceBalanceValidation: true,
      );

      expect(allowed, isFalse);
      expect(appState.availableBalance, 5000.0);
      expect(appState.transactions.length, 1);
    });

    test('Available: ₹0 | Expense: ₹100 -> Rejected', () async {
      expect(appState.availableBalance, 0.0);
      expect(appState.canAffordExpense(100.0), isFalse);

      final allowed = await appState.addTransaction(
        Transaction(
          id: 'exp_4',
          title: 'Snack',
          amount: 100.0,
          type: TransactionType.expense,
          category: 'Food',
          icon: Icons.fastfood,
          categoryColor: Colors.orange,
          date: DateTime.now(),
        ),
        enforceBalanceValidation: true,
      );

      expect(allowed, isFalse);
      expect(appState.availableBalance, 0.0);
      expect(appState.transactions.isEmpty, isTrue);
    });

    test('Available: ₹0 | Expense: ₹0 -> Rejected', () async {
      expect(appState.canAffordExpense(0.0), isFalse);
    });

    test('Available: ₹10,000 | Expense: ₹12,000 -> Rejected', () async {
      await appState.addTransaction(Transaction(
        id: 'inc_5',
        title: 'Bonus',
        amount: 10000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.attach_money,
        categoryColor: Colors.green,
        date: DateTime.now(),
      ));

      expect(appState.availableBalance, 10000.0);
      expect(appState.canAffordExpense(12000.0), isFalse);

      final allowed = await appState.addTransaction(
        Transaction(
          id: 'exp_5',
          title: 'Laptop',
          amount: 12000.0,
          type: TransactionType.expense,
          category: 'Electronics',
          icon: Icons.laptop,
          categoryColor: Colors.purple,
          date: DateTime.now(),
        ),
        enforceBalanceValidation: true,
      );

      expect(allowed, isFalse);
      expect(appState.availableBalance, 10000.0);
    });

    test('Editing Expense: ₹3,000 balance + ₹2,000 old expense -> effective ₹5,000', () async {
      // 1. Give ₹5,000 income
      await appState.addTransaction(Transaction(
        id: 'inc_6',
        title: 'Income',
        amount: 5000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.attach_money,
        categoryColor: Colors.green,
        date: DateTime.now(),
      ));

      // 2. Add ₹2,000 expense -> leaves ₹3,000 balance
      final oldTx = Transaction(
        id: 'exp_edit_1',
        title: 'Groceries',
        amount: 2000.0,
        type: TransactionType.expense,
        category: 'Food',
        icon: Icons.fastfood,
        categoryColor: Colors.orange,
        date: DateTime.now(),
      );
      await appState.addTransaction(oldTx, enforceBalanceValidation: true);

      expect(appState.availableBalance, 3000.0);

      // Effective balance when editing this expense is 3000 + 2000 = 5000
      final effective = appState.getEffectiveAvailableBalance(excludeTransactionId: oldTx.id);
      expect(effective, 5000.0);

      // Editing to ₹4,000 is allowed
      expect(appState.canAffordExpense(4000.0, excludeTransactionId: oldTx.id), isTrue);
      final allowed4000 = await appState.updateTransaction(
        oldTx.copyWith(amount: 4000.0),
        enforceBalanceValidation: true,
      );
      expect(allowed4000, isTrue);
      expect(appState.availableBalance, 1000.0);

      // Now available balance is 1000, effective balance with 4000 is 5000
      // Editing to ₹6,000 is rejected
      expect(appState.canAffordExpense(6000.0, excludeTransactionId: oldTx.id), isFalse);
      final rejected6000 = await appState.updateTransaction(
        oldTx.copyWith(amount: 6000.0),
        enforceBalanceValidation: true,
      );
      expect(rejected6000, isFalse);
      expect(appState.availableBalance, 1000.0);
    });

    test('Non-expense financial integrity preserved', () async {
      // Balance is 0
      expect(appState.availableBalance, 0.0);

      // Income is not blocked
      final incAllowed = await appState.addTransaction(
        Transaction(
          id: 'inc_free',
          title: 'Freelance',
          amount: 8000.0,
          type: TransactionType.income,
          category: 'Income',
          icon: Icons.monetization_on,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ),
        enforceBalanceValidation: true,
      );
      expect(incAllowed, isTrue);
      expect(appState.availableBalance, 8000.0);

      // Borrowing money is cash inflow
      final borrowAllowed = await appState.addTransaction(
        Transaction(
          id: 'borrow_1',
          title: 'Loan from Bob',
          amount: 2000.0,
          type: TransactionType.borrowed,
          category: 'Borrow',
          icon: Icons.handshake,
          categoryColor: Colors.blue,
          date: DateTime.now(),
        ),
        enforceBalanceValidation: true,
      );
      expect(borrowAllowed, isTrue);
      expect(appState.availableBalance, 10000.0);
    });
  });

  group('Insufficient Balance UI - Dialog & Screen Tests', () {
    testWidgets('InsufficientBalanceDialog renders required details correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  InsufficientBalanceDialog.show(
                    context,
                    availableBalance: 5000.0,
                    expenseAmount: 6000.0,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.text('Insufficient Balance'), findsOneWidget);
      expect(
        find.text("You don't have enough available balance for this transaction."),
        findsOneWidget,
      );

      // Verify labels and formatted amounts
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('₹5,000'), findsOneWidget);

      expect(find.text('Expense Amount'), findsOneWidget);
      expect(find.text('₹6,000'), findsOneWidget);

      expect(find.text('Remaining Required'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);

      // Verify dismiss button
      expect(find.text('Got it'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('Insufficient Balance'), findsNothing);
    });

    testWidgets('AddTransactionScreen blocks expense exceeding balance with dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appState = AppState();
      // Setup ₹5,000 income
      await tester.runAsync(() async {
        await appState.addTransaction(Transaction(
          id: 'inc_test',
          title: 'Initial Deposit',
          amount: 5000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.attach_money,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ));
      });

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: AddTransactionScreen(initialType: TransactionType.expense),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Keypad input: 6000
      await tester.tap(find.widgetWithText(InkWell, '6'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '0'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '0'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, '0'));
      await tester.pumpAndSettle();

      // Tap Save button
      final saveBtn = find.text('Save');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Insufficient balance dialog should appear
      expect(find.text('Insufficient Balance'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('₹5,000'), findsOneWidget);
      expect(find.text('Expense Amount'), findsOneWidget);
      expect(find.text('₹6,000'), findsOneWidget);
      expect(find.text('Remaining Required'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);

      // Verify transaction was NOT saved
      expect(appState.transactions.length, 1);
      expect(appState.availableBalance, 5000.0);
    });

    testWidgets('EditTransactionScreen blocks expense exceeding effective balance with dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appState = AppState();
      late Transaction existingExpense;
      await tester.runAsync(() async {
        await appState.addTransaction(Transaction(
          id: 'inc_test2',
          title: 'Salary',
          amount: 5000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.attach_money,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ));
        existingExpense = Transaction(
          id: 'exp_test_edit',
          title: 'Dinner',
          amount: 2000.0,
          type: TransactionType.expense,
          category: 'Food',
          icon: Icons.fastfood,
          categoryColor: Colors.orange,
          date: DateTime.now(),
        );
        await appState.addTransaction(existingExpense);
      });

      expect(appState.availableBalance, 3000.0);

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: MaterialApp(
            home: EditTransactionScreen(transaction: existingExpense),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find amount text field and enter 6000 (which exceeds effective balance 5000)
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '6000');
      await tester.pumpAndSettle();

      // Tap Save Changes
      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Insufficient balance dialog should appear with effective balance ₹5,000
      expect(find.text('Insufficient Balance'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('₹5,000'), findsOneWidget);
      expect(find.text('Expense Amount'), findsOneWidget);
      expect(find.text('₹6,000'), findsOneWidget);
      expect(find.text('Remaining Required'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);

      // Verify transaction was NOT updated
      expect(appState.availableBalance, 3000.0);
      expect(appState.transactions.firstWhere((t) => t.id == 'exp_test_edit').amount, 2000.0);
    });
  });
}
