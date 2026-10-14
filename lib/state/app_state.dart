import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/roast.dart';
import '../theme/app_theme.dart';

/// Central in-memory state manager for Spentee demo application.
class AppState extends ChangeNotifier {
  // Balance
  double _balance = 12450.0;
  double get balance => _balance;

  // Selected mascot ('male' or 'female')
  String _selectedMascot = 'male';
  String get selectedMascot => _selectedMascot;

  void setSelectedMascot(String mascot) {
    _selectedMascot = mascot;
    notifyListeners();
  }

  // Language selection
  String _selectedLanguage = 'English';
  String get selectedLanguage => _selectedLanguage;

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  // Notification Preferences
  final Map<String, bool> _notifications = {
    'daily': true,
    'weekly': true,
    'budget': true,
    'roasts': true,
    'puzzles': false,
  };
  Map<String, bool> get notifications => Map.unmodifiable(_notifications);

  void toggleNotification(String key) {
    if (_notifications.containsKey(key)) {
      _notifications[key] = !_notifications[key]!;
      notifyListeners();
    }
  }

  // In-memory Transactions list
  final List<Transaction> _transactions = [
    Transaction(
      id: 'tx_1',
      title: 'Food & Drinks',
      amount: 250.0,
      type: TransactionType.expense,
      category: 'Food & Drinks',
      icon: Icons.restaurant_rounded,
      categoryColor: AppTheme.accentPink,
      date: DateTime.now().subtract(const Duration(hours: 3)),
      note: 'Coffee with friends ☕',
    ),
    Transaction(
      id: 'tx_2',
      title: 'Transport',
      amount: 80.0,
      type: TransactionType.expense,
      category: 'Transport',
      icon: Icons.directions_car_rounded,
      categoryColor: AppTheme.accentCyan,
      date: DateTime.now().subtract(const Duration(hours: 6)),
      note: 'Cab to work',
    ),
    Transaction(
      id: 'tx_3',
      title: 'Shopping',
      amount: 490.0,
      type: TransactionType.expense,
      category: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      categoryColor: AppTheme.accentPurple,
      date: DateTime.now().subtract(const Duration(hours: 8)),
      note: 'Casual tee shirt',
    ),
  ];

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  /// Add new transaction with proper financial rules.
  void addTransaction(Transaction tx) {
    _transactions.insert(0, tx);
    if (tx.type == TransactionType.expense) {
      _balance -= tx.amount;
    } else if (tx.type == TransactionType.income) {
      _balance += tx.amount;
    }
    // Note: Transfers do not count as purchases/spending.
    notifyListeners();
  }

  /// Calculate today's spending total.
  double get todaySpending {
    final now = DateTime.now();
    double total = 0.0;
    for (final tx in _transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == now.year &&
          tx.date.month == now.month &&
          tx.date.day == now.day) {
        total += tx.amount;
      }
    }
    return total;
  }

  // Roasts list
  final List<RoastItem> _roasts = [
    const RoastItem(
      text: 'Your money has more exits than a shopping mall. 😎',
      category: 'Impulse Spends',
      mascotEmoji: '😎',
    ),
    const RoastItem(
      text: 'Bro is saving money in his imagination. 💀',
      category: 'Savings Reality',
      mascotEmoji: '💀',
    ),
    const RoastItem(
      text: 'Your wallet needs emotional support right now. 😅',
      category: 'Weekend Budget',
      mascotEmoji: '😅',
    ),
    const RoastItem(
      text: 'Salary entered the chat and immediately left. 💨',
      category: 'First Week',
      mascotEmoji: '💨',
    ),
    const RoastItem(
      text: 'Buying 4 coffees a day isn\'t self-care, it\'s high-interest caffeine debt! ☕💸',
      category: 'Daily Habits',
      mascotEmoji: '☕',
    ),
  ];
  int _currentRoastIndex = 0;

  RoastItem get currentRoast => _roasts[_currentRoastIndex % _roasts.length];

  void nextRoast() {
    _currentRoastIndex = (_currentRoastIndex + 1) % _roasts.length;
    notifyListeners();
  }

  // AI Chat Messages
  final List<ChatMessage> _chatMessages = [
    ChatMessage(
      id: 'chat_1',
      text: "I'm getting ₹25,000 this month. How can I save some amount?",
      isUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessage(
      id: 'chat_2',
      text: "Great question! Let's plan this smartly. Here's a simple plan based on your spending pattern:",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      hasPlanCard: true,
      planData: {
        'total': '₹25,000',
        'needs': {'label': 'Needs (50%)', 'amount': '₹12,500', 'percent': 0.5},
        'wants': {'label': 'Wants (30%)', 'amount': '₹7,500', 'percent': 0.3},
        'savings': {'label': 'Savings (20%)', 'amount': '₹5,000', 'percent': 0.2},
      },
    ),
    ChatMessage(
      id: 'chat_3',
      text: "You can save ₹5,000 this month by reducing food delivery and unplanned shopping. Want me to create a detailed weekly plan?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  void sendUserChatMessage(String userQuery) {
    if (userQuery.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: userQuery.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _chatMessages.add(userMsg);
    notifyListeners();

    // Generate responsive context-aware demo response
    String replyText = "That's a smart thought! Remember, keeping daily expenses under ₹500 leaves you with a sweet surplus by month end.";
    bool hasCard = false;
    Map<String, dynamic>? cardData;

    final q = userQuery.toLowerCase();
    if (q.contains('food') || q.contains('coffee') || q.contains('eat')) {
      replyText = "Your food & drinks category takes up around 29% of your budget. Cooking just 2 more dinners a week saves approximately ₹1,800 monthly! 🍳";
    } else if (q.contains('strict') || q.contains('plan') || q.contains('yes')) {
      replyText = "Here is a stricter 60/20/20 breakdown to supercharge your rainy day fund:";
      hasCard = true;
      cardData = {
        'total': 'Strict Mode Plan',
        'needs': {'label': 'Essentials (60%)', 'amount': '₹15,000', 'percent': 0.6},
        'wants': {'label': 'Fun & Treats (15%)', 'amount': '₹3,750', 'percent': 0.15},
        'savings': {'label': 'Hardcore Savings (25%)', 'amount': '₹6,250', 'percent': 0.25},
      };
    } else if (q.contains('roast') || q.contains('funny')) {
      replyText = "You checked your balance 4 times today hoping it multiplied while you weren't looking. Spoiler: it didn't! 💀";
    } else if (q.contains('iphone') || q.contains('buy')) {
      replyText = "Before buying, try the 72-hour rule: wait 3 days. If you still crave it and it doesn't drain your emergency cushion, consider it!";
    }

    final aiMsg = ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      hasPlanCard: hasCard,
      planData: cardData,
    );
    _chatMessages.add(aiMsg);
    notifyListeners();
  }

  // Leaderboard data
  final List<LeaderboardEntry> dailyLeaderboard = const [
    LeaderboardEntry(rank: 1, username: 'MoneyMaster', time: '00:28', avatarPath: 'Assets/extracted/avatar_win.png', medalColor: AppTheme.accentYellow),
    LeaderboardEntry(rank: 2, username: 'PuzzlePro', time: '00:31', avatarPath: 'Assets/extracted/avatar_happy.png', medalColor: Color(0xFFC0C0C0)),
    LeaderboardEntry(rank: 3, username: 'BrainyBuddy', time: '00:33', avatarPath: 'Assets/extracted/avatar_think.png', medalColor: Color(0xFFCD7F32)),
    LeaderboardEntry(rank: 4, username: 'SmartSpender', time: '00:36', avatarPath: 'Assets/extracted/avatar_chill.png'),
    LeaderboardEntry(rank: 5, username: 'GameGuru', time: '00:39', avatarPath: 'Assets/extracted/avatar_roast.png'),
    LeaderboardEntry(rank: 6, username: 'You', time: '00:42', avatarPath: 'Assets/extracted/mascot_main.png', isCurrentUser: true),
    LeaderboardEntry(rank: 7, username: 'CashNinja', time: '00:45', avatarPath: 'Assets/extracted/avatar_ai.png'),
    LeaderboardEntry(rank: 8, username: 'MindMaster', time: '00:47', avatarPath: 'Assets/extracted/avatar_happy.png'),
  ];

  final List<LeaderboardEntry> weeklyLeaderboard = const [
    LeaderboardEntry(rank: 1, username: 'SaverQueen', time: '00:24', avatarPath: 'Assets/extracted/female_main.png', medalColor: AppTheme.accentYellow),
    LeaderboardEntry(rank: 2, username: 'MoneyMaster', time: '00:27', avatarPath: 'Assets/extracted/avatar_win.png', medalColor: Color(0xFFC0C0C0)),
    LeaderboardEntry(rank: 3, username: 'PuzzlePro', time: '00:29', avatarPath: 'Assets/extracted/avatar_happy.png', medalColor: Color(0xFFCD7F32)),
    LeaderboardEntry(rank: 4, username: 'You', time: '00:34', avatarPath: 'Assets/extracted/mascot_main.png', isCurrentUser: true),
    LeaderboardEntry(rank: 5, username: 'BrainyBuddy', time: '00:35', avatarPath: 'Assets/extracted/avatar_think.png'),
    LeaderboardEntry(rank: 6, username: 'CashNinja', time: '00:38', avatarPath: 'Assets/extracted/avatar_ai.png'),
  ];
}

/// An InheritedNotifier providing AppState down the Flutter widget tree.
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
  }
}
