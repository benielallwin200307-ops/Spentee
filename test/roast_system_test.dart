import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/roast.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/services/roast_engine.dart';
import 'package:spentee/services/roast_library.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Spentee AI - Advanced Personalised Roast System Test Suite', () {
    final now = DateTime.now();

    // ── Test 1: Exactly 150 Base Roasts (50 Friendly, 50 Savage, 50 Brutal) ──
    test('1. Library contains exactly 150 base roasts (50 Friendly, 50 Savage, 50 Brutal)', () {
      final base = RoastLibrary.allBaseRoasts;
      expect(base.length, 150);

      final friendly = base.where((r) => r.intensity == RoastIntensity.friendly).toList();
      final savage = base.where((r) => r.intensity == RoastIntensity.savage).toList();
      final brutal = base.where((r) => r.intensity == RoastIntensity.brutal).toList();

      expect(friendly.length, 50, reason: 'Must have exactly 50 Friendly base roasts');
      expect(savage.length, 50, reason: 'Must have exactly 50 Savage base roasts');
      expect(brutal.length, 50, reason: 'Must have exactly 50 Brutal base roasts');

      final ids = <String>{};
      for (final r in base) {
        expect(ids.contains(r.id), isFalse, reason: 'Duplicate roast definition ID: ${r.id}');
        ids.add(r.id);
      }
    });

    // ── Test 2: Exactly 900 Localized Roasts Across All 6 Supported Languages ─
    test('2. Exactly 900 localized roasts across all 6 supported languages (150 x 6)', () {
      final all = RoastLibrary.allRoasts;
      expect(all.length, 900);

      const languages = ['English', 'Tamil', 'Telugu', 'Hindi', 'Malayalam', 'Kannada'];
      for (final lang in languages) {
        final langRoasts = all.where((r) => r.language == lang).toList();
        expect(langRoasts.length, 150, reason: 'Language $lang must have exactly 150 roasts');

        final friendly = langRoasts.where((r) => r.intensity == RoastIntensity.friendly).length;
        final savage = langRoasts.where((r) => r.intensity == RoastIntensity.savage).length;
        final brutal = langRoasts.where((r) => r.intensity == RoastIntensity.brutal).length;

        expect(friendly, 50, reason: '$lang must have 50 friendly roasts');
        expect(savage, 50, reason: '$lang must have 50 savage roasts');
        expect(brutal, 50, reason: '$lang must have 50 brutal roasts');

        for (final r in langRoasts) {
          expect(r.text.trim().isNotEmpty, isTrue, reason: 'Roast ${r.id} in $lang has empty text');
          expect(r.category.isNotEmpty, isTrue);
          expect(r.mascotEmoji.isNotEmpty, isTrue);
        }
      }
    });

    // ── Test 3: Distribution across all 15 Financial Situations ──────────────
    test('3. Roasts cover all 15 financial situations across intensities', () {
      final base = RoastLibrary.allBaseRoasts;
      final situations = base.map((r) => r.situation).toSet();

      final requiredSituations = [
        RoastCategory.foodDining,
        RoastCategory.shopping,
        RoastCategory.entertainment,
        RoastCategory.travelTransport,
        RoastCategory.billsUtilities,
        RoastCategory.subscriptions,
        RoastCategory.groceries,
        RoastCategory.lifestyle,
        RoastCategory.onlineShopping,
        RoastCategory.frequentSmallPurchases,
        RoastCategory.budgetOverspending,
        RoastCategory.highSpendingCategories,
        RoastCategory.savingsHabits,
        RoastCategory.incomeVsExpenses,
        RoastCategory.monthlySpendingBehaviour,
      ];

      for (final sit in requiredSituations) {
        expect(
          situations.contains(sit),
          isTrue,
          reason: 'Situation ${sit.name} must be represented in base roasts',
        );
      }
    });

    // ── Test 4: Empty Wallet State Roast ────────────────────────────────────
    test('4. Empty account produces empty wallet roast without inventing claims', () {
      final emptyRoast = DynamicRoastEngine.generateRoast(
        transactions: const [],
        language: 'English',
        intensity: RoastIntensity.savage,
      );

      expect(emptyRoast.text, contains("I can't roast an empty wallet!"));
      expect(emptyRoast.category, isIn(['Empty Wallet', 'Welcome to Spentee']));
      expect(emptyRoast.situation, RoastCategory.newUserEmpty);
    });

    // ── Test 5: Income-Only Account Roast ────────────────────────────────────
    test('5. Account with only income produces income-only roast', () {
      final incomeTxs = [
        Transaction(
          id: 'inc_1',
          title: 'Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.attach_money,
          categoryColor: Colors.green,
          date: now,
        ),
      ];

      final roast = DynamicRoastEngine.generateRoast(
        transactions: incomeTxs,
        language: 'English',
        intensity: RoastIntensity.friendly,
      );

      expect(roast.text, contains("Your income has arrived, but I don't have any expenses to roast yet!"));
      expect(roast.category, isIn(['Income Only', 'Income Recorded']));
    });

    // ── Test 6: Insufficient Transaction History (< 3 transactions) ──────────
    test('6. Insufficient transaction history (< 3 txs) requests more data', () {
      final sparseTxs = [
        Transaction(
          id: 'exp_1',
          title: 'Snack',
          amount: 60.0,
          type: TransactionType.expense,
          category: 'Food',
          icon: Icons.fastfood,
          categoryColor: Colors.orange,
          date: now,
        ),
        Transaction(
          id: 'exp_2',
          title: 'Coffee',
          amount: 150.0,
          type: TransactionType.expense,
          category: 'Food',
          icon: Icons.local_cafe,
          categoryColor: Colors.orange,
          date: now,
        ),
      ];

      final roast = DynamicRoastEngine.generateRoast(
        transactions: sparseTxs,
        language: 'English',
      );

      expect(roast.text, contains('Log at least 3 transactions to reveal your personalized financial roast!'));
      expect(roast.category, 'Data Needed');
      expect(roast.situation, RoastCategory.insufficientHistory);
    });

    // ── Test 7: Food & Dining Personalised Roast ────────────────────────────
    test('7. High Food & Dining expenses trigger food-focused roasts', () {
      final foodTxs = [
        Transaction(
          id: 'f1',
          title: 'Swiggy Feast',
          amount: 1800.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.orange,
          date: now,
        ),
        Transaction(
          id: 'f2',
          title: 'Cafe Espresso',
          amount: 450.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.local_cafe,
          categoryColor: Colors.orange,
          date: now,
        ),
        Transaction(
          id: 'f3',
          title: 'Dinner with friends',
          amount: 2200.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.fastfood,
          categoryColor: Colors.orange,
          date: now,
        ),
      ];

      final roast = DynamicRoastEngine.generateRoast(
        transactions: foodTxs,
        language: 'English',
        intensity: RoastIntensity.savage,
      );

      expect(
        roast.category.toLowerCase().contains('food') ||
            roast.category.toLowerCase().contains('dining') ||
            roast.text.toLowerCase().contains('food') ||
            roast.text.toLowerCase().contains('kitchen') ||
            roast.situation == RoastCategory.foodDining,
        isTrue,
      );
    });

    // ── Test 8: Shopping Personalised Roast ─────────────────────────────────
    test('8. Dominant shopping expenses trigger shopping-focused roasts', () {
      final shopTxs = [
        Transaction(
          id: 's1',
          title: 'Sneakers',
          amount: 4500.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 's2',
          title: 'Jacket',
          amount: 3200.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: now,
        ),
        Transaction(
          id: 's3',
          title: 'Groceries',
          amount: 400.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.local_grocery_store,
          categoryColor: Colors.green,
          date: now,
        ),
      ];

      final roast = DynamicRoastEngine.generateRoast(
        transactions: shopTxs,
        language: 'English',
        intensity: RoastIntensity.brutal,
      );

      expect(
        roast.category.toLowerCase().contains('shop') ||
            roast.text.toLowerCase().contains('cart') ||
            roast.text.toLowerCase().contains('shopping') ||
            roast.situation == RoastCategory.shopping,
        isTrue,
      );
    });

    // ── Test 9: Budget Overspending Detection ────────────────────────────────
    test('9. Budget overrun triggers budget overspending roast', () {
      final overBudTxs = [
        Transaction(
          id: 'b1',
          title: 'Concert ticket',
          amount: 4000.0,
          type: TransactionType.expense,
          category: 'Entertainment',
          icon: Icons.movie,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 'b2',
          title: 'Theme Park',
          amount: 3000.0,
          type: TransactionType.expense,
          category: 'Entertainment',
          icon: Icons.movie,
          categoryColor: Colors.pink,
          date: now,
        ),
        Transaction(
          id: 'b3',
          title: 'Movie night',
          amount: 1500.0,
          type: TransactionType.expense,
          category: 'Entertainment',
          icon: Icons.movie,
          categoryColor: Colors.pink,
          date: now,
        ),
      ];

      final budget = Budget(
        id: 'bg1',
        category: 'Entertainment',
        limitAmount: 5000.0,
        period: 'Monthly',
        year: now.year,
        month: now.month,
      );

      final roast = DynamicRoastEngine.generateRoast(
        transactions: overBudTxs,
        budgets: [budget],
        language: 'English',
        intensity: RoastIntensity.savage,
      );

      expect(
        roast.situation == RoastCategory.budgetOverspending ||
            roast.situation == RoastCategory.budgetOverrun ||
            roast.category.toLowerCase().contains('budget'),
        isTrue,
      );
    });

    // ── Test 10: No Budget Trigger When Budgets Not Defined ──────────────────
    test('10. Account with no budgets never produces budget overrun roasts', () {
      final normalTxs = [
        Transaction(
          id: 'n1',
          title: 'Utility bill',
          amount: 2000.0,
          type: TransactionType.expense,
          category: 'Bills & Utilities',
          icon: Icons.receipt,
          categoryColor: Colors.blue,
          date: now,
        ),
        Transaction(
          id: 'n2',
          title: 'Gas',
          amount: 1000.0,
          type: TransactionType.expense,
          category: 'Bills & Utilities',
          icon: Icons.receipt,
          categoryColor: Colors.blue,
          date: now,
        ),
        Transaction(
          id: 'n3',
          title: 'Water',
          amount: 500.0,
          type: TransactionType.expense,
          category: 'Bills & Utilities',
          icon: Icons.receipt,
          categoryColor: Colors.blue,
          date: now,
        ),
      ];

      final roast = DynamicRoastEngine.generateRoast(
        transactions: normalTxs,
        budgets: const [], // Zero budgets
        language: 'English',
      );

      expect(roast.situation, isNot(RoastCategory.budgetOverspending));
      expect(roast.situation, isNot(RoastCategory.budgetOverrun));
    });

    // ── Test 11: Transfers & Loans Strictly Isolated ─────────────────────────
    test('11. Transfers, lent money, and repayments are strictly excluded from spending calculations', () {
      final mixedTxs = [
        Transaction(
          id: 'tr_1',
          title: 'Transfer to Savings Vault',
          amount: 50000.0,
          type: TransactionType.transfer,
          category: 'Transfer',
          icon: Icons.sync_alt,
          categoryColor: Colors.blue,
          date: now,
        ),
        Transaction(
          id: 'tr_2',
          title: 'Money Lent to Sam',
          amount: 10000.0,
          type: TransactionType.expense,
          category: 'Money Lent',
          icon: Icons.arrow_outward,
          categoryColor: Colors.amber,
          date: now,
        ),
        Transaction(
          id: 'exp_1',
          title: 'Groceries',
          amount: 1200.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.local_grocery_store,
          categoryColor: Colors.green,
          date: now,
        ),
        Transaction(
          id: 'exp_2',
          title: 'Weekly Milk & Veggies',
          amount: 800.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.local_grocery_store,
          categoryColor: Colors.green,
          date: now,
        ),
        Transaction(
          id: 'exp_3',
          title: 'Snacks & Fruit',
          amount: 600.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.local_grocery_store,
          categoryColor: Colors.green,
          date: now,
        ),
      ];

      final calc = RoastCalculationData.compute(transactions: mixedTxs);
      // Valid expenses must only include the 3 Groceries transactions (1200 + 800 + 600 = 2600)
      expect(calc.validExpenseCount, 3);
      expect(calc.thisMonthExpense, 2600.0);
      expect(calc.topCategoryMonth, 'Groceries');
    });

    // ── Test 12: 3-Tier Intensity Filtering ─────────────────────────────────
    test('12. Intensity selection (Friendly, Savage, Brutal) returns appropriate intensity', () {
      final testTxs = [
        Transaction(id: '1', title: 'Food', amount: 500.0, type: TransactionType.expense, category: 'Food & Dining', icon: Icons.fastfood, categoryColor: Colors.orange, date: now),
        Transaction(id: '2', title: 'Food', amount: 600.0, type: TransactionType.expense, category: 'Food & Dining', icon: Icons.fastfood, categoryColor: Colors.orange, date: now),
        Transaction(id: '3', title: 'Food', amount: 700.0, type: TransactionType.expense, category: 'Food & Dining', icon: Icons.fastfood, categoryColor: Colors.orange, date: now),
      ];

      final friendlyRoast = DynamicRoastEngine.generateRoast(
        transactions: testTxs,
        intensity: RoastIntensity.friendly,
        language: 'English',
      );
      expect(friendlyRoast.intensity, RoastIntensity.friendly);

      final savageRoast = DynamicRoastEngine.generateRoast(
        transactions: testTxs,
        intensity: RoastIntensity.savage,
        language: 'English',
      );
      expect(savageRoast.intensity, RoastIntensity.savage);

      final brutalRoast = DynamicRoastEngine.generateRoast(
        transactions: testTxs,
        intensity: RoastIntensity.brutal,
        language: 'English',
      );
      expect(brutalRoast.intensity, RoastIntensity.brutal);
    });

    // ── Test 13: Anti-Repetition Mechanism ──────────────────────────────────
    test('13. Anti-repetition prevents back-to-back duplicate roast selection', () {
      final testTxs = [
        Transaction(id: '1', title: 'Shop', amount: 1500.0, type: TransactionType.expense, category: 'Shopping', icon: Icons.shopping_bag, categoryColor: Colors.purple, date: now),
        Transaction(id: '2', title: 'Shop', amount: 2000.0, type: TransactionType.expense, category: 'Shopping', icon: Icons.shopping_bag, categoryColor: Colors.purple, date: now),
        Transaction(id: '3', title: 'Shop', amount: 2500.0, type: TransactionType.expense, category: 'Shopping', icon: Icons.shopping_bag, categoryColor: Colors.purple, date: now),
      ];

      final roast1 = DynamicRoastEngine.generateRoast(
        transactions: testTxs,
        language: 'English',
        intensity: RoastIntensity.savage,
      );

      final roast2 = DynamicRoastEngine.generateRoast(
        transactions: testTxs,
        language: 'English',
        intensity: RoastIntensity.savage,
        previousRoastId: roast1.id,
        previousRoastText: roast1.text,
        recentRoastIds: [roast1.id],
      );

      expect(roast2.id, isNot(equals(roast1.id)));
    });

    // ── Test 14: Language Normalization & Cross-Language Consistency ────────
    test('14. Language normalization supports full names and ISO codes', () {
      expect(RoastLibrary.normalizeLanguage('English'), 'English');
      expect(RoastLibrary.normalizeLanguage('en'), 'English');
      expect(RoastLibrary.normalizeLanguage('Tamil'), 'Tamil');
      expect(RoastLibrary.normalizeLanguage('ta'), 'Tamil');
      expect(RoastLibrary.normalizeLanguage('Hindi'), 'Hindi');
      expect(RoastLibrary.normalizeLanguage('hi'), 'Hindi');
      expect(RoastLibrary.normalizeLanguage('Telugu'), 'Telugu');
      expect(RoastLibrary.normalizeLanguage('te'), 'Telugu');
      expect(RoastLibrary.normalizeLanguage('Kannada'), 'Kannada');
      expect(RoastLibrary.normalizeLanguage('kn'), 'Kannada');
      expect(RoastLibrary.normalizeLanguage('Malayalam'), 'Malayalam');
      expect(RoastLibrary.normalizeLanguage('ml'), 'Malayalam');
      expect(RoastLibrary.normalizeLanguage('unknown'), 'English');
    });

    // ── Test 15: Multilingual Output for All 6 Languages ────────────────────
    test('15. Generating roasts across all 6 languages outputs localized content', () {
      final testTxs = [
        Transaction(id: '1', title: 'Coffee', amount: 300.0, type: TransactionType.expense, category: 'Food & Dining', icon: Icons.fastfood, categoryColor: Colors.orange, date: now),
        Transaction(id: '2', title: 'Lunch', amount: 800.0, type: TransactionType.expense, category: 'Food & Dining', icon: Icons.fastfood, categoryColor: Colors.orange, date: now),
        Transaction(id: '3', title: 'Dinner', amount: 1200.0, type: TransactionType.expense, category: 'Food & Dining', icon: Icons.fastfood, categoryColor: Colors.orange, date: now),
      ];

      const langs = ['English', 'Tamil', 'Telugu', 'Hindi', 'Malayalam', 'Kannada'];
      for (final lang in langs) {
        final roast = DynamicRoastEngine.generateRoast(
          transactions: testTxs,
          language: lang,
          intensity: RoastIntensity.savage,
        );

        expect(roast.language, lang);
        expect(roast.text.trim().isNotEmpty, isTrue);
      }
    });

    // ── Test 16: Model Serialization and Deserialization ────────────────────
    test('16. RoastItem toJson and fromJson preserves intensity, situation and fields', () {
      const original = RoastItem(
        id: 'test_r1',
        language: 'Tamil',
        text: 'Test roast content',
        category: 'Food & Dining',
        mascotEmoji: '🔥',
        situation: RoastCategory.foodDining,
        intensity: RoastIntensity.brutal,
      );

      final json = original.toJson();
      expect(json['id'], 'test_r1');
      expect(json['intensity'], 'brutal');
      expect(json['situation'], 'foodDining');

      final deserialized = RoastItem.fromJson(json);
      expect(deserialized.id, original.id);
      expect(deserialized.language, original.language);
      expect(deserialized.text, original.text);
      expect(deserialized.category, original.category);
      expect(deserialized.mascotEmoji, original.mascotEmoji);
      expect(deserialized.situation, original.situation);
      expect(deserialized.intensity, original.intensity);
    });

    // ── Test 17: AppState Intensity Persistence & Dynamic Updates ───────────
    test('17. AppState supports setting roast intensity and triggers updates', () {
      final appState = AppState();
      expect(appState.roastIntensity, RoastIntensity.savage);

      appState.setRoastIntensity(RoastIntensity.brutal);
      expect(appState.roastIntensity, RoastIntensity.brutal);

      appState.setRoastIntensity(RoastIntensity.friendly);
      expect(appState.roastIntensity, RoastIntensity.friendly);
    });

    // ── Test 18: Currency Symbol Formatting ─────────────────────────────────
    test('18. Currency symbol formatting adapts properly (₹, \$, etc.)', () {
      final formattedRupee = RoastCalculationData.formatCurrency(5400.0, symbol: '₹');
      expect(formattedRupee, '₹5,400');

      final formattedDollar = RoastCalculationData.formatCurrency(12500.50, symbol: r'$');
      expect(formattedDollar, r'$12,500.50');
    });

    // ── Test 19: Data Sufficiency Guard Progression ─────────────────────────
    test('19. Data sufficiency progression: 0 tx -> 1 tx -> 2 tx -> 3 tx', () {
      // 0 tx: Empty wallet
      final r0 = DynamicRoastEngine.generateRoast(transactions: const []);
      expect(r0.situation, RoastCategory.newUserEmpty);

      // 1 expense tx: Insufficient history
      final tx1 = Transaction(id: '1', title: 'Food', amount: 100.0, type: TransactionType.expense, category: 'Food', icon: Icons.fastfood, categoryColor: Colors.orange, date: now);
      final r1 = DynamicRoastEngine.generateRoast(transactions: [tx1]);
      expect(r1.situation, RoastCategory.insufficientHistory);

      // 2 expense txs: Insufficient history
      final tx2 = Transaction(id: '2', title: 'Tea', amount: 50.0, type: TransactionType.expense, category: 'Food', icon: Icons.fastfood, categoryColor: Colors.orange, date: now);
      final r2 = DynamicRoastEngine.generateRoast(transactions: [tx1, tx2]);
      expect(r2.situation, RoastCategory.insufficientHistory);

      // 3 expense txs: Full personalized roast unlocked!
      final tx3 = Transaction(id: '3', title: 'Dinner', amount: 500.0, type: TransactionType.expense, category: 'Food & Dining', icon: Icons.fastfood, categoryColor: Colors.orange, date: now);
      final r3 = DynamicRoastEngine.generateRoast(transactions: [tx1, tx2, tx3]);
      expect(r3.situation, isNot(RoastCategory.insufficientHistory));
      expect(r3.situation, isNot(RoastCategory.newUserEmpty));
    });

    // ── Test 20: Next Roast Cycling ─────────────────────────────────────────
    test('20. DynamicRoastEngine.getMatchingRoasts returns multiple valid candidates for cycling', () {
      final activeTxs = [
        Transaction(id: '1', title: 'Sneakers', amount: 3000.0, type: TransactionType.expense, category: 'Shopping', icon: Icons.shopping_bag, categoryColor: Colors.purple, date: now),
        Transaction(id: '2', title: 'Watch', amount: 5000.0, type: TransactionType.expense, category: 'Shopping', icon: Icons.shopping_bag, categoryColor: Colors.purple, date: now),
        Transaction(id: '3', title: 'Headphones', amount: 4000.0, type: TransactionType.expense, category: 'Shopping', icon: Icons.shopping_bag, categoryColor: Colors.purple, date: now),
      ];

      final matching = DynamicRoastEngine.getMatchingRoasts(
        transactions: activeTxs,
        intensity: RoastIntensity.savage,
        language: 'English',
      );

      expect(matching.length, greaterThanOrEqualTo(2), reason: 'Must return candidate pool for cycling');
      for (final r in matching) {
        expect(r.text.trim().isNotEmpty, isTrue);
      }
    });
  });
}
