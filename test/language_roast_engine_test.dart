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

    test('1. Library contains exactly 25 distinct roasts per language (150 total)', () {
      expect(RoastLibrary.allRoasts.length, 150);

      for (final lang in supportedLanguages) {
        final roasts = RoastLibrary.getRoastsForLanguage(lang);
        expect(
          roasts.length,
          25,
          reason: 'Language $lang must have exactly 25 roasts',
        );

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

    test('2. All roast IDs are unique across the entire library', () {
      final ids = <String>{};
      for (final r in RoastLibrary.allRoasts) {
        expect(
          ids.contains(r.id),
          isFalse,
          reason: 'Duplicate roast ID found: ${r.id}',
        );
        ids.add(r.id);
      }
      expect(ids.length, 150);
    });

    test('3. Strictly English/Roman letters only - zero native script characters', () {
      final tamilRegex = RegExp(r'[\u0B80-\u0BFF]');
      final devanagariRegex = RegExp(r'[\u0900-\u097F]');
      final teluguRegex = RegExp(r'[\u0C00-\u0C7F]');
      final kannadaRegex = RegExp(r'[\u0C80-\u0CFF]');
      final malayalamRegex = RegExp(r'[\u0D00-\u0D7F]');

      for (final r in RoastLibrary.allRoasts) {
        // Assert 0 native script characters in all roasts
        expect(
          tamilRegex.hasMatch(r.text),
          isFalse,
          reason: 'Roast ${r.id} in ${r.language} contains Tamil native script: ${r.text}',
        );
        expect(
          devanagariRegex.hasMatch(r.text),
          isFalse,
          reason: 'Roast ${r.id} in ${r.language} contains Devanagari script: ${r.text}',
        );
        expect(
          teluguRegex.hasMatch(r.text),
          isFalse,
          reason: 'Roast ${r.id} in ${r.language} contains Telugu native script: ${r.text}',
        );
        expect(
          kannadaRegex.hasMatch(r.text),
          isFalse,
          reason: 'Roast ${r.id} in ${r.language} contains Kannada native script: ${r.text}',
        );
        expect(
          malayalamRegex.hasMatch(r.text),
          isFalse,
          reason: 'Roast ${r.id} in ${r.language} contains Malayalam native script: ${r.text}',
        );

        // Assert text is not empty and reasonably descriptive
        expect(r.text.trim().isNotEmpty, isTrue);
        expect(r.text.length, greaterThan(15));
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

      final roast = DynamicRoastEngine.generateRoast(
        transactions: savingTxs,
        savingsGoals: goals,
        language: 'Kannada',
      );

      expect(roast.language, 'Kannada');
      expect(
        roast.situation == RoastCategory.goalReached ||
            roast.situation == RoastCategory.improvingSavings ||
            roast.situation == RoastCategory.disciplinedFrugal,
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
