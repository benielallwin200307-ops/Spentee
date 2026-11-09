import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/category_model.dart';
import 'package:spentee/services/sync_service.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String account1Uid = 'user_acc_1_uid';
  const String account2Uid = 'user_acc_2_uid';

  Future<void> cleanTestFiles() async {
    final storageDir = Directory('.spentee_storage');
    if (!await storageDir.exists()) return;
    final files = [
      'spentee_categories.json',
      'spentee_categories_guest.json',
      'spentee_categories_$account1Uid.json',
      'spentee_categories_$account2Uid.json',
    ];
    for (final name in files) {
      final f = File('${storageDir.path}/$name');
      for (int i = 0; i < 6; i++) {
        try {
          if (await f.exists()) {
            await f.delete();
          }
          break;
        } catch (_) {
          if (i == 5) break;
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    }
  }

  setUp(() async {
    SyncService.instance.stopListening();
    await cleanTestFiles();
  });

  tearDown(() async {
    SyncService.instance.stopListening();
    await cleanTestFiles();
  });

  group('Custom Category Multi-Account Isolation Tests', () {
    test('1. CategoryItem serialization supports userId and preserves backward compatibility', () {
      final catWithUid = CategoryItem(
        id: 'cat_parents_expense',
        name: 'Parents Expense',
        isExpense: true,
        isCustom: true,
        icon: Icons.family_restroom_rounded,
        color: const Color(0xFF00E676),
        userId: account1Uid,
      );

      final json = catWithUid.toJson();
      expect(json['userId'], account1Uid);

      final deserialized = CategoryItem.fromJson(json);
      expect(deserialized.id, 'cat_parents_expense');
      expect(deserialized.name, 'Parents Expense');
      expect(deserialized.userId, account1Uid);
      expect(deserialized.isCustom, isTrue);

      // Backward compatibility: JSON without userId should deserialize safely with null userId
      final legacyJson = {
        'id': 'cat_legacy',
        'name': 'Legacy Cat',
        'isExpense': true,
        'isCustom': true,
        'colorValue': const Color(0xFF2979FF).toARGB32(),
        'iconCodePoint': Icons.label_rounded.codePoint,
      };
      final legacyCat = CategoryItem.fromJson(legacyJson);
      expect(legacyCat.id, 'cat_legacy');
      expect(legacyCat.userId, isNull);
    });

    test('2. Multi-Account Isolation: Account 1 and Account 2 have strictly separated categories', () async {
      final appState = AppState();

      // --- STEP 1: Log in as Account 1 ---
      await appState.setUserProfile(
        name: 'Account One',
        email: 'acc1@gmail.com',
        uid: account1Uid,
      );

      expect(appState.userUid, account1Uid);
      expect(appState.customCategories.any((c) => c.name == 'Parents Expense'), isFalse);

      // --- STEP 2: Account 1 creates "Parents Expense" ---
      final parentsExpenseCat = CategoryItem(
        id: 'cat_parents_expense_1',
        name: 'Parents Expense',
        isExpense: true,
        isCustom: true,
        icon: Icons.family_restroom_rounded,
        color: const Color(0xFF00E676),
        userId: account1Uid,
      );
      await appState.addCustomCategory(parentsExpenseCat);

      // Confirm "Parents Expense" exists in Account 1
      expect(appState.customCategories.any((c) => c.name == 'Parents Expense'), isTrue);
      final createdCat = appState.customCategories.firstWhere((c) => c.name == 'Parents Expense');
      expect(createdCat.userId, account1Uid);

      // --- STEP 3: Account 1 logs out ---
      await appState.logout();
      expect(appState.isAuthenticated, isFalse);
      expect(appState.userUid, isEmpty);

      // After logout, in-memory state MUST be reset to default categories ONLY
      expect(
        appState.customCategories.any((c) => c.name == 'Parents Expense'),
        isFalse,
        reason: 'Logout must clear Account 1 custom categories from memory',
      );
      expect(appState.customCategories.every((c) => !c.isCustom), isTrue);

      // --- STEP 4: Log in as Account 2 ---
      await appState.setUserProfile(
        name: 'Account Two',
        email: 'acc2@gmail.com',
        uid: account2Uid,
      );

      expect(appState.userUid, account2Uid);

      // Confirm Account 1's "Parents Expense" is NOT visible in Account 2
      expect(
        appState.customCategories.any((c) => c.name == 'Parents Expense'),
        isFalse,
        reason: 'Account 1 custom category must NOT appear in Account 2',
      );

      // --- STEP 5: Account 2 creates its own custom category "Car Maintenance" ---
      final carMaintenanceCat = CategoryItem(
        id: 'cat_car_maint_2',
        name: 'Car Maintenance',
        isExpense: true,
        isCustom: true,
        icon: Icons.directions_car_rounded,
        color: const Color(0xFFFF9100),
        userId: account2Uid,
      );
      await appState.addCustomCategory(carMaintenanceCat);

      expect(appState.customCategories.any((c) => c.name == 'Car Maintenance'), isTrue);
      expect(appState.customCategories.any((c) => c.name == 'Parents Expense'), isFalse);

      // --- STEP 6: Account 2 logs out ---
      await appState.logout();
      expect(appState.customCategories.any((c) => c.name == 'Car Maintenance'), isFalse);
      expect(appState.customCategories.any((c) => c.name == 'Parents Expense'), isFalse);

      // --- STEP 7: Log back in as Account 1 ---
      await appState.setUserProfile(
        name: 'Account One',
        email: 'acc1@gmail.com',
        uid: account1Uid,
      );

      // Confirm Account 1 still has "Parents Expense"
      expect(
        appState.customCategories.any((c) => c.name == 'Parents Expense'),
        isTrue,
        reason: 'Account 1 must retain "Parents Expense"',
      );
      // Confirm Account 1 DOES NOT have Account 2's "Car Maintenance"
      expect(
        appState.customCategories.any((c) => c.name == 'Car Maintenance'),
        isFalse,
        reason: 'Account 1 must not see Account 2 categories',
      );
    });

    test('3. Cross-Device Cloud Sync Simulation: Same account on another device restores custom categories', () async {
      // Create Account 1's local file as if saved on Device 1
      final appStateDevice1 = AppState();
      await appStateDevice1.setUserProfile(
        name: 'Account One',
        email: 'acc1@gmail.com',
        uid: account1Uid,
      );

      await appStateDevice1.addCustomCategory(CategoryItem(
        id: 'cat_parents_expense_sync',
        name: 'Parents Expense',
        isExpense: true,
        isCustom: true,
        icon: Icons.family_restroom_rounded,
        color: const Color(0xFF00E676),
        userId: account1Uid,
      ));

      // Device 2 starts with fresh AppState
      final appStateDevice2 = AppState();
      await appStateDevice2.setUserProfile(
        name: 'Account One',
        email: 'acc1@gmail.com',
        uid: account1Uid,
      );

      // Verify that Account 1's "Parents Expense" loaded into Device 2
      expect(appStateDevice2.customCategories.any((c) => c.name == 'Parents Expense'), isTrue);

      // Device 2 receives cloud sync event for Account 1
      appStateDevice2.initSyncForTesting(account1Uid);
      expect(appStateDevice2.customCategories.any((c) => c.name == 'Parents Expense'), isTrue);

      await appStateDevice1.logout();
      await appStateDevice2.logout();
    });

    test('4. Security Filter: Incoming remote categories from a different account are rejected', () async {
      final appState = AppState();
      await appState.setUserProfile(
        name: 'Account Two',
        email: 'acc2@gmail.com',
        uid: account2Uid,
      );

      // Simulate a malicious or leaked remote category event containing Account 1's category
      final leakedFromAccount1 = CategoryItem(
        id: 'cat_leaked_from_acc1',
        name: 'Parents Expense',
        isExpense: true,
        isCustom: true,
        icon: Icons.family_restroom_rounded,
        color: const Color(0xFF00E676),
        userId: account1Uid, // Belonging to Account 1!
      );

      final legitForAccount2 = CategoryItem(
        id: 'cat_legit_for_acc2',
        name: 'Gym Subscription',
        isExpense: true,
        isCustom: true,
        icon: Icons.fitness_center_rounded,
        color: const Color(0xFF10B981),
        userId: account2Uid, // Belonging to Account 2!
      );

      // Trigger sync listener callback
      appState.initSyncForTesting(account2Uid);
      SyncService.instance.onCategoriesChanged?.call([leakedFromAccount1, legitForAccount2]);

      // Verify that Account 2 rejects the leaked category but accepts its own
      expect(appState.customCategories.any((c) => c.name == 'Parents Expense'), isFalse);
      expect(appState.customCategories.any((c) => c.name == 'Gym Subscription'), isTrue);

      await appState.logout();
    });

    test('5. Realtime onCategoriesChanged stream callback filters out cross-account categories', () async {
      final appState = AppState();
      await appState.setUserProfile(
        name: 'Account Two',
        email: 'acc2@gmail.com',
        uid: account2Uid,
      );

      // Initialize sync handlers for Account 2
      appState.initSyncForTesting(account2Uid);

      // Directly invoke onCategoriesChanged as would happen from Firestore snapshots
      final mixedRemoteList = [
        CategoryItem(
          id: 'cat_acc1_parents_expense',
          name: 'Parents Expense',
          isExpense: true,
          isCustom: true,
          icon: Icons.family_restroom_rounded,
          color: const Color(0xFF00E676),
          userId: account1Uid, // Account 1's UID!
        ),
        CategoryItem(
          id: 'cat_acc2_groceries_extra',
          name: 'Organic Market',
          isExpense: true,
          isCustom: true,
          icon: Icons.local_grocery_store_rounded,
          color: const Color(0xFF00E5FF),
          userId: account2Uid, // Account 2's UID!
        ),
      ];

      // Invoke callback
      SyncService.instance.onCategoriesChanged?.call(mixedRemoteList);

      // Verify that Account 2 accepted 'Organic Market' but rejected 'Parents Expense'
      expect(appState.customCategories.any((c) => c.name == 'Organic Market'), isTrue);
      expect(appState.customCategories.any((c) => c.name == 'Parents Expense'), isFalse);

      await appState.logout();
    });
  });
}
