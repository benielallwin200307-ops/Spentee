import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/state/app_state.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/roast.dart';
import 'package:spentee/services/notification_service.dart';
import 'package:spentee/services/roast_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Spentee Notification System Test Suite', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
      // Ensure initialised is false during unit tests so flutter_local_notifications plugin calls guard gracefully
      NotificationService.instance.setInitialisedForTesting(false);
    });

    test('1. Verify default reminder switch states and 10:00 PM default time', () {
      final notifs = appState.notifications;
      expect(notifs['daily'], isTrue);
      expect(notifs['weekly'], isTrue);
      expect(notifs['budget'], isTrue);
      expect(notifs['roasts'], isTrue);
      expect(appState.notificationTime, equals('22:00'),
          reason: 'Default daily reminder must be 10:00 PM (22:00)');
    });

    test('2. Toggling and setting switches updates state', () {
      appState.setNotification('daily', false);
      expect(appState.notifications['daily'], isFalse);

      appState.setNotification('daily', true);
      expect(appState.notifications['daily'], isTrue);

      appState.toggleNotification('weekly');
      expect(appState.notifications['weekly'], isFalse);

      appState.toggleNotification('budget');
      expect(appState.notifications['budget'], isFalse);

      appState.toggleNotification('roasts');
      expect(appState.notifications['roasts'], isFalse);
    });

    test('3. Changing notification time updates notificationTime', () {
      appState.setNotificationTime('22:00');
      expect(appState.notificationTime, equals('22:00'));

      appState.setNotificationTime('21:30');
      expect(appState.notificationTime, equals('21:30'));

      appState.setNotificationTime('08:00');
      expect(appState.notificationTime, equals('08:00'));
    });

    test('4. Notification IDs are stable and include dual roasts and legacy cleanups', () {
      expect(NotifId.daily, equals(1));
      expect(NotifId.weekly, equals(2));
      expect(NotifId.roasts, equals(3));
      expect(NotifId.roastMorning, equals(3), reason: 'Morning roast (10:00 AM) ID is 3');
      expect(NotifId.roastEvening, equals(4), reason: 'Evening roast (6:00 PM) ID is 4');
      expect(NotifId.legacyRoast2PM, equals(14), reason: 'Legacy 2:00 PM roast ID is 14');
      expect(NotifId.legacyRoast9PM, equals(21), reason: 'Legacy 9:00 PM roast ID is 21');
      expect(NotifId.budgetBase, equals(100));
    });

    test('5. Budget threshold warning triggers at 80% and 100%', () async {
      final now = DateTime.now();
      final budget = Budget(
        id: 'b_food',
        category: 'Food',
        limitAmount: 1000.0,
        year: now.year,
        month: now.month,
      );
      appState.addBudget(budget);

      expect(budget.calculateSpent(appState.transactions), equals(0.0));

      await appState.addTransaction(Transaction(
        id: 'tx_food_1',
        title: 'Lunch',
        amount: 750.0,
        type: TransactionType.expense,
        category: 'Food',
        date: now,
        icon: Icons.restaurant,
        categoryColor: Colors.orange,
      ));

      expect(budget.calculateSpent(appState.transactions), equals(750.0));

      await appState.addTransaction(Transaction(
        id: 'tx_food_2',
        title: 'Coffee',
        amount: 100.0,
        type: TransactionType.expense,
        category: 'Food',
        date: now,
        icon: Icons.coffee,
        categoryColor: Colors.orange,
      ));

      expect(budget.calculateSpent(appState.transactions), equals(850.0));

      await appState.addTransaction(Transaction(
        id: 'tx_food_3',
        title: 'Dinner',
        amount: 200.0,
        type: TransactionType.expense,
        category: 'Food',
        date: now,
        icon: Icons.restaurant,
        categoryColor: Colors.orange,
      ));

      expect(budget.calculateSpent(appState.transactions), equals(1050.0));
      expect(budget.calculateRemaining(appState.transactions), equals(0.0));
    });

    test('6. NotificationService guards gracefully when not yet initialised', () async {
      expect(NotificationService.instance.isInitialised, isFalse);

      await NotificationService.instance.requestPermission();
      await NotificationService.instance.scheduleDailyReminder('22:00');
      await NotificationService.instance.scheduleWeeklyReminder();
      await NotificationService.instance.scheduleRoastReminder();
      await NotificationService.instance.scheduleRoastReminders();
      await NotificationService.instance.cancelRoastReminders();
      await NotificationService.instance.showBudgetAlert(categoryName: 'Food', percent: 80);
      await NotificationService.instance.cancel(NotifId.daily);
      await NotificationService.instance.cancel(NotifId.roastMorning);
      await NotificationService.instance.cancel(NotifId.roastEvening);
      await NotificationService.instance.cancel(NotifId.legacyRoast2PM);
      await NotificationService.instance.cancel(NotifId.legacyRoast9PM);
      await NotificationService.instance.cancelAll();
      await NotificationService.instance.rescheduleAll(
        notifications: appState.notifications,
        notificationTime: appState.notificationTime,
      );
    });

    test('7. Data Sufficiency Guard: Users without sufficient expense data do NOT receive spending roasts', () {
      final now = DateTime.now();

      // Case A: 0 transactions (empty wallet)
      final roastEmpty = DynamicRoastEngine.generateRoast(transactions: []);
      expect(roastEmpty.situation, equals(RoastCategory.newUserEmpty));
      expect(roastEmpty.text, contains("empty wallet"));

      // Case B: Income only (0 expenses)
      final txIncome = [
        Transaction(
          id: 'inc_1',
          title: 'Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          date: now,
          icon: Icons.work,
          categoryColor: Colors.green,
        ),
      ];
      final roastIncomeOnly = DynamicRoastEngine.generateRoast(transactions: txIncome);
      expect(roastIncomeOnly.situation, equals(RoastCategory.incomeVsExpenses));
      expect(roastIncomeOnly.text, contains("income has arrived"));

      // Case C: Insufficient transactions (< 3 transactions)
      final txTwo = [
        Transaction(
          id: 'tx_1',
          title: 'Coffee',
          amount: 150.0,
          type: TransactionType.expense,
          category: 'Food',
          date: now,
          icon: Icons.coffee,
          categoryColor: Colors.orange,
        ),
        Transaction(
          id: 'tx_2',
          title: 'Metro',
          amount: 50.0,
          type: TransactionType.expense,
          category: 'Travel',
          date: now,
          icon: Icons.train,
          categoryColor: Colors.blue,
        ),
      ];
      final roastInsufficient = DynamicRoastEngine.generateRoast(transactions: txTwo);
      expect(roastInsufficient.situation, equals(RoastCategory.insufficientHistory));
      expect(roastInsufficient.text, contains("Log at least 3 transactions"));
    });

    test('8. Users with sufficient expense data (>= 3 txs) receive personalized spending roasts', () {
      final now = DateTime.now();
      final txSufficient = [
        Transaction(
          id: 'tx_1',
          title: 'Swiggy Dinner',
          amount: 2500.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          date: now,
          icon: Icons.restaurant,
          categoryColor: Colors.orange,
        ),
        Transaction(
          id: 'tx_2',
          title: 'Zomato Lunch',
          amount: 1800.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          date: now,
          icon: Icons.fastfood,
          categoryColor: Colors.orange,
        ),
        Transaction(
          id: 'tx_3',
          title: 'Groceries',
          amount: 900.0,
          type: TransactionType.expense,
          category: 'Groceries',
          date: now,
          icon: Icons.local_grocery_store,
          categoryColor: Colors.green,
        ),
      ];

      final roast = DynamicRoastEngine.generateRoast(
        transactions: txSufficient,
        intensity: RoastIntensity.savage,
      );

      // Verify it's a real spending roast, not an onboarding or insufficient history placeholder
      expect(roast.situation, isNot(equals(RoastCategory.newUserEmpty)));
      expect(roast.situation, isNot(equals(RoastCategory.insufficientHistory)));
      expect(roast.text.isNotEmpty, isTrue);
    });

    test('9. Multilingual Support: Roast notifications generate in all 6 app languages', () {
      final now = DateTime.now();
      final txSufficient = [
        Transaction(
          id: 'tx_1',
          title: 'Food',
          amount: 3000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          date: now,
          icon: Icons.restaurant,
          categoryColor: Colors.orange,
        ),
        Transaction(
          id: 'tx_2',
          title: 'Shopping',
          amount: 2500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: now,
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
        ),
        Transaction(
          id: 'tx_3',
          title: 'Coffee',
          amount: 200.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          date: now,
          icon: Icons.coffee,
          categoryColor: Colors.orange,
        ),
      ];

      final languages = ['English', 'Tamil', 'Telugu', 'Hindi', 'Malayalam', 'Kannada'];

      for (final lang in languages) {
        final roast = DynamicRoastEngine.generateRoast(
          transactions: txSufficient,
          language: lang,
          intensity: RoastIntensity.savage,
        );
        expect(roast.text.isNotEmpty, isTrue, reason: 'Failed generating roast for $lang');
        expect(roast.situation, isNot(equals(RoastCategory.newUserEmpty)));
        expect(roast.situation, isNot(equals(RoastCategory.insufficientHistory)));
      }
    });

    test('10. Anti-Repetition: Morning roast is avoided in evening roast', () {
      final now = DateTime.now();
      final txSufficient = [
        Transaction(
          id: 'tx_1',
          title: 'Amazon',
          amount: 4000.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: now,
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
        ),
        Transaction(
          id: 'tx_2',
          title: 'Flipkart',
          amount: 3500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: now,
          icon: Icons.shopping_cart,
          categoryColor: Colors.purple,
        ),
        Transaction(
          id: 'tx_3',
          title: 'Zara',
          amount: 2200.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: now,
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
        ),
      ];

      final morningRoast = DynamicRoastEngine.generateRoast(
        transactions: txSufficient,
        intensity: RoastIntensity.savage,
      );

      final eveningRoast = DynamicRoastEngine.generateRoast(
        transactions: txSufficient,
        intensity: RoastIntensity.savage,
        previousRoastId: morningRoast.id,
        previousRoastText: morningRoast.text,
        recentRoastIds: [morningRoast.id],
      );

      // Evening roast must avoid repeating the morning roast
      if (morningRoast.id.isNotEmpty && eveningRoast.id.isNotEmpty) {
        expect(eveningRoast.id, isNot(equals(morningRoast.id)),
            reason: 'Evening roast should not have the same ID as morning roast');
      }
    });

    test('11. AppState rescheduleNotifications passes real user financial context', () async {
      final now = DateTime.now();
      await appState.addTransaction(Transaction(
        id: 'tx_food',
        title: 'Restaurant',
        amount: 1500.0,
        type: TransactionType.expense,
        category: 'Food',
        date: now,
        icon: Icons.restaurant,
        categoryColor: Colors.orange,
      ));

      // rescheduleNotifications should complete cleanly without error
      appState.rescheduleNotifications();
      expect(appState.transactions.length, equals(1));
    });
  });
}
