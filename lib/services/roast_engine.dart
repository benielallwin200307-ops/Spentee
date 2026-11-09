import 'dart:math';
import '../models/budget.dart';
import '../models/roast.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import 'roast_library.dart';

/// Computed financial intelligence metrics used to power personalized, rule-based roasts.
class RoastCalculationData {
  final double todayExpense;
  final double thisWeekExpense;
  final double prevWeekExpense;
  final double thisMonthExpense;
  final double prevMonthExpense;
  final double thisMonthIncome;
  final double totalRefunds;

  final Map<String, double> categorySumsMonth;
  final Map<String, double> categorySumsWeek;
  final Map<String, double> categorySumsToday;

  final String topCategoryMonth;
  final double topCategoryMonthAmount;
  final double topCategoryMonthRatio;

  final String topCategoryWeek;
  final double topCategoryWeekAmount;
  final double topCategoryWeekRatio;

  final int smallPurchasesCount;
  final double smallPurchasesAmount;
  final double largestImpulseAmount;

  final Budget? overrunBudget;
  final double overrunRatio;
  final double overrunAmount;

  final Budget? nearLimitBudget;
  final double nearLimitRatio;
  final double nearLimitRemaining;

  final double totalBudgetRemaining;
  final bool hasBudgets;
  final bool allBudgetsRespected;

  final bool hasGoalReached;
  final int totalTransactionCount;
  final int validExpenseCount;

  const RoastCalculationData({
    required this.todayExpense,
    required this.thisWeekExpense,
    required this.prevWeekExpense,
    required this.thisMonthExpense,
    required this.prevMonthExpense,
    required this.thisMonthIncome,
    required this.totalRefunds,
    required this.categorySumsMonth,
    required this.categorySumsWeek,
    required this.categorySumsToday,
    required this.topCategoryMonth,
    required this.topCategoryMonthAmount,
    required this.topCategoryMonthRatio,
    required this.topCategoryWeek,
    required this.topCategoryWeekAmount,
    required this.topCategoryWeekRatio,
    required this.smallPurchasesCount,
    required this.smallPurchasesAmount,
    required this.largestImpulseAmount,
    this.overrunBudget,
    this.overrunRatio = 0.0,
    this.overrunAmount = 0.0,
    this.nearLimitBudget,
    this.nearLimitRatio = 0.0,
    this.nearLimitRemaining = 0.0,
    required this.totalBudgetRemaining,
    required this.hasBudgets,
    required this.allBudgetsRespected,
    required this.hasGoalReached,
    required this.totalTransactionCount,
    required this.validExpenseCount,
  });

  /// Formats currency with commas and proper precision (e.g. ₹3,200).
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final isInt = amount.truncateToDouble() == amount;
    final numStr = isInt ? amount.toInt().toString() : amount.toStringAsFixed(2);
    final parts = numStr.split('.');
    final integerPart = parts[0];
    final regex = RegExp(r'(\d+?)(?=(\d{3})+(?!\d))');
    final withCommas = integerPart.replaceAllMapped(regex, (Match m) => '${m[1]},');
    final formatted = parts.length > 1 ? '$withCommas.${parts[1]}' : withCommas;
    return '$symbol$formatted';
  }

  /// Identifies transfer transactions that must NOT be counted as expenses or income.
  static bool isTransfer(Transaction tx) {
    if (tx.type == TransactionType.transfer) return true;
    final cat = tx.category.toLowerCase().trim();
    final title = tx.title.toLowerCase().trim();
    final note = tx.note.toLowerCase().trim();
    return cat.contains('transfer') ||
        cat == 'sent to friend' ||
        cat == 'savings vault' ||
        cat == 'vault' ||
        title.contains('transfer') ||
        title.contains('vault deposit') ||
        note.contains('transfer') ||
        note.contains('vault deposit');
  }

  /// Checks if a transaction is a refund or reimbursement.
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

  /// Checks if a transaction is money lent out (an asset, not a consumption expense).
  static bool isMoneyLent(Transaction tx) {
    final note = tx.note.toLowerCase();
    final title = tx.title.toLowerCase();
    return note.contains('lent') ||
        note.contains('loan given') ||
        note.contains('lend') ||
        title.contains('lent to') ||
        title.contains('loan to');
  }

  /// Checks if a transaction is money borrowed (a liability, not earned income).
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

  /// Deterministically computes all financial situation metrics from transactions.
  static RoastCalculationData compute({
    required List<Transaction> transactions,
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    final todayStart = DateTime(now.year, now.month, now.day);
    final thisWeekStart = todayStart.subtract(const Duration(days: 6));
    final prevWeekStart = todayStart.subtract(const Duration(days: 13));

    double todayExpense = 0.0;
    double thisWeekExpense = 0.0;
    double prevWeekExpense = 0.0;
    double thisMonthExpense = 0.0;
    double prevMonthExpense = 0.0;
    double thisMonthIncome = 0.0;
    double totalRefunds = 0.0;

    final Map<String, double> categorySumsMonth = {};
    final Map<String, double> categorySumsWeek = {};
    final Map<String, double> categorySumsToday = {};

    int smallPurchasesCount = 0;
    double smallPurchasesAmount = 0.0;
    double largestImpulse = 0.0;
    int validExpenseCount = 0;

    for (final tx in transactions) {
      // 1. Strictly exclude transfers
      if (isTransfer(tx)) continue;

      // 2. Exclude money lent/borrowed/repayments from consumption
      if (isMoneyLent(tx) || isMoneyBorrowed(tx) || isRepayment(tx)) continue;

      // 3. Track refunds
      if (isRefund(tx)) {
        totalRefunds += tx.amount;
        continue;
      }

      // 4. Track income
      if (tx.type == TransactionType.income) {
        if (tx.date.year == currentYear && tx.date.month == currentMonth) {
          thisMonthIncome += tx.amount;
        }
        continue;
      }

      // 5. Consumption Expenses
      if (tx.type == TransactionType.expense) {
        validExpenseCount++;
        final cat = tx.category.trim().isEmpty ? 'General' : tx.category.trim();

        // Today
        if (tx.date.year == now.year &&
            tx.date.month == now.month &&
            tx.date.day == now.day) {
          todayExpense += tx.amount;
          categorySumsToday[cat] = (categorySumsToday[cat] ?? 0.0) + tx.amount;
        }

        // This week (last 7 days inclusive)
        if (!tx.date.isBefore(thisWeekStart)) {
          thisWeekExpense += tx.amount;
          categorySumsWeek[cat] = (categorySumsWeek[cat] ?? 0.0) + tx.amount;
        } else if (!tx.date.isBefore(prevWeekStart) && tx.date.isBefore(thisWeekStart)) {
          prevWeekExpense += tx.amount;
        }

        // This month (calendar month)
        if (tx.date.year == currentYear && tx.date.month == currentMonth) {
          thisMonthExpense += tx.amount;
          categorySumsMonth[cat] = (categorySumsMonth[cat] ?? 0.0) + tx.amount;

          if (tx.amount <= 150) {
            smallPurchasesCount++;
            smallPurchasesAmount += tx.amount;
          }
          if (tx.amount >= 2500 && tx.amount > largestImpulse) {
            largestImpulse = tx.amount;
          }
        }
        // Prev month
        else if (tx.date.year == prevYear && tx.date.month == prevMonth) {
          prevMonthExpense += tx.amount;
        }
      }
    }

    // Net refunds against month expenses if any
    thisMonthExpense = max(0.0, thisMonthExpense - totalRefunds);

    // Compute top category in month
    String topCatMonth = '';
    double topCatMonthAmt = 0.0;
    categorySumsMonth.forEach((cat, amt) {
      if (amt > topCatMonthAmt) {
        topCatMonthAmt = amt;
        topCatMonth = cat;
      }
    });
    final topCatMonthRatio =
        thisMonthExpense > 0 ? (topCatMonthAmt / thisMonthExpense) : 0.0;

    // Compute top category in week
    String topCatWeek = '';
    double topCatWeekAmt = 0.0;
    categorySumsWeek.forEach((cat, amt) {
      if (amt > topCatWeekAmt) {
        topCatWeekAmt = amt;
        topCatWeek = cat;
      }
    });
    final topCatWeekRatio =
        thisWeekExpense > 0 ? (topCatWeekAmt / thisWeekExpense) : 0.0;

    // Budget evaluation
    Budget? worstOverrunBudget;
    double worstOverrunAmount = 0.0;
    double worstOverrunRatio = 0.0;

    Budget? worstNearLimitBudget;
    double worstNearLimitRatio = 0.0;
    double worstNearLimitRemaining = 0.0;

    double totalRemainingBudget = 0.0;
    bool hasBudgetOverrun = false;

    for (final b in budgets) {
      final spent = b.calculateSpent(transactions);
      if (b.limitAmount > 0) {
        final ratio = spent / b.limitAmount;
        if (spent > b.limitAmount) {
          hasBudgetOverrun = true;
          final diff = spent - b.limitAmount;
          if (diff > worstOverrunAmount) {
            worstOverrunAmount = diff;
            worstOverrunRatio = ratio;
            worstOverrunBudget = b;
          }
        } else if (ratio >= 0.8) {
          if (ratio > worstNearLimitRatio) {
            worstNearLimitRatio = ratio;
            worstNearLimitRemaining = b.limitAmount - spent;
            worstNearLimitBudget = b;
          }
        }
        totalRemainingBudget += max(0.0, b.limitAmount - spent);
      }
    }

    // Savings goals evaluation
    bool goalReached = false;
    for (final g in savingsGoals) {
      if (g.currentAmount >= g.targetAmount && g.targetAmount > 0) {
        goalReached = true;
        break;
      }
    }

    return RoastCalculationData(
      todayExpense: todayExpense,
      thisWeekExpense: thisWeekExpense,
      prevWeekExpense: prevWeekExpense,
      thisMonthExpense: thisMonthExpense,
      prevMonthExpense: prevMonthExpense,
      thisMonthIncome: thisMonthIncome,
      totalRefunds: totalRefunds,
      categorySumsMonth: categorySumsMonth,
      categorySumsWeek: categorySumsWeek,
      categorySumsToday: categorySumsToday,
      topCategoryMonth: topCatMonth,
      topCategoryMonthAmount: topCatMonthAmt,
      topCategoryMonthRatio: topCatMonthRatio,
      topCategoryWeek: topCatWeek,
      topCategoryWeekAmount: topCatWeekAmt,
      topCategoryWeekRatio: topCatWeekRatio,
      smallPurchasesCount: smallPurchasesCount,
      smallPurchasesAmount: smallPurchasesAmount,
      largestImpulseAmount: largestImpulse,
      overrunBudget: worstOverrunBudget,
      overrunRatio: worstOverrunRatio,
      overrunAmount: worstOverrunAmount,
      nearLimitBudget: worstNearLimitBudget,
      nearLimitRatio: worstNearLimitRatio,
      nearLimitRemaining: worstNearLimitRemaining,
      totalBudgetRemaining: totalRemainingBudget,
      hasBudgets: budgets.isNotEmpty,
      allBudgetsRespected: budgets.isNotEmpty && !hasBudgetOverrun,
      hasGoalReached: goalReached,
      totalTransactionCount: transactions.length,
      validExpenseCount: validExpenseCount,
    );
  }
}

/// Pure on-device, data-driven financial roast engine for Spentee.
/// Evaluates verified calculations for today, this week, this month, category totals,
/// budget utilisation, and period comparisons to select hilarious, personalized roasts
/// populated with real data without fabricating figures.
class DynamicRoastEngine {
  DynamicRoastEngine._();

  /// Default friendly onboarding roast when user has insufficient transaction history.
  static const String onboardingRoastText =
      "Your wallet is looking suspiciously peaceful. Add a few transactions and let's see your money story!";

  /// Selects a personalized roast based on the user's actual on-device financial behavior,
  /// selected intensity level, and selected language, applying anti-repetition guards.
  static RoastItem generateRoast({
    required List<Transaction> transactions,
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    String? previousRoastText,
    String? previousRoastId,
    List<String>? recentRoastIds,
    String language = 'English',
    String currencySymbol = '₹',
    RoastIntensity intensity = RoastIntensity.savage,
    DateTime? referenceDate,
  }) {
    final canonLang = RoastLibrary.normalizeLanguage(language);

    final candidateRoasts = getMatchingRoasts(
      transactions: transactions,
      budgets: budgets,
      savingsGoals: savingsGoals,
      language: canonLang,
      currencySymbol: currencySymbol,
      intensity: intensity,
      referenceDate: referenceDate,
    );

    if (candidateRoasts.isEmpty) {
      return RoastLibrary.getOnboardingRoast(canonLang, intensity: intensity);
    }

    if (candidateRoasts.length == 1) {
      return candidateRoasts.first;
    }

    // 1. Filter out candidates matching the immediately preceding roast
    final differentFromPrevious = candidateRoasts.where((r) {
      if (previousRoastId != null && r.id == previousRoastId) return false;
      if (previousRoastText != null &&
          r.text.trim().toLowerCase() == previousRoastText.trim().toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    final pool = differentFromPrevious.isNotEmpty
        ? differentFromPrevious
        : candidateRoasts;

    // 2. Prefer roasts not present in recent history
    final history = recentRoastIds ?? const <String>[];
    final unseen = pool.where((r) => !history.contains(r.id)).toList();
    if (unseen.isNotEmpty) {
      return unseen.first;
    }

    return pool.first;
  }

  /// Returns all eligible candidate roasts in the chosen language and intensity matching the user's real data.
  static List<RoastItem> getMatchingRoasts({
    required List<Transaction> transactions,
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    String language = 'English',
    String currencySymbol = '₹',
    RoastIntensity intensity = RoastIntensity.savage,
    DateTime? referenceDate,
  }) {
    final canonLang = RoastLibrary.normalizeLanguage(language);
    final langStaticRoasts = RoastLibrary.getRoastsForLanguage(canonLang, intensity: intensity);
    final templates = RoastLibrary.getDataDrivenTemplates(canonLang, intensity: intensity);

    // 1. True zero-data state: Empty wallet
    if (transactions.isEmpty) {
      return [RoastLibrary.getOnboardingRoast(canonLang, intensity: intensity)];
    }

    final calc = RoastCalculationData.compute(
      transactions: transactions,
      budgets: budgets,
      savingsGoals: savingsGoals,
      referenceDate: referenceDate,
    );

    // 2. Income only state: Has recorded income, but no expenses to roast
    if (calc.validExpenseCount == 0 && calc.thisMonthIncome > 0) {
      return [RoastLibrary.getIncomeOnlyRoast(canonLang, intensity: intensity)];
    }

    // 3. Insufficient transaction history (< 3 transactions or 0 valid expenses)
    if (calc.totalTransactionCount < 3 || calc.validExpenseCount == 0) {
      return [RoastLibrary.getInsufficientHistoryRoast(canonLang, intensity: intensity)];
    }

    // 4. Evaluate active situations and populate placeholder dictionaries
    final List<MapEntry<RoastCategory, Map<String, String>>> situationContexts = [];

    // Helper to format currency
    String fmt(double amt) =>
        RoastCalculationData.formatCurrency(amt, symbol: currencySymbol);

    // ── Priority 1: Budget Overrun & Warnings ──────────────────────────────
    if (calc.overrunBudget != null) {
      final placeholders = {
        'category': calc.overrunBudget!.category,
        'amount': fmt(calc.overrunAmount),
        'budget': fmt(calc.overrunBudget!.limitAmount),
        'percentage': '${(calc.overrunRatio * 100).round()}%',
        'budget_remaining': fmt(0.0),
        'period': 'this month',
      };
      situationContexts.add(MapEntry(RoastCategory.budgetOverrun, placeholders));
      situationContexts.add(MapEntry(RoastCategory.budgetOverspending, placeholders));
    } else if (calc.nearLimitBudget != null) {
      final placeholders = {
        'category': calc.nearLimitBudget!.category,
        'amount': fmt(calc.nearLimitBudget!.calculateSpent(transactions)),
        'budget': fmt(calc.nearLimitBudget!.limitAmount),
        'percentage': '${(calc.nearLimitRatio * 100).round()}%',
        'budget_remaining': fmt(calc.nearLimitRemaining),
        'period': 'this month',
      };
      situationContexts.add(MapEntry(RoastCategory.budgetOverrun, placeholders));
      situationContexts.add(MapEntry(RoastCategory.budgetOverspending, placeholders));
    }

    // ── Priority 2: Category Dominance ──────────────────────────────────────
    final activeTopCat = calc.topCategoryMonth.isNotEmpty
        ? calc.topCategoryMonth
        : calc.topCategoryWeek;
    final activeTopAmt = calc.topCategoryMonth.isNotEmpty
        ? calc.topCategoryMonthAmount
        : calc.topCategoryWeekAmount;
    final activeTopRatio = calc.topCategoryMonth.isNotEmpty
        ? calc.topCategoryMonthRatio
        : calc.topCategoryWeekRatio;
    final periodStr = calc.topCategoryMonth.isNotEmpty ? 'this month' : 'this week';
    final lowerCat = activeTopCat.toLowerCase();

    // Food & Dining
    final isFood = lowerCat.contains('food') ||
        lowerCat.contains('dining') ||
        lowerCat.contains('restaurant') ||
        lowerCat.contains('swiggy') ||
        lowerCat.contains('zomato') ||
        lowerCat.contains('cafe');
    if (isFood && (activeTopRatio >= 0.20 || activeTopAmt >= 1000)) {
      situationContexts.add(MapEntry(
        RoastCategory.foodDining,
        {
          'category': 'food',
          'amount': fmt(activeTopAmt),
          'period': periodStr,
        },
      ));
    }

    // Shopping & Discretionary
    final isShopping = lowerCat.contains('shop') ||
        lowerCat.contains('cloth') ||
        lowerCat.contains('fashion') ||
        lowerCat.contains('retail') ||
        lowerCat.contains('electronics') ||
        lowerCat.contains('apparel');
    if (isShopping && (activeTopRatio >= 0.18 || activeTopAmt >= 1000)) {
      final placeholders = {
        'category': 'shopping',
        'amount': fmt(activeTopAmt),
        'period': periodStr,
      };
      situationContexts.add(MapEntry(RoastCategory.shopping, placeholders));
      situationContexts.add(MapEntry(RoastCategory.shoppingDiscretionary, placeholders));
    }

    // Commute & Transit
    final isTransit = lowerCat.contains('trans') ||
        lowerCat.contains('commute') ||
        lowerCat.contains('cab') ||
        lowerCat.contains('fuel') ||
        lowerCat.contains('travel') ||
        lowerCat.contains('uber') ||
        lowerCat.contains('ola') ||
        lowerCat.contains('metro');
    if (isTransit && (activeTopRatio >= 0.15 || activeTopAmt >= 600)) {
      final placeholders = {
        'category': 'transport',
        'amount': fmt(activeTopAmt),
        'period': periodStr,
      };
      situationContexts.add(MapEntry(RoastCategory.travelTransport, placeholders));
      situationContexts.add(MapEntry(RoastCategory.transitFuel, placeholders));
    }

    // Entertainment & Subscriptions
    final isEntertainment = lowerCat.contains('entert') ||
        lowerCat.contains('movie') ||
        lowerCat.contains('game') ||
        lowerCat.contains('cinema') ||
        lowerCat.contains('concert');
    if (isEntertainment && (activeTopRatio >= 0.12 || activeTopAmt >= 500)) {
      situationContexts.add(MapEntry(
        RoastCategory.entertainment,
        {
          'category': 'entertainment',
          'amount': fmt(activeTopAmt),
          'period': periodStr,
        },
      ));
    }

    final isSubs = lowerCat.contains('subscript') ||
        lowerCat.contains('stream') ||
        lowerCat.contains('netflix') ||
        lowerCat.contains('prime') ||
        lowerCat.contains('hotstar') ||
        lowerCat.contains('spotify');
    if (isSubs) {
      situationContexts.add(MapEntry(
        RoastCategory.subscriptions,
        {
          'category': 'subscriptions',
          'amount': fmt(activeTopAmt),
          'period': periodStr,
        },
      ));
      situationContexts.add(MapEntry(
        RoastCategory.recurringSubs,
        {
          'category': 'subscriptions',
          'amount': fmt(activeTopAmt),
          'period': periodStr,
        },
      ));
    }

    // Groceries
    final isGroceries = lowerCat.contains('grocer') ||
        lowerCat.contains('supermarket') ||
        lowerCat.contains('vegetable') ||
        lowerCat.contains('market');
    if (isGroceries && (activeTopRatio >= 0.15 || activeTopAmt >= 1000)) {
      situationContexts.add(MapEntry(
        RoastCategory.groceries,
        {
          'category': 'groceries',
          'amount': fmt(activeTopAmt),
          'period': periodStr,
        },
      ));
    }

    // Lifestyle & Self-care
    final isLifestyle = lowerCat.contains('life') ||
        lowerCat.contains('spa') ||
        lowerCat.contains('salon') ||
        lowerCat.contains('beauty') ||
        lowerCat.contains('care');
    if (isLifestyle) {
      situationContexts.add(MapEntry(
        RoastCategory.lifestyle,
        {
          'category': 'lifestyle',
          'amount': fmt(activeTopAmt),
          'period': periodStr,
        },
      ));
    }

    // Online Shopping
    final isOnline = lowerCat.contains('amazon') ||
        lowerCat.contains('flipkart') ||
        lowerCat.contains('myntra') ||
        lowerCat.contains('online');
    if (isOnline) {
      situationContexts.add(MapEntry(
        RoastCategory.onlineShopping,
        {
          'category': 'online shopping',
          'amount': fmt(activeTopAmt),
          'period': periodStr,
        },
      ));
    }

    // Category Heavy (> 30% spent in one category)
    if (activeTopRatio >= 0.30 && activeTopAmt >= 1000) {
      final placeholders = {
        'category': activeTopCat,
        'amount': fmt(activeTopAmt),
        'percentage': '${(activeTopRatio * 100).round()}%',
        'period': periodStr,
      };
      situationContexts.add(MapEntry(RoastCategory.highSpendingCategories, placeholders));
      situationContexts.add(MapEntry(RoastCategory.categoryHeavy, placeholders));
    }

    // ── Priority 3: Frequent Small Purchases ────────────────────────────────
    if (calc.smallPurchasesCount >= 3) {
      final placeholders = {
        'count': '${calc.smallPurchasesCount}',
        'amount': fmt(calc.smallPurchasesAmount),
        'period': 'this month',
      };
      situationContexts.add(MapEntry(RoastCategory.frequentSmallPurchases, placeholders));
      situationContexts.add(MapEntry(RoastCategory.microPurchases, placeholders));
    }

    // ── Priority 4: Cash Flow, Deficit Spending & Savings Habits ─────────────
    if (calc.prevWeekExpense > 0 && calc.thisWeekExpense > 0 && calc.thisWeekExpense < calc.prevWeekExpense) {
      final diff = calc.prevWeekExpense - calc.thisWeekExpense;
      final pct = ((diff / calc.prevWeekExpense) * 100).round();
      situationContexts.add(MapEntry(
        RoastCategory.spendingImproved,
        {
          'amount': fmt(diff),
          'percentage': '$pct%',
          'period': 'this week',
        },
      ));
    } else if (calc.prevMonthExpense > 0 && calc.thisMonthExpense > 0 && calc.thisMonthExpense < calc.prevMonthExpense) {
      final diff = calc.prevMonthExpense - calc.thisMonthExpense;
      final pct = ((diff / calc.prevMonthExpense) * 100).round();
      situationContexts.add(MapEntry(
        RoastCategory.spendingImproved,
        {
          'amount': fmt(diff),
          'percentage': '$pct%',
          'period': 'this month',
        },
      ));
    }

    if (calc.todayExpense == 0.0 && calc.thisMonthExpense > 0) {
      situationContexts.add(MapEntry(
        RoastCategory.disciplinedFrugal,
        {
          'period': 'today',
        },
      ));
    }

    if (calc.allBudgetsRespected && calc.thisMonthExpense > 0) {
      situationContexts.add(MapEntry(
        RoastCategory.withinBudget,
        {
          'budget_remaining': fmt(calc.totalBudgetRemaining),
          'period': 'this month',
        },
      ));
    }

    if (calc.hasGoalReached) {
      situationContexts.add(MapEntry(
        RoastCategory.goalReached,
        {
          'period': 'this month',
        },
      ));
    }

    if (calc.thisMonthIncome > 0 && calc.thisMonthExpense > 0 && calc.thisMonthIncome > calc.thisMonthExpense) {
      final saved = calc.thisMonthIncome - calc.thisMonthExpense;
      final savingsRate = ((saved / calc.thisMonthIncome) * 100).round();
      if (savingsRate >= 30) {
        situationContexts.add(MapEntry(
          RoastCategory.improvingSavings,
          {
            'amount': fmt(saved),
            'percentage': '$savingsRate%',
            'period': 'this month',
          },
        ));
      }
    }

    if (calc.thisMonthExpense > calc.thisMonthIncome && calc.thisMonthIncome > 0) {
      final placeholders = {
        'amount': fmt(calc.thisMonthExpense),
        'period': 'this month',
      };
      situationContexts.add(MapEntry(RoastCategory.incomeVsExpenses, placeholders));
      situationContexts.add(MapEntry(RoastCategory.deficitSpending, placeholders));
    } else {
      situationContexts.add(MapEntry(
        RoastCategory.savingsHabits,
        {
          'amount': fmt(calc.thisMonthExpense),
          'period': 'this month',
        },
      ));
    }

    situationContexts.add(MapEntry(
      RoastCategory.monthlySpendingBehaviour,
      {
        'amount': fmt(calc.thisMonthExpense),
        'period': 'this month',
      },
    ));

    // ── Priority 5: Candidate Assembly ──────────────────────────────────────
    final candidates = <RoastItem>[];

    for (final entry in situationContexts) {
      final sit = entry.key;
      final placeholders = entry.value;

      // 1. Data-driven templates first
      final matchingTemplates = templates.where((t) => t.situation == sit).toList();
      for (final tmpl in matchingTemplates) {
        if (!candidates.any((c) => c.id == tmpl.id)) {
          candidates.add(tmpl.populate(placeholders));
        }
      }

      // 2. Static hand-crafted localized roasts
      for (final r in langStaticRoasts) {
        if (r.situation == sit && !candidates.any((c) => c.id == r.id)) {
          candidates.add(r.populate(placeholders));
        }
      }
    }

    // Fallback: If no situation specifically matched, return all available roasts of this language & intensity
    if (candidates.isEmpty) {
      candidates.addAll(langStaticRoasts);
    }

    return candidates;
  }
}

