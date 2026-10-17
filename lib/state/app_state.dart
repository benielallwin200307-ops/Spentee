import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/roast.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

/// Central state manager with persistent user profile and theme preferences.
class AppState extends ChangeNotifier {
  // Balance
  double _balance = 12450.0;
  double get balance => _balance;

  // User Profile
  String _userUid = '';
  String get userUid => _userUid;

  String _userName = 'Alex';
  String get userName => _userName;

  String _userEmail = 'alex@example.com';
  String get userEmail => _userEmail;

  String _userGender = 'male';
  String get userGender => _userGender;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Selected mascot ('male' or 'female')
  String _selectedMascot = 'male';
  String get selectedMascot => _selectedMascot;

  // Isolated per-user profile mapping keyed by user UID
  final Map<String, dynamic> _userProfiles = {};

  AppState() {
    // Listen to Firebase auth state changes to keep session synchronized
    AuthService.instance.authStateChanges.listen((user) {
      if (user == null && _isAuthenticated) {
        _isAuthenticated = false;
        _userUid = '';
        notifyListeners();
      } else if (user != null && !_isAuthenticated) {
        _isAuthenticated = true;
        _userUid = user.uid;
        _userEmail = user.email ?? _userEmail;
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          _userName = user.displayName!;
        }
        if (_userProfiles.containsKey(user.uid) &&
            _userProfiles[user.uid]['selectedMascot'] != null) {
          _selectedMascot = _userProfiles[user.uid]['selectedMascot'];
          _userGender = _selectedMascot;
        }
        notifyListeners();
      }
    });
  }

  bool hasSavedMascotForUser(String uid) {
    if (uid.isEmpty) return false;
    return _userProfiles.containsKey(uid) &&
        _userProfiles[uid] is Map &&
        _userProfiles[uid]['selectedMascot'] != null;
  }

  String? getSavedMascotForUser(String uid) {
    if (hasSavedMascotForUser(uid)) {
      return _userProfiles[uid]['selectedMascot'] as String?;
    }
    return null;
  }

  void setSelectedMascot(String mascot, {String? uid}) {
    _selectedMascot = mascot;
    _userGender = mascot;
    final targetUid = uid ?? _userUid;
    if (targetUid.isNotEmpty) {
      final existing = _userProfiles[targetUid] is Map
          ? Map<String, dynamic>.from(_userProfiles[targetUid])
          : <String, dynamic>{};
      existing['selectedMascot'] = mascot;
      existing['userGender'] = mascot;
      _userProfiles[targetUid] = existing;
    }
    notifyListeners();
    saveToStorage();
  }

  void setUserProfile({
    required String name,
    required String email,
    required String gender,
    String? uid,
  }) {
    _userName = name;
    _userEmail = email;
    _userGender = gender;
    _selectedMascot = gender;
    _isAuthenticated = true;
    final targetUid = uid ?? _userUid;
    if (targetUid.isNotEmpty) {
      _userUid = targetUid;
      final existing = _userProfiles[targetUid] is Map
          ? Map<String, dynamic>.from(_userProfiles[targetUid])
          : <String, dynamic>{};
      existing['userName'] = name;
      existing['userEmail'] = email;
      existing['selectedMascot'] = gender;
      existing['userGender'] = gender;
      _userProfiles[targetUid] = existing;
    }
    notifyListeners();
    saveToStorage();
  }

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
    saveToStorage();
  }

  Future<void> logout() async {
    try {
      await AuthService.instance.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
    _isAuthenticated = false;
    _userUid = '';
    notifyListeners();
    await saveToStorage();
  }

  Future<File?> _getStorageFile() async {
    try {
      // Primary Android path
      final androidFiles = Directory('/data/user/0/com.spentee.spentee/files');
      if (await androidFiles.exists()) {
        return File('${androidFiles.path}/user_profile.json');
      }
      final androidAppFlutter =
          Directory('/data/user/0/com.spentee.spentee/app_flutter');
      if (await androidAppFlutter.exists()) {
        return File('${androidAppFlutter.path}/user_profile.json');
      }
      // Fallback for desktop / unit tests / local run
      final localDir = Directory('.spentee_storage');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      return File('${localDir.path}/user_profile.json');
    } catch (e) {
      debugPrint('Storage directory lookup error: $e');
      return null;
    }
  }

  Future<void> saveToStorage() async {
    try {
      final file = await _getStorageFile();
      if (file == null) return;
      final data = {
        'userName': _userName,
        'userEmail': _userEmail,
        'userGender': _userGender,
        'selectedMascot': _selectedMascot,
        'selectedLanguage': _selectedLanguage,
        'isAuthenticated': _isAuthenticated,
        'userProfiles': _userProfiles,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving user profile to storage: $e');
    }
  }

  Future<void> initFromStorage() async {
    try {
      final file = await _getStorageFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          if (data.containsKey('userProfiles') && data['userProfiles'] is Map) {
            _userProfiles.addAll(Map<String, dynamic>.from(data['userProfiles']));
          }
          if (data.containsKey('userName') && data['userName'] != null) {
            _userName = data['userName'];
          }
          if (data.containsKey('userEmail') && data['userEmail'] != null) {
            _userEmail = data['userEmail'];
          }
          if (data.containsKey('userGender') && data['userGender'] != null) {
            _userGender = data['userGender'];
          }
          if (data.containsKey('selectedMascot') && data['selectedMascot'] != null) {
            _selectedMascot = data['selectedMascot'];
          }
          if (data.containsKey('selectedLanguage') &&
              data['selectedLanguage'] != null) {
            _selectedLanguage = data['selectedLanguage'];
          }
        }
      }

      // Restore session from Firebase Authentication
      final currentUser = AuthService.instance.currentUser;
      if (currentUser != null) {
        _isAuthenticated = true;
        _userUid = currentUser.uid;
        _userEmail = currentUser.email ?? _userEmail;
        if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
          _userName = currentUser.displayName!;
        }
        if (_userProfiles.containsKey(currentUser.uid) &&
            _userProfiles[currentUser.uid]['selectedMascot'] != null) {
          _selectedMascot = _userProfiles[currentUser.uid]['selectedMascot'];
          _userGender = _selectedMascot;
        }
      } else {
        _isAuthenticated = false;
        _userUid = '';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile from storage: $e');
    }
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
