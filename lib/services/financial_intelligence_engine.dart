import 'dart:math';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/lent_borrowed_record.dart';
import 'roast_engine.dart';

/// Represents a deterministic financial calculation result over a specific dataset and period.
class FinancialAuditSummary {
  final DateTime startDate;
  final DateTime endDate;
  final double grossExpense;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double totalTransfers;
  final double totalRefunds;
  final double totalMoneyLent;
  final double totalMoneyBorrowed;
  final double totalRepaymentsReceived;
  final double totalRepaymentsMade;
  final Map<String, double> categoryExpenses;
  final Map<String, double> categoryIncome;
  final String topCategory;
  final double topCategoryAmount;
  final int transactionCount;

  const FinancialAuditSummary({
    required this.startDate,
    required this.endDate,
    this.grossExpense = 0.0,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.totalTransfers,
    required this.totalRefunds,
    required this.totalMoneyLent,
    required this.totalMoneyBorrowed,
    required this.totalRepaymentsReceived,
    required this.totalRepaymentsMade,
    required this.categoryExpenses,
    required this.categoryIncome,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.transactionCount,
  });
}

/// The result returned by the deterministic engine to the chat layer.
class FinancialEngineResponse {
  final String text;
  final bool handled;
  final List<String> actionButtons;
  final bool hasPlanCard;
  final Map<String, dynamic>? planData;
  final bool needsConsent;
  final bool isAmbiguous;
  final double? suggestedSavingsAmount;
  final String? suggestedSavingsTitle;

  const FinancialEngineResponse({
    required this.text,
    this.handled = true,
    this.actionButtons = const [],
    this.hasPlanCard = false,
    this.planData,
    this.needsConsent = false,
    this.isAmbiguous = false,
    this.suggestedSavingsAmount,
    this.suggestedSavingsTitle,
  });
}

/// Data sufficiency status for financial insight generation.
enum DataSufficiencyStatus {
  zeroData,
  incomeOnly,
  expensesOnly,
  insufficientHistory,
  matureData,
}

/// Status of an individual budget in insights.
enum BudgetStatusType {
  exceeded,
  nearLimit,
  healthy,
}

/// Detailed breakdown of an individual category budget.
class BudgetInsightDetail {
  final String category;
  final double limit;
  final double spent;
  final double remaining;
  final double ratio;
  final BudgetStatusType status;

  const BudgetInsightDetail({
    required this.category,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.ratio,
    required this.status,
  });
}

/// Comprehensive, verified personalized financial insights container.
class PersonalizedFinancialInsights {
  final DateTime period;
  final DataSufficiencyStatus sufficiencyStatus;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final bool isDeficit;
  final String highestCategory;
  final double highestCategoryAmount;
  final double highestCategoryPercent;
  final String lowestCategory;
  final double lowestCategoryAmount;
  final double lowestCategoryPercent;
  final Map<String, double> categoryExpenses;
  final Map<String, double> categoryIncome;
  final List<BudgetInsightDetail> budgets;
  final double totalBudgetLimit;
  final double totalBudgetSpent;
  final double totalBudgetRemaining;
  final bool hasPreviousMonthData;
  final double previousMonthExpense;
  final double previousMonthIncome;
  final double expenseChangePercent;
  final double incomeChangePercent;
  final List<String> increasedCategories;
  final List<String> decreasedCategories;
  final List<String> unusualSpikes;
  final List<String> actionableRecommendations;
  final String quickInsightTitle;
  final String quickInsightSubtitle;

  const PersonalizedFinancialInsights({
    required this.period,
    required this.sufficiencyStatus,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.isDeficit,
    required this.highestCategory,
    required this.highestCategoryAmount,
    required this.highestCategoryPercent,
    required this.lowestCategory,
    required this.lowestCategoryAmount,
    required this.lowestCategoryPercent,
    required this.categoryExpenses,
    required this.categoryIncome,
    required this.budgets,
    required this.totalBudgetLimit,
    required this.totalBudgetSpent,
    required this.totalBudgetRemaining,
    required this.hasPreviousMonthData,
    required this.previousMonthExpense,
    required this.previousMonthIncome,
    required this.expenseChangePercent,
    required this.incomeChangePercent,
    required this.increasedCategories,
    required this.decreasedCategories,
    required this.unusualSpikes,
    required this.actionableRecommendations,
    required this.quickInsightTitle,
    required this.quickInsightSubtitle,
  });
}

/// A high-performance, deterministic Financial Intelligence Engine for Spentee.
/// Guarantees exact arithmetic, prevents double counting, strictly excludes transfers
/// from income/expense totals, handles debt/refund boundaries, and respects user privacy.
class FinancialIntelligenceEngine {
  FinancialIntelligenceEngine._();
  static final FinancialIntelligenceEngine instance =
      FinancialIntelligenceEngine._();

  // ───────────────────────────────────────────────────────────────────────────
  // 1. DETERMINISTIC TRANSACTION CLASSIFICATION HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  /// Checks if a transaction is a transfer between accounts or vaults.
  /// Transfers MUST NOT count as consumption expenses or earned income.
  static bool isTransfer(Transaction tx) {
    if (tx.type == TransactionType.transfer) return true;
    if (tx.isInvestment) return true;
    final cat = tx.category.toLowerCase().trim();
    final title = tx.title.toLowerCase().trim();
    return cat == 'bank transfer' ||
        cat == 'sent to friend' ||
        cat == 'savings vault' ||
        cat == 'wallet transfer' ||
        cat == 'own account transfer' ||
        title.contains('transfer') ||
        title.contains('vault deposit');
  }

  /// Checks if an entry is a refund or reimbursement.
  static bool isRefund(Transaction tx) {
    final note = tx.note.toLowerCase();
    final title = tx.title.toLowerCase();
    final cat = tx.category.toLowerCase();
    return note.contains('refund') ||
        note.contains('reimbursement') ||
        note.contains('cashback') ||
        title.contains('refund') ||
        title.contains('cashback') ||
        cat.contains('refund');
  }

  /// Checks if an entry is money lent out to someone (a receivable asset).
  static bool isMoneyLent(Transaction tx) {
    if (tx.type == TransactionType.lent || tx.isLent) return true;
    final note = tx.note.toLowerCase();
    final title = tx.title.toLowerCase();
    final cat = tx.category.toLowerCase();
    return cat == 'money lent' ||
        note.contains('lent') ||
        note.contains('loan given') ||
        note.contains('lend') ||
        title.contains('lent to') ||
        title.contains('loan to');
  }

  /// Checks if an entry is money borrowed from someone (a liability).
  static bool isMoneyBorrowed(Transaction tx) {
    if (tx.type == TransactionType.borrowed || tx.isBorrowed) return true;
    final note = tx.note.toLowerCase();
    final title = tx.title.toLowerCase();
    final cat = tx.category.toLowerCase();
    return cat == 'money borrowed' ||
        note.contains('borrowed') ||
        note.contains('loan taken') ||
        title.contains('borrowed from') ||
        title.contains('loan from');
  }

  /// Checks if an entry is a repayment for lent/borrowed money.
  static bool isRepayment(Transaction tx) {
    if (tx.type == TransactionType.repaymentReceived ||
        tx.type == TransactionType.repaymentMade ||
        tx.isRepaymentReceived ||
        tx.isRepaymentMade) {
      return true;
    }
    final note = tx.note.toLowerCase();
    final title = tx.title.toLowerCase();
    final cat = tx.category.toLowerCase();
    return cat == 'repayment received' ||
        cat == 'repayment made' ||
        note.contains('repaid') ||
        note.contains('repayment') ||
        note.contains('returned money') ||
        title.contains('repayment') ||
        title.contains('returned money');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. DETERMINISTIC FINANCIAL AUDIT & AGGREGATION
  // ───────────────────────────────────────────────────────────────────────────

  /// Computes exact financial metrics for a specific time range.
  FinancialAuditSummary computeAudit({
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    double grossIncome = 0.0;
    double grossExpense = 0.0;
    double totalTransfers = 0.0;
    double totalRefunds = 0.0;
    double moneyLent = 0.0;
    double moneyBorrowed = 0.0;
    double repaymentsReceived = 0.0;
    double repaymentsMade = 0.0;

    final Map<String, double> categoryExpenses = {};
    final Map<String, double> categoryIncome = {};
    int count = 0;

    for (final tx in transactions) {
      // Date boundary check [startDate, endDate] inclusive
      if (tx.date.isBefore(startDate) || tx.date.isAfter(endDate)) {
        continue;
      }
      count++;

      // 1. Refunds: Netting out against expenses to prevent double-counting
      if (isRefund(tx)) {
        totalRefunds += tx.amount;
        continue;
      }

      // 2. Money Lent: Outflow tracked as asset, not consumed expense
      if (isMoneyLent(tx)) {
        moneyLent += tx.amount;
        continue;
      }

      // 3. Money Borrowed: Inflow tracked as liability, not earned income
      if (isMoneyBorrowed(tx)) {
        moneyBorrowed += tx.amount;
        continue;
      }

      // 4. Repayments
      if (isRepayment(tx)) {
        if (tx.type == TransactionType.repaymentReceived ||
            tx.isRepaymentReceived ||
            tx.type == TransactionType.income) {
          repaymentsReceived += tx.amount;
        } else {
          repaymentsMade += tx.amount;
        }
        continue;
      }

      // 5. Transfers & Investments: Excluded from income and expense
      if (isTransfer(tx)) {
        totalTransfers += tx.amount;
        continue;
      }

      // 6. Standard Income
      if (tx.type == TransactionType.income) {
        grossIncome += tx.amount;
        categoryIncome[tx.category] =
            (categoryIncome[tx.category] ?? 0.0) + tx.amount;
      }

      // 7. Standard Expense
      if (tx.type == TransactionType.expense) {
        grossExpense += tx.amount;
        categoryExpenses[tx.category] =
            (categoryExpenses[tx.category] ?? 0.0) + tx.amount;
      }
    }

    // Net expense after subtracting received refunds from expense total
    final netExpense = max(0.0, grossExpense - totalRefunds);
    final netSavings = grossIncome - netExpense;

    String topCat = 'None';
    double topAmt = 0.0;
    categoryExpenses.forEach((cat, amt) {
      if (amt > topAmt) {
        topAmt = amt;
        topCat = cat;
      }
    });

    return FinancialAuditSummary(
      startDate: startDate,
      endDate: endDate,
      grossExpense: grossExpense,
      totalIncome: grossIncome,
      totalExpense: netExpense,
      netSavings: netSavings,
      totalTransfers: totalTransfers,
      totalRefunds: totalRefunds,
      totalMoneyLent: moneyLent,
      totalMoneyBorrowed: moneyBorrowed,
      totalRepaymentsReceived: repaymentsReceived,
      totalRepaymentsMade: repaymentsMade,
      categoryExpenses: categoryExpenses,
      categoryIncome: categoryIncome,
      topCategory: topCat,
      topCategoryAmount: topAmt,
      transactionCount: count,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2.5 COMPREHENSIVE PERSONALIZED FINANCIAL INSIGHTS GENERATOR
  // ───────────────────────────────────────────────────────────────────────────

  /// Generates a comprehensive, deterministically verified set of personalized financial
  /// insights based strictly on the user's authentic records. Never hallucinates or invents data.
  PersonalizedFinancialInsights generatePersonalizedInsights({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final audit = computeAudit(
      transactions: transactions,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final startOfPrevMonth = DateTime(prevYear, prevMonth, 1);
    final endOfPrevMonth = DateTime(prevYear, prevMonth + 1, 0, 23, 59, 59);

    final prevAudit = computeAudit(
      transactions: transactions,
      startDate: startOfPrevMonth,
      endDate: endOfPrevMonth,
    );

    final hasPreviousMonthData = prevAudit.transactionCount > 0 ||
        prevAudit.totalExpense > 0 ||
        prevAudit.totalIncome > 0;

    // Determine data sufficiency status
    DataSufficiencyStatus status;
    final hasAnyIncome = audit.totalIncome > 0 || transactions.any((t) => t.type == TransactionType.income);
    final hasAnyExpense = audit.totalExpense > 0 || transactions.any((t) => t.type == TransactionType.expense);

    if (transactions.isEmpty || (!hasAnyIncome && !hasAnyExpense)) {
      status = DataSufficiencyStatus.zeroData;
    } else if (audit.totalExpense == 0 && audit.totalIncome > 0) {
      status = DataSufficiencyStatus.incomeOnly;
    } else if (audit.totalIncome == 0 && audit.totalExpense > 0) {
      status = DataSufficiencyStatus.expensesOnly;
    } else if (!hasPreviousMonthData) {
      status = DataSufficiencyStatus.insufficientHistory;
    } else {
      status = DataSufficiencyStatus.matureData;
    }

    final totalIncome = audit.totalIncome;
    final totalExpense = audit.totalExpense;
    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? ((netSavings / totalIncome) * 100) : 0.0;
    final isDeficit = totalExpense > totalIncome;

    // Category sorting
    final categoryExpenses = Map<String, double>.from(audit.categoryExpenses);
    final categoryIncome = Map<String, double>.from(audit.categoryIncome);
    final sortedExpenses = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final highestCategory = sortedExpenses.isNotEmpty ? sortedExpenses.first.key : 'None';
    final highestCategoryAmount = sortedExpenses.isNotEmpty ? sortedExpenses.first.value : 0.0;
    final highestCategoryPercent =
        totalExpense > 0 ? (highestCategoryAmount / totalExpense) * 100 : 0.0;

    final lowestCategory = sortedExpenses.length > 1 ? sortedExpenses.last.key : 'None';
    final lowestCategoryAmount = sortedExpenses.length > 1 ? sortedExpenses.last.value : 0.0;
    final lowestCategoryPercent =
        totalExpense > 0 ? (lowestCategoryAmount / totalExpense) * 100 : 0.0;

    // Budgets analysis for current month & year
    final activeBudgets = budgets
        .where((b) => b.year == now.year && b.month == now.month)
        .toList();

    double totalBudgetLimit = 0.0;
    double totalBudgetSpent = 0.0;
    final budgetDetails = <BudgetInsightDetail>[];

    for (final b in activeBudgets) {
      final spent = b.calculateSpent(transactions);
      final remaining = b.calculateRemaining(transactions);
      final ratio = b.limitAmount > 0 ? (spent / b.limitAmount) : 0.0;
      totalBudgetLimit += b.limitAmount;
      totalBudgetSpent += spent;

      BudgetStatusType bStatus;
      if (spent > b.limitAmount) {
        bStatus = BudgetStatusType.exceeded;
      } else if (ratio >= 0.80) {
        bStatus = BudgetStatusType.nearLimit;
      } else {
        bStatus = BudgetStatusType.healthy;
      }

      budgetDetails.add(BudgetInsightDetail(
        category: b.category,
        limit: b.limitAmount,
        spent: spent,
        remaining: remaining,
        ratio: ratio,
        status: bStatus,
      ));
    }
    final totalBudgetRemaining = max(0.0, totalBudgetLimit - totalBudgetSpent);

    // Month-over-month category & spike analysis
    final increasedCategories = <String>[];
    final decreasedCategories = <String>[];
    final unusualSpikes = <String>[];

    double expenseChangePercent = 0.0;
    double incomeChangePercent = 0.0;

    if (hasPreviousMonthData) {
      if (prevAudit.totalExpense > 0) {
        expenseChangePercent =
            ((totalExpense - prevAudit.totalExpense) / prevAudit.totalExpense) * 100;
      }
      if (prevAudit.totalIncome > 0) {
        incomeChangePercent =
            ((totalIncome - prevAudit.totalIncome) / prevAudit.totalIncome) * 100;
      }

      for (final entry in categoryExpenses.entries) {
        final cat = entry.key;
        final curr = entry.value;
        final prev = prevAudit.categoryExpenses[cat] ?? 0.0;

        if (prev > 0) {
          final diff = curr - prev;
          final pct = (diff / prev) * 100;
          if (diff >= 500 && pct >= 30) {
            unusualSpikes.add('$cat (+${pct.toStringAsFixed(0)}% vs last month)');
            increasedCategories.add(cat);
          } else if (diff >= 200) {
            increasedCategories.add(cat);
          } else if (diff <= -200) {
            decreasedCategories.add(cat);
          }
        } else if (curr >= 1000) {
          unusualSpikes.add('$cat (New expense: ₹${_formatCurrency(curr)})');
          increasedCategories.add(cat);
        }
      }
    }

    // Actionable recommendations based on real data
    final recommendations = <String>[];
    if (isDeficit) {
      recommendations.add(
        'Deficit Alert: Expenses exceed income by ₹${_formatCurrency(totalExpense - totalIncome)}. Prioritize essential living costs and pause discretionary spending until next month.',
      );
    }

    if (highestCategoryPercent >= 35.0 && highestCategory != 'None') {
      recommendations.add(
        '$highestCategory represents ${highestCategoryPercent.toStringAsFixed(0)}% of your spending (₹${_formatCurrency(highestCategoryAmount)}). Reviewing discretionary expenses here could create immediate breathing room.',
      );
    }

    final exceeded = budgetDetails.where((b) => b.status == BudgetStatusType.exceeded).toList();
    if (exceeded.isNotEmpty) {
      recommendations.add(
        '${exceeded.first.category} has exceeded its budget limit by ₹${_formatCurrency(exceeded.first.spent - exceeded.first.limit)}. Consider dialing back spending in this category.',
      );
    }

    if (savingsRate >= 20.0) {
      recommendations.add(
        'Healthy Savings: You are saving ${savingsRate.toStringAsFixed(0)}% of your income. Consider allocating your ₹${_formatCurrency(netSavings)} surplus to emergency savings or investments.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Try applying the 72-hour pause rule for non-essential purchases over ₹1,000 to prevent impulse spending.',
      );
    }

    // Quick Insight Title and Subtitle for UI cards
    String quickTitle;
    String quickSubtitle;

    if (status == DataSufficiencyStatus.zeroData) {
      quickTitle = 'Start Your Financial Journey';
      quickSubtitle = 'Log your transactions to unlock personalized Spentee AI insights.';
    } else if (status == DataSufficiencyStatus.incomeOnly) {
      quickTitle = 'Income Recorded';
      quickSubtitle = 'Log your daily expenses to unlock spending analysis and savings tracking.';
    } else if (status == DataSufficiencyStatus.expensesOnly) {
      quickTitle = 'Spending Recorded';
      quickSubtitle = 'Add your income to calculate your savings rate and net cash flow.';
    } else if (isDeficit) {
      quickTitle = 'Deficit Alert for ${_monthName(now.month)}';
      quickSubtitle =
          'Spending exceeds income by ₹${_formatCurrency(totalExpense - totalIncome)}. Top outflow: $highestCategory.';
    } else {
      quickTitle = '$highestCategory is your top spend (${highestCategoryPercent.toStringAsFixed(0)}%)';
      quickSubtitle =
          'You have saved ₹${_formatCurrency(netSavings)} (${savingsRate.toStringAsFixed(0)}% savings rate) this month.';
    }

    return PersonalizedFinancialInsights(
      period: now,
      sufficiencyStatus: status,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: netSavings,
      savingsRate: savingsRate,
      isDeficit: isDeficit,
      highestCategory: highestCategory,
      highestCategoryAmount: highestCategoryAmount,
      highestCategoryPercent: highestCategoryPercent,
      lowestCategory: lowestCategory,
      lowestCategoryAmount: lowestCategoryAmount,
      lowestCategoryPercent: lowestCategoryPercent,
      categoryExpenses: categoryExpenses,
      categoryIncome: categoryIncome,
      budgets: budgetDetails,
      totalBudgetLimit: totalBudgetLimit,
      totalBudgetSpent: totalBudgetSpent,
      totalBudgetRemaining: totalBudgetRemaining,
      hasPreviousMonthData: hasPreviousMonthData,
      previousMonthExpense: prevAudit.totalExpense,
      previousMonthIncome: prevAudit.totalIncome,
      expenseChangePercent: expenseChangePercent,
      incomeChangePercent: incomeChangePercent,
      increasedCategories: increasedCategories,
      decreasedCategories: decreasedCategories,
      unusualSpikes: unusualSpikes,
      actionableRecommendations: recommendations,
      quickInsightTitle: quickTitle,
      quickInsightSubtitle: quickSubtitle,
    );
  }

  /// 1. Monthly Financial Summary
  FinancialEngineResponse generateMonthlySummaryQuery({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final insights = generatePersonalizedInsights(
      transactions: transactions,
      budgets: budgets,
      referenceDate: now,
    );

    if (insights.sufficiencyStatus == DataSufficiencyStatus.zeroData) {
      return const FinancialEngineResponse(
        text: '👋 **Welcome to Spentee AI!**\n\n'
            'Start recording your income and expenses. I\'ll analyse your financial activity and help you make better money decisions.',
        actionButtons: [
          'Add an expense',
          'Add income',
          'What can Hiro do?',
        ],
      );
    }

    if (insights.sufficiencyStatus == DataSufficiencyStatus.incomeOnly) {
      return FinancialEngineResponse(
        text: '💰 **Income Recorded:**\n\n'
            'You have recorded income, but there isn\'t enough expense data yet to analyse your spending.\n\n'
            '• Total Income: **₹${_formatCurrency(insights.totalIncome)}**\n\n'
            'Log your daily expenses to see net savings, category allocations, and budget progress.',
        actionButtons: const [
          'Add an expense',
          'How much did I earn this month?',
          'What is my current available balance?',
        ],
      );
    }

    if (insights.sufficiencyStatus == DataSufficiencyStatus.expensesOnly) {
      return FinancialEngineResponse(
        text: '📉 **Expenses Recorded:**\n\n'
            'You have recorded expenses of **₹${_formatCurrency(insights.totalExpense)}** for ${_monthName(now.month)} ${now.year}, but no income has been recorded yet.\n\n'
            'Record your income to calculate your net savings rate, cash flow, and monthly financial summary.',
        actionButtons: const [
          'Add income',
          'Where did most of my money go?',
          'How much did I spend this month?',
        ],
      );
    }

    final buffer = StringBuffer();
    final month = _monthName(now.month);
    final year = now.year;

    buffer.writeln('📊 **Monthly Financial Summary ($month $year):**\n');
    buffer.writeln('• **Total Income:** ₹${_formatCurrency(insights.totalIncome)}');
    buffer.writeln('• **Total Expenses:** ₹${_formatCurrency(insights.totalExpense)}');

    if (insights.isDeficit) {
      final deficit = insights.totalExpense - insights.totalIncome;
      buffer.writeln('• **Net Deficit:** -₹${_formatCurrency(deficit)} (Expenses exceed income)');
    } else {
      buffer.writeln('• **Net Savings:** **₹${_formatCurrency(insights.netSavings)}** (${insights.savingsRate.toStringAsFixed(1)}% savings rate)');
    }

    if (insights.highestCategory != 'None') {
      buffer.writeln('• **Top Spending Category:** **${insights.highestCategory}** (₹${_formatCurrency(insights.highestCategoryAmount)} • ${insights.highestCategoryPercent.toStringAsFixed(0)}% of spending)');
    }

    if (insights.budgets.isNotEmpty) {
      final onTrack = insights.budgets.where((b) => b.status != BudgetStatusType.exceeded).length;
      buffer.writeln('• **Budget Performance:** $onTrack of ${insights.budgets.length} budgets on track (₹${_formatCurrency(insights.totalBudgetRemaining)} remaining of ₹${_formatCurrency(insights.totalBudgetLimit)} limit)');
    } else {
      buffer.writeln('• **Budget Performance:** No category budgets set for $month $year.');
    }

    buffer.writeln('\n💡 **Recommendations:**');
    for (int i = 0; i < insights.actionableRecommendations.length; i++) {
      buffer.writeln('${i + 1}. ${insights.actionableRecommendations[i]}');
    }

    return FinancialEngineResponse(
      text: buffer.toString().trim(),
      actionButtons: const [
        'Spending analysis',
        'Budget insights',
        'Savings insights',
        'Spending behaviour',
      ],
    );
  }

  /// 2. Spending Analysis
  FinancialEngineResponse generateSpendingAnalysisQuery({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final insights = generatePersonalizedInsights(
      transactions: transactions,
      budgets: budgets,
      referenceDate: now,
    );

    if (insights.sufficiencyStatus == DataSufficiencyStatus.zeroData) {
      return const FinancialEngineResponse(
        text: '👋 **Welcome to Spentee AI!**\n\n'
            'Start recording your income and expenses. I\'ll analyse your financial activity and help you make better money decisions.',
        actionButtons: [
          'Add an expense',
          'Add income',
          'What can Hiro do?',
        ],
      );
    }

    if (insights.sufficiencyStatus == DataSufficiencyStatus.incomeOnly) {
      return FinancialEngineResponse(
        text: '💰 **Income Recorded:**\n\n'
            'You have recorded income, but there isn\'t enough expense data yet to analyse your spending.\n\n'
            'Add your daily expenses to unlock spending analysis and category breakdowns.',
        actionButtons: const [
          'Add an expense',
          'How much did I earn this month?',
          'What is my current available balance?',
        ],
      );
    }

    final buffer = StringBuffer();
    final month = _monthName(now.month);
    final year = now.year;

    buffer.writeln('💳 **Spending Analysis ($month $year):**\n');
    buffer.writeln('• **Total Spending:** **₹${_formatCurrency(insights.totalExpense)}** across ${insights.categoryExpenses.length} categories');
    if (insights.highestCategory != 'None') {
      buffer.writeln('• **Highest Spending Category:** **${insights.highestCategory}** — ₹${_formatCurrency(insights.highestCategoryAmount)} (${insights.highestCategoryPercent.toStringAsFixed(1)}% of expenses)');
    }
    if (insights.lowestCategory != 'None' && insights.categoryExpenses.length > 1) {
      buffer.writeln('• **Lowest Spending Category:** **${insights.lowestCategory}** — ₹${_formatCurrency(insights.lowestCategoryAmount)} (${insights.lowestCategoryPercent.toStringAsFixed(1)}% of expenses)');
    }

    buffer.writeln('\n📂 **Category Breakdown:**');
    final sorted = insights.categoryExpenses.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      final pct = insights.totalExpense > 0 ? ((entry.value / insights.totalExpense) * 100).toStringAsFixed(1) : '0';
      buffer.writeln('• **${entry.key}**: ₹${_formatCurrency(entry.value)} ($pct%)');
    }

    buffer.writeln('\n📈 **Spending Shifts & Spikes:**');
    if (insights.hasPreviousMonthData) {
      if (insights.unusualSpikes.isNotEmpty) {
        buffer.writeln('• **Unusual Spikes:** ${insights.unusualSpikes.join(', ')}');
      }
      if (insights.increasedCategories.isNotEmpty) {
        buffer.writeln('• **Increased Spending vs Last Month:** ${insights.increasedCategories.join(', ')}');
      }
      if (insights.decreasedCategories.isNotEmpty) {
        buffer.writeln('• **Reduced Spending vs Last Month:** ${insights.decreasedCategories.join(', ')}');
      }
      if (insights.unusualSpikes.isEmpty && insights.increasedCategories.isEmpty && insights.decreasedCategories.isEmpty) {
        buffer.writeln('• Spending levels are consistent with last month.');
      }
    } else {
      buffer.writeln('• *Historical comparison will be available next month once you have consecutive monthly records.*');
    }

    return FinancialEngineResponse(
      text: buffer.toString().trim(),
      actionButtons: const [
        'Where did most of my money go?',
        'Spending behaviour',
        'Monthly financial summary',
      ],
    );
  }

  /// 3. Income Analysis
  FinancialEngineResponse generateIncomeAnalysisQuery({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final insights = generatePersonalizedInsights(
      transactions: transactions,
      budgets: budgets,
      referenceDate: now,
    );

    if (insights.sufficiencyStatus == DataSufficiencyStatus.zeroData) {
      return const FinancialEngineResponse(
        text: '👋 **Welcome to Spentee AI!**\n\n'
            'Start recording your income and expenses. I\'ll analyse your financial activity and help you make better money decisions.',
        actionButtons: [
          'Add an expense',
          'Add income',
          'What can Hiro do?',
        ],
      );
    }

    if (insights.totalIncome == 0) {
      return const FinancialEngineResponse(
        text: '💵 **Income Analysis:**\n\n'
            'No earned income has been recorded for this month yet.\n\n'
            'Record your salary, freelance earnings, or investment returns to view your income source breakdown and trends.',
        actionButtons: [
          'Add income',
          'How much did I spend this month?',
          'What is my current available balance?',
        ],
      );
    }

    final buffer = StringBuffer();
    final month = _monthName(now.month);
    final year = now.year;

    buffer.writeln('💵 **Income Analysis ($month $year):**\n');
    buffer.writeln('• **Total Income:** **₹${_formatCurrency(insights.totalIncome)}**');

    if (insights.categoryIncome.isNotEmpty) {
      final sortedIncome = insights.categoryIncome.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final primary = sortedIncome.first;
      final primaryPct = insights.totalIncome > 0 ? ((primary.value / insights.totalIncome) * 100).toStringAsFixed(1) : '0';
      buffer.writeln('• **Primary Income Source:** **${primary.key}** — ₹${_formatCurrency(primary.value)} ($primaryPct%)\n');

      buffer.writeln('📂 **Income Breakdown by Source:**');
      for (final entry in sortedIncome) {
        final pct = insights.totalIncome > 0 ? ((entry.value / insights.totalIncome) * 100).toStringAsFixed(1) : '0';
        buffer.writeln('• **${entry.key}**: ₹${_formatCurrency(entry.value)} ($pct%)');
      }
    } else {
      buffer.writeln('• Income source: General income.');
    }

    buffer.writeln('\n📊 **Month-over-Month Comparison:**');
    if (insights.hasPreviousMonthData) {
      final prev = insights.previousMonthIncome;
      buffer.writeln('• **Previous Month Income:** ₹${_formatCurrency(prev)}');
      if (prev > 0) {
        final change = insights.incomeChangePercent;
        final sign = change >= 0 ? '+' : '';
        buffer.writeln('• **Income Change:** $sign${change.toStringAsFixed(1)}%');
      }
      if (insights.totalIncome > prev) {
        buffer.writeln('• Pattern: Your earned income increased this month.');
      } else if (insights.totalIncome < prev) {
        buffer.writeln('• Pattern: Your earned income is lower compared to last month.');
      } else {
        buffer.writeln('• Pattern: Your income has remained completely stable.');
      }
    } else {
      buffer.writeln('• *Income comparison will be available once you record income across multiple months.*');
    }

    return FinancialEngineResponse(
      text: buffer.toString().trim(),
      actionButtons: const [
        'How much did I earn this month?',
        'Savings insights',
        'Monthly financial summary',
      ],
    );
  }

  /// 4. Savings Insights
  FinancialEngineResponse generateSavingsInsightsQuery({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final insights = generatePersonalizedInsights(
      transactions: transactions,
      budgets: budgets,
      referenceDate: now,
    );

    if (insights.sufficiencyStatus == DataSufficiencyStatus.zeroData) {
      return const FinancialEngineResponse(
        text: '👋 **Welcome to Spentee AI!**\n\n'
            'Start recording your income and expenses. I\'ll analyse your financial activity and help you make better money decisions.',
        actionButtons: [
          'Add an expense',
          'Add income',
          'What can Hiro do?',
        ],
      );
    }

    if (insights.totalIncome == 0) {
      return FinancialEngineResponse(
        text: '🌱 **Savings Insights:**\n\n'
            'You have recorded expenses of **₹${_formatCurrency(insights.totalExpense)}**, but no income has been recorded yet.\n\n'
            'Record your income to allow me to calculate your net savings rate, cash flow, and personalized savings targets.',
        actionButtons: const [
          'Add income',
          'How much did I spend this month?',
          'What is my current available balance?',
        ],
      );
    }

    final buffer = StringBuffer();
    final month = _monthName(now.month);
    final year = now.year;

    buffer.writeln('🌱 **Savings Insights ($month $year):**\n');
    buffer.writeln('• **Total Income:** ₹${_formatCurrency(insights.totalIncome)}');
    buffer.writeln('• **Total Expenses:** ₹${_formatCurrency(insights.totalExpense)}');

    if (insights.isDeficit) {
      final deficit = insights.totalExpense - insights.totalIncome;
      buffer.writeln('• **Net Deficit:** **-₹${_formatCurrency(deficit)}**');
      buffer.writeln('• **Status:** Living expenses exceed income. Building savings is currently paused.\n');
      buffer.writeln('🎯 **Immediate Recovery Target:**');
      buffer.writeln('• Reduce discretionary spending by ₹${_formatCurrency(deficit)} to bring cash flow back to break-even.');
    } else {
      buffer.writeln('• **Net Savings:** **₹${_formatCurrency(insights.netSavings)}**');
      buffer.writeln('• **Savings Rate:** **${insights.savingsRate.toStringAsFixed(1)}%** of earned income\n');

      buffer.writeln('🎯 **Realistic Savings Target:**');
      final targetRate = insights.savingsRate < 20.0 ? 20.0 : min(50.0, insights.savingsRate + 5.0);
      final targetSavings = insights.totalIncome * (targetRate / 100);
      buffer.writeln('• Based on your current income of ₹${_formatCurrency(insights.totalIncome)}, a realistic savings target is **₹${_formatCurrency(targetSavings)}** (${targetRate.toStringAsFixed(0)}% target rate).');
    }

    buffer.writeln('\n✂️ **Opportunities to Reduce Spending:**');
    if (insights.highestCategory != 'None') {
      final discretionaryCats = ['dining', 'food', 'shopping', 'entertainment', 'clothing', 'cafe'];
      final isDiscretionary = discretionaryCats.any((d) => insights.highestCategory.toLowerCase().contains(d));
      if (isDiscretionary) {
        final potentialTrim = (insights.highestCategoryAmount * 0.15).roundToDouble();
        buffer.writeln('• **${insights.highestCategory}**: Trimming non-essential spends by 15% would save you **₹${_formatCurrency(potentialTrim)}** this month.');
      } else {
        buffer.writeln('• Review recurring subscriptions and impulse purchases in discretionary categories.');
      }
    }
    buffer.writeln('• Apply the 72-hour delay rule before non-essential purchases over ₹1,000.');

    return FinancialEngineResponse(
      text: buffer.toString().trim(),
      actionButtons: const [
        'How can I save ₹800 this month?',
        'Budget performance',
        'Monthly financial summary',
      ],
    );
  }

  /// 5. Budget Insights
  FinancialEngineResponse generateBudgetInsightsQuery({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final insights = generatePersonalizedInsights(
      transactions: transactions,
      budgets: budgets,
      referenceDate: now,
    );

    final month = _monthName(now.month);
    final year = now.year;

    if (insights.budgets.isEmpty) {
      return FinancialEngineResponse(
        text: '🛡️ **Budget Insights ($month $year):**\n\n'
            'You have not set any category budgets for $month $year yet.\n\n'
            'Setting monthly budgets for top categories like Food & Dining, Shopping, and Transport helps prevent overspending and ensures consistent savings.',
        actionButtons: const [
          'Set Category Budget',
          'Review my spending this month',
          'Monthly financial summary',
        ],
      );
    }

    final buffer = StringBuffer();
    buffer.writeln('🛡️ **Budget Insights & Performance ($month $year):**\n');
    buffer.writeln('• **Total Budget Limit:** ₹${_formatCurrency(insights.totalBudgetLimit)}');
    buffer.writeln('• **Total Budget Spent:** ₹${_formatCurrency(insights.totalBudgetSpent)}');
    buffer.writeln('• **Remaining Budget Buffer:** **₹${_formatCurrency(insights.totalBudgetRemaining)}**\n');

    buffer.writeln('📋 **Category Status:**');
    for (final b in insights.budgets) {
      String statusTag;
      switch (b.status) {
        case BudgetStatusType.exceeded:
          statusTag = '⚠️ Exceeded (+₹${_formatCurrency(b.spent - b.limit)})';
          break;
        case BudgetStatusType.nearLimit:
          statusTag = '⚡ Near Limit (Remaining: ₹${_formatCurrency(b.remaining)})';
          break;
        case BudgetStatusType.healthy:
          statusTag = '✅ Healthy (Remaining: ₹${_formatCurrency(b.remaining)})';
          break;
      }
      final pct = (b.ratio * 100).toStringAsFixed(0);
      buffer.writeln('• **${b.category}**: ₹${_formatCurrency(b.spent)} / ₹${_formatCurrency(b.limit)} ($pct%) — $statusTag');
    }

    buffer.writeln('\n💡 **Budget Adjustments & Recommendations:**');
    final exceeded = insights.budgets.where((b) => b.status == BudgetStatusType.exceeded).toList();
    final healthy = insights.budgets.where((b) => b.status == BudgetStatusType.healthy && b.remaining > 500).toList();

    if (exceeded.isNotEmpty && healthy.isNotEmpty) {
      buffer.writeln('• **Reallocation Opportunity:** ${exceeded.first.category} exceeded budget by ₹${_formatCurrency(exceeded.first.spent - exceeded.first.limit)}. You have ₹${_formatCurrency(healthy.first.remaining)} buffer in ${healthy.first.category}. You can reallocate ₹${_formatCurrency(min(exceeded.first.spent - exceeded.first.limit, healthy.first.remaining))} to balance your limits.');
    } else if (exceeded.isNotEmpty) {
      buffer.writeln('• Dial back spending in ${exceeded.map((e) => e.category).join(', ')} for the rest of $month.');
    } else {
      buffer.writeln('• All budgets are healthy! Maintain your current pacing to finish the month with ₹${_formatCurrency(insights.totalBudgetRemaining)} in surplus.');
    }

    return FinancialEngineResponse(
      text: buffer.toString().trim(),
      actionButtons: const [
        'How much budget do I have left?',
        'Spending analysis',
        'Monthly financial summary',
      ],
    );
  }

  /// 6. Spending Behaviour
  FinancialEngineResponse generateSpendingBehaviourQuery({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final insights = generatePersonalizedInsights(
      transactions: transactions,
      budgets: budgets,
      referenceDate: now,
    );

    if (insights.sufficiencyStatus == DataSufficiencyStatus.zeroData) {
      return const FinancialEngineResponse(
        text: '👋 **Welcome to Spentee AI!**\n\n'
            'Start recording your income and expenses. I\'ll analyse your financial activity and help you make better money decisions.',
        actionButtons: [
          'Add an expense',
          'Add income',
          'What can Hiro do?',
        ],
      );
    }

    if (insights.sufficiencyStatus == DataSufficiencyStatus.incomeOnly) {
      return FinancialEngineResponse(
        text: '💰 **Income Recorded:**\n\n'
            'You have recorded income, but there isn\'t enough expense data yet to analyse your spending behaviour.\n\n'
            'Add your daily expenses to unlock spending habit analysis and pacing.',
        actionButtons: const [
          'Add an expense',
          'How much did I earn this month?',
          'What is my current available balance?',
        ],
      );
    }

    final buffer = StringBuffer();
    final month = _monthName(now.month);
    final year = now.year;
    final daysElapsed = max(1, now.day);
    final dailyPace = insights.totalExpense / daysElapsed;

    buffer.writeln('🧠 **Spending Behaviour & Habits ($month $year):**\n');
    buffer.writeln('• **Daily Spending Pace:** **₹${_formatCurrency(dailyPace)}/day** (over $daysElapsed days elapsed)');

    // Essential vs Discretionary
    final essentialKeywords = ['grocery', 'groceries', 'bill', 'bills', 'utilit', 'health', 'medicine', 'medical', 'transport', 'commute', 'rent', 'fuel'];
    double essentialTotal = 0.0;
    double discretionaryTotal = 0.0;

    for (final entry in insights.categoryExpenses.entries) {
      final lower = entry.key.toLowerCase();
      if (essentialKeywords.any((k) => lower.contains(k))) {
        essentialTotal += entry.value;
      } else {
        discretionaryTotal += entry.value;
      }
    }

    final essentialPct = insights.totalExpense > 0 ? ((essentialTotal / insights.totalExpense) * 100).toStringAsFixed(0) : '0';
    final discretionaryPct = insights.totalExpense > 0 ? ((discretionaryTotal / insights.totalExpense) * 100).toStringAsFixed(0) : '0';

    buffer.writeln('• **Essential Living Spending:** ₹${_formatCurrency(essentialTotal)} ($essentialPct%)');
    buffer.writeln('• **Discretionary Spending:** ₹${_formatCurrency(discretionaryTotal)} ($discretionaryPct%)\n');

    buffer.writeln('📊 **Month-over-Month Behaviour:**');
    if (insights.hasPreviousMonthData) {
      final change = insights.expenseChangePercent;
      final sign = change >= 0 ? '+' : '';
      buffer.writeln('• **Overall Spending Change:** $sign${change.toStringAsFixed(1)}% vs previous month');
      if (insights.increasedCategories.isNotEmpty) {
        buffer.writeln('• **Increased Categories:** ${insights.increasedCategories.join(', ')}');
      }
      if (insights.decreasedCategories.isNotEmpty) {
        buffer.writeln('• **Reduced Categories:** ${insights.decreasedCategories.join(', ')}');
      }
      if (insights.unusualSpikes.isNotEmpty) {
        buffer.writeln('• **Unusual Spikes:** ${insights.unusualSpikes.join(', ')}');
      }
    } else {
      buffer.writeln('• *Spentee requires at least two consecutive months of records to establish recurring behavioural trends. Continue logging daily to unlock month-over-month habit analysis.*');
    }

    buffer.writeln('\n💡 **Mindful Habit Tip:**');
    if (discretionaryTotal > essentialTotal && insights.totalExpense > 0) {
      buffer.writeln('• Discretionary purchases currently exceed essentials. Pause non-essential purchases for 72 hours before completing checkout.');
    } else {
      buffer.writeln('• Great balance! Your essentials form the foundation of your expenses. Keep maintaining mindful daily spending.');
    }

    return FinancialEngineResponse(
      text: buffer.toString().trim(),
      actionButtons: const [
        'Where did most of my money go?',
        'Monthly financial summary',
        'Budget insights',
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. DETERMINISTIC QUERY INTERPRETER & ANSWER GENERATOR
  // ───────────────────────────────────────────────────────────────────────────

  /// Evaluates whether a query can be answered deterministically using the user's
  /// actual recorded financial data. If matched, returns exact, verifiable metrics.
  FinancialEngineResponse? evaluateQuery({
    required String query,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<SavingsGoal> savingsGoals,
    required bool userConsented,
    List<LentBorrowedRecord> debts = const [],
    double? availableBalance,
    List<String> recentRoastIds = const [],
    String language = 'English',
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final q = query.trim().toLowerCase();

    // ── 0. Roast Requests ("Roast me", "Roast my spending") ────────────────
    if (_matchesRoastQuery(q)) {
      final roast = DynamicRoastEngine.generateRoast(
        transactions: transactions,
        budgets: budgets,
        savingsGoals: savingsGoals,
        recentRoastIds: recentRoastIds,
        language: language,
        referenceDate: now,
      );
      return FinancialEngineResponse(
        text: '🔥 **Spentee Roast:**\n\n${roast.text}',
        actionButtons: const [
          'Where did most of my money go?',
          'How much did I spend this month?',
          'How can I save ₹800 this month?',
          'Another roast please 🔥',
        ],
      );
    }

    // ── 0.1 Monthly Financial Summary ──────────────────────────────────────────
    if (_matchesMonthlySummary(q)) {
      return generateMonthlySummaryQuery(
        transactions: transactions,
        budgets: budgets,
        referenceDate: now,
      );
    }

    // ── 0.2 Spending Analysis ──────────────────────────────────────────────────
    if (_matchesSpendingAnalysis(q)) {
      return generateSpendingAnalysisQuery(
        transactions: transactions,
        budgets: budgets,
        referenceDate: now,
      );
    }

    // ── 0.3 Income Analysis ────────────────────────────────────────────────────
    if (_matchesIncomeAnalysis(q)) {
      return generateIncomeAnalysisQuery(
        transactions: transactions,
        budgets: budgets,
        referenceDate: now,
      );
    }

    // ── 0.4 Savings Insights ───────────────────────────────────────────────────
    if (_matchesSavingsInsights(q)) {
      return generateSavingsInsightsQuery(
        transactions: transactions,
        budgets: budgets,
        referenceDate: now,
      );
    }

    // ── 0.5 Budget Insights ────────────────────────────────────────────────────
    if (_matchesBudgetInsights(q)) {
      return generateBudgetInsightsQuery(
        transactions: transactions,
        budgets: budgets,
        referenceDate: now,
      );
    }

    // ── 0.6 Spending Behaviour ─────────────────────────────────────────────────
    if (_matchesSpendingBehaviour(q)) {
      return generateSpendingBehaviourQuery(
        transactions: transactions,
        budgets: budgets,
        referenceDate: now,
      );
    }

    // ── 2. "Who owes me money?" / Detailed Pending Debt Collections ────────
    if (_matchesWhoOwesMe(q)) {
      final activeLent = debts
          .where((d) => d.type == DebtType.lent && d.outstandingAmount > 0)
          .toList();

      if (activeLent.isEmpty) {
        return const FinancialEngineResponse(
          text: '🤝 **Lending & Receivables Status:**\n\n'
              'Nobody currently owes you money! All lent loans have been fully settled, or no active loans are recorded.',
          actionButtons: [
            'How much money have I lent?',
            'How much did I spend this month?',
            'Where did most of my money go?',
          ],
        );
      }

      double totalPending = 0.0;
      final buffer = StringBuffer();
      buffer.writeln('🤝 **People Who Owe You Money (Active Receivables):**\n');

      for (final d in activeLent) {
        totalPending += d.outstandingAmount;
        final dueDateStr = d.dueDate != null ? ' (Due: ${_formatDate(d.dueDate!)})' : '';
        final isOverdue = d.dueDate != null && d.dueDate!.isBefore(now);
        final statusTag = isOverdue ? ' ⚠️ *Overdue*' : '';
        buffer.writeln(
            '• **${d.personName}**: **₹${_formatCurrency(d.outstandingAmount)}** remaining (out of ₹${_formatCurrency(d.amount)} lent)$dueDateStr$statusTag');
      }

      buffer.writeln(
          '\n📊 **Total Money to Collect:** **₹${_formatCurrency(totalPending)}** across ${activeLent.length} person(s).');

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'How much money have I lent?',
          'How much did I spend this month?',
          'What is my current available balance?',
        ],
      );
    }

    // ── 3. Lending & Borrowing Questions ──────────────────────────────────
    if (_matchesHowMuchLent(q)) {
      final lentDebts = debts.where((d) => d.type == DebtType.lent).toList();
      double totalPrincipal = lentDebts.fold(0.0, (sum, d) => sum + d.amount);
      double totalOutstanding =
          lentDebts.fold(0.0, (sum, d) => sum + d.outstandingAmount);
      double totalCollected = totalPrincipal - totalOutstanding;

      if (lentDebts.isEmpty) {
        final audit = computeAudit(
          transactions: transactions,
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(now.year + 1, 12, 31),
        );
        totalPrincipal = audit.totalMoneyLent;
        totalCollected = audit.totalRepaymentsReceived;
        totalOutstanding = max(0.0, totalPrincipal - totalCollected);
      }

      return FinancialEngineResponse(
        text: '🤝 **Money Lent Summary:**\n\n'
            '• Total Money Lent: **₹${_formatCurrency(totalPrincipal)}**\n'
            '• **Repayments Collected:** ₹${_formatCurrency(totalCollected)}\n'
            '• Money Still to Collect: **₹${_formatCurrency(totalOutstanding)}**\n\n'
            '*Note: Money lent is tracked as a receivable asset and is strictly excluded from your living expenses.*',
        actionButtons: const [
          'Who owes me money?',
          'How much have I borrowed?',
          'What is my current available balance?',
        ],
      );
    }

    if (_matchesHowMuchToCollect(q)) {
      final lentDebts = debts.where((d) => d.type == DebtType.lent).toList();
      double totalOutstanding =
          lentDebts.fold(0.0, (sum, d) => sum + d.outstandingAmount);

      if (lentDebts.isEmpty) {
        final audit = computeAudit(
          transactions: transactions,
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(now.year + 1, 12, 31),
        );
        totalOutstanding =
            max(0.0, audit.totalMoneyLent - audit.totalRepaymentsReceived);
      }

      return FinancialEngineResponse(
        text: '📥 **Money to Collect:**\n\n'
            'You still need to collect **₹${_formatCurrency(totalOutstanding)}** in outstanding receivables.\n\n'
            'Ask *"Who owes me money?"* to see individual borrowers.',
        actionButtons: const [
          'Who owes me money?',
          'How much money have I lent?',
          'What is my current available balance?',
        ],
      );
    }

    if (_matchesHowMuchBorrowed(q)) {
      final borrowedDebts =
          debts.where((d) => d.type == DebtType.borrowed).toList();
      double totalPrincipal = borrowedDebts.fold(0.0, (sum, d) => sum + d.amount);
      double totalOutstanding =
          borrowedDebts.fold(0.0, (sum, d) => sum + d.outstandingAmount);
      double totalRepaid = totalPrincipal - totalOutstanding;

      if (borrowedDebts.isEmpty) {
        final audit = computeAudit(
          transactions: transactions,
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(now.year + 1, 12, 31),
        );
        totalPrincipal = audit.totalMoneyBorrowed;
        totalRepaid = audit.totalRepaymentsMade;
        totalOutstanding = max(0.0, totalPrincipal - totalRepaid);
      }

      return FinancialEngineResponse(
        text: '📤 **Money Borrowed Summary:**\n\n'
            '• Total Money Borrowed: **₹${_formatCurrency(totalPrincipal)}**\n'
            '• **Repayments Made:** ₹${_formatCurrency(totalRepaid)}\n'
            '• Money Still to Repay: **₹${_formatCurrency(totalOutstanding)}**\n\n'
            '*Note: Borrowed funds are tracked as liabilities and are strictly excluded from your earned income.*',
        actionButtons: const [
          'How much do I still need to repay?',
          'How much money have I lent?',
          'What is my current available balance?',
        ],
      );
    }

    if (_matchesHowMuchToRepay(q)) {
      final borrowedDebts =
          debts.where((d) => d.type == DebtType.borrowed).toList();
      double totalOutstanding =
          borrowedDebts.fold(0.0, (sum, d) => sum + d.outstandingAmount);

      if (borrowedDebts.isEmpty) {
        final audit = computeAudit(
          transactions: transactions,
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(now.year + 1, 12, 31),
        );
        totalOutstanding =
            max(0.0, audit.totalMoneyBorrowed - audit.totalRepaymentsMade);
      }

      final active = borrowedDebts.where((d) => d.outstandingAmount > 0).toList();
      final buffer = StringBuffer();
      buffer.writeln('📤 **Money to Repay:**\n');
      buffer.writeln(
          'You currently owe **₹${_formatCurrency(totalOutstanding)}** in liabilities.\n');

      if (active.isNotEmpty) {
        buffer.writeln('**Pending Repayments:**');
        for (final d in active) {
          buffer.writeln(
              '• To **${d.personName}**: ₹${_formatCurrency(d.outstandingAmount)}');
        }
      }

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'How much have I borrowed?',
          'How much money have I lent?',
          'What is my current available balance?',
        ],
      );
    }

    if (_matchesRepaidOrCollected(q)) {
      final lentDebts = debts.where((d) => d.type == DebtType.lent).toList();
      final borrowedDebts =
          debts.where((d) => d.type == DebtType.borrowed).toList();

      double totalCollected = lentDebts.fold(0.0, (sum, d) => sum + d.repaidAmount);
      double totalRepaid =
          borrowedDebts.fold(0.0, (sum, d) => sum + d.repaidAmount);

      if (debts.isEmpty) {
        final audit = computeAudit(
          transactions: transactions,
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(now.year + 1, 12, 31),
        );
        totalCollected = audit.totalRepaymentsReceived;
        totalRepaid = audit.totalRepaymentsMade;
      }

      return FinancialEngineResponse(
        text: '🔄 **Repayment & Collection Ledger:**\n\n'
            '• **Repayments Collected (from money lent):** **₹${_formatCurrency(totalCollected)}**\n'
            '• **Repayments Made (for money borrowed):** **₹${_formatCurrency(totalRepaid)}**\n\n'
            '*Note: Repayments are settlement transfers that restore your balance without being double-counted as income or expenses.*',
        actionButtons: const [
          'How much money have I lent?',
          'How much have I borrowed?',
          'What is my current available balance?',
        ],
      );
    }

    // ── 4. "What is my current available balance?" ─────────────────────────
    if (_matchesAvailableBalance(q)) {
      double bal = availableBalance ?? 0.0;
      if (availableBalance == null) {
        for (final tx in transactions) {
          if (tx.isCashOutflow) bal -= tx.amount;
          if (tx.isCashInflow) bal += tx.amount;
        }
      }

      final sign = bal < 0 ? '-' : '';
      final absBal = bal.abs();

      return FinancialEngineResponse(
        text: '💳 **Current Available Balance:**\n\n'
            '• **Spendable Cash Balance:** **$sign₹${_formatCurrency(absBal)}**\n\n'
            'This reflects your spendable cash after earned income, living expenses, investments, loans, and debt repayments.',
        actionButtons: const [
          'How much did I spend today?',
          'How much did I earn this month?',
          'Where did most of my money go?',
        ],
      );
    }

    // ── 5. "What was my biggest expense?" ──────────────────────────────────
    if (_matchesBiggestExpense(q)) {
      final isThisMonth =
          q.contains('this month') || q.contains('current month');
      final validExpenses = transactions
          .where((tx) {
            if (tx.type != TransactionType.expense ||
                isTransfer(tx) ||
                isRefund(tx) ||
                isMoneyLent(tx)) {
              return false;
            }
            if (isThisMonth) {
              return tx.date.year == now.year && tx.date.month == now.month;
            }
            return true;
          })
          .toList();

      if (validExpenses.isEmpty) {
        return const FinancialEngineResponse(
          text: '📊 **Biggest Expense:**\n\n'
              'No expense transactions have been recorded yet.',
          actionButtons: [
            'How much did I spend today?',
            'How much did I earn this month?',
          ],
        );
      }

      validExpenses.sort((a, b) => b.amount.compareTo(a.amount));
      final topTx = validExpenses.first;

      return FinancialEngineResponse(
        text: '🏆 **Biggest Expense Recorded:**\n\n'
            '• **Purchase:** **${topTx.title}**\n'
            '• **Amount:** **₹${_formatCurrency(topTx.amount)}**\n'
            '• **Category:** ${topTx.category}\n'
            '• **Date:** ${_formatDate(topTx.date)}\n'
            '${topTx.note.isNotEmpty ? '• **Note:** ${topTx.note}\n' : ''}',
        actionButtons: const [
          'Where did most of my money go?',
          'How much did I spend this month?',
          'Show my recent transactions',
        ],
      );
    }

    // ── 6. "Show my recent transactions" ──────────────────────────────────
    if (_matchesRecentTransactions(q)) {
      final validTxs = transactions.where((tx) => !tx.isDeleted).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (validTxs.isEmpty) {
        return const FinancialEngineResponse(
          text: '📋 **Recent Transactions:**\n\n'
              'No transactions recorded yet in your account.',
          actionButtons: [
            'How much did I spend today?',
            'What is my current available balance?',
          ],
        );
      }

      final recent = validTxs.take(5).toList();
      final buffer = StringBuffer();
      buffer.writeln('📋 **Your 5 Most Recent Transactions:**\n');

      for (final tx in recent) {
        final signAmount = tx.displaySignedAmount;
        final extra = tx.personName != null && tx.personName!.isNotEmpty
            ? ' • ${tx.personName}'
            : '';
        buffer.writeln('• **${tx.title}**: **$signAmount** (${tx.category}$extra • ${_formatDate(tx.date)})');
      }

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'What was my biggest expense?',
          'How much did I spend today?',
          'What is my current available balance?',
        ],
      );
    }

    // ── 7. "How much did I spend today?" ───────────────────────────────────
    if (_matchesTodaySpend(q)) {
      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      final buffer = StringBuffer();
      buffer.writeln('📅 **Spending Summary for Today (${_formatDate(now)}):**\n');
      buffer.writeln('• **Total Spent:** ₹${_formatCurrency(audit.totalExpense)}');

      if (audit.totalRefunds > 0) {
        buffer.writeln(
            '• **Refunds Credited:** ₹${_formatCurrency(audit.totalRefunds)} *(deducted to prevent overcounting)*');
      }
      if (audit.totalTransfers > 0) {
        buffer.writeln(
            '• **Transfers:** ₹${_formatCurrency(audit.totalTransfers)} *(excluded from expenses)*');
      }

      final todayExpenses = transactions.where((tx) =>
          tx.type == TransactionType.expense &&
          !isTransfer(tx) &&
          !isRefund(tx) &&
          !isMoneyLent(tx) &&
          !tx.date.isBefore(start) &&
          !tx.date.isAfter(end)).toList();

      if (todayExpenses.isNotEmpty) {
        buffer.writeln('\n**Transactions Today:**');
        for (final tx in todayExpenses) {
          buffer.writeln('• ${tx.title}: ₹${_formatCurrency(tx.amount)} (${tx.category})');
        }
      }

      if (audit.categoryExpenses.isNotEmpty) {
        buffer.writeln('\n**Category Breakdown:**');
        audit.categoryExpenses.forEach((cat, amt) {
          buffer.writeln('  - $cat: ₹${_formatCurrency(amt)}');
        });
      } else {
        buffer.writeln('\n*No category expenses recorded for today.*');
      }

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'How much did I spend yesterday?',
          'How much did I earn this month?',
          'Where did most of my money go?',
        ],
      );
    }

    // ── 8. "How much did I spend yesterday?" ───────────────────────────────
    if (_matchesYesterdaySpend(q)) {
      final yesterday = now.subtract(const Duration(days: 1));
      final start = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
      final end =
          DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      final buffer = StringBuffer();
      buffer.writeln('📅 **Spending Summary for Yesterday (${_formatDate(yesterday)}):**\n');
      buffer.writeln('• **Total Spent:** ₹${_formatCurrency(audit.totalExpense)}');

      if (audit.totalRefunds > 0) {
        buffer.writeln(
            '• **Refunds Credited:** ₹${_formatCurrency(audit.totalRefunds)} *(deducted)*');
      }

      final yExpenses = transactions.where((tx) =>
          tx.type == TransactionType.expense &&
          !isTransfer(tx) &&
          !isRefund(tx) &&
          !isMoneyLent(tx) &&
          !tx.date.isBefore(start) &&
          !tx.date.isAfter(end)).toList();

      if (yExpenses.isNotEmpty) {
        buffer.writeln('\n**Transactions Yesterday:**');
        for (final tx in yExpenses) {
          buffer.writeln('• ${tx.title}: ₹${_formatCurrency(tx.amount)} (${tx.category})');
        }
      } else {
        buffer.writeln('\n*No expenses recorded for yesterday.*');
      }

      if (audit.categoryExpenses.isNotEmpty) {
        buffer.writeln('\n**Category Breakdown:**');
        audit.categoryExpenses.forEach((cat, amt) {
          buffer.writeln('  - $cat: ₹${_formatCurrency(amt)}');
        });
      }

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'How much did I spend today?',
          'How much did I spend this week?',
          'Where did most of my money go?',
        ],
      );
    }

    // ── 9. "How much did I spend this week?" ───────────────────────────────
    if (_matchesWeekSpend(q)) {
      final todayStart = DateTime(now.year, now.month, now.day);
      final start = todayStart.subtract(const Duration(days: 6));
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      final spendAmount = audit.grossExpense > 0 ? audit.grossExpense : audit.totalExpense;
      final dailyAvg = spendAmount / 7.0;

      final buffer = StringBuffer();
      buffer.writeln('📅 **Weekly Spending Summary (Last 7 Days):**\n');
      buffer.writeln('• **Total Spent:** **₹${_formatCurrency(spendAmount)}**');
      if (audit.totalRefunds > 0) {
        buffer.writeln(
            '• **Net Spending (after ₹${_formatCurrency(audit.totalRefunds)} refunds):** ₹${_formatCurrency(audit.totalExpense)}');
      }
      buffer.writeln('• **Daily Average:** ₹${_formatCurrency(dailyAvg)}/day');

      if (audit.topCategory != 'None') {
        buffer.writeln(
            '• **Top Spending Area:** ${audit.topCategory} (₹${_formatCurrency(audit.topCategoryAmount)})');
      }

      if (audit.categoryExpenses.isNotEmpty) {
        buffer.writeln('\n**Category Breakdown:**');
        audit.categoryExpenses.forEach((cat, amt) {
          buffer.writeln('  - $cat: ₹${_formatCurrency(amt)}');
        });
      } else {
        buffer.writeln('\n*No expenses recorded in the last 7 days.*');
      }

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'How much did I spend this month?',
          'Am I spending more than usual?',
          'Where did most of my money go?',
        ],
      );
    }

    // ── 10. "How much did I spend this month?" ─────────────────────────────
    if (_matchesMonthSpend(q)) {
      final start = DateTime(now.year, now.month, 1, 0, 0, 0);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      final monthName = _monthName(now.month);
      final dailyPace = audit.totalExpense / max(1, now.day);

      final buffer = StringBuffer();
      buffer.writeln('📊 **Spending Report for $monthName ${now.year}:**\n');
      buffer.writeln('• **Total Spending (Month-to-Date):** **₹${_formatCurrency(audit.totalExpense)}**');
      buffer.writeln('• **Current Spending Pace:** ₹${_formatCurrency(dailyPace)}/day');

      if (audit.topCategory != 'None') {
        final pct = audit.totalExpense > 0
            ? ((audit.topCategoryAmount / audit.totalExpense) * 100).toStringAsFixed(1)
            : '0';
        buffer.writeln(
            '• **Top Category:** ${audit.topCategory} (₹${_formatCurrency(audit.topCategoryAmount)}, $pct%)');
      }

      if (audit.categoryExpenses.isNotEmpty) {
        buffer.writeln('\n**Category Breakdown:**');
        audit.categoryExpenses.forEach((cat, amt) {
          buffer.writeln('  - $cat: ₹${_formatCurrency(amt)}');
        });
      }

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'How much did I earn this month?',
          'Compare this month with last month',
          'How much budget do I have left?',
        ],
      );
    }

    // ── 11. "How much have I spent this year?" ─────────────────────────────
    if (_matchesYearSpend(q)) {
      final start = DateTime(now.year, 1, 1, 0, 0, 0);
      final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      final elapsedMonths = max(1, now.month);
      final monthlyAvg = audit.totalExpense / elapsedMonths;

      final buffer = StringBuffer();
      buffer.writeln('🗓️ **Annual Spending Summary (${now.year} Year-to-Date):**\n');
      buffer.writeln('• **Total Spent in ${now.year}:** **₹${_formatCurrency(audit.totalExpense)}**');
      buffer.writeln('• **Monthly Average Spending:** ₹${_formatCurrency(monthlyAvg)}/month');

      if (audit.topCategory != 'None') {
        buffer.writeln(
            '• **Highest Spending Category:** ${audit.topCategory} (₹${_formatCurrency(audit.topCategoryAmount)})');
      }

      if (audit.categoryExpenses.isNotEmpty) {
        buffer.writeln('\n**Category Breakdown:**');
        audit.categoryExpenses.forEach((cat, amt) {
          buffer.writeln('  - $cat: ₹${_formatCurrency(amt)}');
        });
      }

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'How much did I spend this month?',
          'What is my total income and total spending?',
          'Where did most of my money go?',
        ],
      );
    }

    // ── 12. "What is my total income and total spending?" ──────────────────
    if (_matchesTotalIncomeAndSpend(q)) {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(now.year + 1, 12, 31, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      return FinancialEngineResponse(
        text: '📈 **Total Income & Spending Audit (Tracked History):**\n\n'
            '• Total Earned Income: **₹${_formatCurrency(audit.totalIncome)}**\n'
            '• Total Consumption Spending: **₹${_formatCurrency(audit.totalExpense)}**\n'
            '• Net Cumulative Savings: **₹${_formatCurrency(audit.netSavings)}**\n\n'
            '• Internal Transfers: ₹${_formatCurrency(audit.totalTransfers)} *(excluded from expenses & income)*\n'
            '• Money Lent Out: ₹${_formatCurrency(audit.totalMoneyLent)}\n'
            '• Money Borrowed: ₹${_formatCurrency(audit.totalMoneyBorrowed)}',
        actionButtons: const [
          'What is my current available balance?',
          'Where did most of my money go?',
          'Compare this month with last month',
        ],
      );
    }

    // ── 13. "Am I spending more than usual?" / Spending Pace ────────────────
    if (_matchesSpendingPace(q)) {
      final curStart = DateTime(now.year, now.month, 1, 0, 0, 0);
      final curEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final curAudit = computeAudit(
        transactions: transactions,
        startDate: curStart,
        endDate: curEnd,
      );

      final prevDate = DateTime(now.year, now.month - 1, 1);
      final prevStart = DateTime(prevDate.year, prevDate.month, 1, 0, 0, 0);
      final prevEnd =
          DateTime(prevDate.year, prevDate.month + 1, 0, 23, 59, 59, 999);
      final prevAudit = computeAudit(
        transactions: transactions,
        startDate: prevStart,
        endDate: prevEnd,
      );

      final curDailyPace = curAudit.totalExpense / max(1, now.day);
      final daysInPrev = DateTime(prevDate.year, prevDate.month + 1, 0).day;
      final prevDailyPace = prevAudit.totalExpense / max(1, daysInPrev);

      final buffer = StringBuffer();
      buffer.writeln('📈 **Spending Pace Analysis:**\n');

      if (prevAudit.totalExpense == 0) {
        buffer.writeln(
            'There are no recorded expenses from last month to establish a prior baseline.\n'
            '• Current pace this month: **₹${_formatCurrency(curDailyPace)}/day** (₹${_formatCurrency(curAudit.totalExpense)} total so far).');
      } else {
        final diff = curDailyPace - prevDailyPace;
        final pct = ((diff / prevDailyPace) * 100).toStringAsFixed(1);
        if (diff > 0) {
          buffer.writeln(
              '🔺 **Spending Faster Than Last Month:**\n'
              'You are spending an average of **₹${_formatCurrency(curDailyPace)}/day** this month, compared to **₹${_formatCurrency(prevDailyPace)}/day** last month (+**$pct%** pace increase).\n\n'
              'Primary driver: **${curAudit.topCategory}** (₹${_formatCurrency(curAudit.topCategoryAmount)}).');
        } else if (diff < 0) {
          buffer.writeln(
              '🔻 **Pacing Lower Than Last Month:**\n'
              'Good news! You are spending an average of **₹${_formatCurrency(curDailyPace)}/day** this month, compared to **₹${_formatCurrency(prevDailyPace)}/day** last month (**$pct%** pace decrease).');
        } else {
          buffer.writeln(
              'Your daily spending pace (**₹${_formatCurrency(curDailyPace)}/day**) matches last month exactly.');
        }
      }

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'Where did most of my money go?',
          'How can I save ₹800 this month?',
          'How much budget do I have left?',
        ],
      );
    }

    // ── 14. "How much did I save this month?" ──────────────────────────────
    if (_matchesMonthSavings(q)) {
      final start = DateTime(now.year, now.month, 1, 0, 0, 0);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      final monthName = _monthName(now.month);
      final savingsRate = audit.totalIncome > 0
          ? ((audit.netSavings / audit.totalIncome) * 100).toStringAsFixed(1)
          : '0';

      return FinancialEngineResponse(
        text: '💰 **Savings Report for $monthName ${now.year}:**\n\n'
            '• **Earned Income:** ₹${_formatCurrency(audit.totalIncome)}\n'
            '• **Total Living Expenses:** ₹${_formatCurrency(audit.totalExpense)}\n'
            '• **Net Savings Saved:** **₹${_formatCurrency(audit.netSavings)}** ($savingsRate% savings rate)',
        actionButtons: const [
          'Where did most of my money go?',
          'How can I save ₹800 this month?',
          'What is my current available balance?',
        ],
      );
    }

    // ── 15. "How much did I earn this month?" ──────────────────────────────
    if (_matchesMonthEarn(q)) {
      final start = DateTime(now.year, now.month, 1, 0, 0, 0);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      final monthName = _monthName(now.month);
      final buffer = StringBuffer();
      buffer.writeln('💼 **Earnings Report for $monthName ${now.year}:**\n');
      buffer.writeln('• **Total Earned Income:** ₹${_formatCurrency(audit.totalIncome)}');

      if (audit.totalTransfers > 0) {
        buffer.writeln(
            '• **Internal Transfers:** ₹${_formatCurrency(audit.totalTransfers)} *(strictly excluded from earnings)*');
      }
      if (audit.totalRepaymentsReceived > 0) {
        buffer.writeln(
            '• **Loan Repayments Received:** ₹${_formatCurrency(audit.totalRepaymentsReceived)} *(accounted separately)*');
      }
      if (audit.categoryIncome.isNotEmpty) {
        buffer.writeln('\n**Income Sources:**');
        audit.categoryIncome.forEach((cat, amt) {
          buffer.writeln('  - $cat: ₹${_formatCurrency(amt)}');
        });
      } else {
        buffer.writeln('\n*No income recorded yet for $monthName ${now.year}.*');
      }

      buffer.writeln('\n• **Month Net Savings:** ₹${_formatCurrency(audit.netSavings)}');

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'How much did I spend today?',
          'Compare this month with last month',
          'How much budget do I have left?',
        ],
      );
    }

    // ── 16. "Where did most of my money go?" / Top expense area ───────────
    if (_matchesTopSpending(q)) {
      final start = DateTime(now.year, now.month, 1, 0, 0, 0);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      final monthName = _monthName(now.month);
      if (audit.totalExpense == 0 || audit.categoryExpenses.isEmpty) {
        return FinancialEngineResponse(
          text: '📊 **Spending Analysis for $monthName ${now.year}:**\n\n'
              'You have no recorded expenses in $monthName ${now.year}. All tracked funds are intact!',
          actionButtons: const [
            'How much did I earn this month?',
            'How much budget do I have left?',
          ],
        );
      }

      final sorted = audit.categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top = sorted.first;
      final topPercent = ((top.value / audit.totalExpense) * 100).toStringAsFixed(1);

      final buffer = StringBuffer();
      buffer.writeln('🎯 **Top Outflows for $monthName ${now.year}:**\n');
      buffer.writeln(
          'Most of your money went to **${top.key}**, totaling **₹${_formatCurrency(top.value)}** ($topPercent% of all expenses).\n');
      buffer.writeln('**Full Category Breakdown:**');
      for (final entry in sorted) {
        final pct = ((entry.value / audit.totalExpense) * 100).toStringAsFixed(1);
        buffer.writeln(
            '• **${entry.key}**: ₹${_formatCurrency(entry.value)} ($pct%)');
      }

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'How can I save ₹800 this month?',
          'How much budget do I have left?',
          'Compare this month with last month',
        ],
      );
    }

    // ── 17. "How much budget do I have left?" ──────────────────────────────
    if (_matchesBudgetRemaining(q)) {
      final currentYear = now.year;
      final currentMonth = now.month;
      final monthName = _monthName(currentMonth);

      final activeBudgets = budgets
          .where((b) => b.year == currentYear && b.month == currentMonth)
          .toList();

      if (activeBudgets.isEmpty) {
        return FinancialEngineResponse(
          text: '💡 **Budget Status for $monthName $currentYear:**\n\n'
              'You haven\'t set category budgets for $monthName $currentYear yet.\n'
              'Setting category limits keeps discretionary spending in check.',
          actionButtons: const [
            'Set Category Budget',
            'Review my spending this month',
          ],
        );
      }

      double totalLimit = 0.0;
      double totalSpent = 0.0;
      final buffer = StringBuffer();
      buffer.writeln('🛡️ **Active Budgets for $monthName $currentYear:**\n');

      for (final b in activeBudgets) {
        final spent = b.calculateSpent(transactions);
        final remaining = b.calculateRemaining(transactions);
        final ratio = (b.calculateRatio(transactions) * 100).toStringAsFixed(0);
        totalLimit += b.limitAmount;
        totalSpent += spent;

        final statusEmoji = spent > b.limitAmount
            ? '⚠️ Exceeded'
            : (spent >= b.limitAmount * 0.85 ? '⚡ Near Limit' : '✅ Healthy');

        buffer.writeln(
            '• **${b.category}**: ₹${_formatCurrency(spent)} of ₹${_formatCurrency(b.limitAmount)} ($ratio% used) — $statusEmoji');
        buffer.writeln('  Remaining: **₹${_formatCurrency(remaining)}**');
      }

      final overallRemaining = max(0.0, totalLimit - totalSpent);
      buffer.writeln(
          '\n📊 **Overall Budget Remaining:** **₹${_formatCurrency(overallRemaining)}** '
          'out of ₹${_formatCurrency(totalLimit)}.');

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'Where did most of my money go?',
          'How can I save ₹800 this month?',
          'Compare this month with last month',
        ],
      );
    }

    // ── 18. "Compare this month with last month" ───────────────────────────
    if (_matchesMonthComparison(q)) {
      final curStart = DateTime(now.year, now.month, 1, 0, 0, 0);
      final curEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final curAudit = computeAudit(
        transactions: transactions,
        startDate: curStart,
        endDate: curEnd,
      );

      final prevDate = DateTime(now.year, now.month - 1, 1);
      final prevStart = DateTime(prevDate.year, prevDate.month, 1, 0, 0, 0);
      final prevEnd =
          DateTime(prevDate.year, prevDate.month + 1, 0, 23, 59, 59, 999);
      final prevAudit = computeAudit(
        transactions: transactions,
        startDate: prevStart,
        endDate: prevEnd,
      );

      final curName = _monthName(now.month);
      final prevName = _monthName(prevDate.month);

      final diffExpense = curAudit.totalExpense - prevAudit.totalExpense;
      final pctExpense = prevAudit.totalExpense > 0
          ? ((diffExpense / prevAudit.totalExpense) * 100).toStringAsFixed(1)
          : 'N/A';

      final diffIncome = curAudit.totalIncome - prevAudit.totalIncome;

      final buffer = StringBuffer();
      buffer.writeln('📈 **Month-over-Month Comparison ($curName vs $prevName ${now.year}):**\n');
      buffer.writeln('• **Spending:**');
      buffer.writeln('  - $prevName: ₹${_formatCurrency(prevAudit.totalExpense)}');
      buffer.writeln('  - $curName: ₹${_formatCurrency(curAudit.totalExpense)}');

      if (diffExpense > 0) {
        buffer.writeln(
            '  - Difference: 🔺 **+₹${_formatCurrency(diffExpense)}** (+$pctExpense%)');
      } else if (diffExpense < 0) {
        buffer.writeln(
            '  - Difference: 🔻 **-₹${_formatCurrency(diffExpense.abs())}** ($pctExpense%)');
      } else {
        buffer.writeln('  - Difference: Exact match with last month.');
      }

      buffer.writeln('\n• **Income:**');
      buffer.writeln('  - $prevName: ₹${_formatCurrency(prevAudit.totalIncome)}');
      buffer.writeln('  - $curName: ₹${_formatCurrency(curAudit.totalIncome)}');
      if (diffIncome != 0) {
        final sign = diffIncome > 0 ? '+' : '-';
        buffer.writeln('  - Difference: $sign₹${_formatCurrency(diffIncome.abs())}');
      }

      buffer.writeln('\n• **Net Savings:**');
      buffer.writeln('  - $prevName: ₹${_formatCurrency(prevAudit.netSavings)}');
      buffer.writeln('  - $curName: ₹${_formatCurrency(curAudit.netSavings)}');

      return FinancialEngineResponse(
        text: buffer.toString().trim(),
        actionButtons: const [
          'Where did most of my money go?',
          'How can I save ₹800 this month?',
          'How much budget do I have left?',
        ],
      );
    }

    // ── 19. Category Spend Queries (Food, Shopping, Travel, Bills, etc.) ───
    final catQuery = _matchCategorySpend(q, transactions);
    if (catQuery != null) {
      final categoryName = catQuery['category'] as String;
      final start = DateTime(now.year, now.month, 1, 0, 0, 0);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      final catSpent = audit.categoryExpenses[categoryName] ?? 0.0;
      final monthName = _monthName(now.month);

      return FinancialEngineResponse(
        text: '🛍️ **$categoryName Spending in $monthName ${now.year}:**\n\n'
            '• Total Recorded: **₹${_formatCurrency(catSpent)}**\n'
            '• Share of Monthly Spending: ${audit.totalExpense > 0 ? ((catSpent / audit.totalExpense) * 100).toStringAsFixed(1) : 0}%',
        actionButtons: const [
          'Where did most of my money go?',
          'How much budget do I have left?',
        ],
      );
    }

    // ── 20. Missing Data / Ambiguity Guards ────────────────────────────────
    final ambiguousResponse = _checkAmbiguity(q, transactions, now);
    if (ambiguousResponse != null) {
      return ambiguousResponse;
    }

    // ── 21. Personalized Savings Plan ("Where can I reduce my spending?") ─
    final savingsMatch = _matchSavingsGoalQuery(q);
    if (savingsMatch != null) {
      final targetAmount = savingsMatch['target'] as double;
      return _generatePersonalizedSavingsPlan(
        targetAmount: targetAmount,
        transactions: transactions,
        budgets: budgets,
        savingsGoals: savingsGoals,
        userConsented: userConsented,
        now: now,
      );
    }

    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. FINANCIAL EDUCATION ENGINE (OFFLINE DETERMINISTIC)
  // ───────────────────────────────────────────────────────────────────────────

  static FinancialEngineResponse? evaluateFinancialEducation(String q) {
    // 1. SIP
    if (q.contains('what is an sip') ||
        q.contains('what is a sip') ||
        q.contains('what is sip') ||
        q.contains('explain sip') ||
        q.contains('explain sips') ||
        q.contains('systematic investment plan')) {
      return const FinancialEngineResponse(
        text: '📈 **What is an SIP (Systematic Investment Plan)?**\n\n'
            'An **SIP** is an investment strategy where you invest a fixed amount of money at regular intervals (typically monthly or weekly) into a mutual fund rather than investing a lump sum.\n\n'
            '**Key Advantages:**\n'
            '1. **Rupee-Cost Averaging**: You buy more mutual fund units when market prices are low and fewer units when prices are high, smoothing out market volatility.\n'
            '2. **Power of Compounding**: Regular earnings generate their own earnings over long horizons.\n'
            '3. **Disciplined Habit**: Automates investing so you save before spending.\n\n'
            '💡 **Hypothetical Illustration:**\n'
            '*If you invest a hypothetical ₹1,000 every month for 10 years (total deposited: ₹1,20,000), compounding at an illustrative 12% annual return would accumulate to approximately ₹2,32,000.*\n\n'
            '⚠️ *Disclaimer: Hypothetical illustration for financial education only. Mutual fund investments are subject to market risks.*',
        actionButtons: [
          'What are mutual funds, stocks, and ETFs?',
          'What is compound interest?',
          'How can I save ₹800 this month?',
        ],
      );
    }

    // 2. Mutual Funds, Stocks, and ETFs
    if ((q.contains('mutual fund') ||
            q.contains('stocks and etf') ||
            q.contains('stock and etf') ||
            (q.contains('stock') && q.contains('etf'))) &&
        (q.contains('what') || q.contains('explain') || q.contains('difference'))) {
      return const FinancialEngineResponse(
        text: '🏛️ **Stocks, Mutual Funds & ETFs Explained:**\n\n'
            '• **Individual Stocks**: Direct ownership of a share in a single company. Offers highest growth potential but carries company-specific risk and volatility.\n\n'
            '• **Mutual Funds**: A pool of money collected from many investors and managed by professional fund managers across hundreds of companies and bonds.\n\n'
            '• **ETFs (Exchange-Traded Funds)**: Similar to mutual funds in diversification, but trade directly on stock exchanges throughout the trading day like regular stocks, typically with lower expense ratios.\n\n'
            '💡 **Hypothetical Illustration:**\n'
            '*Buying ₹5,000 of one stock ties your fate to one company. Putting ₹5,000 into an index ETF distributes your ₹5,000 across the top 50 companies.*\n\n'
            '⚠️ *Disclaimer: Illustrative comparison for financial literacy.*',
        actionButtons: [
          'What is an SIP?',
          'What is compound interest?',
          'What is inflation?',
        ],
      );
    }

    // 3. Compound Interest
    if (q.contains('compound interest')) {
      return const FinancialEngineResponse(
        text: '🌱 **What is Compound Interest?**\n\n'
            'Compound interest is interest earned on your initial principal **plus** the accumulated interest from previous periods—commonly referred to as **"interest on interest"**.\n\n'
            '**How it Works:**\n'
            'Unlike simple interest (which only pays interest on the principal), compound interest accelerates growth exponentially over time.\n\n'
            '💡 **Hypothetical Illustration:**\n'
            '*If you deposit ₹10,000 at an 8% annual compound interest rate:*\n'
            '• Year 1: Earns ₹800 ➔ Balance: ₹10,800\n'
            '• Year 2: Earns 8% on ₹10,800 = ₹864 ➔ Balance: ₹11,664\n'
            '• Year 10: Balance grows to ~₹21,589 without adding any extra deposits!\n\n'
            '⚠️ *Disclaimer: Illustrative mathematical example for educational purposes.*',
        actionButtons: [
          'What is inflation?',
          'What is an emergency fund?',
          'What is an SIP?',
        ],
      );
    }

    // 4. Inflation
    if (q.contains('what is inflation') ||
        q.contains('explain inflation') ||
        q.contains('how does inflation work')) {
      return const FinancialEngineResponse(
        text: '📉 **What is Inflation?**\n\n'
            '**Inflation** is the rate at which the general level of prices for goods and services rises, resulting in a gradual decrease in the purchasing power of your money.\n\n'
            '**Why it Matters:**\n'
            'If your savings earn 3% interest in a traditional account while inflation runs at 6%, your real purchasing power shrinks by 3% every year.\n\n'
            '💡 **Hypothetical Illustration:**\n'
            '*A basket of groceries that costs ₹1,000 today would cost ₹1,060 next year at a 6% annual inflation rate. Keeping cash hidden under a mattress quietly erodes its real value over time.*\n\n'
            '⚠️ *Disclaimer: General financial educational explanation.*',
        actionButtons: [
          'What is an emergency fund?',
          'Difference between saving and investing',
          'What is compound interest?',
        ],
      );
    }

    // 5. Emergency Fund
    if (q.contains('emergency fund')) {
      return const FinancialEngineResponse(
        text: '🛡️ **What is an Emergency Fund?**\n\n'
            'An **Emergency Fund** is a liquid financial safety cushion reserved strictly for unexpected life events, such as medical emergencies, car/home repairs, or sudden job loss.\n\n'
            '**Standard Rule of Thumb:**\n'
            'Save **3 to 6 months** of essential living expenses (rent, groceries, utilities, EMIs, insurance).\n\n'
            '💡 **Hypothetical Illustration:**\n'
            '*If your monthly non-negotiable living expenses total ₹25,000, your target emergency cushion should be between ₹75,000 and ₹1,50,000, kept in a high-yield savings account or liquid fund for immediate withdrawal.*\n\n'
            '⚠️ *Disclaimer: Guidelines are illustrative and depend on personal circumstances.*',
        actionButtons: [
          'How much money do I have left in my budget?',
          'Difference between saving and investing',
          'What is an SIP?',
        ],
      );
    }

    // 6. Difference between Saving and Investing
    if ((q.contains('saving') && q.contains('investing')) &&
        (q.contains('difference') || q.contains('vs') || q.contains('between'))) {
      return const FinancialEngineResponse(
        text: '⚖️ **Saving vs. Investing: What is the Difference?**\n\n'
            '• **Saving**:\n'
            '  - Purpose: Short-term goals and emergency protection (0 to 3 years).\n'
            '  - Risk: Very low / capital preservation.\n'
            '  - Liquidity: Instant access (savings accounts, liquid vaults).\n'
            '  - Limitation: Rarely beats inflation long-term.\n\n'
            '• **Investing**:\n'
            '  - Purpose: Long-term wealth generation (3+ years).\n'
            '  - Risk: Moderate to high (subject to market fluctuations).\n'
            '  - Return: Seeks to outpace inflation and build compounding growth (mutual funds, stocks, real estate).\n\n'
            '💡 *Rule of thumb: Save for peace of mind today; invest for freedom tomorrow.*',
        actionButtons: [
          'What is an SIP?',
          'What is an emergency fund?',
          'How can I save ₹800 this month?',
        ],
      );
    }

    // 7. Budgets and Interest Rates
    if (q.contains('50/30/20') ||
        q.contains('how do budgets') ||
        q.contains('how does budget work') ||
        q.contains('how do interest rates work') ||
        q.contains('how does interest rate work')) {
      return const FinancialEngineResponse(
        text: '📊 **How Budgets & Interest Rates Work:**\n\n'
            '**The 50/30/20 Budget Framework:**\n'
            '• **50% Needs**: Housing, groceries, utilities, transit, medicine.\n'
            '• **30% Wants**: Dining out, shopping, streaming, vacations.\n'
            '• **20% Savings & Debt Repayment**: Emergency buffer, SIPs, paying down loans.\n\n'
            '**How Interest Rates Work:**\n'
            '• **On Borrowing (APR)**: The fee you pay a lender to use their money.\n'
            '• **On Savings (APY)**: The yield you earn for lending your deposits to a bank or fund.\n\n'
            '💡 *Prioritize paying off high-interest debt first to protect your cash flow.*',
        actionButtons: [
          'How much budget do I have left?',
          'Where did most of my money go?',
          'How can I save ₹800 this month?',
        ],
      );
    }

    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. LOCAL PRE-SCREENING: IS FINANCIAL QUERY CLASSIFIER
  // ───────────────────────────────────────────────────────────────────────────

  /// Classifies whether a user question is finance-related or an unrelated prompt.
  /// Used locally before making any network calls to block unsupported topics cleanly.
  static bool isFinancialQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;

    // Explicit non-financial topics block (jokes, code, trivia, weather, games, etc.)
    final nonFinancial = RegExp(
      r'\b(joke|jokes|riddle|riddles|funny|quicksort|algorithm|python|javascript|coding|code|compile|programming|weather|forecast|horoscope|recipe|recipes|cook|cooking|bake|baking|movie|movies|song|songs|lyrics|translate|translation|chess|poem|poetry|story|stories)\b',
    );
    if (nonFinancial.hasMatch(q)) return false;

    // Financial keywords with word boundaries to prevent substring collisions (e.g. 'rs' in 'retrievers')
    final financialWordRegex = RegExp(
      r'\b(spend|spent|spending|spends|expense|expenses|cost|costs|costing|'
      r'income|incomes|earn|earned|earns|earning|salary|salaries|wage|wages|revenue|'
      r'money|cash|fund|funds|rupee|rupees|dollar|dollars|rs|inr|'
      r'balance|balances|net worth|networth|wallet|wallets|vault|vaults|'
      r'budget|budgets|budgeting|limit|limits|saving|savings|save|saved|saves|'
      r'debt|debts|lend|lent|borrow|borrowed|loan|loans|'
      r'owe|owes|owed|repay|repaid|repayment|repayments|repaying|'
      r'collect|collected|collecting|collection|refund|refunds|refunded|reimbursement|'
      r'transaction|transactions|receipt|receipts|purchase|purchases|purchased|'
      r'buy|bought|pay|paid|payment|payments|paying|bill|bills|'
      r'afford|wealth|invest|invests|invested|investing|investment|investments|'
      r'sip|sips|mutual fund|mutual funds|stock|stocks|etf|etfs|'
      r'share market|equity|equities|compound interest|inflation|'
      r'emergency fund|interest rate|interest rates|apr|apy|'
      r'dividend|dividends|portfolio|portfolios|crypto|bitcoin|asset|assets|'
      r'liability|liabilities|50/30/20|snowball|avalanche|'
      r'roast|audit|trim|cut spending|reduce spending|'
      r'insight|insights|summary|overview|report|reports|'
      r'behaviour|behavior|habit|habits|trend|trends|pacing|discretionary|'
      r'groceries|grocery|dining|shopping|transport|travel|finance|financial)\b',
    );

    if (financialWordRegex.hasMatch(q)) return true;

    // Common greeting or capability queries in chat
    final politeTriggers = [
      'hi', 'hello', 'hey', 'who are you', 'what can you do', 'help',
      'start', 'welcome', 'guide'
    ];
    for (final p in politeTriggers) {
      if (q == p || q.startsWith('$p ') || q.endsWith(' $p')) return true;
    }

    return false;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. PERSONALIZED SAVINGS PLAN ENGINE
  // ───────────────────────────────────────────────────────────────────────────

  FinancialEngineResponse _generatePersonalizedSavingsPlan({
    required double targetAmount,
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required List<SavingsGoal> savingsGoals,
    required bool userConsented,
    required DateTime now,
  }) {
    final monthName = _monthName(now.month);

    if (!userConsented) {
      return FinancialEngineResponse(
        text: '🔒 **Data Privacy Consent Required**\n\n'
            'To generate a customized, realistic plan to save ₹${_formatCurrency(targetAmount)} this month, '
            'Spentee AI requires your permission to inspect your local spending breakdown on this device.\n\n'
            '• Your data stays local-first.\n'
            '• No financial transactions are uploaded without explicit approval.',
        needsConsent: true,
        actionButtons: const [
          'Grant Permission & Analyze',
          'General Savings Tips',
        ],
        suggestedSavingsAmount: targetAmount,
        suggestedSavingsTitle: 'Monthly Savings Goal',
      );
    }

    final start = DateTime(now.year, now.month, 1, 0, 0, 0);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    final audit = computeAudit(
      transactions: transactions,
      startDate: start,
      endDate: end,
    );

    final discretionary = <String, double>{};
    audit.categoryExpenses.forEach((cat, amt) {
      final lower = cat.toLowerCase();
      if (lower.contains('food') ||
          lower.contains('dining') ||
          lower.contains('shop') ||
          lower.contains('entert') ||
          lower.contains('other')) {
        discretionary[cat] = amt;
      }
    });

    final totalDiscretionary =
        discretionary.values.fold<double>(0.0, (sum, v) => sum + v);

    final buffer = StringBuffer();
    buffer.writeln(
        '🎯 **Personalized Plan to Save ₹${_formatCurrency(targetAmount)} in $monthName ${now.year}:**\n');

    final itemizedPlans = <Map<String, dynamic>>[];

    if (totalDiscretionary > 0 && totalDiscretionary >= targetAmount) {
      buffer.writeln(
          'Based on your recorded ₹${_formatCurrency(totalDiscretionary)} in discretionary spending this month, '
          'here is a realistic, itemized trimming plan:\n');

      double accumulated = 0.0;
      final sorted = discretionary.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (int i = 0; i < sorted.length; i++) {
        final entry = sorted[i];
        if (accumulated >= targetAmount) break;

        final remainingToCut = targetAmount - accumulated;
        final cutCandidate = min(entry.value * 0.35, remainingToCut);
        final cut = (cutCandidate < 100 && remainingToCut >= 100)
            ? min(remainingToCut, entry.value * 0.5)
            : cutCandidate;

        if (cut > 0) {
          accumulated += cut;
          itemizedPlans.add({
            'category': entry.key,
            'current': entry.value,
            'reduction': cut,
            'target': entry.value - cut,
          });
          buffer.writeln(
              '${itemizedPlans.length}. **${entry.key}**: Trim by **₹${_formatCurrency(cut)}** '
              '(Cap spending at ₹${_formatCurrency(entry.value - cut)} instead of ₹${_formatCurrency(entry.value)}).');
        }
      }
    } else {
      buffer.writeln(
          'Here is an itemized allocation guideline to set aside ₹${_formatCurrency(targetAmount)}:\n');
      final cut1 = (targetAmount * 0.50).roundToDouble();
      final cut2 = (targetAmount * 0.30).roundToDouble();
      final cut3 = targetAmount - cut1 - cut2;

      buffer.writeln('1. **Food & Dining**: Trim non-essential delivery by **₹${_formatCurrency(cut1)}**.');
      buffer.writeln('2. **Shopping**: Postpone impulse retail purchases to save **₹${_formatCurrency(cut2)}**.');
      buffer.writeln('3. **Entertainment**: Pause unneeded entertainment/services for **₹${_formatCurrency(cut3)}**.');
    }

    buffer.writeln(
        '\n⚠️ *Important: These are proposed budget reduction targets, not realized savings. '
        'Savings only materialize when you follow the plan and record less spending.*');

    SavingsGoal? existingGoal;
    for (final g in savingsGoals) {
      if (g.targetAmount == targetAmount &&
          !g.isCompleted &&
          g.createdAt.month == now.month &&
          g.createdAt.year == now.year) {
        existingGoal = g;
        break;
      }
    }

    final bool isGoalPersisted = existingGoal != null;
    if (isGoalPersisted) {
      buffer.writeln(
          '\n📌 *You have an active tracked savings goal for ₹${_formatCurrency(targetAmount)} ("${existingGoal.title}").*');
    } else {
      buffer.writeln(
          '\nTap **"Create Savings Goal"** below to activate and persist this goal in your tracker.');
    }

    final totalFormatted = '₹${_formatCurrency(targetAmount)}';

    return FinancialEngineResponse(
      text: buffer.toString().trim(),
      hasPlanCard: true,
      planData: {
        'total': totalFormatted,
        'needs': {
          'label': 'Target Goal',
          'amount': totalFormatted,
          'percent': 1.0,
        },
        'wants': {
          'label': 'Proposed Reductions',
          'amount': totalFormatted,
          'percent': 1.0,
        },
        'savings': {
          'label': 'Projected Savings Target',
          'amount': totalFormatted,
          'percent': 1.0,
        },
        'status': isGoalPersisted ? 'Tracked' : 'Proposed',
      },
      actionButtons: [
        if (!isGoalPersisted) 'Create Savings Goal',
        'Set Category Budget',
        'How much budget do I have left?',
      ],
      suggestedSavingsAmount: targetAmount,
      suggestedSavingsTitle:
          'Monthly Savings Plan (₹${_formatCurrency(targetAmount)})',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 7. PRIVACY SUMMARY BUILDER (FOR SECURE BACKEND INTEGRATION)
  // ───────────────────────────────────────────────────────────────────────────

  /// Generates a strictly minimal, aggregated summary to provide high-level context
  /// to the secure LLM backend ONLY when explicit consent is given.
  /// NEVER includes transaction notes, IDs, recipient names, or timestamps.
  static Map<String, dynamic> buildMinimalSummary({
    required List<Transaction> transactions,
    required List<Budget> budgets,
    required bool userConsented,
  }) {
    if (!userConsented) {
      return {'consent': false, 'context': 'No financial data shared.'};
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final audit = instance.computeAudit(
      transactions: transactions,
      startDate: start,
      endDate: end,
    );

    final topCategories = audit.categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final minimalCatShares = <String, String>{};
    for (int i = 0; i < min(3, topCategories.length); i++) {
      final entry = topCategories[i];
      final pct = audit.totalExpense > 0
          ? ((entry.value / audit.totalExpense) * 100).toStringAsFixed(0)
          : '0';
      minimalCatShares[entry.key] = '$pct%';
    }

    final insights = instance.generatePersonalizedInsights(
      transactions: transactions,
      budgets: budgets,
      referenceDate: now,
    );

    return {
      'consent': true,
      'month': _monthName(now.month),
      'year': now.year,
      'monthly_spend_total': audit.totalExpense.toStringAsFixed(0),
      'monthly_income_total': audit.totalIncome.toStringAsFixed(0),
      'net_savings': insights.netSavings.toStringAsFixed(0),
      'savings_rate_percent': insights.savingsRate.toStringAsFixed(1),
      'highest_category': insights.highestCategory,
      'data_sufficiency': insights.sufficiencyStatus.name,
      'top_expense_categories_share': minimalCatShares,
      'active_budgets_count': budgets.length,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 8. QUERY MATCHING HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  static bool _matchesMonthlySummary(String q) {
    return q.contains('monthly summary') ||
        q.contains('monthly financial summary') ||
        q.contains('financial summary') ||
        q.contains('monthly report') ||
        q.contains('financial report') ||
        q.contains('monthly overview') ||
        q.contains('financial overview') ||
        q.contains('summary of this month') ||
        q.contains('summary of my finances') ||
        q == 'monthly financial summary' ||
        q == 'financial summary';
  }

  static bool _matchesSpendingAnalysis(String q) {
    return q.contains('spending analysis') ||
        q.contains('analyse my spending') ||
        q.contains('analyze my spending') ||
        q.contains('breakdown of my spending') ||
        q.contains('spending breakdown') ||
        q.contains('category spending analysis') ||
        q.contains('how do i spend my money') ||
        q.contains('where is my money going') ||
        q.contains('analyse spending') ||
        q.contains('analyze spending') ||
        q == 'spending analysis';
  }

  static bool _matchesIncomeAnalysis(String q) {
    return q.contains('income analysis') ||
        q.contains('analyse my income') ||
        q.contains('analyze my income') ||
        q.contains('income breakdown') ||
        q.contains('where does my income come from') ||
        q.contains('income sources') ||
        q.contains('breakdown of my income') ||
        q.contains('analyse income') ||
        q.contains('analyze income') ||
        q == 'income analysis';
  }

  static bool _matchesSavingsInsights(String q) {
    return q.contains('savings insights') ||
        q.contains('saving insights') ||
        q.contains('how are my savings') ||
        q.contains('savings rate') ||
        q.contains('savings advice') ||
        q.contains('savings target') ||
        q.contains('ways to save') ||
        q == 'savings insights';
  }

  static bool _matchesBudgetInsights(String q) {
    return q.contains('budget insights') ||
        q.contains('budget performance') ||
        q.contains('how are my budgets doing') ||
        q.contains('how are my budgets performing') ||
        q.contains('budget analysis') ||
        q.contains('budget limits') ||
        q.contains('budget review') ||
        q == 'budget insights' ||
        q == 'budget performance';
  }

  static bool _matchesSpendingBehaviour(String q) {
    return q.contains('spending behaviour') ||
        q.contains('spending behavior') ||
        q.contains('spending habits') ||
        q.contains('spending habit') ||
        q.contains('spending pattern') ||
        q.contains('spending patterns') ||
        q.contains('recurring spending') ||
        q.contains('spending trends') ||
        q.contains('habit analysis') ||
        q == 'spending behaviour' ||
        q == 'spending behavior';
  }

  static bool _matchesRoastQuery(String q) {
    return q == 'roast me' ||
        q.contains('roast me') ||
        q.contains('roast my spending') ||
        q.contains('roast my habits') ||
        q.contains('give me a roast') ||
        q.contains('spending roast') ||
        q.contains('roast my money') ||
        q.contains('witty spending roast');
  }

  static bool _matchesWhoOwesMe(String q) {
    return q.contains('who owes me') ||
        q.contains('who owes') ||
        q.contains('people who owe me') ||
        q.contains('who do i need to collect from') ||
        q.contains('pending collections');
  }

  static bool _matchesHowMuchLent(String q) {
    return q.contains('lent') &&
        (q.contains('how much') || q.contains('total') || q.contains('money')) &&
        !q.contains('collect') &&
        !q.contains('repay');
  }

  static bool _matchesHowMuchToCollect(String q) {
    if (q.contains('repaid') || q.contains('repayment') || q.contains('collected')) {
      return false;
    }
    return (q.contains('to collect') || q.contains('need to collect')) ||
        (q.contains('collect') &&
            (q.contains('how much') ||
                q.contains('still') ||
                q.contains('need to') ||
                q.contains('pending') ||
                q.contains('outstanding')));
  }

  static bool _matchesHowMuchBorrowed(String q) {
    return q.contains('borrowed') &&
        (q.contains('how much') || q.contains('total') || q.contains('money')) &&
        !q.contains('repay');
  }

  static bool _matchesHowMuchToRepay(String q) {
    return (q.contains('repay') || q.contains('pay back')) &&
        (q.contains('how much') ||
            q.contains('still') ||
            q.contains('need to') ||
            q.contains('pending') ||
            q.contains('left to') ||
            q.contains('do i have to'));
  }

  static bool _matchesRepaidOrCollected(String q) {
    return (q.contains('repaid') ||
            q.contains('repayment') ||
            q.contains('collected') ||
            q.contains('repaid or collected') ||
            q.contains('repay or collect')) &&
        (q.contains('how much') ||
            q.contains('total') ||
            q.contains('track') ||
            q.contains('summary') ||
            q.contains('ledger'));
  }

  static bool _matchesAvailableBalance(String q) {
    return q.contains('available balance') ||
        (q.contains('balance') &&
            (q.contains('current') ||
                q.contains('my') ||
                q.contains('what is') ||
                q.contains('check'))) ||
        q.contains('how much money do i have') ||
        q.contains('how much cash do i have');
  }

  static bool _matchesBiggestExpense(String q) {
    return q.contains('biggest expense') ||
        q.contains('highest expense') ||
        q.contains('largest expense') ||
        q.contains('most expensive') ||
        q.contains('biggest purchase') ||
        q.contains('largest purchase') ||
        q.contains('largest transaction');
  }

  static bool _matchesRecentTransactions(String q) {
    return q.contains('recent transaction') ||
        q.contains('recent transactions') ||
        q.contains('last transactions') ||
        q.contains('latest transaction') ||
        q.contains('latest transactions') ||
        q.contains('show my transactions') ||
        q.contains('show recent') ||
        q.contains('recent purchases') ||
        q.contains('recent activity');
  }

  static bool _matchesTodaySpend(String q) {
    return (q.contains('spend') || q.contains('spent')) &&
        (q.contains('today') || q.contains('so far today'));
  }

  static bool _matchesYesterdaySpend(String q) {
    return (q.contains('spend') || q.contains('spent')) && q.contains('yesterday');
  }

  static bool _matchesWeekSpend(String q) {
    return (q.contains('spend') || q.contains('spent')) &&
        (q.contains('this week') || q.contains('weekly') || q.contains('last 7 days') || q.contains('past 7 days'));
  }

  static bool _matchesMonthSpend(String q) {
    return (q.contains('spend') || q.contains('spent')) &&
        (q.contains('this month') ||
            q.contains('monthly spending') ||
            q.contains('how much did i spend this month') ||
            q.contains('my spending this month')) &&
        !q.contains('last month') &&
        !q.contains('compare') &&
        !q.contains('usual');
  }

  static bool _matchesYearSpend(String q) {
    return (q.contains('spend') || q.contains('spent')) &&
        (q.contains('this year') ||
            q.contains('annual') ||
            q.contains('year to date') ||
            q.contains('spent this year'));
  }

  static bool _matchesTotalIncomeAndSpend(String q) {
    return (q.contains('total income') && (q.contains('spend') || q.contains('expense'))) ||
        q.contains('total spending and income') ||
        q.contains('total income and total spending') ||
        q.contains('all time income') ||
        q.contains('lifetime income') ||
        (q.contains('total income') && q.contains('total')) ||
        q.contains('what is my total income');
  }

  static bool _matchesSpendingPace(String q) {
    return q.contains('spending more than usual') ||
        q.contains('spending more than normal') ||
        q.contains('am i overspending') ||
        q.contains('spending pace') ||
        q.contains('spending trend');
  }

  static bool _matchesMonthSavings(String q) {
    return (q.contains('how much did i save') ||
            q.contains('how much have i saved') ||
            q.contains('my savings this month') ||
            q.contains('save this month')) &&
        !q.contains('how can i save') &&
        !q.contains('how to save');
  }

  static bool _matchesMonthEarn(String q) {
    return (q.contains('earn') || q.contains('earned') || q.contains('income')) &&
        (q.contains('month') || q.contains('this month')) &&
        !q.contains('total income');
  }

  static bool _matchesTopSpending(String q) {
    return (q.contains('where') && (q.contains('money') || q.contains('spent'))) ||
        q.contains('most of my money') ||
        q.contains('top expense') ||
        q.contains('top category') ||
        q.contains('which category did i spend the most') ||
        (q.contains('what') && q.contains('spent most'));
  }

  static bool _matchesBudgetRemaining(String q) {
    return q.contains('budget') &&
        (q.contains('left') || q.contains('remain') || q.contains('how much') || q.contains('have left'));
  }

  static bool _matchesMonthComparison(String q) {
    return (q.contains('compare') && q.contains('month')) ||
        (q.contains('this month') && q.contains('last month')) ||
        q.contains('month over month') ||
        q.contains('vs last month');
  }

  static Map<String, dynamic>? _matchCategorySpend(
      String q, List<Transaction> transactions) {
    if (!q.contains('how much') && !q.contains('spent on') && !q.contains('spend on') && !q.contains('spending on')) {
      return null;
    }

    final categoryMap = {
      'food & dining': ['food', 'dining', 'dinner', 'lunch', 'coffee', 'restaurant', 'cafe'],
      'food & drinks': ['drinks', 'beverage', 'bar'],
      'shopping': ['shopping', 'clothes', 'apparel', 'retail', 'amazon'],
      'transport': ['transport', 'travel', 'commute', 'fuel', 'cab', 'metro', 'transit', 'uber', 'taxi'],
      'bills & utilities': ['bills', 'utilities', 'electricity', 'water', 'recharge', 'wifi', 'internet'],
      'entertainment': ['entertainment', 'movie', 'gaming', 'streaming', 'netflix'],
      'groceries': ['groceries', 'grocery', 'supermarket'],
      'health & care': ['health', 'care', 'medicine', 'medical', 'doctor', 'pharmacy'],
      'salary': ['salary'],
      'freelance': ['freelance'],
      'investments': ['investments', 'investment'],
    };

    for (final entry in categoryMap.entries) {
      for (final keyword in entry.value) {
        if (q.contains(keyword)) {
          final matchingCat = transactions
              .map((tx) => tx.category)
              .firstWhere(
                (c) => c.toLowerCase().trim() == entry.key,
                orElse: () => entry.key.split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
              );
          return {'category': matchingCat};
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? _matchSavingsGoalQuery(String q) {
    if (!q.contains('save') || (!q.contains('how') && !q.contains('can i') && !q.contains('want to') && !q.contains('reduce'))) {
      return null;
    }

    final match = RegExp(r'(?:₹|rs\.?|inr\s*)?(\d{2,7})').firstMatch(q);
    if (match != null) {
      final amt = double.tryParse(match.group(1) ?? '');
      if (amt != null && amt > 0) {
        return {'target': amt};
      }
    }

    if (q.contains('save more money') || q.contains('how to save') || q.contains('reduce my spending')) {
      return {'target': 1000.0};
    }

    return null;
  }

  static FinancialEngineResponse? _checkAmbiguity(
      String q, List<Transaction> transactions, DateTime now) {
    final yearMatch = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(q);
    if (yearMatch != null) {
      final year = int.tryParse(yearMatch.group(1)!);
      if (year != null && (year < 2024 || year > now.year + 1)) {
        return FinancialEngineResponse(
          text: '🔍 **Missing Historical Data for $year:**\n\n'
              'I searched your local transaction records, but no entries were found for the year $year. '
              'Spentee records start from 2026.\n\n'
              'Would you like me to inspect your records for 2026 instead?',
          isAmbiguous: true,
          actionButtons: const [
            'How much did I spend today?',
            'How much did I earn this month?',
          ],
        );
      }
    }

    if (q.contains('how much did i spend on') || q.contains('my spending on')) {
      final tokens = q.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').split(' ');
      final hasSpecificTarget = tokens.length > 5;
      if (hasSpecificTarget) {
        final categoryMatched = transactions.any((tx) =>
            q.contains(tx.category.toLowerCase()) ||
            q.contains(tx.title.toLowerCase()));
        if (!categoryMatched) {
          return const FinancialEngineResponse(
            text: '🤔 **Clarification Needed:**\n\n'
                'I could not find any recorded transactions matching that specific category or description. '
                'Could you clarify which category you are inquiring about (e.g. Food & Dining, Shopping, Transport, or Bills)?\n\n'
                '*To keep your financial reporting completely reliable, Spentee AI never invents or guesses numbers.*',
            isAmbiguous: true,
            actionButtons: [
              'Where did most of my money go?',
              'How much did I spend today?',
            ],
          );
        }
      }
    }

    return null;
  }

  static String _formatCurrency(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString().replaceAllMapped(
            RegExp(r'(\d+?)(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return amount.toStringAsFixed(2);
  }

  static String _formatDate(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) return names[month - 1];
    return 'Month';
  }
}
