import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/lent_borrowed_record.dart';
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
  });
}
