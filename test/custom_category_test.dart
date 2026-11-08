import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/category_model.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/screens/add_transaction_screen.dart';
import 'package:spentee/screens/edit_transaction_screen.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Clean up any test category files
    final storageDir = Directory('.spentee_storage');
    if (await storageDir.exists()) {
      final catFile = File('${storageDir.path}/spentee_categories.json');
      if (await catFile.exists()) await catFile.delete();
      final guestFile = File('${storageDir.path}/spentee_categories_guest.json');
      if (await guestFile.exists()) await guestFile.delete();
      final userFile = File('${storageDir.path}/spentee_categories_test_user.json');
      if (await userFile.exists()) await userFile.delete();
    }
  });

  tearDown(() async {
    final storageDir = Directory('.spentee_storage');
    if (await storageDir.exists()) {
      final catFile = File('${storageDir.path}/spentee_categories.json');
      if (await catFile.exists()) await catFile.delete();
      final guestFile = File('${storageDir.path}/spentee_categories_guest.json');
      if (await guestFile.exists()) await guestFile.delete();
      final userFile = File('${storageDir.path}/spentee_categories_test_user.json');
      if (await userFile.exists()) await userFile.delete();
    }
  });

  group('Custom Categories Integration & Safety Tests', () {
    test('1. AppState starts with all 8 default expense and 4 default income categories', () {
      final appState = AppState();
      final expenseCats = appState.customCategories.where((c) => c.isExpense).toList();
      final incomeCats = appState.customCategories.where((c) => !c.isExpense).toList();

      expect(expenseCats.length, 8);
      expect(incomeCats.length, 4);

      expect(expenseCats.any((c) => c.name == 'Food & Drinks'), isTrue);
      expect(expenseCats.any((c) => c.name == 'Transport'), isTrue);
      expect(expenseCats.any((c) => c.name == 'Shopping'), isTrue);
      expect(expenseCats.any((c) => c.name == 'Bills & Utilities'), isTrue);
      expect(expenseCats.any((c) => c.name == 'Entertainment'), isTrue);
      expect(expenseCats.any((c) => c.name == 'Groceries'), isTrue);
      expect(expenseCats.any((c) => c.name == 'Health & Care'), isTrue);
      expect(expenseCats.any((c) => c.name == 'Others'), isTrue);

      expect(incomeCats.any((c) => c.name == 'Salary'), isTrue);
      expect(incomeCats.any((c) => c.name == 'Freelance'), isTrue);
      expect(incomeCats.any((c) => c.name == 'Investments'), isTrue);
      expect(incomeCats.any((c) => c.name == 'Gift / Bonus'), isTrue);
    });

    test('2. Adding Expense and Income custom categories works and prevents duplicates', () async {
      final appState = AppState();

      final customExp = CategoryItem(
        id: 'cat_pet_care',
        name: 'Pet Care',
        isExpense: true,
        isCustom: true,
        icon: Icons.pets_rounded,
        color: const Color(0xFFFF9100),
      );

      final customInc = CategoryItem(
        id: 'cat_crypto_staking',
        name: 'Crypto Staking',
        isExpense: false,
        isCustom: true,
        icon: Icons.currency_bitcoin_rounded,
        color: const Color(0xFF00E5FF),
      );

      await appState.addCustomCategory(customExp);
      await appState.addCustomCategory(customInc);

      final expList = appState.customCategories.where((c) => c.isExpense).toList();
      final incList = appState.customCategories.where((c) => !c.isExpense).toList();

      expect(expList.any((c) => c.name == 'Pet Care'), isTrue);
      expect(incList.any((c) => c.name == 'Crypto Staking'), isTrue);

      // Attempt duplicate addition for same type should be prevented
      final dupExp = CategoryItem(
        id: 'cat_pet_care_duplicate',
        name: 'Pet Care',
        isExpense: true,
        isCustom: true,
        icon: Icons.pets_rounded,
        color: const Color(0xFFFF9100),
      );
      await appState.addCustomCategory(dupExp);
      final expAfterDup = appState.customCategories.where((c) => c.isExpense).toList();
      expect(expAfterDup.where((c) => c.name == 'Pet Care').length, 1);
    });

    test('3. Custom categories persist locally across simulated app restart', () async {
      final appState1 = AppState();

      final gymCat = CategoryItem(
        id: 'cat_gym_membership',
        name: 'Gym Membership',
        isExpense: true,
        isCustom: true,
        icon: Icons.fitness_center_rounded,
        color: const Color(0xFF10B981),
      );

      final dividendCat = CategoryItem(
        id: 'cat_stock_dividends',
        name: 'Stock Dividends',
        isExpense: false,
        isCustom: true,
        icon: Icons.trending_up_rounded,
        color: const Color(0xFFA855F7),
      );

      await appState1.addCustomCategory(gymCat);
      await appState1.addCustomCategory(dividendCat);

      // Simulate closing and reopening app
      final appState2 = AppState();
      await appState2.loadCategoriesFromStorage();

      final restoredExpense = appState2.customCategories.where((c) => c.isExpense).toList();
      final restoredIncome = appState2.customCategories.where((c) => !c.isExpense).toList();

      expect(restoredExpense.any((c) => c.name == 'Gym Membership'), isTrue);
      expect(restoredIncome.any((c) => c.name == 'Stock Dividends'), isTrue);

      final restoredGym = restoredExpense.firstWhere((c) => c.name == 'Gym Membership');
      expect(restoredGym.isCustom, isTrue);
      expect(restoredGym.icon.codePoint, Icons.fitness_center_rounded.codePoint);
      expect(restoredGym.color.toARGB32(), const Color(0xFF10B981).toARGB32());
    });

    test('4. Renaming a category updates the category list and past transactions', () async {
      final appState = AppState();

      final initialCat = CategoryItem(
        id: 'cat_sub_1',
        name: 'Online Subs',
        isExpense: true,
        isCustom: true,
        icon: Icons.subscriptions_rounded,
        color: Colors.blue,
      );
      await appState.addCustomCategory(initialCat);

      final tx = Transaction(
        id: 'tx_sub_test',
        title: 'Online Subs',
        amount: 299.0,
        type: TransactionType.expense,
        category: 'Online Subs',
        icon: Icons.subscriptions_rounded,
        categoryColor: Colors.blue,
        date: DateTime.now(),
      );
      await appState.addTransaction(tx);

      // Rename category
      await appState.renameCategory('cat_sub_1', 'Streaming Services');

      expect(appState.customCategories.any((c) => c.name == 'Streaming Services'), isTrue);
      expect(appState.customCategories.any((c) => c.name == 'Online Subs'), isFalse);

      // Verify historical transaction was updated to maintain integrity
      final updatedTx = appState.transactions.firstWhere((t) => t.id == 'tx_sub_test');
      expect(updatedTx.category, 'Streaming Services');
      expect(updatedTx.title, 'Streaming Services');
    });

    test('5. Deleting custom category reassigns past transactions to Others', () async {
      final appState = AppState();

      final tempCat = CategoryItem(
        id: 'cat_temp',
        name: 'Temporary Hobby',
        isExpense: true,
        isCustom: true,
        icon: Icons.palette_rounded,
        color: Colors.orange,
      );
      await appState.addCustomCategory(tempCat);

      final tx = Transaction(
        id: 'tx_hobby_1',
        title: 'Temporary Hobby',
        amount: 150.0,
        type: TransactionType.expense,
        category: 'Temporary Hobby',
        icon: Icons.palette_rounded,
        categoryColor: Colors.orange,
        date: DateTime.now(),
      );
      await appState.addTransaction(tx);

      await appState.deleteCategory('cat_temp');

      expect(appState.customCategories.any((c) => c.id == 'cat_temp'), isFalse);
      final updatedTx = appState.transactions.firstWhere((t) => t.id == 'tx_hobby_1');
      expect(updatedTx.category, 'Others');
    });

    testWidgets('6. AddTransactionScreen displays custom expense category in picker and saves transaction', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appState = AppState();

      final customExp = CategoryItem(
        id: 'cat_pet',
        name: 'Pet Food',
        isExpense: true,
        isCustom: true,
        icon: Icons.pets_rounded,
        color: const Color(0xFFFF9100),
      );
      await tester.runAsync(() async {
        await appState.addTransaction(Transaction(
          id: 'inc_setup_pet',
          title: 'Initial Funds',
          amount: 1000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.attach_money,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ));
        await appState.addCustomCategory(customExp);
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

      // Open Category Picker
      final categoryLabel = find.text('Category');
      await tester.ensureVisible(categoryLabel);
      await tester.tap(categoryLabel);
      await tester.pumpAndSettle();

      // Verify custom category is displayed in the picker
      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Pet Food'), findsOneWidget);

      // Select 'Pet Food'
      await tester.tap(find.text('Pet Food'));
      await tester.pumpAndSettle();

      // Check detail card shows selected category
      expect(find.text('Pet Food'), findsOneWidget);

      // Enter amount: '5'
      await tester.tap(find.text('5'));
      await tester.pump();

      // Save transaction
      final saveBtn = find.text('Save');
      await tester.ensureVisible(saveBtn);
      await tester.runAsync(() async {
        await tester.tap(saveBtn);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify transaction was saved with custom category
      expect(appState.transactions.length, 2);
      final savedTx = appState.transactions.first;
      expect(savedTx.category, 'Pet Food');
      expect(savedTx.amount, 5.0);
      expect(savedTx.type, TransactionType.expense);
    });

    testWidgets('7. AddTransactionScreen displays custom income category in picker and saves transaction', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appState = AppState();

      final customInc = CategoryItem(
        id: 'cat_consulting',
        name: 'Consulting',
        isExpense: false,
        isCustom: true,
        icon: Icons.work_rounded,
        color: const Color(0xFF00E5FF),
      );
      await tester.runAsync(() async {
        await appState.addCustomCategory(customInc);
      });

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: AddTransactionScreen(initialType: TransactionType.income),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Category Picker
      final categoryLabel = find.text('Category');
      await tester.ensureVisible(categoryLabel);
      await tester.tap(categoryLabel);
      await tester.pumpAndSettle();

      // Verify custom income category is displayed in picker
      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Consulting'), findsOneWidget);

      // Select 'Consulting'
      await tester.tap(find.text('Consulting'));
      await tester.pumpAndSettle();

      expect(find.text('Consulting'), findsOneWidget);

      // Enter amount: '1', '2'
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();

      // Save
      final saveBtn = find.text('Save');
      await tester.ensureVisible(saveBtn);
      await tester.runAsync(() async {
        await tester.tap(saveBtn);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(appState.transactions.length, 1);
      final savedTx = appState.transactions.first;
      expect(savedTx.category, 'Consulting');
      expect(savedTx.amount, 12.0);
      expect(savedTx.type, TransactionType.income);
    });

    testWidgets('8. EditTransactionScreen displays and selects custom categories', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appState = AppState();

      final customExp = CategoryItem(
        id: 'cat_coaching',
        name: 'Coaching',
        isExpense: true,
        isCustom: true,
        icon: Icons.sports_rounded,
        color: Colors.teal,
      );
      final initialTx = Transaction(
        id: 'tx_edit_test',
        title: 'Dinner at Italian Place',
        amount: 300.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.pink,
        date: DateTime.now().subtract(const Duration(hours: 1)),
      );
      await tester.runAsync(() async {
        await appState.addTransaction(Transaction(
          id: 'inc_setup_edit',
          title: 'Initial Funds',
          amount: 1000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.attach_money,
          categoryColor: Colors.green,
          date: DateTime.now(),
        ));
        await appState.addCustomCategory(customExp);
        await appState.addTransaction(initialTx);
      });

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: MaterialApp(
            home: EditTransactionScreen(transaction: initialTx),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open category picker in EditTransactionScreen
      await tester.tap(find.text('Food & Drinks'));
      await tester.pumpAndSettle();

      expect(find.text('Coaching'), findsOneWidget);

      // Select 'Coaching'
      await tester.tap(find.text('Coaching'));
      await tester.pumpAndSettle();

      // Save changes
      await tester.runAsync(() async {
        await tester.tap(find.text('Save Changes'));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final updated = appState.transactions.firstWhere((t) => t.id == 'tx_edit_test');
      expect(updated.category, 'Coaching');
    });
  });
}
