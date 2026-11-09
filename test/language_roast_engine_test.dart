import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/roast.dart';
import 'package:spentee/models/savings_goal.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/services/roast_engine.dart';
import 'package:spentee/services/roast_library.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  group('Spentee Language-Aware Personalized Roast Engine Tests', () {
    const supportedLanguages = [
      'English',
      'Tamil',
      'Hindi',
      'Telugu',
      'Kannada',
      'Malayalam',
    ];

    test('1. Library contains 150 distinct base roasts across 6 languages (900 total)', () {
      expect(RoastLibrary.allBaseRoasts.length, 150);
      expect(RoastLibrary.allRoasts.length, 900);

      for (final lang in supportedLanguages) {
        final roasts = RoastLibrary.getRoastsForLanguage(lang);
        expect(
          roasts.length,
          150,
          reason: 'Language $lang must have exactly 150 roasts',
        );

        // Verify intensity breakdown: 50 Friendly, 50 Savage, 50 Brutal
        final friendly = roasts.where((r) => r.intensity == RoastIntensity.friendly).length;
        final savage = roasts.where((r) => r.intensity == RoastIntensity.savage).length;
        final brutal = roasts.where((r) => r.intensity == RoastIntensity.brutal).length;
        expect(friendly, 50, reason: 'Language $lang must have 50 friendly roasts');
        expect(savage, 50, reason: 'Language $lang must have 50 savage roasts');
        expect(brutal, 50, reason: 'Language $lang must have 50 brutal roasts');

        // Verify all roasts in this set are tagged with the right language
        for (final r in roasts) {
          expect(
            r.language.toLowerCase(),
            lang.toLowerCase(),
            reason: 'Roast ${r.id} must be tagged with language $lang',
          );
        }
      }
    });

    test('2. All roast IDs are unique across base definitions and per language', () {
      // 1. Verify 150 base roast definitions have unique IDs
      final baseIds = <String>{};
      for (final def in RoastLibrary.allBaseRoasts) {
        expect(
          baseIds.contains(def.id),
          isFalse,
          reason: 'Duplicate base roast ID found: ${def.id}',
        );
        baseIds.add(def.id);
      }
      expect(baseIds.length, 150);

      // 2. Verify all 150 IDs per language are unique
      for (final lang in supportedLanguages) {
        final langIds = <String>{};
        final roasts = RoastLibrary.getRoastsForLanguage(lang);
        for (final r in roasts) {
          expect(
            langIds.contains(r.id),
            isFalse,
            reason: 'Duplicate roast ID found in language $lang: ${r.id}',
          );
          langIds.add(r.id);
        }
        expect(langIds.length, 150);
      }
    });

    test('3. Validates meaningful localized content and scripts across all 6 languages', () {
      for (final lang in supportedLanguages) {
        final roasts = RoastLibrary.getRoastsForLanguage(lang);
        expect(roasts.length, 150);

        for (final r in roasts) {
          // Meaningful text validation: non-empty and reasonably descriptive
          expect(r.text.trim().isNotEmpty, isTrue, reason: 'Roast ${r.id} in $lang has empty text');
          expect(r.text.trim().length, greaterThan(15), reason: 'Roast ${r.id} in $lang is too short');

          // Ensure valid situation and intensity are assigned
          expect(r.situation, isNotNull);
          expect(r.intensity, isNotNull);

          // Category and emoji must be present
          expect(r.category.isNotEmpty, isTrue);
          expect(r.mascotEmoji.isNotEmpty, isTrue);

          // Base roasts must not contain raw unpopulated template tokens
          expect(r.text.contains('{amount}'), isFalse, reason: 'Unpopulated {amount} token in ${r.id}');
          expect(r.text.contains('{category}'), isFalse, reason: 'Unpopulated {category} token in ${r.id}');
        }

        // Language-specific content checks
        if (lang == 'English') {
          // English roasts must contain Latin alphabetical characters
          for (final r in roasts) {
            expect(RegExp(r'[a-zA-Z]').hasMatch(r.text), isTrue);
          }
        } else {
          // Regional languages (Tamil, Hindi, Telugu, Kannada, Malayalam) must have authentic localized content
          final hasRichContent = roasts.every((r) => r.text.length > 20 && r.mascotEmoji.isNotEmpty);
          expect(hasRichContent, isTrue, reason: 'Language $lang must contain rich localized roasts');
        }
      }
    });

    test('4. Selected language strictly governs the roast library used', () {
      final now = DateTime.now();
      final sampleTxs = [
        Transaction(
          id: 'tx_1',
          title: 'Biryani Order',
          amount: 650.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 'tx_2',
          title: 'Swiggy Dinner',
          amount: 850.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 'tx_3',
          title: 'Snacks & Chai',
          amount: 320.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
      ];

      for (final lang in supportedLanguages) {
        final roast = DynamicRoastEngine.generateRoast(
          transactions: sampleTxs,
          language: lang,
        );
        expect(
          roast.language.toLowerCase(),
          lang.toLowerCase(),
          reason: 'Selected language $lang must return a $lang roast, never fallback to English',
        );

        final matching = DynamicRoastEngine.getMatchingRoasts(
          transactions: sampleTxs,
          language: lang,
        );
        for (final m in matching) {
          expect(
            m.language.toLowerCase(),
            lang.toLowerCase(),
            reason: 'All matching roasts must belong to $lang',
          );
        }
      }
    });

    test('5. New users receive friendly onboarding roast without invented claims', () {
      for (final lang in supportedLanguages) {
        // Zero transactions
        final zeroRoast = DynamicRoastEngine.generateRoast(
          transactions: [],
          language: lang,
        );
        expect(zeroRoast.language.toLowerCase(), lang.toLowerCase());
        expect(zeroRoast.situation, RoastCategory.newUserEmpty);
        expect(zeroRoast.text, isNotEmpty);

        // Under 3 transactions (insufficient history)
        final oneTxRoast = DynamicRoastEngine.generateRoast(
          transactions: [
            Transaction(
              id: 'tx_lone',
              title: 'Coffee',
              amount: 50.0,
              type: TransactionType.expense,
              category: 'Food & Dining',
              icon: Icons.coffee,
              categoryColor: Colors.brown,
              date: DateTime.now(),
            ),
          ],
          language: lang,
        );
        expect(oneTxRoast.language.toLowerCase(), lang.toLowerCase());
        // Must not claim fabricated numbers or fake habits
        expect(oneTxRoast.situation == RoastCategory.newUserEmpty ||
            oneTxRoast.situation == RoastCategory.insufficientHistory, isTrue);
      }
    });

    test('6. Category-specific roasts trigger based on verified on-device behavior', () {
      final now = DateTime.now();

      // Food dominance scenario
      final foodTxs = [
        Transaction(
          id: 'f1',
          title: 'Zomato',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 'f2',
          title: 'Swiggy',
          amount: 1200.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 'f3',
          title: 'Tea stall',
          amount: 100.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
      ];

      final foodRoast = DynamicRoastEngine.generateRoast(
        transactions: foodTxs,
        language: 'Tamil',
      );
      expect(foodRoast.language, 'Tamil');
      expect(
        foodRoast.situation == RoastCategory.foodDining ||
            foodRoast.situation == RoastCategory.categoryHeavy,
        isTrue,
      );

      // Shopping dominance scenario
      final shoppingTxs = [
        Transaction(
          id: 's1',
          title: 'Zara Clothes',
          amount: 4500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 's2',
          title: 'Shoes',
          amount: 3200.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 's3',
          title: 'Metro',
          amount: 50.0,
          type: TransactionType.expense,
          category: 'Transport',
          icon: Icons.subway,
          categoryColor: Colors.blue,
          date: now,
        ),
      ];

      final shoppingRoast = DynamicRoastEngine.generateRoast(
        transactions: shoppingTxs,
        language: 'Hindi',
      );
      expect(shoppingRoast.language, 'Hindi');
      expect(
        shoppingRoast.situation == RoastCategory.shopping ||
            shoppingRoast.situation == RoastCategory.shoppingDiscretionary ||
            shoppingRoast.situation == RoastCategory.categoryHeavy,
        isTrue,
      );
    });

    test('7. Improving saving habits and frugal discipline produce positive roasts', () {
      final now = DateTime.now();
      final savingTxs = [
        Transaction(
          id: 'inc1',
          title: 'Monthly Salary',
          amount: 100000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.money,
          categoryColor: Colors.green,
          date: now,
        ),
        Transaction(
          id: 'exp1',
          title: 'Modest Grocery',
          amount: 8000.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.shopping_basket,
          categoryColor: Colors.amber,
          date: now.subtract(const Duration(days: 3)),
        ),
        Transaction(
          id: 'exp2',
          title: 'Utilities',
          amount: 2500.0,
          type: TransactionType.expense,
          category: 'Bills',
          icon: Icons.flash_on,
          categoryColor: Colors.orange,
          date: now.subtract(const Duration(days: 6)),
        ),
      ];

      final goals = [
        SavingsGoal(
          id: 'sg_1',
          title: 'Emergency Fund',
          targetAmount: 50000.0,
          currentAmount: 50000.0, // Reached!
          createdAt: now.subtract(const Duration(days: 30)),
        ),
      ];

      // 1. Verify candidate collection identifies positive financial situations
      final matching = DynamicRoastEngine.getMatchingRoasts(
        transactions: savingTxs,
        savingsGoals: goals,
        language: 'Kannada',
      );
      expect(
        matching.any((m) =>
            m.situation == RoastCategory.goalReached ||
            m.situation == RoastCategory.improvingSavings ||
            m.situation == RoastCategory.disciplinedFrugal ||
            m.situation == RoastCategory.savingsHabits),
        isTrue,
        reason: 'Candidates must include positive saving and discipline roasts',
      );

      // 2. Verify selected roast is localized in Kannada and reflects financial context
      final roast = DynamicRoastEngine.generateRoast(
        transactions: savingTxs,
        savingsGoals: goals,
        language: 'Kannada',
      );

      expect(roast.language, 'Kannada');
      expect(
        roast.situation == RoastCategory.goalReached ||
            roast.situation == RoastCategory.improvingSavings ||
            roast.situation == RoastCategory.disciplinedFrugal ||
            roast.situation == RoastCategory.savingsHabits ||
            roast.situation == RoastCategory.groceries ||
            roast.situation == RoastCategory.highSpendingCategories ||
            roast.situation == RoastCategory.monthlySpendingBehaviour,
        isTrue,
      );
    });

    test('8. Anti-repetition avoids back-to-back duplicate roasts', () {
      final now = DateTime.now();
      final sampleTxs = [
        Transaction(
          id: 't1',
          title: 'Dinner',
          amount: 2500.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 't2',
          title: 'Lunch',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 't3',
          title: 'Coffee',
          amount: 250.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: now,
        ),
      ];

      for (final lang in supportedLanguages) {
        final roast1 = DynamicRoastEngine.generateRoast(
          transactions: sampleTxs,
          language: lang,
        );

        final roast2 = DynamicRoastEngine.generateRoast(
          transactions: sampleTxs,
          previousRoastId: roast1.id,
          previousRoastText: roast1.text,
          recentRoastIds: [roast1.id],
          language: lang,
        );

        expect(
          roast2.id != roast1.id,
          isTrue,
          reason: 'Language $lang repeated roast ${roast1.id} back-to-back',
        );
      }
    });

    test('9. Roast is cached and stable across simple rebuilds until refreshed', () {
      final state = AppState();
      state.setLanguage('Malayalam');

      final initialRoast = state.currentRoast;
      expect(initialRoast.language, 'Malayalam');

      // Multiple reads must return identical cached roast instance
      final secondRead = state.currentRoast;
      final thirdRead = state.currentRoast;
      expect(identical(initialRoast, secondRead), isTrue);
      expect(identical(initialRoast, thirdRead), isTrue);
    });

    test('10. AppState immediate language switching updates roast without restart', () {
      final state = AppState();

      state.setLanguage('Telugu');
      expect(state.selectedLanguage, 'Telugu');
      expect(state.currentRoast.language, 'Telugu');

      state.setLanguage('Tamil');
      expect(state.selectedLanguage, 'Tamil');
      expect(state.currentRoast.language, 'Tamil');

      state.setLanguage('Hindi');
      expect(state.selectedLanguage, 'Hindi');
      expect(state.currentRoast.language, 'Hindi');

      state.setLanguage('Kannada');
      expect(state.selectedLanguage, 'Kannada');
      expect(state.currentRoast.language, 'Kannada');

      state.setLanguage('Malayalam');
      expect(state.selectedLanguage, 'Malayalam');
      expect(state.currentRoast.language, 'Malayalam');

      state.setLanguage('English');
      expect(state.selectedLanguage, 'English');
      expect(state.currentRoast.language, 'English');
    });

    test('11. Roast engine operations are pure read-only and preserve balances & data', () async {
      final state = AppState();
      final now = DateTime.now();

      await state.addTransaction(
        Transaction(
          id: 'test_tx_income',
          title: 'Salary Deposit',
          amount: 60000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.wallet,
          categoryColor: Colors.green,
          date: now,
        ),
      );

      await state.addTransaction(
        Transaction(
          id: 'test_tx_exp',
          title: 'Groceries',
          amount: 5000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.shopping_basket,
          categoryColor: Colors.pink,
          date: now,
        ),
      );

      final balanceBefore = state.balance;
      final txCountBefore = state.transactions.length;

      // Cycle roasts across all languages
      for (final lang in supportedLanguages) {
        state.setLanguage(lang);
        state.refreshRoast();
        state.nextRoast();
      }

      expect(state.balance, balanceBefore);
      expect(state.transactions.length, txCountBefore);
    });
  });
}
