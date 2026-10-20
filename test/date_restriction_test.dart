import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/lent_borrowed_record.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/state/app_state.dart';
import 'package:spentee/utils/date_restriction.dart';

void main() {
  group('DateRestriction Unit and Integration Tests', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final nextYear = DateTime(now.year + 1, now.month, now.day);
    final pastYear = DateTime(2023, 5, 15);

    test('1. Today is recognized as valid (today or past)', () {
      expect(DateRestriction.isTodayOrPast(today), isTrue);
      expect(DateRestriction.isTodayOrPast(now), isTrue);
      expect(DateRestriction.isFuture(today), isFalse);
      expect(DateRestriction.isFuture(now), isFalse);
    });

    test('2. Yesterday and historical dates are valid', () {
      expect(DateRestriction.isTodayOrPast(yesterday), isTrue);
      expect(DateRestriction.isTodayOrPast(pastYear), isTrue);
      expect(DateRestriction.isTodayOrPast(DateTime(2020, 1, 1)), isTrue);
      expect(DateRestriction.isFuture(yesterday), isFalse);
      expect(DateRestriction.isFuture(pastYear), isFalse);
    });

    test('3. Tomorrow and upcoming future dates are strictly rejected', () {
      expect(DateRestriction.isTodayOrPast(tomorrow), isFalse);
      expect(DateRestriction.isFuture(tomorrow), isTrue);

      expect(DateRestriction.isTodayOrPast(nextMonth), isFalse);
      expect(DateRestriction.isFuture(nextMonth), isTrue);

      expect(DateRestriction.isTodayOrPast(nextYear), isFalse);
      expect(DateRestriction.isFuture(nextYear), isTrue);
    });

    test('4. Future month detection and clamping logic', () {
      expect(DateRestriction.isMonthInFuture(now.year, now.month), isFalse);
      expect(DateRestriction.isMonthInFuture(now.year, now.month + 1), isTrue);
      expect(DateRestriction.isMonthInFuture(now.year + 1, 1), isTrue);
      expect(DateRestriction.isMonthInFuture(now.year - 1, 12), isFalse);

      final clamped = DateRestriction.clampToCurrentMonth(nextMonth);
      expect(clamped.year, now.year);
      expect(clamped.month, now.month);
      expect(clamped.day, 1);

      final pastMonth = DateTime(now.year, now.month - 1, 1);
      final clampedPast = DateRestriction.clampToCurrentMonth(pastMonth);
      expect(clampedPast.month, pastMonth.month);
    });

    test('5. AppState rejects transactions with future dates', () async {
      final appState = AppState();
      final initialCount = appState.transactions.length;
      final initialBalance = appState.balance;

      // Attempt adding a transaction with tomorrow's date
      final futureTx = Transaction(
        id: 'tx_future_test',
        title: 'Future Lunch',
        amount: 250.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.orange,
        date: tomorrow,
      );

      await appState.addTransaction(futureTx);

      // Verify transaction was REJECTED
      expect(appState.transactions.length, initialCount);
      expect(appState.balance, initialBalance);
      expect(appState.transactions.any((t) => t.id == 'tx_future_test'), isFalse);

      // Adding valid today transaction succeeds
      final todayTx = Transaction(
        id: 'tx_today_test',
        title: 'Today Lunch',
        amount: 150.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.orange,
        date: today,
      );

      await appState.addTransaction(todayTx);
      expect(appState.transactions.length, initialCount + 1);
      expect(appState.transactions.first.id, 'tx_today_test');
    });

    test('6. AppState rejects debt records with future transaction dates', () async {
      final appState = AppState();
      final futureDebt = LentBorrowedRecord(
        id: 'debt_future_test',
        type: DebtType.lent,
        personName: 'Future Friend',
        amount: 1000.0,
        date: tomorrow,
      );

      await appState.addDebt(futureDebt);
      expect(appState.debts.any((d) => d.id == 'debt_future_test'), isFalse);

      // Valid record succeeds
      final validDebt = LentBorrowedRecord(
        id: 'debt_valid_test',
        type: DebtType.lent,
        personName: 'Valid Friend',
        amount: 1000.0,
        date: yesterday,
      );

      await appState.addDebt(validDebt);
      expect(appState.debts.any((d) => d.id == 'debt_valid_test'), isTrue);

      // Updating with future date is rejected
      final updatedFuture = validDebt.copyWith(date: tomorrow);
      await appState.updateDebt(updatedFuture);
      final retrieved = appState.debts.firstWhere((d) => d.id == 'debt_valid_test');
      expect(retrieved.date, yesterday);
    });

    test('7. AppState rejects repayments with future payment dates', () async {
      final appState = AppState();
      final debt = LentBorrowedRecord(
        id: 'debt_repay_test',
        type: DebtType.lent,
        personName: 'Repay Friend',
        amount: 2000.0,
        date: yesterday,
      );
      await appState.addDebt(debt);

      // Attempt repayment in the future
      final futureRepayResult = await appState.recordRepayment(
        debtId: debt.id,
        amount: 500.0,
        date: tomorrow,
      );
      expect(futureRepayResult, isFalse);
      final check1 = appState.debts.firstWhere((d) => d.id == debt.id);
      expect(check1.repaidAmount, 0.0);

      // Repayment with today date succeeds
      final todayRepayResult = await appState.recordRepayment(
        debtId: debt.id,
        amount: 500.0,
        date: today,
      );
      expect(todayRepayResult, isTrue);
      final check2 = appState.debts.firstWhere((d) => d.id == debt.id);
      expect(check2.repaidAmount, 500.0);
    });

    testWidgets('8. showRestrictedDatePicker limits lastDate to device local today',
        (tester) async {
      DateTime? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedResult = await DateRestriction.showRestrictedDatePicker(
                    context,
                    initialDate: today,
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Open picker
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Find DatePickerDialog / CalendarDatePicker
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Check the state of CalendarDatePicker
      final datePickerFinder = find.byType(CalendarDatePicker);
      expect(datePickerFinder, findsOneWidget);
      final calendarDatePicker = tester.widget<CalendarDatePicker>(datePickerFinder);

      // Verify that lastDate is today
      expect(calendarDatePicker.lastDate.year, today.year);
      expect(calendarDatePicker.lastDate.month, today.month);
      expect(calendarDatePicker.lastDate.day, today.day);

      // Verify that selectableDayPredicate rejects tomorrow
      expect(calendarDatePicker.selectableDayPredicate!(tomorrow), isFalse);
      // Verify that selectableDayPredicate accepts today & yesterday
      expect(calendarDatePicker.selectableDayPredicate!(today), isTrue);
      expect(calendarDatePicker.selectableDayPredicate!(yesterday), isTrue);

      // Tap OK button to close
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNotNull);
      expect(DateRestriction.isTodayOrPast(selectedResult!), isTrue);
    });
  });
}
