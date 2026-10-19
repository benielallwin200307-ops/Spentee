import 'dart:math';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';

/// Represents a deterministic financial calculation result over a specific dataset and period.
class FinancialAuditSummary {
  final DateTime startDate;
  final DateTime endDate;
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

/// A high-performance, deterministic Financial Intelligence Engine for Spentee.
/// Guarantees exact arithmetic, prevents double counting, strictly excludes transfers
/// from income/expense totals, handles debt/refund boundaries, and respects user consent.
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
    final cat = tx.category.toLowerCase().trim();
    final title = tx.title.toLowerCase().trim();
    return cat == 'bank transfer' ||
        cat == 'sent to friend' ||
        cat == 'savings vault' ||
        cat == 'wallet transfer' ||
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
    final note = tx.note.toLowerCase();
    final title = tx.title.toLowerCase();
    return note.contains('lent') ||
        note.contains('loan given') ||
        note.contains('lend') ||
        title.contains('lent to') ||
        title.contains('loan to');
  }

  /// Checks if an entry is money borrowed from someone (a liability).
  static bool isMoneyBorrowed(Transaction tx) {
    final note = tx.note.toLowerCase();
    final title = tx.title.toLowerCase();
    return note.contains('borrowed') ||
        note.contains('loan taken') ||
        title.contains('borrowed from') ||
        title.contains('loan from');
  }

  /// Checks if an entry is a repayment for lent/borrowed money.
  static bool isRepayment(Transaction tx) {
    final note = tx.note.toLowerCase();
    final title = tx.title.toLowerCase();
    return note.contains('repaid') ||
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
        // If logged as income, treat as refund offset, do not inflate earned income
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
        if (tx.type == TransactionType.income) {
          repaymentsReceived += tx.amount;
        } else {
          repaymentsMade += tx.amount;
        }
        continue;
      }

      // 5. Transfers: Excluded from income and expense
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
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final q = query.trim().toLowerCase();

    // ── A. "How much did I spend today?" / Today's spending ────────────────
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
          'How much did I earn this month?',
          'Where did most of my money go?',
          'How much budget do I have left?',
        ],
      );
    }

    // ── B. "How much did I earn this month?" / Monthly income ─────────────
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

    // ── C. "Where did most of my money go?" / Top expense area ────────────
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

      // Sort categories descending
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

    // ── D. "How much budget do I have left?" / Budget remaining ────────────
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

    // ── E. "Compare this month with last month" / Month-over-month ─────────
    if (_matchesMonthComparison(q)) {
      // Current Month
      final curStart = DateTime(now.year, now.month, 1, 0, 0, 0);
      final curEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final curAudit = computeAudit(
        transactions: transactions,
        startDate: curStart,
        endDate: curEnd,
      );

      // Previous Month
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

    // ── F. Specific Category Spend Queries (e.g. "How much did I spend on Food?") ─
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
        actionButtons: [
          'Where did most of my money go?',
          'How much budget do I have left?',
        ],
      );
    }

    // ── G. Transfers, Refunds, Lent/Borrowed Specific Inquiries ─────────────
    if (q.contains('transfer') && (q.contains('how much') || q.contains('total') || q.contains('my'))) {
      final start = DateTime(now.year, now.month, 1, 0, 0, 0);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      return FinancialEngineResponse(
        text: '🔄 **Transfers Audit for ${_monthName(now.month)} ${now.year}:**\n\n'
            '• **Total Transfers:** ₹${_formatCurrency(audit.totalTransfers)}\n\n'
            '*Note: In compliance with strict financial accounting, transfers represent reallocations between accounts or vaults and are excluded from expense and income totals.*',
        actionButtons: const [
          'How much did I spend today?',
          'How much did I earn this month?',
        ],
      );
    }

    if (q.contains('refund') && (q.contains('how much') || q.contains('any') || q.contains('total'))) {
      final start = DateTime(now.year, now.month, 1, 0, 0, 0);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      return FinancialEngineResponse(
        text: '💳 **Refunds Audit for ${_monthName(now.month)} ${now.year}:**\n\n'
            '• **Refunds Credited:** ₹${_formatCurrency(audit.totalRefunds)}\n\n'
            '*Note: Refunds are applied directly against expenses to prevent double-counting income or inflating your living expenses.*',
        actionButtons: const [
          'How much did I spend today?',
          'Where did most of my money go?',
        ],
      );
    }

    if ((q.contains('lent') || q.contains('borrowed') || q.contains('loan')) &&
        (q.contains('how much') || q.contains('track') || q.contains('total') || q.contains('money'))) {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(now.year, 12, 31, 23, 59, 59);
      final audit = computeAudit(
        transactions: transactions,
        startDate: start,
        endDate: end,
      );

      return FinancialEngineResponse(
        text: '🤝 **Personal Debt & Receivables Audit:**\n\n'
            '• **Money Lent Out (Receivables):** ₹${_formatCurrency(audit.totalMoneyLent)}\n'
            '• **Repayments Received:** ₹${_formatCurrency(audit.totalRepaymentsReceived)}\n'
            '• **Net Outstanding to Receive:** ₹${_formatCurrency(max(0.0, audit.totalMoneyLent - audit.totalRepaymentsReceived))}\n\n'
            '• **Money Borrowed (Liabilities):** ₹${_formatCurrency(audit.totalMoneyBorrowed)}\n'
            '• **Repayments Made:** ₹${_formatCurrency(audit.totalRepaymentsMade)}\n'
            '• **Net Outstanding to Pay:** ₹${_formatCurrency(max(0.0, audit.totalMoneyBorrowed - audit.totalRepaymentsMade))}',
        actionButtons: const [
          'How much did I earn this month?',
          'How much did I spend today?',
        ],
      );
    }

    // ── H. Ambiguous Period or Missing Historical Data Detection ─────────
    final ambiguousResponse = _checkAmbiguity(q, transactions, now);
    if (ambiguousResponse != null) {
      return ambiguousResponse;
    }

    // ── I. Personalized Advice & Savings Goal Requests ─────────────────────
    // e.g. "How can I save ₹800 this month?"
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

    // Not handled deterministically; eligible for general-purpose AI
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. PERSONALIZED SAVINGS PLAN ENGINE
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

    // Audit current month's spending patterns
    final start = DateTime(now.year, now.month, 1, 0, 0, 0);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    final audit = computeAudit(
      transactions: transactions,
      startDate: start,
      endDate: end,
    );

    // Identify discretionary categories (Food & Dining, Shopping, Entertainment, etc.)
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

    // Realistic itemized plan
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
        // Allocate up to 35% of this category's spend or remaining target
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
      // If current recorded spend is low, distribute target across standard categories
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

    // Check if goal is already created
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
  // 5. PRIVACY SUMMARY BUILDER (FOR SECURE BACKEND INTEGRATION)
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

    // Extract top 3 category percentages only
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

    return {
      'consent': true,
      'month': _monthName(now.month),
      'year': now.year,
      'monthly_spend_total': audit.totalExpense.toStringAsFixed(0),
      'monthly_income_total': audit.totalIncome.toStringAsFixed(0),
      'top_expense_categories_share': minimalCatShares,
      'active_budgets_count': budgets.length,
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. INTERNAL PARSING & AMBIGUITY HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  static bool _matchesTodaySpend(String q) {
    return (q.contains('spend') || q.contains('spent')) &&
        (q.contains('today') || q.contains('so far today'));
  }

  static bool _matchesMonthEarn(String q) {
    return (q.contains('earn') || q.contains('earned') || q.contains('income')) &&
        (q.contains('month') || q.contains('this month'));
  }

  static bool _matchesTopSpending(String q) {
    return (q.contains('where') && (q.contains('money') || q.contains('spent'))) ||
        q.contains('most of my money') ||
        q.contains('top expense') ||
        q.contains('top category') ||
        (q.contains('what') && q.contains('spent most'));
  }

  static bool _matchesBudgetRemaining(String q) {
    return q.contains('budget') &&
        (q.contains('left') || q.contains('remain') || q.contains('how much'));
  }

  static bool _matchesMonthComparison(String q) {
    return (q.contains('compare') && q.contains('month')) ||
        (q.contains('this month') && q.contains('last month')) ||
        q.contains('month over month') ||
        q.contains('vs last month');
  }

  static Map<String, dynamic>? _matchCategorySpend(
      String q, List<Transaction> transactions) {
    if (!q.contains('how much') && !q.contains('spent on') && !q.contains('spend on')) {
      return null;
    }

    final knownCategories = [
      'Food & Dining',
      'Food & Drinks',
      'Shopping',
      'Transport',
      'Bills & Utilities',
      'Entertainment',
      'Groceries',
      'Health & Care',
      'Others',
      'Salary',
      'Freelance',
      'Investments',
    ];

    for (final cat in knownCategories) {
      final name = cat.toLowerCase();
      final tokens = name.split('&').map((t) => t.trim()).toList();
      for (final t in tokens) {
        if (q.contains(t) && t.length > 3) {
          return {'category': cat};
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? _matchSavingsGoalQuery(String q) {
    if (!q.contains('save') || (!q.contains('how') && !q.contains('can i') && !q.contains('want to'))) {
      return null;
    }

    // Look for currency amounts e.g. "800", "₹800", "5000", "rs 800", etc.
    final match = RegExp(r'(?:₹|rs\.?|inr\s*)?(\d{2,7})').firstMatch(q);
    if (match != null) {
      final amt = double.tryParse(match.group(1) ?? '');
      if (amt != null && amt > 0) {
        return {'target': amt};
      }
    }

    if (q.contains('save more money') || q.contains('how to save')) {
      return {'target': 1000.0};
    }

    return null;
  }

  static FinancialEngineResponse? _checkAmbiguity(
      String q, List<Transaction> transactions, DateTime now) {
    // If the query asks for an unknown year/period e.g. "how much did I spend in 2021" or "July 2022"
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

    // If query asks about an ambiguous category not in transactions e.g. "vacation", "crypto"
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
