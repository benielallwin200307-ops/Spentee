import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/lent_borrowed_record.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/screens/lent_borrowed_screen.dart';
import 'package:spentee/services/debt_reminder_library.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  group('Spentee Lent & Borrowed Money with Funny Reminders Tests', () {
    final now = DateTime.now();

    test('1. Model integrity: serialization, deserialization and initial state', () {
      final dueDate = now.add(const Duration(days: 7));
      final record = LentBorrowedRecord(
        id: 'debt_1',
        type: DebtType.lent,
        personName: 'Rahul',
        amount: 2500.0,
        date: now,
        dueDate: dueDate,
        note: 'Weekend trip share',
      );

      expect(record.personName, 'Rahul');
      expect(record.amount, 2500.0);
      expect(record.outstandingAmount, 2500.0);
      expect(record.repaidAmount, 0.0);
      expect(record.status, DebtStatus.pending);
      expect(record.isFullySettled, isFalse);
      expect(record.isOverdue, isFalse);

      final json = record.toJson();
      final restored = LentBorrowedRecord.fromJson(json);

      expect(restored.id, record.id);
      expect(restored.type, record.type);
      expect(restored.personName, record.personName);
      expect(restored.amount, record.amount);
      expect(restored.outstandingAmount, record.outstandingAmount);
      expect(restored.note, record.note);
    });

    test('2. Status transitions: Pending -> Partially Repaid -> Fully Settled', () {
      final record = LentBorrowedRecord(
        id: 'debt_2',
        type: DebtType.lent,
        personName: 'Priya',
        amount: 5000.0,
        date: now,
        dueDate: now.add(const Duration(days: 14)),
      );

      expect(record.status, DebtStatus.pending);

      // Record partial repayment of 2000
      final partial = record.copyWith(
        repayments: [
          RepaymentRecord(
            id: 'rep_1',
            amount: 2000.0,
            date: now,
            note: 'First installment via GPay',
          ),
        ],
      );

      expect(partial.repaidAmount, 2000.0);
      expect(partial.outstandingAmount, 3000.0);
      expect(partial.progressRatio, 0.4);
      expect(partial.status, DebtStatus.partiallyRepaid);
      expect(partial.isFullySettled, isFalse);

      // Record final repayment of 3000
      final settled = partial.copyWith(
        repayments: [
          ...partial.repayments,
          RepaymentRecord(
            id: 'rep_2',
            amount: 3000.0,
            date: now,
            note: 'Cash settlement',
          ),
        ],
      );

      expect(settled.repaidAmount, 5000.0);
      expect(settled.outstandingAmount, 0.0);
      expect(settled.progressRatio, 1.0);
      expect(settled.status, DebtStatus.settled);
      expect(settled.isFullySettled, isTrue);
    });

    test('3. Overdue detection: accurately flags when due date has passed', () {
      final pastDate = now.subtract(const Duration(days: 5));
      final overdueRecord = LentBorrowedRecord(
        id: 'debt_overdue',
        type: DebtType.lent,
        personName: 'Karthik',
        amount: 1500.0,
        date: now.subtract(const Duration(days: 20)),
        dueDate: pastDate,
      );

      expect(overdueRecord.isOverdue, isTrue);
      expect(overdueRecord.status, DebtStatus.overdue);
      expect(overdueRecord.daysOverdue, greaterThanOrEqualTo(4));
    });

    test('4. Financial Accounting Rule: Money lent does NOT count as an ordinary expense', () {
      final appState = AppState();

      final initialSpending = appState.todaySpending;
      final initialMonthExpense = appState.monthExpense;

      // Add lent record
      final lent = LentBorrowedRecord(
        id: 'd_lent_acc',
        type: DebtType.lent,
        personName: 'Amit',
        amount: 10000.0,
        date: now,
      );
      appState.addDebt(lent);

      // Today's spending and month's consumption expenses must NOT increase by 10,000
      expect(appState.todaySpending, initialSpending);
      expect(appState.monthExpense, initialMonthExpense);

      // Budget calculation must strictly NOT be consumed
      final foodBudget = Budget(
        id: 'b_food_test',
        category: 'Food & Dining',
        limitAmount: 15000.0,
        year: now.year,
        month: now.month,
      );
      expect(foodBudget.calculateSpent(appState.transactions), 0.0);

      // Outstanding lent receivable is tracked cleanly
      expect(appState.totalLentOutstanding, greaterThanOrEqualTo(10000.0));
    });

    test('5. Financial Accounting Rule: Money borrowed and repayments do NOT count as income or expense', () {
      final appState = AppState();

      final initialIncome = appState.monthIncome;
      final initialExpense = appState.monthExpense;

      // Borrow money: 8,000
      final borrowed = LentBorrowedRecord(
        id: 'd_borrowed_acc',
        type: DebtType.borrowed,
        personName: 'Vikram',
        amount: 8000.0,
        date: now,
      );
      appState.addDebt(borrowed);

      // Month earned income must NOT be inflated by borrowed 8,000
      expect(appState.monthIncome, initialIncome);

      // Repay borrowed money
      appState.recordRepayment(debtId: 'd_borrowed_acc', amount: 8000.0);

      // Ordinary expense must NOT be inflated by the debt repayment
      expect(appState.monthExpense, initialExpense);
    });

    test('6. Net debt position: calculates difference between receivables and payables', () {
      final appState = AppState();

      // Clean state for calculation test
      final lent1 = LentBorrowedRecord(
        id: 'l1',
        type: DebtType.lent,
        personName: 'Friend A',
        amount: 5000.0,
        date: now,
      );
      final borrowed1 = LentBorrowedRecord(
        id: 'b1',
        type: DebtType.borrowed,
        personName: 'Friend B',
        amount: 2000.0,
        date: now,
      );

      appState.addDebt(lent1);
      appState.addDebt(borrowed1);

      // Net position should be positive (receivables > payables)
      expect(appState.netDebtPosition, greaterThanOrEqualTo(3000.0));
    });

    test('7. Repayment validation: rejects invalid amounts (> outstanding or <= 0)', () async {
      final appState = AppState();

      final record = LentBorrowedRecord(
        id: 'val_debt',
        type: DebtType.lent,
        personName: 'Suresh',
        amount: 1000.0,
        date: now,
      );
      await appState.addDebt(record);

      // Reject negative amount
      final negResult = await appState.recordRepayment(debtId: 'val_debt', amount: -50.0);
      expect(negResult, isFalse);

      // Reject 0 amount
      final zeroResult = await appState.recordRepayment(debtId: 'val_debt', amount: 0.0);
      expect(zeroResult, isFalse);

      // Reject amount exceeding outstanding balance (1000)
      final excessResult = await appState.recordRepayment(debtId: 'val_debt', amount: 1500.0);
      expect(excessResult, isFalse);

      // Accept valid partial repayment (400)
      final validResult = await appState.recordRepayment(debtId: 'val_debt', amount: 400.0);
      expect(validResult, isTrue);

      final updated = appState.debts.firstWhere((d) => d.id == 'val_debt');
      expect(updated.outstandingAmount, 600.0);
      expect(updated.repaidAmount, 400.0);
      expect(updated.status, DebtStatus.partiallyRepaid);
    });

    test('8. Funny Reminder Library: contains at least 30 unique templates', () {
      final templates = DebtReminderLibrary.templates;
      expect(templates.length, greaterThanOrEqualTo(30));

      final uniqueIds = <String>{};
      for (final tmpl in templates) {
        expect(uniqueIds.contains(tmpl.id), isFalse, reason: 'Duplicate reminder ID: ${tmpl.id}');
        uniqueIds.add(tmpl.id);
        expect(tmpl.text.trim().isNotEmpty, isTrue);
      }
    });

    test('9. Contextual reminders: correctly populates placeholders without raw braces', () {
      final record = LentBorrowedRecord(
        id: 'rem_test',
        type: DebtType.lent,
        personName: 'Anand',
        amount: 3500.0,
        date: now,
        dueDate: now.add(const Duration(days: 3)),
        repayments: [
          RepaymentRecord(
            id: 'r1',
            amount: 1000.0,
            date: now,
          ),
        ],
      );

      final reminders = DebtReminderLibrary.getRemindersForRecord(record);
      expect(reminders.isNotEmpty, isTrue);

      for (final rem in reminders) {
        expect(rem.contains('{name}'), isFalse);
        expect(rem.contains('{amount}'), isFalse);
        expect(rem.contains('{remaining}'), isFalse);
        expect(rem.contains('{repaid}'), isFalse);
        expect(rem.contains('{due_date}'), isFalse);
        expect(rem.contains('{days_overdue}'), isFalse);
        expect(rem.contains('Anand'), isTrue);
      }
    });

    test('10. Overdue reminders: includes overdue duration and playful amnesia jokes', () {
      final overdue = LentBorrowedRecord(
        id: 'overdue_test',
        type: DebtType.lent,
        personName: 'Kunal',
        amount: 4000.0,
        date: now.subtract(const Duration(days: 30)),
        dueDate: now.subtract(const Duration(days: 10)),
      );

      final reminders = DebtReminderLibrary.getRemindersForRecord(overdue);
      expect(reminders.isNotEmpty, isTrue);

      final randomRem = DebtReminderLibrary.getRandomReminder(overdue);
      expect(randomRem.contains('Kunal'), isTrue);
      expect(randomRem.toLowerCase().contains('overdue') ||
          randomRem.toLowerCase().contains('days') ||
          randomRem.toLowerCase().contains('remind') ||
          randomRem.toLowerCase().contains('artefact') ||
          randomRem.toLowerCase().contains('ghost'), isTrue);
    });

    test('11. Borrowed self-reminders: encourages user to be a good friend and repay', () {
      final borrowed = LentBorrowedRecord(
        id: 'self_rem_test',
        type: DebtType.borrowed,
        personName: 'Sneha',
        amount: 1200.0,
        date: now,
      );

      final reminders = DebtReminderLibrary.getRemindersForRecord(borrowed);
      expect(reminders.isNotEmpty, isTrue);

      for (final r in reminders) {
        expect(r.contains('Sneha'), isTrue);
      }
    });

    test('12. Full settlement celebration: generates debt cleared message', () {
      final settled = LentBorrowedRecord(
        id: 'settled_test',
        type: DebtType.lent,
        personName: 'Manish',
        amount: 2000.0,
        date: now,
        repayments: [
          RepaymentRecord(
            id: 'rep_full',
            amount: 2000.0,
            date: now,
          ),
        ],
      );

      expect(settled.isFullySettled, isTrue);
      final reminders = DebtReminderLibrary.getRemindersForRecord(settled);
      expect(reminders.isNotEmpty, isTrue);

      final msg = reminders.first;
      expect(msg.contains('Manish'), isTrue);
      expect(msg.toLowerCase().contains('cleared') ||
          msg.toLowerCase().contains('received') ||
          msg.toLowerCase().contains('restored') ||
          msg.toLowerCase().contains('zeroed'), isTrue);
    });

    testWidgets('13. Redesigned UI: Header, Summary Cards, Tabs and Chips render correctly', (tester) async {
      final appState = AppState();
      final now = DateTime.now();

      final recordLent = LentBorrowedRecord(
        id: 'widget_lent_1',
        type: DebtType.lent,
        personName: 'Rahul Sharma',
        amount: 2500.0,
        date: now,
        dueDate: now.add(const Duration(days: 7)),
        note: 'Dinner & Cab share',
      );

      final recordBorrowed = LentBorrowedRecord(
        id: 'widget_borrowed_1',
        type: DebtType.borrowed,
        personName: 'Priya Patel',
        amount: 1200.0,
        date: now,
        dueDate: now.add(const Duration(days: 14)),
      );

      appState.setDebtsForTesting([recordLent, recordBorrowed]);

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: LentBorrowedScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header checks
      expect(find.text('Lent & Borrowed'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsWidgets); // App bar plus & FAB

      // Summary cards
      expect(find.text('To Collect'), findsOneWidget);
      expect(find.text('To Repay'), findsOneWidget);
      expect(find.text('₹2500'), findsWidgets);
      expect(find.text('₹1200'), findsWidgets);

      // Tabs
      expect(find.text('Money Lent'), findsOneWidget);
      expect(find.text('Borrowed'), findsOneWidget);
      expect(find.text('Settled'), findsOneWidget);

      // Filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Partially Repaid'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('14. Redesigned UI: Record Card, Reminder Box, Actions and Details Modal', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appState = AppState();
      final now = DateTime.now();

      final recordLent = LentBorrowedRecord(
        id: 'card_test_1',
        type: DebtType.lent,
        personName: 'Amit Verma',
        amount: 3500.0,
        date: now,
        dueDate: now.add(const Duration(days: 5)),
        note: 'Concert tickets',
      );

      appState.setDebtsForTesting([recordLent]);

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: LentBorrowedScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Card attributes
      expect(find.text('Amit Verma'), findsOneWidget);
      expect(find.text('A'), findsOneWidget); // Initial avatar
      expect(find.text('₹3500'), findsWidgets); // Card amount & summary
      expect(find.text('Pending'), findsWidgets); // Badge & Filter chip

      // Embedded reminder box elements
      expect(find.text('Another joke'), findsOneWidget);
      expect(find.text('Copy reminder'), findsOneWidget);

      // Action buttons on card
      expect(find.text('Record Repayment'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // Ensure visible and tap 3-dot overflow menu
      await tester.ensureVisible(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap View Details to open loan details modal sheet
      await tester.tap(find.text('View Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Loan Details'), findsOneWidget);
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Outstanding'), findsOneWidget);
      expect(find.text('Concert tickets'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Loan Details'), findsNothing);
    });

    test('15. Money Lent: immediately subtracts amount from Main Balance, adds "Money Lent" transaction, increases Money to Collect', () async {
      final appState = AppState();
      await appState.addTransaction(Transaction(
        id: 'tx_init_15',
        title: 'Salary',
        amount: 50000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.green,
        date: now,
      ));
      expect(appState.balance, 50000.0);
      expect(appState.availableBalance, 50000.0);
      expect(appState.totalLentOutstanding, 0.0);

      // Lend ₹10,000 to Friend
      await appState.addDebt(LentBorrowedRecord(
        id: 'debt_lent_15',
        type: DebtType.lent,
        personName: 'Rohan',
        amount: 10000.0,
        date: now,
        note: 'Weekend trip share',
      ));

      // Main Balance reduced immediately
      expect(appState.balance, 40000.0);
      expect(appState.availableBalance, 40000.0);
      // Money to Collect increased
      expect(appState.totalLentOutstanding, 10000.0);
      // Not counted as ordinary expense
      expect(appState.monthExpense, 0.0);
      expect(appState.todaySpending, 0.0);

      // Transaction history entry exists
      final lentTx = appState.transactions.firstWhere((t) => t.id == 'tx_debt_debt_lent_15');
      expect(lentTx.title, 'Money Lent');
      expect(lentTx.type, TransactionType.lent);
      expect(lentTx.amount, 10000.0);
      expect(lentTx.personName, 'Rohan');
      expect(lentTx.displaySignedAmount, '-₹10000');
    });

    test('16. Money Borrowed: immediately adds amount to Main Balance, adds "Money Borrowed" transaction, increases Money to Repay', () async {
      final appState = AppState();
      await appState.addTransaction(Transaction(
        id: 'tx_init_16',
        title: 'Salary',
        amount: 20000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.green,
        date: now,
      ));
      expect(appState.balance, 20000.0);

      // Borrow ₹15,000 from Vikram
      await appState.addDebt(LentBorrowedRecord(
        id: 'debt_borrow_16',
        type: DebtType.borrowed,
        personName: 'Vikram',
        amount: 15000.0,
        date: now,
        note: 'Emergency loan',
      ));

      // Main Balance increased immediately
      expect(appState.balance, 35000.0);
      expect(appState.availableBalance, 35000.0);
      // Money to Repay increased
      expect(appState.totalBorrowedOutstanding, 15000.0);
      // Not counted as ordinary income
      expect(appState.monthIncome, 20000.0);

      // Transaction history entry exists
      final borrowTx = appState.transactions.firstWhere((t) => t.id == 'tx_debt_debt_borrow_16');
      expect(borrowTx.title, 'Money Borrowed');
      expect(borrowTx.type, TransactionType.borrowed);
      expect(borrowTx.amount, 15000.0);
      expect(borrowTx.personName, 'Vikram');
      expect(borrowTx.displaySignedAmount, '+₹15000');
    });

    test('17. Repayment Received on money lent: increases Main Balance, reduces Money to Collect, adds Repayment Received transaction', () async {
      final appState = AppState();
      await appState.addTransaction(Transaction(
        id: 'tx_init_17',
        title: 'Salary',
        amount: 30000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.green,
        date: now,
      ));

      await appState.addDebt(LentBorrowedRecord(
        id: 'debt_lent_17',
        type: DebtType.lent,
        personName: 'Pooja',
        amount: 8000.0,
        date: now,
      ));
      expect(appState.balance, 22000.0);
      expect(appState.totalLentOutstanding, 8000.0);

      // Partial repayment of 3,000 received
      final repSuccess = await appState.recordRepayment(
        debtId: 'debt_lent_17',
        amount: 3000.0,
        note: 'GPay payment',
      );
      expect(repSuccess, isTrue);

      // Balance increases by 3,000; Money to Collect reduces by 3,000
      expect(appState.balance, 25000.0);
      expect(appState.totalLentOutstanding, 5000.0);
      // Does not count as ordinary income
      expect(appState.monthIncome, 30000.0);

      // Transaction history entry exists
      final repTx = appState.transactions.firstWhere((t) => t.type == TransactionType.repaymentReceived);
      expect(repTx.title, 'Repayment Received');
      expect(repTx.amount, 3000.0);
      expect(repTx.personName, 'Pooja');
      expect(repTx.displaySignedAmount, '+₹3000');
    });

    test('18. Repayment Made on money borrowed: decreases Main Balance, reduces Money to Repay, adds Repayment Made transaction', () async {
      final appState = AppState();
      await appState.addTransaction(Transaction(
        id: 'tx_init_18',
        title: 'Salary',
        amount: 10000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.green,
        date: now,
      ));

      await appState.addDebt(LentBorrowedRecord(
        id: 'debt_borrow_18',
        type: DebtType.borrowed,
        personName: 'Samir',
        amount: 5000.0,
        date: now,
      ));
      expect(appState.balance, 15000.0);
      expect(appState.totalBorrowedOutstanding, 5000.0);

      // Repayment made of 2,000
      final repSuccess = await appState.recordRepayment(
        debtId: 'debt_borrow_18',
        amount: 2000.0,
        note: 'Cash return',
      );
      expect(repSuccess, isTrue);

      // Balance decreases by 2,000; Money to Repay reduces by 2,000
      expect(appState.balance, 13000.0);
      expect(appState.totalBorrowedOutstanding, 3000.0);
      // Does not count as ordinary expense
      expect(appState.monthExpense, 0.0);

      // Transaction history entry exists
      final repTx = appState.transactions.firstWhere((t) => t.type == TransactionType.repaymentMade);
      expect(repTx.title, 'Repayment Made');
      expect(repTx.amount, 2000.0);
      expect(repTx.personName, 'Samir');
      expect(repTx.displaySignedAmount, '-₹2000');
    });

    test('19. Editing and deleting debts & repayments: reverses and recalculates balance deterministically without duplicates', () async {
      final appState = AppState();
      await appState.addTransaction(Transaction(
        id: 'tx_init_19',
        title: 'Initial',
        amount: 10000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.green,
        date: now,
      ));
      expect(appState.balance, 10000.0);

      // Lend ₹4,000
      await appState.addDebt(LentBorrowedRecord(
        id: 'debt_19',
        type: DebtType.lent,
        personName: 'Kunal',
        amount: 4000.0,
        date: now,
      ));
      expect(appState.balance, 6000.0);

      // Edit debt amount from 4,000 to 5,000
      await appState.updateDebt(LentBorrowedRecord(
        id: 'debt_19',
        type: DebtType.lent,
        personName: 'Kunal',
        amount: 5000.0,
        date: now,
      ));
      expect(appState.balance, 5000.0);
      expect(appState.totalLentOutstanding, 5000.0);

      // Record repayment of 1,500
      await appState.recordRepayment(debtId: 'debt_19', amount: 1500.0);
      expect(appState.balance, 6500.0);
      expect(appState.totalLentOutstanding, 3500.0);

      // Delete the repayment installment
      final repId = appState.debts.first.repayments.first.id;
      final delRepSuccess = await appState.deleteRepayment(debtId: 'debt_19', repaymentId: repId);
      expect(delRepSuccess, isTrue);
      // Balance restored back to 5000.0
      expect(appState.balance, 5000.0);
      expect(appState.totalLentOutstanding, 5000.0);

      // Delete the entire debt
      await appState.deleteDebt('debt_19');
      // Balance restored completely back to initial 10,000.0
      expect(appState.balance, 10000.0);
      expect(appState.totalLentOutstanding, 0.0);
      expect(appState.debts, isEmpty);
      expect(appState.transactions.where((t) => t.debtId == 'debt_19'), isEmpty);
    });

    test('20. Deleting a debt transaction from Transactions Screen reverses balance and removes debt', () async {
      final appState = AppState();
      await appState.addTransaction(Transaction(
        id: 'tx_init_20',
        title: 'Initial',
        amount: 20000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.green,
        date: now,
      ));

      await appState.addDebt(LentBorrowedRecord(
        id: 'debt_20',
        type: DebtType.borrowed,
        personName: 'Dev',
        amount: 7000.0,
        date: now,
      ));
      expect(appState.balance, 27000.0);

      // User deletes the "Money Borrowed" transaction directly
      await appState.deleteTransaction('tx_debt_debt_20');

      // Balance decreases by 7,000 back to 20,000
      expect(appState.balance, 20000.0);
      expect(appState.totalBorrowedOutstanding, 0.0);
      expect(appState.debts, isEmpty);
    });
  });
}
