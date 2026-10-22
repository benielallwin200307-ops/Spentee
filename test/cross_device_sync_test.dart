import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/savings_goal.dart';
import 'package:spentee/models/lent_borrowed_record.dart';
import 'package:spentee/models/category_model.dart';
import 'package:spentee/services/sync_service.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Device Data Synchronization Model Serialization Tests', () {
    test('1. Transaction serialization includes updatedAt and isDeleted', () {
      final now = DateTime(2026, 10, 22, 12, 0, 0);
      final tx = Transaction(
        id: 'tx_sync_1',
        title: 'Grocery Run',
        amount: 450.0,
        type: TransactionType.expense,
        category: 'Groceries',
        icon: Icons.shopping_basket_rounded,
        categoryColor: Colors.green,
        date: now,
        updatedAt: now,
        isDeleted: false,
      );

      final json = tx.toJson();
      expect(json['id'], 'tx_sync_1');
      expect(json['updatedAt'], now.toIso8601String());
      expect(json['isDeleted'], isFalse);

      final restored = Transaction.fromJson(json);
      expect(restored.id, tx.id);
      expect(restored.title, tx.title);
      expect(restored.amount, tx.amount);
      expect(restored.updatedAt.toIso8601String(), now.toIso8601String());
      expect(restored.isDeleted, isFalse);
    });

    test('2. Budget serialization includes updatedAt and isDeleted', () {
      final now = DateTime(2026, 10, 22, 12, 0, 0);
      final budget = Budget(
        id: 'b_sync_1',
        category: 'Food & Dining',
        limitAmount: 5000.0,
        year: 2026,
        month: 10,
        updatedAt: now,
        isDeleted: false,
      );

      final json = budget.toJson();
      expect(json['id'], 'b_sync_1');
      expect(json['updatedAt'], now.toIso8601String());
      expect(json['isDeleted'], isFalse);

      final restored = Budget.fromJson(json);
      expect(restored.id, budget.id);
      expect(restored.category, 'Food & Dining');
      expect(restored.limitAmount, 5000.0);
      expect(restored.updatedAt.toIso8601String(), now.toIso8601String());
      expect(restored.isDeleted, isFalse);
    });

    test('3. SavingsGoal serialization includes updatedAt and isDeleted', () {
      final now = DateTime(2026, 10, 22, 12, 0, 0);
      final goal = SavingsGoal(
        id: 'sg_sync_1',
        title: 'MacBook M4 Pro',
        targetAmount: 200000.0,
        currentAmount: 50000.0,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      final json = goal.toJson();
      expect(json['id'], 'sg_sync_1');
      expect(json['updatedAt'], now.toIso8601String());
      expect(json['isDeleted'], isFalse);

      final restored = SavingsGoal.fromJson(json);
      expect(restored.id, goal.id);
      expect(restored.title, 'MacBook M4 Pro');
      expect(restored.targetAmount, 200000.0);
      expect(restored.updatedAt.toIso8601String(), now.toIso8601String());
    });

    test('4. LentBorrowedRecord serialization includes updatedAt, isDeleted, repayments', () {
      final now = DateTime(2026, 10, 22, 12, 0, 0);
      final debt = LentBorrowedRecord(
        id: 'debt_sync_1',
        type: DebtType.lent,
        personName: 'Alex',
        amount: 3000.0,
        date: now,
        repayments: [
          RepaymentRecord(
            id: 'rep_1',
            amount: 1000.0,
            date: now,
            note: 'UPI payment',
          ),
        ],
        updatedAt: now,
        isDeleted: false,
      );

      final json = debt.toJson();
      expect(json['id'], 'debt_sync_1');
      expect(json['type'], 'lent');
      expect(json['updatedAt'], now.toIso8601String());
      expect(json['isDeleted'], isFalse);
      expect((json['repayments'] as List).length, 1);

      final restored = LentBorrowedRecord.fromJson(json);
      expect(restored.id, debt.id);
      expect(restored.personName, 'Alex');
      expect(restored.repayments.length, 1);
      expect(restored.repayments.first.amount, 1000.0);
      expect(restored.outstandingAmount, 2000.0);
    });

    test('5. CategoryItem serialization includes updatedAt', () {
      final now = DateTime(2026, 10, 22, 12, 0, 0);
      final cat = CategoryItem(
        id: 'cat_custom_1',
        name: 'Subscriptions',
        isExpense: true,
        isCustom: true,
        icon: Icons.subscriptions_rounded,
        color: Colors.purple,
        updatedAt: now,
      );

      final json = cat.toJson();
      expect(json['id'], 'cat_custom_1');
      expect(json['isCustom'], isTrue);
      expect(json['updatedAt'], now.toIso8601String());

      final restored = CategoryItem.fromJson(json);
      expect(restored.id, cat.id);
      expect(restored.name, 'Subscriptions');
      expect(restored.isCustom, isTrue);
    });
  });

  group('AppState Cross-Device Resilient Union-Merge Tests', () {
    test('6. Remote transactions seamlessly merge with local transactions without data loss', () async {
      final appState = AppState();
      appState.initSyncForTesting('user_sync_test');
      final sync = SyncService.instance;

      // Add a local transaction (Device A)
      final localTx = Transaction(
        id: 'tx_local_1',
        title: 'Local Coffee',
        amount: 150.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.coffee,
        categoryColor: Colors.brown,
        date: DateTime(2026, 10, 20, 10, 0),
        updatedAt: DateTime(2026, 10, 20, 10, 0),
      );
      await appState.addTransaction(localTx);
      expect(appState.transactions.length, 1);

      // Simulate remote listener receiving a transaction added from Device B
      final remoteTx = Transaction(
        id: 'tx_device_b_1',
        title: 'Device B Lunch',
        amount: 350.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.restaurant,
        categoryColor: Colors.orange,
        date: DateTime(2026, 10, 21, 13, 0),
        updatedAt: DateTime(2026, 10, 21, 13, 0),
      );

      sync.onTransactionsChanged?.call([remoteTx]);

      // Both transactions must now exist! Union merge preserves local pending writes
      expect(appState.transactions.length, 2);
      expect(appState.transactions.any((t) => t.id == 'tx_local_1'), isTrue);
      expect(appState.transactions.any((t) => t.id == 'tx_device_b_1'), isTrue);
      // Balance correctly updated for both expenses: -150 - 350 = -500
      expect(appState.balance, -500.0);
    });

    test('7. Conflict resolution: newer remote transaction updates older local version', () async {
      final appState = AppState();
      appState.initSyncForTesting('user_sync_test');
      final sync = SyncService.instance;

      // Local initial version
      final localTx = Transaction(
        id: 'tx_shared_1',
        title: 'Dinner at Bistro',
        amount: 800.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.restaurant,
        categoryColor: Colors.orange,
        date: DateTime.now().subtract(const Duration(hours: 2)),
      );
      await appState.addTransaction(localTx);
      expect(appState.transactions.first.amount, 800.0);

      // Newer version from Device B (edited amount to 950 with newer updatedAt)
      final newerRemoteTx = Transaction(
        id: 'tx_shared_1',
        title: 'Dinner at Bistro (Split with Alex)',
        amount: 950.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.restaurant,
        categoryColor: Colors.orange,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().add(const Duration(seconds: 10)),
      );

      sync.onTransactionsChanged?.call([newerRemoteTx]);

      expect(appState.transactions.length, 1);
      expect(appState.transactions.first.title, 'Dinner at Bistro (Split with Alex)');
      expect(appState.transactions.first.amount, 950.0);
      expect(appState.balance, -950.0);
    });

    test('8. Soft deleted remote transaction is removed from local state', () async {
      final appState = AppState();
      appState.initSyncForTesting('user_sync_test');
      final sync = SyncService.instance;

      final tx1 = Transaction(
        id: 'tx_active_1',
        title: 'Fuel',
        amount: 500.0,
        type: TransactionType.expense,
        category: 'Transport',
        icon: Icons.local_gas_station,
        categoryColor: Colors.blue,
        date: DateTime.now().subtract(const Duration(hours: 1)),
      );
      await appState.addTransaction(tx1);
      expect(appState.transactions.length, 1);

      // Remote signals that tx_active_1 has been deleted with a newer timestamp
      final deletedTx = tx1.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now().add(const Duration(seconds: 10)),
      );

      sync.onTransactionsChanged?.call([deletedTx]);

      // Deleted record is excluded from active transactions
      expect(appState.transactions.isEmpty, isTrue);
      expect(appState.balance, 0.0);
    });

    test('9. Remote budget and savings goal sync updates AppState reactively', () async {
      final appState = AppState();
      appState.initSyncForTesting('user_sync_test');
      final sync = SyncService.instance;

      final remoteBudget = Budget(
        id: 'b_remote_1',
        category: 'Entertainment',
        limitAmount: 4000.0,
        year: 2026,
        month: 10,
        updatedAt: DateTime(2026, 10, 22),
      );

      final remoteGoal = SavingsGoal(
        id: 'sg_remote_1',
        title: 'Emergency Fund',
        targetAmount: 100000.0,
        currentAmount: 25000.0,
        createdAt: DateTime(2026, 10, 22),
        updatedAt: DateTime(2026, 10, 22),
      );

      sync.onBudgetsChanged?.call([remoteBudget]);
      sync.onSavingsGoalsChanged?.call([remoteGoal]);

      expect(appState.budgets.any((b) => b.id == 'b_remote_1'), isTrue);
      expect(appState.savingsGoals.any((g) => g.id == 'sg_remote_1'), isTrue);
      expect(appState.savingsGoals.first.progressRatio, 0.25);
    });

    test('10. Profile sync updates theme, language, mascot across devices', () async {
      final appState = AppState();
      appState.initSyncForTesting('user_sync_test');
      final sync = SyncService.instance;

      sync.onProfileChanged?.call({
        'userName': 'Beniel Allwin',
        'selectedMascot': 'female',
        'selectedLanguage': 'Tamil',
        'displayTheme': 'Dark',
      });

      expect(appState.userName, 'Beniel Allwin');
      expect(appState.selectedMascot, 'female');
      expect(appState.isFemaleMascot, isTrue);
      expect(appState.selectedLanguage, 'Tamil');
    });
  });
}
