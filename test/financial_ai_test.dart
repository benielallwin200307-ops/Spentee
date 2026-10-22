import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/savings_goal.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/services/ai_chat_service.dart';
import 'package:spentee/services/financial_intelligence_engine.dart';

void main() {
  group('Spentee AI Deterministic Financial Intelligence Engine Tests', () {
    final fixedNow = DateTime(2026, 10, 19, 14, 30);

    // Known test fixtures
    final testTransactions = [
      // Today's expenses (Oct 19, 2026)
      Transaction(
        id: 'tx_today_1',
        title: 'Morning Espresso',
        amount: 150.0,
        type: TransactionType.expense,
        category: 'Food & Dining',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.pink,
        date: DateTime(2026, 10, 19, 8, 30),
      ),
      Transaction(
        id: 'tx_today_2',
        title: 'Metro Commute',
        amount: 60.0,
        type: TransactionType.expense,
        category: 'Transport',
        icon: Icons.directions_car_rounded,
        categoryColor: Colors.cyan,
        date: DateTime(2026, 10, 19, 9, 15),
      ),

      // Month expenses (October 2026)
      Transaction(
        id: 'tx_oct_food',
        title: 'Family Dinner',
        amount: 5270.0,
        type: TransactionType.expense,
        category: 'Food & Dining',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.pink,
        date: DateTime(2026, 10, 10, 19, 0),
      ),
      Transaction(
        id: 'tx_oct_shop',
        title: 'Winter Jacket',
        amount: 4680.0,
        type: TransactionType.expense,
        category: 'Shopping',
        icon: Icons.shopping_bag_rounded,
        categoryColor: Colors.purple,
        date: DateTime(2026, 10, 12, 16, 0),
      ),
      Transaction(
        id: 'tx_oct_trans',
        title: 'Fuel',
        amount: 2740.0,
        type: TransactionType.expense,
        category: 'Transport',
        icon: Icons.directions_car_rounded,
        categoryColor: Colors.cyan,
        date: DateTime(2026, 10, 5, 11, 0),
      ),
      Transaction(
        id: 'tx_oct_bills',
        title: 'Electricity & Internet',
        amount: 2100.0,
        type: TransactionType.expense,
        category: 'Bills & Utilities',
        icon: Icons.receipt_long_rounded,
        categoryColor: Colors.orange,
        date: DateTime(2026, 10, 3, 10, 0),
      ),
      Transaction(
        id: 'tx_oct_ent',
        title: 'Movie Premiere',
        amount: 1420.0,
        type: TransactionType.expense,
        category: 'Entertainment',
        icon: Icons.sports_esports_rounded,
        categoryColor: Colors.blue,
        date: DateTime(2026, 10, 8, 20, 0),
      ),
      Transaction(
        id: 'tx_oct_oth',
        title: 'Stationery Supplies',
        amount: 1000.0,
        type: TransactionType.expense,
        category: 'Others',
        icon: Icons.more_horiz_rounded,
        categoryColor: Colors.green,
        date: DateTime(2026, 10, 7, 15, 0),
      ),

      // Month Earned Income (October 2026)
      Transaction(
        id: 'tx_oct_salary',
        title: 'October Salary',
        amount: 50000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.teal,
        date: DateTime(2026, 10, 1, 9, 0),
      ),

      // Transfers: MUST BE STRICTLY EXCLUDED from spending & income
      Transaction(
        id: 'tx_oct_transfer1',
        title: 'Bank Account Transfer',
        amount: 15000.0,
        type: TransactionType.transfer,
        category: 'Bank Transfer',
        icon: Icons.account_balance_rounded,
        categoryColor: Colors.blue,
        date: DateTime(2026, 10, 2, 10, 0),
      ),
      Transaction(
        id: 'tx_oct_transfer2',
        title: 'Sent to Friend',
        amount: 3000.0,
        type: TransactionType.transfer,
        category: 'Sent to Friend',
        icon: Icons.person_rounded,
        categoryColor: Colors.purple,
        date: DateTime(2026, 10, 6, 14, 0),
      ),
      Transaction(
        id: 'tx_oct_transfer3',
        title: 'Vault Allocation',
        amount: 5000.0,
        type: TransactionType.transfer,
        category: 'Savings Vault',
        icon: Icons.lock_clock_rounded,
        categoryColor: Colors.teal,
        date: DateTime(2026, 10, 4, 18, 0),
      ),

      // Refund: MUST OFFSET EXPENSE and NOT DOUBLE-COUNT AS EARNED INCOME
      Transaction(
        id: 'tx_oct_refund',
        title: 'Amazon Return Refund',
        amount: 420.0,
        type: TransactionType.income,
        category: 'Shopping',
        icon: Icons.receipt_rounded,
        categoryColor: Colors.purple,
        date: DateTime(2026, 10, 14, 12, 0),
        note: 'Order cancellation refund',
      ),

      // Debt & Loans: Lent & Repayments
      Transaction(
        id: 'tx_oct_lent',
        title: 'Lent to Alex for emergency',
        amount: 2000.0,
        type: TransactionType.expense,
        category: 'Sent to Friend',
        icon: Icons.person_rounded,
        categoryColor: Colors.blue,
        date: DateTime(2026, 10, 9, 12, 0),
        note: 'Money lent to Alex',
      ),
      Transaction(
        id: 'tx_oct_repay_rec',
        title: 'Repayment from Alex',
        amount: 1000.0,
        type: TransactionType.income,
        category: 'Bank Transfer',
        icon: Icons.account_balance_rounded,
        categoryColor: Colors.green,
        date: DateTime(2026, 10, 16, 17, 0),
        note: 'Repaid partial loan by Alex',
      ),

      // Previous Month: September 2026 (for comparison verification)
      Transaction(
        id: 'tx_sep_sal',
        title: 'September Salary',
        amount: 50000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.teal,
        date: DateTime(2026, 9, 1, 9, 0),
      ),
      Transaction(
        id: 'tx_sep_food',
        title: 'Dining Out',
        amount: 6000.0,
        type: TransactionType.expense,
        category: 'Food & Dining',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.pink,
        date: DateTime(2026, 9, 10, 20, 0),
      ),
      Transaction(
        id: 'tx_sep_shop',
        title: 'Apparel',
        amount: 4000.0,
        type: TransactionType.expense,
        category: 'Shopping',
        icon: Icons.shopping_bag_rounded,
        categoryColor: Colors.purple,
        date: DateTime(2026, 9, 15, 14, 0),
      ),
    ];

    final testBudgets = [
      Budget(
        id: 'b_food',
        category: 'Food & Dining',
        limitAmount: 6000.0,
        period: 'Monthly',
        year: 2026,
        month: 10,
      ),
      Budget(
        id: 'b_shop',
        category: 'Shopping',
        limitAmount: 5000.0,
        period: 'Monthly',
        year: 2026,
        month: 10,
      ),
    ];

    final testSavingsGoals = <SavingsGoal>[
      SavingsGoal(
        id: 'sg_existing',
        title: 'Emergency Cushion',
        targetAmount: 25000.0,
        currentAmount: 8500.0,
        createdAt: DateTime(2026, 9, 15),
      ),
    ];

    test('1. Deterministic calculation excludes transfers from income and expenses', () {
      final audit = FinancialIntelligenceEngine.instance.computeAudit(
        transactions: testTransactions,
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31, 23, 59, 59),
      );

      // Transfers total: 15,000 + 3,000 + 5,000 = 23,000
      expect(audit.totalTransfers, 23000.0);

      // Earned Income: 50,000 (transfers & loan repayments are strictly excluded)
      expect(audit.totalIncome, 50000.0);

      // Gross expense: 150 + 60 + 5270 + 4680 + 2740 + 2100 + 1420 + 1000 = 17,420
      // Net expense after refund offset (420): 17,420 - 420 = 17,000
      expect(audit.totalRefunds, 420.0);
      expect(audit.totalExpense, 17000.0);

      // Net Savings: 50,000 - 17,000 = 33,000
      expect(audit.netSavings, 33000.0);
    });

    test('2. "How much did I spend today?" returns exact deterministic total', () {
      final res = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'How much did I spend today?',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsented: true,
        referenceDate: fixedNow,
      );

      expect(res, isNotNull);
      // Today expenses: 150 + 60 = 210
      expect(res!.text, contains('₹210'));
      expect(res.text, contains('Morning Espresso'));
      expect(res.text, contains('Metro Commute'));
      expect(res.handled, isTrue);
    });

    test('3. "How much did I earn this month?" returns exact income without double-counting', () {
      final res = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'How much did I earn this month?',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsented: true,
        referenceDate: fixedNow,
      );

      expect(res, isNotNull);
      // October salary = 50,000
      expect(res!.text, contains('₹50,000'));
      // Transfers and repayments explicitly separated
      expect(res.text, contains('Internal Transfers'));
      expect(res.text, contains('₹23,000'));
      expect(res.text, contains('Loan Repayments Received'));
      expect(res.text, contains('₹1,000'));
    });

    test('4. "Where did most of my money go?" accurately identifies top category', () {
      final res = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Where did most of my money go?',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsented: true,
        referenceDate: fixedNow,
      );

      expect(res, isNotNull);
      // Top category in Oct is Food & Dining (150 + 5270 = 5420)
      expect(res!.text, contains('Food & Dining'));
      expect(res.text, contains('₹5,420'));
      expect(res.text, contains('Shopping'));
    });

    test('5. "How much budget do I have left?" evaluates real saved budgets', () {
      final res = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'How much budget do I have left?',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsented: true,
        referenceDate: fixedNow,
      );

      expect(res, isNotNull);
      // Food & Dining: Limit 6000, spent 5420, remaining 580
      expect(res!.text, contains('Food & Dining'));
      expect(res.text, contains('₹5,420 of ₹6,000'));
      expect(res.text, contains('Remaining: **₹580**'));

      // Shopping: Limit 5000, spent 4680, remaining 320
      expect(res.text, contains('Shopping'));
      expect(res.text, contains('₹4,680 of ₹5,000'));
      expect(res.text, contains('Remaining: **₹320**'));
    });

    test('6. "Compare this month with last month" calculates deterministic delta', () {
      final res = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Compare this month with last month.',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsented: true,
        referenceDate: fixedNow,
      );

      expect(res, isNotNull);
      // Sept spend: 6000 + 4000 = 10,000
      expect(res!.text, contains('September: ₹10,000'));
      // Oct spend: 17,000
      expect(res.text, contains('October: ₹17,000'));
      // Difference: +7,000 (+70.0%)
      expect(res.text, contains('+₹7,000'));
      expect(res.text, contains('+70.0%'));
    });

    test('7. "How can I save ₹800 this month?" returns itemized plan and distinguishes suggestions from actual savings', () {
      final res = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'How can I save ₹800 this month?',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsented: true,
        referenceDate: fixedNow,
      );

      expect(res, isNotNull);
      expect(res!.text, contains('Personalized Plan to Save ₹800'));
      expect(res.text, contains('Food & Dining'));
      // Distinguishes suggestions from actual savings
      expect(res.text, contains('Important: These are proposed budget reduction targets, not realized savings'));
      // Does not claim an unpersisted goal is tracked
      expect(res.text, contains('Tap **"Create Savings Goal"** below to activate and persist this goal'));
      expect(res.actionButtons, contains('Create Savings Goal'));
      expect(res.suggestedSavingsAmount, 800.0);
    });

    test('8. When user has NOT consented, personalized advice requests consent without leaking data', () {
      final res = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'How can I save ₹800 this month?',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsented: false,
        referenceDate: fixedNow,
      );

      expect(res, isNotNull);
      expect(res!.needsConsent, isTrue);
      expect(res.text, contains('Data Privacy Consent Required'));
      expect(res.actionButtons, contains('Grant Permission & Analyze'));
    });

    test('9. Missing historical data or ambiguous queries return clear explanations, never inventing totals', () {
      // Missing year
      final missingYearRes = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'How much did I spend in 2021?',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsented: true,
        referenceDate: fixedNow,
      );

      expect(missingYearRes, isNotNull);
      expect(missingYearRes!.isAmbiguous, isTrue);
      expect(missingYearRes.text, contains('Missing Historical Data for 2021'));

      // Ambiguous unknown category
      final ambiguousCatRes = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'How much did I spend on luxury yacht cruise?',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsented: true,
        referenceDate: fixedNow,
      );

      expect(ambiguousCatRes, isNotNull);
      expect(ambiguousCatRes!.isAmbiguous, isTrue);
      expect(ambiguousCatRes.text, contains('Clarification Needed'));
      expect(ambiguousCatRes.text, contains('never invents or guesses numbers'));
    });

    test('10. buildMinimalSummary strictly enforces privacy consent', () {
      // Without consent
      final noConsentSummary = FinancialIntelligenceEngine.buildMinimalSummary(
        transactions: testTransactions,
        budgets: testBudgets,
        userConsented: false,
      );
      expect(noConsentSummary['consent'], isFalse);
      expect(noConsentSummary.containsKey('monthly_spend_total'), isFalse);

      // With consent
      final consentedSummary = FinancialIntelligenceEngine.buildMinimalSummary(
        transactions: testTransactions,
        budgets: testBudgets,
        userConsented: true,
      );
      expect(consentedSummary['consent'], isTrue);
      expect(consentedSummary['monthly_spend_total'], '17000');
      expect(consentedSummary['monthly_income_total'], '50000');
      // Contains only top 3 category percentages, NO raw transactions or notes
      expect(consentedSummary.containsKey('top_expense_categories_share'), isTrue);
      expect(consentedSummary.containsKey('transactions'), isFalse);
    });

    test('11. General questions route to backend or explain setup when offline without fake answers', () async {
      // A general query like "Explain SIPs for beginners" or "What is quantum computing"
      final response = await AiChatService.instance.generateResponse(
        query: 'What is a Systematic Investment Plan (SIP)?',
        transactions: testTransactions,
        budgets: testBudgets,
        savingsGoals: testSavingsGoals,
        userConsentedToDataAnalysis: false,
        userMascot: 'mascot_main',
        backendUrlOverride: 'http://127.0.0.1:59999', // Non-existent test port
      );

      expect(response.isUser, isFalse);
      // Must not return fake AI answer; must explain backend offline cleanly
      expect(response.text, contains('AI Backend Offline'));
      expect(response.text, contains('Retry Connection'));
      expect(response.actionButtons, contains('Retry Connection'));
      expect(response.actionButtons, contains('How much did I spend today?'));
    });

    test('12. Answer relevance: conceptual inquiries explain concepts directly without habit tangents', () async {
      final health = await AiChatService.instance.checkBackendHealth('http://localhost:3000');
      if (health['status'] == 'ok' && health['configured'] == true) {
        final response = await AiChatService.instance.generateResponse(
          query: 'What is compound interest? Explain in one sentence.',
          transactions: testTransactions,
          budgets: testBudgets,
          savingsGoals: testSavingsGoals,
          userConsentedToDataAnalysis: true,
          userMascot: 'mascot_main',
          backendUrlOverride: 'http://localhost:3000',
        );

        if (response.isError) {
          expect(
            response.text,
            anyOf(
              contains('Rate Limit'),
              contains('Backend Service Error'),
              contains('AI Backend Offline'),
            ),
          );
        } else if (response.text.contains('AI Backend Offline') || response.text.contains('ai backend offline')) {
          expect(response.text.toLowerCase(), contains('offline'));
        } else {
          expect(response.isUser, isFalse);
          final lower = response.text.toLowerCase();
          expect(lower, contains('interest'));
          expect(lower.contains('core principles of financial habits'), isFalse);
        }
      }
    });
  });
}
