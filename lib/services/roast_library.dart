import '../models/roast.dart';
import 'roast_data_friendly.dart';
import 'roast_data_savage.dart';
import 'roast_data_brutal.dart';
import 'roast_definition.dart';

/// Comprehensive multilingual library containing exactly 150 unique base roasts
/// (50 Friendly, 50 Savage, 50 Brutal) localized across all 6 supported languages
/// (English, Tamil, Telugu, Hindi, Malayalam, Kannada), totaling 900 localized roast records.
class RoastLibrary {
  RoastLibrary._();

  /// Exactly 150 unique base roast definitions across 15 financial situations.
  static final List<RoastDefinition> allBaseRoasts = [
    ...friendlyRoasts,
    ...savageRoasts,
    ...brutalRoasts,
  ];

  /// Complete collection of 900 localized roast items (150 roasts x 6 languages).
  static final List<RoastItem> allRoasts = _buildAllRoasts();

  /// 56 Data-Driven Roast Templates with verified placeholders:
  /// {amount}, {category}, {period}, {percentage}, {budget_remaining}, {count}
  static const List<RoastItem> dataDrivenTemplates = [
    // ── 1. Food & Dining (6 templates) ──────────────────────────────────
    RoastItem(
      id: 'tmpl_food_01',
      language: 'English',
      category: 'Dining Habits',
      situation: RoastCategory.foodDining,
      mascotEmoji: '🍕',
      text: "Your food spending hit {amount} {period}! At this point, delivery riders should invite you to their team standup! 🍕🛵",
    ),
    RoastItem(
      id: 'tmpl_food_02',
      language: 'English',
      category: 'Foodie Life',
      situation: RoastCategory.foodDining,
      mascotEmoji: '🍔',
      text: "You spent {amount} on food {period}?! The local restaurant is seriously considering adding you to their board of directors! 🍔👑",
    ),
    RoastItem(
      id: 'tmpl_food_03',
      language: 'English',
      category: 'Delivery Spree',
      situation: RoastCategory.foodDining,
      mascotEmoji: '🍳',
      text: "Food delivery cost you {amount} {period}. Your stove is sitting at home wondering if you two are officially broken up! 🍳💔",
    ),
    RoastItem(
      id: 'tmpl_food_04',
      language: 'English',
      category: 'Foodie Life',
      situation: RoastCategory.foodDining,
      mascotEmoji: '🍟',
      text: "{amount} dropped on food {period}. Eating out isn't an occasional treat anymore, it's your primary lifestyle! 🍟👀",
    ),
    RoastItem(
      id: 'tmpl_food_05',
      language: 'English',
      category: 'Dining Habits',
      situation: RoastCategory.foodDining,
      mascotEmoji: '🍜',
      text: "Food cravings devoured {amount} {period}! Your taste buds clearly don't consult your bank balance before ordering. 🍜💸",
    ),
    RoastItem(
      id: 'tmpl_food_06',
      language: 'English',
      category: 'Dining Habits',
      situation: RoastCategory.foodDining,
      mascotEmoji: '🍩',
      text: "A grand {amount} spent on food {period}! Even gourmet food critics don't inspect restaurant menus as often as you do. 🍩🥂",
    ),

    // ── 2. Shopping & Discretionary (6 templates) ────────────────────────
    RoastItem(
      id: 'tmpl_shop_01',
      language: 'English',
      category: 'Retail Therapy',
      situation: RoastCategory.shoppingDiscretionary,
      mascotEmoji: '🛍️',
      text: "{amount} spent on shopping {period}! That checkout button never stood a chance against your impulse power. 🛍️📦",
    ),
    RoastItem(
      id: 'tmpl_shop_02',
      language: 'English',
      category: 'Wardrobe Expansion',
      situation: RoastCategory.shoppingDiscretionary,
      mascotEmoji: '👗',
      text: "Retail therapy cost you {amount} {period}. Your closet is living like royalty while your bank account cries! 👗💸",
    ),
    RoastItem(
      id: 'tmpl_shop_03',
      language: 'English',
      category: 'Retail Therapy',
      situation: RoastCategory.shoppingDiscretionary,
      mascotEmoji: '🛒',
      text: "'I\\'ll just browse' turned into {amount} of shopping {period}. Your self-control was officially on leave! 🛒😅",
    ),
    RoastItem(
      id: 'tmpl_shop_04',
      language: 'English',
      category: 'Retail Therapy',
      situation: RoastCategory.shoppingDiscretionary,
      mascotEmoji: '📦',
      text: "{amount} dropped on retail packages {period}. The courier drivers know your address better than your relatives do! 📦🚚",
    ),
    RoastItem(
      id: 'tmpl_shop_05',
      language: 'English',
      category: 'Wardrobe Expansion',
      situation: RoastCategory.shoppingDiscretionary,
      mascotEmoji: '✨',
      text: "Your shopping haul took {amount} {period}. We hope that purchase brings as much joy as the bill brings regret! 🛍️✨",
    ),
    RoastItem(
      id: 'tmpl_shop_06',
      language: 'English',
      category: 'Retail Therapy',
      situation: RoastCategory.shoppingDiscretionary,
      mascotEmoji: '💳',
      text: "{amount} spent on shopping {period}! You're practically keeping the e-commerce sector afloat single-handedly. 💳🚀",
    ),

    // ── 3. Transport & Commute (5 templates) ─────────────────────────────
    RoastItem(
      id: 'tmpl_trans_01',
      language: 'English',
      category: 'Commute',
      situation: RoastCategory.transitFuel,
      mascotEmoji: '🚗',
      text: "{amount} spent on transport {period}! Are you travelling across town, or did you accidentally take a cab to the moon? 🚗🚀",
    ),
    RoastItem(
      id: 'tmpl_trans_02',
      language: 'English',
      category: 'Transit',
      situation: RoastCategory.transitFuel,
      mascotEmoji: '🚕',
      text: "Commuting cost you {amount} {period}. The transport department is preparing a bronze statue in your honour! 🚕💨",
    ),
    RoastItem(
      id: 'tmpl_trans_03',
      language: 'English',
      category: 'Commute',
      situation: RoastCategory.transitFuel,
      mascotEmoji: '🚲',
      text: "{amount} spent on transit rides {period}. At this rate, buying a bicycle might be the best investment of your life! 🚲💸",
    ),
    RoastItem(
      id: 'tmpl_trans_04',
      language: 'English',
      category: 'Transit',
      situation: RoastCategory.transitFuel,
      mascotEmoji: '🛵',
      text: "Cruising around racked up {amount} {period}. Your wheels are spinning faster than your savings can keep up! 🛵💨",
    ),
    RoastItem(
      id: 'tmpl_trans_05',
      language: 'English',
      category: 'Commute',
      situation: RoastCategory.transitFuel,
      mascotEmoji: '🚘',
      text: "{amount} spent on cab rides {period}. Your driver's kids are getting college degrees thanks to your commute habits! 🚘🎓",
    ),

    // ── 4. Entertainment & Subscriptions (5 templates) ───────────────────
    RoastItem(
      id: 'tmpl_ent_01',
      language: 'English',
      category: 'Subscriptions',
      situation: RoastCategory.recurringSubs,
      mascotEmoji: '📺',
      text: "{amount} spent on entertainment {period}! You have enough streaming passes to launch your own satellite network. 📺🍿",
    ),
    RoastItem(
      id: 'tmpl_ent_02',
      language: 'English',
      category: 'Entertainment',
      situation: RoastCategory.recurringSubs,
      mascotEmoji: '🎮',
      text: "You dropped {amount} on entertainment {period}. Are you having fun, or is your bank card the real punchline here? 🎮😂",
    ),
    RoastItem(
      id: 'tmpl_ent_03',
      language: 'English',
      category: 'Subscriptions',
      situation: RoastCategory.recurringSubs,
      mascotEmoji: '🎬',
      text: "{amount} poured into media and games {period}. You're practically funding half the entertainment industry! 🎬🍿",
    ),
    RoastItem(
      id: 'tmpl_ent_04',
      language: 'English',
      category: 'Entertainment',
      situation: RoastCategory.recurringSubs,
      mascotEmoji: '🎟️',
      text: "That {amount} on leisure {period} better come with VIP seating and personal fireworks! 🎟️✨",
    ),
    RoastItem(
      id: 'tmpl_ent_05',
      language: 'English',
      category: 'Entertainment',
      situation: RoastCategory.recurringSubs,
      mascotEmoji: '🎭',
      text: "Leisure and fun cost {amount} {period}. Good thing laughing is free, because your balance is taking a hit! 🎭💸",
    ),

    // ── 5. Budget Warnings & Overruns (7 templates) ──────────────────────
    RoastItem(
      id: 'tmpl_bud_01',
      language: 'English',
      category: 'Budget Warning',
      situation: RoastCategory.budgetOverrun,
      mascotEmoji: '🚨',
      text: "Alert: You've already blown through {percentage} of your {category} budget with only {budget_remaining} left! 🚨📉",
    ),
    RoastItem(
      id: 'tmpl_bud_02',
      language: 'English',
      category: 'Budget Warning',
      situation: RoastCategory.budgetOverrun,
      mascotEmoji: '⚠️',
      text: "Budget alarm: {category} is at {percentage} of its limit! Tread lightly, you're skating on thin financial ice. ⚠️🧊",
    ),
    RoastItem(
      id: 'tmpl_bud_03',
      language: 'English',
      category: 'Budget Overrun',
      situation: RoastCategory.budgetOverrun,
      mascotEmoji: '🏃',
      text: "You sprinted past your {category} budget by {percentage}! That wasn't a limit, that was an Olympic speed bump to you! 🏃💨",
    ),
    RoastItem(
      id: 'tmpl_bud_04',
      language: 'English',
      category: 'Budget Warning',
      situation: RoastCategory.budgetOverrun,
      mascotEmoji: '✈️',
      text: "Only {budget_remaining} remains in your {category} budget {period}! Time to put the wallet on strict airplane mode. ✈️🔒",
    ),
    RoastItem(
      id: 'tmpl_bud_05',
      language: 'English',
      category: 'Budget Overrun',
      situation: RoastCategory.budgetOverrun,
      mascotEmoji: '🛑',
      text: "Your {category} budget is crying at {percentage} spent. Only {budget_remaining} cushion left before catastrophe! 🛑💸",
    ),
    RoastItem(
      id: 'tmpl_bud_06',
      language: 'English',
      category: 'Budget Warning',
      situation: RoastCategory.budgetOverrun,
      mascotEmoji: '📊',
      text: "Budget checkpoint: You've consumed {percentage} of your {category} cap! That {budget_remaining} reserve won't survive long. ⚠️📊",
    ),
    RoastItem(
      id: 'tmpl_bud_07',
      language: 'English',
      category: 'Budget Overrun',
      situation: RoastCategory.budgetOverrun,
      mascotEmoji: '💥',
      text: "{category} budget hit {percentage}! If monthly spending limits had feelings, this one would be calling the police! 📣💥",
    ),

    // ── 6. Small Frequent Purchases / Micro-purchases (5 templates) ─────
    RoastItem(
      id: 'tmpl_mic_01',
      language: 'English',
      category: 'Micro Purchases',
      situation: RoastCategory.microPurchases,
      mascotEmoji: '☕',
      text: "You made {count} small purchases totaling {amount} {period}. 'It's only a small snack' they said... look at the total! ☕👀",
    ),
    RoastItem(
      id: 'tmpl_mic_02',
      language: 'English',
      category: 'Micro Purchases',
      situation: RoastCategory.microPurchases,
      mascotEmoji: '🪚',
      text: "{count} quick micro-spends added up to {amount} {period}! Paper cuts for your wallet, one tiny swipe at a time. 🪚💸",
    ),
    RoastItem(
      id: 'tmpl_mic_03',
      language: 'English',
      category: 'Micro Purchases',
      situation: RoastCategory.microPurchases,
      mascotEmoji: '🍩',
      text: "Those {count} little treats racked up {amount} {period}. Death by a thousand small cravings! 🍩🛒",
    ),
    RoastItem(
      id: 'tmpl_mic_04',
      language: 'English',
      category: 'Micro Purchases',
      situation: RoastCategory.microPurchases,
      mascotEmoji: '🪙',
      text: "'It\\'s just pocket change' happened {count} times {period} for a grand total of {amount}. Your pocket begs to differ! 🪙🏃",
    ),
    RoastItem(
      id: 'tmpl_mic_05',
      language: 'English',
      category: 'Micro Purchases',
      situation: RoastCategory.microPurchases,
      mascotEmoji: '⛵',
      text: "{count} tiny swipes drained {amount} from your balance {period}. Tiny leaks sink big financial ships! ⛵💦",
    ),

    // ── 7. Overall Spending Spikes & Daily Peaks (6 templates) ───────────
    RoastItem(
      id: 'tmpl_spk_01',
      language: 'English',
      category: 'Spending Spike',
      situation: RoastCategory.spendingSpike,
      mascotEmoji: '🔥',
      text: "You spent {amount} {period}! Did money personally offend you, or was there an emergency spending festival? 🔥🏃",
    ),
    RoastItem(
      id: 'tmpl_spk_02',
      language: 'English',
      category: 'Daily Spike',
      situation: RoastCategory.spendingSpike,
      mascotEmoji: '⚡',
      text: "A wild {amount} vanished from your account {period}. We hope whatever you bought was worth that minor cardiac event! ⚡📉",
    ),
    RoastItem(
      id: 'tmpl_spk_03',
      language: 'English',
      category: 'Spending Spike',
      situation: RoastCategory.spendingSpike,
      mascotEmoji: '🏥',
      text: "Total damage {period}: {amount}. Your wallet is currently in the ICU on intensive life support! 🏥💸",
    ),
    RoastItem(
      id: 'tmpl_spk_04',
      language: 'English',
      category: 'Daily Spike',
      situation: RoastCategory.spendingSpike,
      mascotEmoji: '🏃',
      text: "Whoa! {amount} spent {period}. If spending money burned calories, you'd be a fitness influencer by now! 🏃‍♂️💨",
    ),
    RoastItem(
      id: 'tmpl_spk_05',
      language: 'English',
      category: 'Spending Spike',
      situation: RoastCategory.spendingSpike,
      mascotEmoji: '💳',
      text: "{amount} spent {period}! Your bank sent an automated sigh of sheer exhaustion with that last transaction. 💳😮‍💨",
    ),
    RoastItem(
      id: 'tmpl_spk_06',
      language: 'English',
      category: 'Daily Spike',
      situation: RoastCategory.spendingSpike,
      mascotEmoji: '🏎️',
      text: "You burned through {amount} {period}. At this velocity, we need to install a speedometer on your debit card! 🏎️💨",
    ),

    // ── 8. Comparisons & Category Heavy (6 templates) ────────────────────
    RoastItem(
      id: 'tmpl_cmp_01',
      language: 'English',
      category: 'Progress',
      situation: RoastCategory.spendingImproved,
      mascotEmoji: '📉',
      text: "You cut spending by {percentage} compared to last period, saving {amount}! Look at you evolving into a financial zen master! 📉🎉",
    ),
    RoastItem(
      id: 'tmpl_cmp_02',
      language: 'English',
      category: 'Progress',
      situation: RoastCategory.spendingImproved,
      mascotEmoji: '🧘',
      text: "Spending dropped {percentage} vs last period! Either you unlocked legendary self-control, or you misplaced your phone! 🧘‍♂️✨",
    ),
    RoastItem(
      id: 'tmpl_cmp_03',
      language: 'English',
      category: 'Category Heavy',
      situation: RoastCategory.categoryHeavy,
      mascotEmoji: '📈',
      text: "You're spending {percentage} of your funds on {category} ({amount}) {period}. That's quite an intense focus! 📈🔥",
    ),
    RoastItem(
      id: 'tmpl_cmp_04',
      language: 'English',
      category: 'Category Heavy',
      situation: RoastCategory.categoryHeavy,
      mascotEmoji: '💸',
      text: "{category} swallowed {percentage} ({amount}) of your expenses {period}. Was that a purchase or a personal hostage situation? 💸📊",
    ),
    RoastItem(
      id: 'tmpl_cmp_05',
      language: 'English',
      category: 'Progress',
      situation: RoastCategory.spendingImproved,
      mascotEmoji: '👏',
      text: "Nice! You shaved {amount} ({percentage}) off your expenses compared to last period. Your bank balance thanks you! 👏💚",
    ),
    RoastItem(
      id: 'tmpl_cmp_06',
      language: 'English',
      category: 'Category Heavy',
      situation: RoastCategory.categoryHeavy,
      mascotEmoji: '🎯',
      text: "{percentage} of your money went straight to {category} ({amount}) {period}. Talk about putting all your eggs in one basket! 🎯👀",
    ),

    // ── 9. Positive Savings, Frugality & Budget Health (6 templates) ─────
    RoastItem(
      id: 'tmpl_pos_01',
      language: 'English',
      category: 'Disciplined',
      situation: RoastCategory.disciplinedFrugal,
      mascotEmoji: '🧘',
      text: "Zero spending recorded {period}! Your wallet is officially enjoying a peaceful spa day, completely stress-free. 🧘‍♀️💆",
    ),
    RoastItem(
      id: 'tmpl_pos_02',
      language: 'English',
      category: 'Savings Champion',
      situation: RoastCategory.improvingSavings,
      mascotEmoji: '🐉',
      text: "You saved {amount} ({percentage} of your income) this month! Look at you hoarding wealth like a wise dragon! 🐉💰",
    ),
    RoastItem(
      id: 'tmpl_pos_03',
      language: 'English',
      category: 'Within Budget',
      situation: RoastCategory.withinBudget,
      mascotEmoji: '🎯',
      text: "Boom! You've stayed comfortably within budget with {budget_remaining} left to spare {period}. Self-control looks great on you! 🎯🛡️",
    ),
    RoastItem(
      id: 'tmpl_pos_04',
      language: 'English',
      category: 'Frugal Fortress',
      situation: RoastCategory.disciplinedFrugal,
      mascotEmoji: '📊',
      text: "Clean financial discipline! Managing your expenses with {budget_remaining} safely protected. Even Wall Street is taking notes! 📊👔",
    ),
    RoastItem(
      id: 'tmpl_pos_05',
      language: 'English',
      category: 'Goal Unlocked',
      situation: RoastCategory.goalReached,
      mascotEmoji: '🏆',
      text: "Savings milestone conquered! You stayed disciplined and protected your balance. Now keep that winning streak alive! 🎯🏆",
    ),
    RoastItem(
      id: 'tmpl_pos_06',
      language: 'English',
      category: 'Disciplined',
      situation: RoastCategory.disciplinedFrugal,
      mascotEmoji: '💌',
      text: "Look at that discipline! No unnecessary splurges {period}. Your future self is already sending thank-you notes! 💌✨",
    ),

    // ── 10. Friendly Neutral / Insufficient History (4 templates) ────────
    RoastItem(
      id: 'tmpl_neu_01',
      language: 'English',
      category: 'Getting Started',
      situation: RoastCategory.newUserEmpty,
      mascotEmoji: '🕊️',
      text: "Your wallet is looking suspiciously peaceful. Add a few transactions and let's see your money story!",
    ),
    RoastItem(
      id: 'tmpl_neu_02',
      language: 'English',
      category: 'Fresh Start',
      situation: RoastCategory.insufficientHistory,
      mascotEmoji: '🎯',
      text: "Clean slate alert! No financial crimes detected yet. Log your daily spends whenever you're ready! 🎯😌",
    ),
    RoastItem(
      id: 'tmpl_neu_03',
      language: 'English',
      category: 'Fresh Start',
      situation: RoastCategory.insufficientHistory,
      mascotEmoji: '☕',
      text: "Just getting started! Keep tracking your daily coffee, travel, and snacks to unlock custom spending roasts. ☕✨",
    ),
    RoastItem(
      id: 'tmpl_neu_04',
      language: 'English',
      category: 'Getting Started',
      situation: RoastCategory.newUserEmpty,
      mascotEmoji: '🌶️',
      text: "Tracking mode active. As you log transactions, your personal financial mascot will serve up spicy observations! 🌶️👀",
    ),
  ];

  static List<RoastItem> _buildAllRoasts() {
    final list = <RoastItem>[];
    const languages = ['English', 'Tamil', 'Telugu', 'Hindi', 'Malayalam', 'Kannada'];
    for (final lang in languages) {
      for (final def in allBaseRoasts) {
        list.add(def.toRoastItem(lang));
      }
    }
    return list;
  }

  /// Normalizes language input to one of the 6 canonical supported languages.
  static String normalizeLanguage(String? lang) {
    if (lang == null || lang.trim().isEmpty) return 'English';
    final lower = lang.trim().toLowerCase();
    if (lower.contains('tamil') || lower == 'ta') return 'Tamil';
    if (lower.contains('hindi') || lower == 'hi') return 'Hindi';
    if (lower.contains('telugu') || lower == 'te') return 'Telugu';
    if (lower.contains('kannada') || lower == 'kn') return 'Kannada';
    if (lower.contains('malayalam') || lower == 'ml') return 'Malayalam';
    return 'English';
  }

  /// Returns all roasts for a given language, optionally filtered by intensity.
  static List<RoastItem> getRoastsForLanguage(
    String language, {
    RoastIntensity? intensity,
  }) {
    final canon = normalizeLanguage(language);
    return allRoasts.where((r) {
      if (r.language != canon) return false;
      if (intensity != null && r.intensity != intensity) return false;
      return true;
    }).toList();
  }

  /// Returns a roast by its stable ID in the requested language.
  static RoastItem? getRoastById(String id, String language) {
    final canon = normalizeLanguage(language);
    final def = allBaseRoasts.firstWhere(
      (d) => d.id == id,
      orElse: () => allBaseRoasts.first,
    );
    return def.toRoastItem(canon);
  }

  /// Special state: Onboarding / zero data empty wallet roast.
  static RoastItem getOnboardingRoast(
    String language, {
    RoastIntensity intensity = RoastIntensity.friendly,
  }) {
    final canon = normalizeLanguage(language);
    final texts = {
      'English': "Give me some transactions first. I can't roast an empty wallet! 👛✨",
      'Tamil': "Mothalla konjam transactions add pannunga. Kaali wallet-ah roast panna mudiyathu! 👛✨",
      'Telugu': "Mundu konni transactions add cheyandi. Kaali purse ni roast cheyaleru kada! 👛✨",
      'Hindi': "Pehle kuch transactions add karo. Khali wallet ko roast nahi kar sakta! 👛✨",
      'Malayalam': "Aadhyam kurachu transactions add cheyyu. Kaali purseine roast cheyyaan pattilla! 👛✨",
      'Kannada': "Modalu konjam transactions add madi. Khali wallet na roast madakke aagalla! 👛✨",
    };

    return RoastItem(
      id: 'r_onboarding',
      language: canon,
      text: texts[canon] ?? texts['English']!,
      category: 'Welcome to Spentee',
      mascotEmoji: '👛',
      situation: RoastCategory.newUserEmpty,
      intensity: intensity,
    );
  }

  /// Special state: Income recorded, but no expenses to roast.
  static RoastItem getIncomeOnlyRoast(
    String language, {
    RoastIntensity intensity = RoastIntensity.friendly,
  }) {
    final canon = normalizeLanguage(language);
    final texts = {
      'English': "Your income has arrived, but I don't have any expenses to roast yet! 💰🌱",
      'Tamil': "Unga income vanthuruchu, aana roast panna innum expense onnum varala! 💰🌱",
      'Telugu': "Mee income vachesindi, kani roast cheyadaniki inka expenses em levu! 💰🌱",
      'Hindi': "Aapki income toh aa gayi, par roast karne ke liye abhi koi kharcha nahi hai! 💰🌱",
      'Malayalam': "Ningalude income vannu, pakshe roast cheyyaan expenses onnum vannittilla! 💰🌱",
      'Kannada': "Nimma income banthu, aadre roast madakke innu expenses enu bandilla! 💰🌱",
    };

    return RoastItem(
      id: 'r_income_only',
      language: canon,
      text: texts[canon] ?? texts['English']!,
      category: 'Income Recorded',
      mascotEmoji: '💰',
      situation: RoastCategory.incomeVsExpenses,
      intensity: intensity,
    );
  }

  /// Special state: Insufficient transaction history (e.g. fewer than 3 records).
  static RoastItem getInsufficientHistoryRoast(
    String language, {
    RoastIntensity intensity = RoastIntensity.friendly,
  }) {
    final canon = normalizeLanguage(language);
    final texts = {
      'English': "Log at least 3 transactions to reveal your personalized financial roast! 📊✨",
      'Tamil': "Unga personalized roast paaka kuraingathathu 3 transactions add pannunga! 📊✨",
      'Telugu': "Mee personalized roast chudali ante kanisam 3 transactions add cheyandi! 📊✨",
      'Hindi': "Apna personalized roast dekhne ke liye kam se kam 3 transactions add karein! 📊✨",
      'Malayalam': "Personalized roast kaanaan kuranjath 3 transactions add cheyyuka! 📊✨",
      'Kannada': "Personalized roast nodokke kadime andre 3 transactions add madi! 📊✨",
    };

    return RoastItem(
      id: 'r_insufficient_history',
      language: canon,
      text: texts[canon] ?? texts['English']!,
      category: 'Data Needed',
      mascotEmoji: '📊',
      situation: RoastCategory.insufficientHistory,
      intensity: intensity,
    );
  }

  /// Dynamic data-driven templates with verified placeholder interpolation.
  static List<RoastItem> getDataDrivenTemplates(
    String language, {
    RoastIntensity intensity = RoastIntensity.savage,
  }) {
    final canon = normalizeLanguage(language);
    final list = dataDrivenTemplates
        .map((t) => t.copyWith(language: canon, intensity: intensity))
        .toList();

    switch (intensity) {
      case RoastIntensity.friendly:
        list.addAll([
          RoastItem(
            id: 'tpl_f_food',
            language: canon,
            category: 'Food & Dining',
            situation: RoastCategory.foodDining,
            mascotEmoji: '🍕',
            intensity: RoastIntensity.friendly,
            text: "{amount} on {category}? Your tastebuds are clearly enjoying a wonderful feast this month! 🍕✨",
          ),
          RoastItem(
            id: 'tpl_f_shopping',
            language: canon,
            category: 'Shopping',
            situation: RoastCategory.shopping,
            mascotEmoji: '🛍️',
            intensity: RoastIntensity.friendly,
            text: "{amount} on shopping! Your wardrobe is glowing with new additions! 🛍️✨",
          ),
          RoastItem(
            id: 'tpl_f_budget',
            language: canon,
            category: 'Budget Overrun',
            situation: RoastCategory.budgetOverspending,
            mascotEmoji: '🎯',
            intensity: RoastIntensity.friendly,
            text: "Your {category} budget crossed its ₹{budget} target by {amount}. Let's gently steer it back next week! 🎯🌱",
          ),
          RoastItem(
            id: 'tpl_f_top',
            language: canon,
            category: 'Top Outflow',
            situation: RoastCategory.highSpendingCategories,
            mascotEmoji: '👑',
            intensity: RoastIntensity.friendly,
            text: "{category} took {percentage}% of your spends ({amount}). A clear favorite in your book! 👑📊",
          ),
        ]);
        break;

      case RoastIntensity.brutal:
        list.addAll([
          RoastItem(
            id: 'tpl_b_food',
            language: canon,
            category: 'Food & Dining',
            situation: RoastCategory.foodDining,
            mascotEmoji: '💀',
            intensity: RoastIntensity.brutal,
            text: "{amount} on {category}? Local restaurants should add your portrait to their dining hall of fame! 💀🍽️",
          ),
          RoastItem(
            id: 'tpl_b_shopping',
            language: canon,
            category: 'Shopping',
            situation: RoastCategory.shopping,
            mascotEmoji: '🛍️',
            intensity: RoastIntensity.brutal,
            text: "{amount} on shopping! Your shopping cart is officially the most expensive habit in the zip code! 🛍️📉",
          ),
          RoastItem(
            id: 'tpl_b_budget',
            language: canon,
            category: 'Budget Overrun',
            situation: RoastCategory.budgetOverspending,
            mascotEmoji: '🛑',
            intensity: RoastIntensity.brutal,
            text: "Your {category} budget of ₹{budget} was exceeded by {amount}! You didn't just cross the limit, you incinerated it! 🛑🔥",
          ),
          RoastItem(
            id: 'tpl_b_top',
            language: canon,
            category: 'Top Outflow',
            situation: RoastCategory.highSpendingCategories,
            mascotEmoji: '🕳️',
            intensity: RoastIntensity.brutal,
            text: "{category} swallowed {percentage}% of your expenses ({amount}). Your funds fell into a black hole! 🕳️🌪️",
          ),
        ]);
        break;

      case RoastIntensity.savage:
        list.addAll([
          RoastItem(
            id: 'tpl_s_food',
            language: canon,
            category: 'Food & Dining',
            situation: RoastCategory.foodDining,
            mascotEmoji: '🍕',
            intensity: RoastIntensity.savage,
            text: "{amount} on {category}? Your kitchen must be wondering why it even exists! 🍕📦",
          ),
          RoastItem(
            id: 'tpl_s_shopping',
            language: canon,
            category: 'Shopping',
            situation: RoastCategory.shopping,
            mascotEmoji: '🛒',
            intensity: RoastIntensity.savage,
            text: "{amount} on shopping! Your shopping cart is clearly the most hardworking member of this household! 🛒💳",
          ),
          RoastItem(
            id: 'tpl_s_budget',
            language: canon,
            category: 'Budget Overrun',
            situation: RoastCategory.budgetOverspending,
            mascotEmoji: '🛑',
            intensity: RoastIntensity.savage,
            text: "Your {category} budget had one job (₹{budget}). You blew past it by {amount}! 🛑🏖️",
          ),
          RoastItem(
            id: 'tpl_s_top',
            language: canon,
            category: 'Top Outflow',
            situation: RoastCategory.highSpendingCategories,
            mascotEmoji: '👑',
            intensity: RoastIntensity.savage,
            text: "{category} took {percentage}% of your money ({amount}). You're basically running their company! 👑💸",
          ),
        ]);
        break;
    }
    return list;
  }
}
