import '../models/budget.dart';
import '../models/roast.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import 'roast_library.dart';

/// Pure on-device, language-aware financial roast engine for Spentee.
/// Evaluates deterministic financial metrics to select hilarious, culturally authentic roasts
/// in the user's selected language using English/Roman letters only.
class DynamicRoastEngine {
  DynamicRoastEngine._();

  /// Default friendly onboarding roast when user has insufficient transaction history.
  static const String onboardingRoastText =
      "Your wallet is looking suspiciously peaceful. Add a few transactions and let's see your money story!";

  /// Selects a personalized roast based on the user's actual on-device financial behavior
  /// and selected language, applying anti-repetition guards.
  static RoastItem generateRoast({
    required List<Transaction> transactions,
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    String? previousRoastText,
    String? previousRoastId,
    List<String>? recentRoastIds,
    String language = 'English',
    String currencySymbol = '₹',
  }) {
    final canonLang = RoastLibrary.normalizeLanguage(language);

    final candidateRoasts = getMatchingRoasts(
      transactions: transactions,
      budgets: budgets,
      savingsGoals: savingsGoals,
      language: canonLang,
      currencySymbol: currencySymbol,
    );

    if (candidateRoasts.isEmpty) {
      return RoastLibrary.getOnboardingRoast(canonLang);
    }

    if (candidateRoasts.length == 1) {
      return candidateRoasts.first;
    }

    // 1. Filter out candidate that directly matches the immediately preceding roast
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

  /// Returns all eligible candidate roasts in the chosen language matching the user's real data.
  static List<RoastItem> getMatchingRoasts({
    required List<Transaction> transactions,
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    String language = 'English',
    String currencySymbol = '₹',
  }) {
    final canonLang = RoastLibrary.normalizeLanguage(language);
    final langRoasts = RoastLibrary.getRoastsForLanguage(canonLang);

    // 1. Check for true zero-data state
    if (transactions.isEmpty) {
      return [RoastLibrary.getOnboardingRoast(canonLang)];
    }

    final expenseTxs =
        transactions.where((t) => t.type == TransactionType.expense).toList();

    // 2. Insufficient transaction history (< 3 transactions or 0 expenses)
    if (transactions.length < 3 || expenseTxs.isEmpty) {
      final onboarding = RoastLibrary.getOnboardingRoast(canonLang);
      final insufficient = RoastLibrary.getInsufficientHistoryRoast(canonLang);
      final playful = langRoasts.where((r) => r.situation == RoastCategory.playfulWallet);

      return [
        onboarding,
        insufficient,
        ...playful,
      ];
    }

    final now = DateTime.now();

    // Calculate current month and previous month financial metrics
    double monthExpense = 0.0;
    double monthIncome = 0.0;
    double todayExpense = 0.0;
    double prevMonthExpense = 0.0;
    int smallPurchasesCount = 0;
    bool hasLargeImpulse = false;
    final Map<String, double> categorySums = {};

    final currentMonth = now.month;
    final currentYear = now.year;
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    for (final tx in transactions) {
      // Exclude transfers strictly from earnings and expenses
      if (tx.type == TransactionType.transfer) continue;

      // Current month
      if (tx.date.year == currentYear && tx.date.month == currentMonth) {
        if (tx.type == TransactionType.expense) {
          monthExpense += tx.amount;
          final cat = tx.category.trim().isEmpty ? 'General' : tx.category.trim();
          categorySums[cat] = (categorySums[cat] ?? 0.0) + tx.amount;

          if (tx.date.day == now.day) {
            todayExpense += tx.amount;
          }

          if (tx.amount <= 150) {
            smallPurchasesCount++;
          }
          if (tx.amount >= 2500) {
            hasLargeImpulse = true;
          }
        } else if (tx.type == TransactionType.income) {
          monthIncome += tx.amount;
        }
      }
      // Previous month
      else if (tx.date.year == prevYear && tx.date.month == prevMonth) {
        if (tx.type == TransactionType.expense) {
          prevMonthExpense += tx.amount;
        }
      }
    }

    // Determine top category
    String topCategory = '';
    double topCategoryAmount = 0.0;
    categorySums.forEach((cat, sum) {
      if (sum > topCategoryAmount) {
        topCategoryAmount = sum;
        topCategory = cat;
      }
    });

    final double topCategoryRatio =
        monthExpense > 0 ? (topCategoryAmount / monthExpense) : 0.0;
    final lowerTopCat = topCategory.toLowerCase();

    // Determine active situations supported by real financial data
    final List<RoastCategory> activeSituations = [];

    // Situation: Food & Dining
    final isFood = lowerTopCat.contains('food') ||
        lowerTopCat.contains('dining') ||
        lowerTopCat.contains('restaurant') ||
        lowerTopCat.contains('swiggy') ||
        lowerTopCat.contains('zomato') ||
        lowerTopCat.contains('grocery');
    if (isFood && (topCategoryRatio >= 0.22 || topCategoryAmount >= 1500)) {
      activeSituations.add(RoastCategory.foodDining);
    }

    // Situation: Shopping & Discretionary
    final isShopping = lowerTopCat.contains('shop') ||
        lowerTopCat.contains('cloth') ||
        lowerTopCat.contains('fashion') ||
        lowerTopCat.contains('retail') ||
        lowerTopCat.contains('electronics');
    if (isShopping && (topCategoryRatio >= 0.20 || topCategoryAmount >= 1200)) {
      activeSituations.add(RoastCategory.shoppingDiscretionary);
    }

    // Situation: Commute & Transit
    final isTransit = lowerTopCat.contains('trans') ||
        lowerTopCat.contains('commute') ||
        lowerTopCat.contains('cab') ||
        lowerTopCat.contains('fuel') ||
        lowerTopCat.contains('travel') ||
        lowerTopCat.contains('uber') ||
        lowerTopCat.contains('ola');
    if (isTransit && (topCategoryRatio >= 0.15 || topCategoryAmount >= 800)) {
      activeSituations.add(RoastCategory.transitFuel);
    }

    // Situation: Category Heavy (> 45% spent in one category)
    if (topCategoryRatio >= 0.45 && monthExpense >= 2000) {
      activeSituations.add(RoastCategory.categoryHeavy);
    }

    // Situation: Budget Overruns
    bool hasBudgetOverrun = false;
    for (final b in budgets) {
      final spent = b.calculateSpent(transactions);
      if (spent > b.limitAmount && b.limitAmount > 0) {
        hasBudgetOverrun = true;
        break;
      }
    }
    if (hasBudgetOverrun) {
      activeSituations.add(RoastCategory.budgetOverrun);
    }

    // Situation: Deficit Spending (Expenses > Income)
    if (monthExpense > monthIncome && monthIncome > 0) {
      activeSituations.add(RoastCategory.deficitSpending);
      activeSituations.add(RoastCategory.difficultySaving);
    }

    // Situation: Daily Spending Spike
    if (todayExpense > 2000 || (monthExpense > 0 && todayExpense >= monthExpense * 0.4 && todayExpense >= 1000)) {
      activeSituations.add(RoastCategory.spendingSpike);
    }

    // Situation: Micro Purchases Adding Up
    if (smallPurchasesCount >= 4) {
      activeSituations.add(RoastCategory.microPurchases);
    }

    // Situation: Impulse Purchases
    if (hasLargeImpulse && monthIncome > 0 && (monthExpense / monthIncome) >= 0.5) {
      activeSituations.add(RoastCategory.impulsePurchases);
    }

    // Situation: Savings Goal Reached
    bool hasGoalReached = false;
    for (final g in savingsGoals) {
      if (g.currentAmount >= g.targetAmount && g.targetAmount > 0) {
        hasGoalReached = true;
        break;
      }
    }
    if (hasGoalReached) {
      activeSituations.insert(0, RoastCategory.goalReached);
    }

    // Situation: Improving Savings & Frugal Habits
    if (monthIncome > 0 && monthExpense > 0) {
      final savingsRate = (monthIncome - monthExpense) / monthIncome;
      if (savingsRate >= 0.25) {
        activeSituations.add(RoastCategory.improvingSavings);
        activeSituations.add(RoastCategory.disciplinedFrugal);
      }
    }

    // Situation: Zero Spend Today
    if (todayExpense == 0.0 && monthExpense > 0) {
      activeSituations.add(RoastCategory.disciplinedFrugal);
    }

    // Situation: Within Budget
    if (budgets.isNotEmpty && !hasBudgetOverrun && monthExpense > 0) {
      activeSituations.add(RoastCategory.withinBudget);
    }

    // Situation: Spending Improved vs Previous Month
    if (prevMonthExpense > 0 && monthExpense > 0 && monthExpense < prevMonthExpense) {
      activeSituations.add(RoastCategory.spendingImproved);
    }

    // Situation: Consistent Tracking
    if (transactions.length >= 7) {
      activeSituations.add(RoastCategory.consistentTracking);
    }

    // Collect all candidates matching the active situations in priority order
    final candidates = <RoastItem>[];
    for (final sit in activeSituations) {
      for (final r in langRoasts) {
        if (r.situation == sit && !candidates.any((c) => c.id == r.id)) {
          candidates.add(r);
        }
      }
    }

    // If no specific behavioral trigger fired, provide balanced and playful entries
    if (candidates.isEmpty) {
      return langRoasts.where((r) {
        return r.situation == RoastCategory.playfulWallet ||
            r.situation == RoastCategory.balancedSteady ||
            r.situation == RoastCategory.consistentTracking;
      }).toList();
    }

    // Append playful wallet entries for variety
    final playfulEntries = langRoasts.where((r) => r.situation == RoastCategory.playfulWallet);
    for (final p in playfulEntries) {
      if (!candidates.any((c) => c.id == p.id)) {
        candidates.add(p);
      }
    }

    return candidates;
  }
}
