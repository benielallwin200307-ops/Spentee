import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/services/financial_intelligence_engine.dart';

void main() {
  group('Spentee AI – Personalised Financial Insights Test Suite', () {
    final fixedRefDate = DateTime(2026, 10, 20, 12, 0); // October 2026 (day 20)

    test('1. Zero Data State: Correct DataSufficiencyStatus and welcoming prompt', () {
      final insights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
        transactions: [],
        budgets: [],
        referenceDate: fixedRefDate,
      );

      expect(insights.sufficiencyStatus, equals(DataSufficiencyStatus.zeroData));
      expect(insights.totalIncome, equals(0.0));
      expect(insights.totalExpense, equals(0.0));
      expect(insights.netSavings, equals(0.0));
      expect(insights.savingsRate, equals(0.0));
      expect(insights.quickInsightTitle, equals('Start Your Financial Journey'));

      // Test Hiro deterministic queries in zero data state
      final summaryResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Monthly financial summary',
        transactions: [],
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(summaryResp, isNotNull);
      expect(summaryResp!.text, contains("Start recording your income and expenses. I'll analyse your financial activity and help you make better money decisions."));
      expect(summaryResp.actionButtons, contains('Add an expense'));
      expect(summaryResp.actionButtons, contains('Add income'));

      final spendingResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Spending analysis',
        transactions: [],
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(spendingResp, isNotNull);
      expect(spendingResp!.text, contains("Start recording your income and expenses"));
    });

    test('2. Income Only State: Acknowledges income and requests expenses', () {
      final incomeTxs = [
        Transaction(
          id: 'tx_inc_1',
          title: 'Monthly Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.work_rounded,
          categoryColor: Colors.green,
          date: DateTime(2026, 10, 1, 10, 0),
        ),
      ];

      final insights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
        transactions: incomeTxs,
        budgets: [],
        referenceDate: fixedRefDate,
      );

      expect(insights.sufficiencyStatus, equals(DataSufficiencyStatus.incomeOnly));
      expect(insights.totalIncome, equals(50000.0));
      expect(insights.totalExpense, equals(0.0));
      expect(insights.quickInsightTitle, equals('Income Recorded'));

      final summaryResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Monthly financial summary',
        transactions: incomeTxs,
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(summaryResp, isNotNull);
      expect(summaryResp!.text, contains("You have recorded income, but there isn't enough expense data yet to analyse your spending."));
      expect(summaryResp.text, contains('50,000'));
      expect(summaryResp.actionButtons, contains('Add an expense'));
    });

    test('3. Expenses Only State: Prompts user to record income to calculate savings rate', () {
      final expenseTxs = [
        Transaction(
          id: 'tx_exp_1',
          title: 'Groceries',
          amount: 4500.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.shopping_basket_rounded,
          categoryColor: Colors.orange,
          date: DateTime(2026, 10, 5, 14, 0),
        ),
      ];

      final insights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
        transactions: expenseTxs,
        budgets: [],
        referenceDate: fixedRefDate,
      );

      expect(insights.sufficiencyStatus, equals(DataSufficiencyStatus.expensesOnly));
      expect(insights.totalIncome, equals(0.0));
      expect(insights.totalExpense, equals(4500.0));
      expect(insights.quickInsightTitle, equals('Spending Recorded'));

      final summaryResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Monthly financial summary',
        transactions: expenseTxs,
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(summaryResp, isNotNull);
      expect(summaryResp!.text, contains('no income has been recorded yet'));
      expect(summaryResp.actionButtons, contains('Add income'));

      final savingsResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Savings insights',
        transactions: expenseTxs,
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(savingsResp, isNotNull);
      expect(savingsResp!.text, contains('no income has been recorded yet'));
    });

    test('4. Spending Analysis: Highest and lowest categories, category breakdown, MoM spike detection', () {
      final currentMonthTxs = [
        Transaction(
          id: 'tx_food',
          title: 'Dinner at Bistro',
          amount: 6000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant_rounded,
          categoryColor: Colors.pink,
          date: DateTime(2026, 10, 8, 20, 0),
        ),
        Transaction(
          id: 'tx_shopping',
          title: 'Autumn Jacket',
          amount: 3000.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag_rounded,
          categoryColor: Colors.purple,
          date: DateTime(2026, 10, 12, 16, 0),
        ),
        Transaction(
          id: 'tx_transport',
          title: 'Cab ride',
          amount: 1000.0,
          type: TransactionType.expense,
          category: 'Transport',
          icon: Icons.directions_car_rounded,
          categoryColor: Colors.cyan,
          date: DateTime(2026, 10, 14, 11, 0),
        ),
      ];

      // Previous month transactions (September 2026) for spike comparison
      final prevMonthTxs = [
        Transaction(
          id: 'tx_prev_food',
          title: 'September Food',
          amount: 3000.0, // Food increased from 3000 to 6000 (+100% spike)
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant_rounded,
          categoryColor: Colors.pink,
          date: DateTime(2026, 9, 15, 12, 0),
        ),
        Transaction(
          id: 'tx_prev_transport',
          title: 'September Transport',
          amount: 1200.0,
          type: TransactionType.expense,
          category: 'Transport',
          icon: Icons.directions_car_rounded,
          categoryColor: Colors.cyan,
          date: DateTime(2026, 9, 20, 12, 0),
        ),
      ];

      final allTxs = [...currentMonthTxs, ...prevMonthTxs];

      final insights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
        transactions: allTxs,
        budgets: [],
        referenceDate: fixedRefDate,
      );

      expect(insights.totalExpense, equals(10000.0));
      expect(insights.highestCategory, equals('Food & Dining'));
      expect(insights.highestCategoryAmount, equals(6000.0));
      expect(insights.highestCategoryPercent, equals(60.0));
      expect(insights.lowestCategory, equals('Transport'));
      expect(insights.lowestCategoryAmount, equals(1000.0));
      expect(insights.lowestCategoryPercent, equals(10.0));
      expect(insights.hasPreviousMonthData, isTrue);
      expect(insights.unusualSpikes, isNotEmpty);
      expect(insights.unusualSpikes.first, contains('Food & Dining'));

      final spendingResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Spending analysis',
        transactions: allTxs,
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(spendingResp, isNotNull);
      expect(spendingResp!.text, contains('**Total Spending:** **₹10,000**'));
      expect(spendingResp.text, contains('**Highest Spending Category:** **Food & Dining** — ₹6,000 (60.0% of expenses)'));
      expect(spendingResp.text, contains('**Lowest Spending Category:** **Transport** — ₹1,000 (10.0% of expenses)'));
      expect(spendingResp.text, contains('Unusual Spikes:'));
    });

    test('5. Income Analysis: Income sources, shares, and MoM stability', () {
      final incomeTxs = [
        Transaction(
          id: 'tx_sal',
          title: 'Corporate Salary',
          amount: 60000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.work_rounded,
          categoryColor: Colors.green,
          date: DateTime(2026, 10, 1, 10, 0),
        ),
        Transaction(
          id: 'tx_free',
          title: 'App Design Project',
          amount: 15000.0,
          type: TransactionType.income,
          category: 'Freelance',
          icon: Icons.laptop_rounded,
          categoryColor: Colors.blue,
          date: DateTime(2026, 10, 15, 14, 0),
        ),
        // September income for MoM comparison
        Transaction(
          id: 'tx_prev_sal',
          title: 'September Salary',
          amount: 60000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.work_rounded,
          categoryColor: Colors.green,
          date: DateTime(2026, 9, 1, 10, 0),
        ),
      ];

      final insights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
        transactions: incomeTxs,
        budgets: [],
        referenceDate: fixedRefDate,
      );

      expect(insights.totalIncome, equals(75000.0));
      expect(insights.categoryIncome['Salary'], equals(60000.0));
      expect(insights.categoryIncome['Freelance'], equals(15000.0));
      expect(insights.hasPreviousMonthData, isTrue);

      final incomeResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Income analysis',
        transactions: incomeTxs,
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(incomeResp, isNotNull);
      expect(incomeResp!.text, contains('**Total Income:** **₹75,000**'));
      expect(incomeResp.text, contains('**Primary Income Source:** **Salary**'));
      expect(incomeResp.text, contains('**Freelance**: ₹15,000'));
      expect(incomeResp.text, contains('**Previous Month Income:** ₹60,000'));
      expect(incomeResp.text, contains('**Income Change:** +25.0%'));
    });

    test('6. Savings Insights: Net savings, savings rate, deficit alert, and realistic target', () {
      // Case A: Healthy Savings
      final healthyTxs = [
        Transaction(
          id: 'tx_inc',
          title: 'Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.work,
          categoryColor: Colors.green,
          date: DateTime(2026, 10, 1),
        ),
        Transaction(
          id: 'tx_exp',
          title: 'Expenses',
          amount: 30000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: DateTime(2026, 10, 5),
        ),
      ];

      final healthyInsights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
        transactions: healthyTxs,
        budgets: [],
        referenceDate: fixedRefDate,
      );

      expect(healthyInsights.netSavings, equals(20000.0));
      expect(healthyInsights.savingsRate, equals(40.0));
      expect(healthyInsights.isDeficit, isFalse);

      final savingsResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Savings insights',
        transactions: healthyTxs,
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(savingsResp, isNotNull);
      expect(savingsResp!.text, contains('**Net Savings:** **₹20,000**'));
      expect(savingsResp.text, contains('**Savings Rate:** **40.0%**'));
      expect(savingsResp.text, contains('Realistic Savings Target:'));

      // Case B: Deficit Situation
      final deficitTxs = [
        Transaction(
          id: 'tx_inc_small',
          title: 'Part-time',
          amount: 20000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.work,
          categoryColor: Colors.green,
          date: DateTime(2026, 10, 1),
        ),
        Transaction(
          id: 'tx_exp_big',
          title: 'Rent & Living',
          amount: 28000.0,
          type: TransactionType.expense,
          category: 'Bills & Utilities',
          icon: Icons.receipt,
          categoryColor: Colors.red,
          date: DateTime(2026, 10, 5),
        ),
      ];

      final deficitInsights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
        transactions: deficitTxs,
        budgets: [],
        referenceDate: fixedRefDate,
      );

      expect(deficitInsights.isDeficit, isTrue);
      expect(deficitInsights.netSavings, equals(-8000.0));

      final deficitResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Savings insights',
        transactions: deficitTxs,
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(deficitResp, isNotNull);
      expect(deficitResp!.text, contains('**Net Deficit:** **-₹8,000**'));
      expect(deficitResp.text, contains('Immediate Recovery Target:'));
    });

    test('7. Budget Insights: Exceeded, near-limit, healthy statuses and reallocation advice', () {
      final txs = [
        Transaction(
          id: 'tx_food',
          title: 'Food Spends',
          amount: 11000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: DateTime(2026, 10, 10),
        ),
        Transaction(
          id: 'tx_shop',
          title: 'Shopping Spends',
          amount: 4200.0,
          type: TransactionType.expense,
          category: 'Shopping',
          icon: Icons.shopping_bag,
          categoryColor: Colors.purple,
          date: DateTime(2026, 10, 12),
        ),
        Transaction(
          id: 'tx_trans',
          title: 'Transport Spends',
          amount: 1000.0,
          type: TransactionType.expense,
          category: 'Transport',
          icon: Icons.car_rental,
          categoryColor: Colors.cyan,
          date: DateTime(2026, 10, 15),
        ),
      ];

      final budgets = [
        // Limit: 10,000, Spent: 11,000 -> Exceeded
        Budget(
          id: 'b_food',
          category: 'Food & Dining',
          limitAmount: 10000.0,
          year: 2026,
          month: 10,
        ),
        // Limit: 5,000, Spent: 4,200 (84%) -> Near Limit
        Budget(
          id: 'b_shop',
          category: 'Shopping',
          limitAmount: 5000.0,
          year: 2026,
          month: 10,
        ),
        // Limit: 4,000, Spent: 1,000 (25%) -> Healthy
        Budget(
          id: 'b_trans',
          category: 'Transport',
          limitAmount: 4000.0,
          year: 2026,
          month: 10,
        ),
      ];

      final insights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
        transactions: txs,
        budgets: budgets,
        referenceDate: fixedRefDate,
      );

      expect(insights.budgets.length, equals(3));
      final foodDetail = insights.budgets.firstWhere((b) => b.category == 'Food & Dining');
      expect(foodDetail.status, equals(BudgetStatusType.exceeded));
      expect(foodDetail.spent, equals(11000.0));

      final shopDetail = insights.budgets.firstWhere((b) => b.category == 'Shopping');
      expect(shopDetail.status, equals(BudgetStatusType.nearLimit));

      final transDetail = insights.budgets.firstWhere((b) => b.category == 'Transport');
      expect(transDetail.status, equals(BudgetStatusType.healthy));
      expect(transDetail.remaining, equals(3000.0));

      final budgetResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Budget insights',
        transactions: txs,
        budgets: budgets,
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(budgetResp, isNotNull);
      expect(budgetResp!.text, contains('Exceeded (+₹1,000)'));
      expect(budgetResp.text, contains('Near Limit'));
      expect(budgetResp.text, contains('Healthy'));
      expect(budgetResp.text, contains('Reallocation Opportunity:'));
    });

    test('8. Monthly Financial Summary: Full structured report with recommendations', () {
      final txs = [
        Transaction(
          id: 'tx_income',
          title: 'Salary',
          amount: 80000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.work,
          categoryColor: Colors.green,
          date: DateTime(2026, 10, 1),
        ),
        Transaction(
          id: 'tx_expense',
          title: 'Dining Out',
          amount: 32000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: DateTime(2026, 10, 10),
        ),
      ];

      final budgets = [
        Budget(
          id: 'b_food',
          category: 'Food & Dining',
          limitAmount: 30000.0,
          year: 2026,
          month: 10,
        ),
      ];

      final summaryResp = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Monthly financial summary',
        transactions: txs,
        budgets: budgets,
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );

      expect(summaryResp, isNotNull);
      expect(summaryResp!.text, contains('Monthly Financial Summary (October 2026):'));
      expect(summaryResp.text, contains('Total Income:** ₹80,000'));
      expect(summaryResp.text, contains('Total Expenses:** ₹32,000'));
      expect(summaryResp.text, contains('Net Savings:** **₹48,000** (60.0% savings rate)'));
      expect(summaryResp.text, contains('Top Spending Category:** **Food & Dining**'));
      expect(summaryResp.text, contains('Recommendations:'));
    });

    test('9. Spending Behaviour: Pacing, essential vs discretionary, and data sufficiency guard', () {
      final txs = [
        Transaction(
          id: 'tx_groceries',
          title: 'Supermarket Groceries',
          amount: 8000.0, // Essential
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.shopping_basket,
          categoryColor: Colors.green,
          date: DateTime(2026, 10, 5),
        ),
        Transaction(
          id: 'tx_dining',
          title: 'Weekend Dining',
          amount: 6000.0, // Discretionary
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: DateTime(2026, 10, 10),
        ),
      ];

      // Case A: No previous month data -> Historical claims must be strictly guarded
      final behaviourRespWithoutHistory = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Spending behaviour',
        transactions: txs,
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate, // day 20
      );
      expect(behaviourRespWithoutHistory, isNotNull);
      expect(behaviourRespWithoutHistory!.text, contains('Daily Spending Pace:** **₹700/day**')); // 14,000 / 20 days
      expect(behaviourRespWithoutHistory.text, contains('Essential Living Spending:** ₹8,000 (57%)'));
      expect(behaviourRespWithoutHistory.text, contains('Discretionary Spending:** ₹6,000 (43%)'));
      expect(behaviourRespWithoutHistory.text, contains('Spentee requires at least two consecutive months of records to establish recurring behavioural trends.'));

      // Case B: With previous month data -> MoM behaviour is evaluated
      final txsWithPrev = [
        ...txs,
        Transaction(
          id: 'tx_prev_groceries',
          title: 'September Groceries',
          amount: 7000.0,
          type: TransactionType.expense,
          category: 'Groceries',
          icon: Icons.shopping_basket,
          categoryColor: Colors.green,
          date: DateTime(2026, 9, 15),
        ),
      ];

      final behaviourRespWithHistory = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'Spending behaviour',
        transactions: txsWithPrev,
        budgets: [],
        savingsGoals: [],
        userConsented: true,
        referenceDate: fixedRefDate,
      );
      expect(behaviourRespWithHistory, isNotNull);
      expect(behaviourRespWithHistory!.text, contains('Month-over-Month Behaviour:'));
      expect(behaviourRespWithHistory.text, contains('Overall Spending Change:'));
    });

    test('10. Financial Rules & Accounting Isolation: Transfers and Debts are excluded', () {
      final mixedTxs = [
        Transaction(
          id: 'tx_income_real',
          title: 'Salary',
          amount: 50000.0,
          type: TransactionType.income,
          category: 'Salary',
          icon: Icons.work,
          categoryColor: Colors.green,
          date: DateTime(2026, 10, 1),
        ),
        Transaction(
          id: 'tx_transfer',
          title: 'Transfer to Savings',
          amount: 20000.0,
          type: TransactionType.transfer, // Internal transfer - MUST NOT count as expense or income
          category: 'Transfer',
          icon: Icons.swap_horiz,
          categoryColor: Colors.grey,
          date: DateTime(2026, 10, 2),
        ),
        Transaction(
          id: 'tx_lent',
          title: 'Loan to Rahul',
          amount: 5000.0,
          type: TransactionType.lent, // Debt asset - MUST NOT count as expense
          category: 'Lent',
          icon: Icons.handshake,
          categoryColor: Colors.blue,
          date: DateTime(2026, 10, 3),
        ),
        Transaction(
          id: 'tx_expense_real',
          title: 'Living Expense',
          amount: 15000.0,
          type: TransactionType.expense,
          category: 'Food & Dining',
          icon: Icons.restaurant,
          categoryColor: Colors.pink,
          date: DateTime(2026, 10, 4),
        ),
      ];

      final insights = FinancialIntelligenceEngine.instance.generatePersonalizedInsights(
        transactions: mixedTxs,
        budgets: [],
        referenceDate: fixedRefDate,
      );

      // Verify that transfers and lent amounts are strictly isolated
      expect(insights.totalIncome, equals(50000.0));
      expect(insights.totalExpense, equals(15000.0)); // Exactly 15,000, not 40,000!
      expect(insights.netSavings, equals(35000.0));
      expect(insights.savingsRate, equals(70.0));
    });
  });
}
