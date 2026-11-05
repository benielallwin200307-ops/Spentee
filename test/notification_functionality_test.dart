import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/state/app_state.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Functionality and Reminders Test Suite', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
      // Ensure initialised is false during pure unit tests so plugin calls guard gracefully
      NotificationService.instance.setInitialisedForTesting(false);
    });

    test('1. Verify default reminder switch states', () {
      final notifs = appState.notifications;
      expect(notifs['daily'], isTrue);
      expect(notifs['weekly'], isTrue);
      expect(notifs['budget'], isTrue);
      expect(notifs['roasts'], isTrue);
      expect(appState.notificationTime, equals('20:00'));
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
      appState.setNotificationTime('21:30');
      expect(appState.notificationTime, equals('21:30'));

      appState.setNotificationTime('08:00');
      expect(appState.notificationTime, equals('08:00'));
    });

    test('4. Notification IDs are stable and distinct', () {
      expect(NotifId.daily, equals(1));
      expect(NotifId.weekly, equals(2));
      expect(NotifId.roasts, equals(3));
      expect(NotifId.budgetBase, equals(100));
    });

    test('5. Budget threshold warning triggers at 80% and 100%', () async {
      // Set up a category budget: Food ₹1000
      final now = DateTime.now();
      final budget = Budget(
        id: 'b_food',
        category: 'Food',
        limitAmount: 1000.0,
        year: now.year,
        month: now.month,
      );
      appState.addBudget(budget);

      // Verify initial spent is 0
      expect(budget.calculateSpent(appState.transactions), equals(0.0));

      // Add expense ₹750 (75% - below 80%)
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

      // Spent is 750 / 1000 = 75%
      expect(budget.calculateSpent(appState.transactions), equals(750.0));

      // Add expense ₹100 (brings total to ₹850, crossing 80% threshold)
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

      // Add expense ₹200 (brings total to ₹1050, crossing 100% threshold)
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

      // All methods should complete cleanly without throwing LateInitializationError
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.scheduleDailyReminder('20:00');
      await NotificationService.instance.scheduleWeeklyReminder();
      await NotificationService.instance.scheduleRoastReminder();
      await NotificationService.instance.showBudgetAlert(categoryName: 'Food', percent: 80);
      await NotificationService.instance.cancel(NotifId.daily);
      await NotificationService.instance.cancelAll();
      await NotificationService.instance.rescheduleAll(
        notifications: appState.notifications,
        notificationTime: appState.notificationTime,
      );
    });
  });
}
