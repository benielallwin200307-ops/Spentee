import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/lent_borrowed_record.dart';
import 'package:spentee/screens/profile_screen.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Delete Account Feature Tests', () {
    testWidgets('1. ProfileScreen renders Delete Account button with red trash icon and red text',
        (WidgetTester tester) async {
      final appState = AppState();
      appState.initSyncForTesting('test_user_delete_1');

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to bottom to ensure Delete Account button is visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever_rounded), findsOneWidget);
    });

    testWidgets('2. Tapping Delete Account opens Step 1 dialog, Cancel dismisses it',
        (WidgetTester tester) async {
      final appState = AppState();
      appState.initSyncForTesting('test_user_delete_2');

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to bottom
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Verify Step 1 Dialog appears
      expect(find.text('Delete Account?'), findsOneWidget);
      expect(find.textContaining('permanently removes your Spentee profile'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Delete Account?'), findsNothing);
    });

    testWidgets('3. Step 1 Continue opens Step 2 Final Confirmation dialog',
        (WidgetTester tester) async {
      final appState = AppState();
      appState.initSyncForTesting('test_user_delete_3');

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to bottom
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Tap Continue to go to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify Step 2 Dialog appears
      expect(find.text('Final Confirmation'), findsOneWidget);
      expect(find.textContaining('irreversibly erased immediately'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
      expect(find.text('Permanently Delete Account'), findsOneWidget);

      // Tap Go Back
      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Final Confirmation'), findsNothing);
    });

    test('4. AppState.deleteAccount wipes local data and resets state', () async {
      final appState = AppState();
      const testUid = 'local_delete_test_user';
      appState.initSyncForTesting(testUid);

      // Populate test data
      appState.addTransaction(Transaction(
        id: 'tx_del_1',
        title: 'Dinner',
        amount: 250.0,
        date: DateTime.now(),
        category: 'Food',
        icon: Icons.restaurant,
        categoryColor: const Color(0xFF00E676),
        type: TransactionType.expense,
      ));

      appState.addBudget(Budget(
        id: 'b_del_1',
        category: 'Food',
        limitAmount: 1000.0,
        period: 'Monthly',
        year: 2026,
        month: 10,
      ));

      appState.addDebt(LentBorrowedRecord(
        id: 'debt_del_1',
        personName: 'Alex',
        amount: 500.0,
        date: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        type: DebtType.lent,
      ));

      expect(appState.transactions.length, 2);
      expect(appState.budgets.length, 1);
      expect(appState.debts.length, 1);
      expect(appState.isAuthenticated, isTrue);

      // Create a dummy file in .spentee_storage to test file removal
      final storageDir = Directory('.spentee_storage');
      if (!await storageDir.exists()) {
        await storageDir.create(recursive: true);
      }
      final dummyTxFile = File('${storageDir.path}/spentee_transactions_$testUid.json');
      await dummyTxFile.writeAsString('[]');
      expect(await dummyTxFile.exists(), isTrue);

      // Also create another user's file to verify preservation
      final otherUserFile = File('${storageDir.path}/spentee_transactions_other_preserved_user.json');
      await otherUserFile.writeAsString('[]');
      expect(await otherUserFile.exists(), isTrue);

      // Execute account deletion
      await appState.deleteAccount();

      // Verify in-memory state is wiped
      expect(appState.transactions, isEmpty);
      expect(appState.budgets, isEmpty);
      expect(appState.debts, isEmpty);
      expect(appState.balance, 0.0);
      expect(appState.isAuthenticated, isFalse);
      expect(appState.userUid, isEmpty);

      // Verify user's local file is deleted
      expect(await dummyTxFile.exists(), isFalse);

      // Verify other user's file is preserved!
      expect(await otherUserFile.exists(), isTrue);
      await otherUserFile.delete(); // cleanup
    });
  });
}
