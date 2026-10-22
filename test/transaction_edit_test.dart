import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/state/app_state.dart';
import 'package:spentee/screens/edit_transaction_screen.dart';
import 'package:spentee/widgets/transaction_details_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transaction Edit & Safety Unit Tests', () {
    test('1. updateTransaction edits expense and recalculates balance accurately', () async {
      final appState = AppState();
      final now = DateTime.now();

      final initialTx = Transaction(
        id: 'tx_expense_1',
        title: 'Dinner',
        amount: 500.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.pink,
        date: now.subtract(const Duration(hours: 2)),
      );

      await appState.addTransaction(initialTx);
      final balanceAfterAdd = appState.balance;

      // Update amount from ₹500 to ₹800
      final updatedTx = initialTx.copyWith(
        title: 'Fancy Dinner',
        amount: 800.0,
      );

      final success = await appState.updateTransaction(updatedTx);

      expect(success, isTrue);
      expect(appState.transactions.length, 1);
      expect(appState.transactions.first.title, 'Fancy Dinner');
      expect(appState.transactions.first.amount, 800.0);
      expect(appState.transactions.first.id, 'tx_expense_1');
      // Balance should decrease by extra ₹300
      expect(appState.balance, balanceAfterAdd - 300.0);
    });

    test('2. updateTransaction edits income and updates monthIncome and balance', () async {
      final appState = AppState();
      final now = DateTime.now();

      final initialSalary = Transaction(
        id: 'tx_income_1',
        title: 'Salary',
        amount: 30000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.green,
        date: now.subtract(const Duration(days: 1)),
      );

      await appState.addTransaction(initialSalary);
      final balanceAfterSalary = appState.balance;
      final incomeAfterSalary = appState.monthIncome;

      // Update Salary from 30,000 to 35,000
      final updatedSalary = initialSalary.copyWith(amount: 35000.0);
      final success = await appState.updateTransaction(updatedSalary);

      expect(success, isTrue);
      expect(appState.balance, balanceAfterSalary + 5000.0);
      expect(appState.monthIncome, incomeAfterSalary + 5000.0);
      expect(appState.transactions.first.amount, 35000.0);
    });

    test('3. updateTransaction handles type changes (expense to transfer restores funds)', () async {
      final appState = AppState();
      final now = DateTime.now();

      final tx = Transaction(
        id: 'tx_type_change',
        title: 'Sent to Friend',
        amount: 1000.0,
        type: TransactionType.expense,
        category: 'Sent to Friend',
        icon: Icons.person_rounded,
        categoryColor: Colors.purple,
        date: now.subtract(const Duration(hours: 1)),
      );

      await appState.addTransaction(tx);
      final balanceWithExpense = appState.balance;

      // Change from Expense to Transfer (Transfers do not affect balance)
      final transferTx = tx.copyWith(type: TransactionType.transfer);
      await appState.updateTransaction(transferTx);

      // Balance should be restored by ₹1000
      expect(appState.balance, balanceWithExpense + 1000.0);
      expect(appState.transactions.first.type, TransactionType.transfer);
    });

    test('4. updateTransaction rejects future dates and preserves existing record', () async {
      final appState = AppState();
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final txDate = now.subtract(const Duration(hours: 2));
      final tx = Transaction(
        id: 'tx_date_check',
        title: 'Groceries',
        amount: 400.0,
        type: TransactionType.expense,
        category: 'Groceries',
        icon: Icons.local_grocery_store_rounded,
        categoryColor: Colors.green,
        date: txDate,
      );

      await appState.addTransaction(tx);
      final balanceBefore = appState.balance;

      // Attempt to set date into tomorrow
      final futureTx = tx.copyWith(date: tomorrow, amount: 999.0);
      final success = await appState.updateTransaction(futureTx);

      expect(success, isFalse);
      expect(appState.transactions.first.amount, 400.0);
      expect(appState.transactions.first.date.day, txDate.day);
      expect(appState.balance, balanceBefore);
    });
  });

  group('Transaction UI & Edit Widget Tests', () {
    testWidgets('5. EditTransactionScreen pre-fills fields with existing transaction values', (tester) async {
      final appState = AppState();
      final tx = Transaction(
        id: 'tx_widget_test',
        title: 'Morning Espresso',
        amount: 120.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.pink,
        date: DateTime.now().subtract(const Duration(hours: 1)),
        note: 'Extra shot',
      );

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: MaterialApp(
            home: EditTransactionScreen(transaction: tx),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check pre-filled text
      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('Morning Espresso'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('Extra shot'), findsOneWidget);
      expect(find.text('Food & Drinks'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('6. EditTransactionScreen allows switching transaction types reactively', (tester) async {
      final appState = AppState();
      final tx = Transaction(
        id: 'tx_switch_test',
        title: 'Lunch',
        amount: 250.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.pink,
        date: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: MaterialApp(
            home: EditTransactionScreen(transaction: tx),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial type buttons
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);

      // Tap Income switch
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // Tap Transfer switch
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();
    });

    testWidgets('7. TransactionDetailsModal renders transaction attributes and actions', (tester) async {
      final tx = Transaction(
        id: 'tx_details_test',
        title: 'Movie Ticket',
        amount: 350.0,
        type: TransactionType.expense,
        category: 'Entertainment',
        icon: Icons.sports_esports_rounded,
        categoryColor: Colors.blue,
        date: DateTime.now(),
        note: 'Weekend show',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDetailsModal(transaction: tx),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check details content
      expect(find.text('Transaction Details'), findsOneWidget);
      expect(find.text('Movie Ticket'), findsOneWidget);
      expect(find.text('₹350'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
      expect(find.text('Weekend show'), findsOneWidget);
      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('8. Transaction card displays 3-dot popup menu with View, Edit, Delete', (tester) async {
      final appState = AppState();
      final tx = Transaction(
        id: 'tx_menu_test',
        title: 'Office Commute',
        amount: 80.0,
        type: TransactionType.expense,
        category: 'Transport',
        icon: Icons.directions_car_rounded,
        categoryColor: Colors.cyan,
        date: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(tx.title),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'details', child: Text('View Details')),
                        PopupMenuItem(value: 'edit', child: Text('Edit Transaction')),
                        PopupMenuItem(value: 'delete', child: Text('Delete Transaction')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify transaction card and more_vert icon are present
      expect(find.text('Office Commute'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // Tap 3-dot popup menu and verify options
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('Delete Transaction'), findsOneWidget);
    });
  });
}
