import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/roast.dart';
import '../models/budget.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/ai_chat_service.dart';

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

  Future<void> updateUserName(String newName) async {
    _userName = newName;
    if (_userUid.isNotEmpty) {
      final existing = _userProfiles[_userUid] is Map
          ? Map<String, dynamic>.from(_userProfiles[_userUid])
          : <String, dynamic>{};
      existing['userName'] = newName;
      _userProfiles[_userUid] = existing;
    }
    try {
      await AuthService.instance.currentUser?.updateDisplayName(newName);
    } catch (e) {
      debugPrint('Firebase display name update error: $e');
    }
    notifyListeners();
    await saveToStorage();
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
        'displayTheme': _displayTheme,
        'notifications': _notifications,
        'notificationTime': _notificationTime,
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
          if (data.containsKey('displayTheme') &&
              data['displayTheme'] != null) {
            _displayTheme = data['displayTheme'];
          }
          if (data.containsKey('notificationTime') &&
              data['notificationTime'] != null) {
            _notificationTime = data['notificationTime'];
          }
          if (data.containsKey('notifications') &&
              data['notifications'] is Map) {
            final notifMap = data['notifications'] as Map;
            notifMap.forEach((k, v) {
              if (v is bool) _notifications[k.toString()] = v;
            });
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

      await loadChatSessionsFromDisk();
      await loadTransactionsFromStorage();
      await loadBudgetsFromStorage();
      await loadCategoriesFromStorage();
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
    saveToStorage();
  }

  void setSelectedLanguage(String lang) => setLanguage(lang);

  // Display Theme ('Dark', 'Light', 'System')
  String _displayTheme = 'Dark';
  String get displayTheme => _displayTheme;

  ThemeMode get themeMode {
    switch (_displayTheme.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  void setDisplayTheme(String theme) {
    _displayTheme = theme;
    notifyListeners();
    saveToStorage();
  }

  // Notification Preferences
  String _notificationTime = '20:00';
  String get notificationTime => _notificationTime;

  void setNotificationTime(String time) {
    _notificationTime = time;
    notifyListeners();
    saveToStorage();
  }

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
      saveToStorage();
    }
  }

  void setNotification(String key, bool value) {
    _notifications[key] = value;
    notifyListeners();
    saveToStorage();
  }

  // In-memory Transactions list
  final List<Transaction> _transactions = [
    Transaction(
      id: 'tx_1',
      title: 'Food & Drinks',
      amount: 250.0,
      type: TransactionType.expense,
      category: 'Food & Dining',
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
    // October 2026 Historical records
    Transaction(
      id: 'tx_oct_sal',
      title: 'Monthly Salary',
      amount: 50000.0,
      type: TransactionType.income,
      category: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      categoryColor: AppTheme.primaryMint,
      date: DateTime(2026, 10, 1, 9, 0),
      note: 'Oct salary credited',
    ),
    Transaction(
      id: 'tx_oct_food1',
      title: 'Weekend Dining',
      amount: 3200.0,
      type: TransactionType.expense,
      category: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      categoryColor: AppTheme.accentPink,
      date: DateTime(2026, 10, 10, 20, 30),
      note: 'Dinner with family',
    ),
    Transaction(
      id: 'tx_oct_food2',
      title: 'Supermarket Groceries',
      amount: 1292.0,
      type: TransactionType.expense,
      category: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      categoryColor: AppTheme.accentPink,
      date: DateTime(2026, 10, 5, 17, 15),
      note: 'Weekly essentials',
    ),
    Transaction(
      id: 'tx_oct_shop',
      title: 'Autumn Apparel',
      amount: 2630.0,
      type: TransactionType.expense,
      category: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      categoryColor: AppTheme.accentPurple,
      date: DateTime(2026, 10, 8, 14, 45),
      note: 'Jacket & jeans',
    ),
    Transaction(
      id: 'tx_oct_trans',
      title: 'Fuel & Metro Pass',
      amount: 1418.0,
      type: TransactionType.expense,
      category: 'Transport',
      icon: Icons.directions_car_rounded,
      categoryColor: AppTheme.accentCyan,
      date: DateTime(2026, 10, 4, 11, 20),
      note: 'Monthly commute recharge',
    ),
    Transaction(
      id: 'tx_oct_bills',
      title: 'High-Speed Wi-Fi & Electricity',
      amount: 1248.0,
      type: TransactionType.expense,
      category: 'Bills & Utilities',
      icon: Icons.receipt_long_rounded,
      categoryColor: AppTheme.accentOrange,
      date: DateTime(2026, 10, 3, 10, 0),
      note: 'Broadband bill',
    ),
    Transaction(
      id: 'tx_oct_ent',
      title: 'Streaming & Games Pass',
      amount: 998.0,
      type: TransactionType.expense,
      category: 'Entertainment',
      icon: Icons.sports_esports_rounded,
      categoryColor: AppTheme.accentBlue,
      date: DateTime(2026, 10, 7, 19, 0),
      note: 'Subscriptions renewal',
    ),
    Transaction(
      id: 'tx_oct_oth',
      title: 'Books & Stationery',
      amount: 874.0,
      type: TransactionType.expense,
      category: 'Others',
      icon: Icons.more_horiz_rounded,
      categoryColor: Color(0xFF10B981),
      date: DateTime(2026, 10, 6, 16, 30),
      note: 'Notebooks and organizer',
    ),
    // September 2026 (Income: ₹50,000, Total Spent: ₹14,180 -> -12% trend in Oct)
    Transaction(
      id: 'tx_sep_sal',
      title: 'Monthly Salary',
      amount: 50000.0,
      type: TransactionType.income,
      category: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      categoryColor: AppTheme.primaryMint,
      date: DateTime(2026, 9, 1, 9, 0),
    ),
    Transaction(
      id: 'tx_sep_food',
      title: 'Food & Dining',
      amount: 5100.0,
      type: TransactionType.expense,
      category: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      categoryColor: AppTheme.accentPink,
      date: DateTime(2026, 9, 15, 13, 0),
    ),
    Transaction(
      id: 'tx_sep_shop',
      title: 'Shopping',
      amount: 3600.0,
      type: TransactionType.expense,
      category: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      categoryColor: AppTheme.accentPurple,
      date: DateTime(2026, 9, 18, 15, 0),
    ),
    Transaction(
      id: 'tx_sep_trans',
      title: 'Transport',
      amount: 1800.0,
      type: TransactionType.expense,
      category: 'Transport',
      icon: Icons.directions_car_rounded,
      categoryColor: AppTheme.accentCyan,
      date: DateTime(2026, 9, 12, 10, 0),
    ),
    Transaction(
      id: 'tx_sep_bills',
      title: 'Bills & Utilities',
      amount: 1500.0,
      type: TransactionType.expense,
      category: 'Bills & Utilities',
      icon: Icons.receipt_long_rounded,
      categoryColor: AppTheme.accentOrange,
      date: DateTime(2026, 9, 5, 10, 0),
    ),
    Transaction(
      id: 'tx_sep_ent',
      title: 'Entertainment',
      amount: 1200.0,
      type: TransactionType.expense,
      category: 'Entertainment',
      icon: Icons.sports_esports_rounded,
      categoryColor: AppTheme.accentBlue,
      date: DateTime(2026, 9, 22, 18, 0),
    ),
    Transaction(
      id: 'tx_sep_oth',
      title: 'Others',
      amount: 980.0,
      type: TransactionType.expense,
      category: 'Others',
      icon: Icons.more_horiz_rounded,
      categoryColor: Color(0xFF10B981),
      date: DateTime(2026, 9, 25, 12, 0),
    ),
    // August 2026 (Income: ₹45,000, Spent: ₹22,000)
    Transaction(
      id: 'tx_aug_sal',
      title: 'Monthly Salary',
      amount: 45000.0,
      type: TransactionType.income,
      category: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      categoryColor: AppTheme.primaryMint,
      date: DateTime(2026, 8, 1, 9, 0),
    ),
    Transaction(
      id: 'tx_aug_exp',
      title: 'Monthly Living Expenses',
      amount: 22000.0,
      type: TransactionType.expense,
      category: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      categoryColor: AppTheme.accentPink,
      date: DateTime(2026, 8, 15, 12, 0),
    ),
    // July 2026 (Income: ₹42,000, Spent: ₹20,000)
    Transaction(
      id: 'tx_jul_sal',
      title: 'Monthly Salary',
      amount: 42000.0,
      type: TransactionType.income,
      category: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      categoryColor: AppTheme.primaryMint,
      date: DateTime(2026, 7, 1, 9, 0),
    ),
    Transaction(
      id: 'tx_jul_exp',
      title: 'Monthly Living Expenses',
      amount: 20000.0,
      type: TransactionType.expense,
      category: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      categoryColor: AppTheme.accentPink,
      date: DateTime(2026, 7, 15, 12, 0),
    ),
    // June 2026 (Income: ₹38,000, Spent: ₹18,000)
    Transaction(
      id: 'tx_jun_sal',
      title: 'Monthly Salary',
      amount: 38000.0,
      type: TransactionType.income,
      category: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      categoryColor: AppTheme.primaryMint,
      date: DateTime(2026, 6, 1, 9, 0),
    ),
    Transaction(
      id: 'tx_jun_exp',
      title: 'Monthly Living Expenses',
      amount: 18000.0,
      type: TransactionType.expense,
      category: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      categoryColor: AppTheme.accentPink,
      date: DateTime(2026, 6, 15, 12, 0),
    ),
    // May 2026 (Income: ₹40,000, Spent: ₹16,000)
    Transaction(
      id: 'tx_may_sal',
      title: 'Monthly Salary',
      amount: 40000.0,
      type: TransactionType.income,
      category: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      categoryColor: AppTheme.primaryMint,
      date: DateTime(2026, 5, 1, 9, 0),
    ),
    Transaction(
      id: 'tx_may_exp',
      title: 'Monthly Living Expenses',
      amount: 16000.0,
      type: TransactionType.expense,
      category: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      categoryColor: AppTheme.accentPink,
      date: DateTime(2026, 5, 15, 12, 0),
    ),
  ];

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  Future<File?> _getTransactionsFile() async {
    try {
      final androidFiles = Directory('/data/user/0/com.spentee.spentee/files');
      if (await androidFiles.exists()) {
        return File('${androidFiles.path}/spentee_transactions.json');
      }
      final androidAppFlutter =
          Directory('/data/user/0/com.spentee.spentee/app_flutter');
      if (await androidAppFlutter.exists()) {
        return File('${androidAppFlutter.path}/spentee_transactions.json');
      }
      final localDir = Directory('.spentee_storage');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      return File('${localDir.path}/spentee_transactions.json');
    } catch (e) {
      debugPrint('Transactions storage lookup error: $e');
      return null;
    }
  }

  Future<void> saveTransactionsToStorage() async {
    try {
      final file = await _getTransactionsFile();
      if (file == null) return;
      final data = {
        'balance': _balance,
        'transactions': _transactions.map((tx) => tx.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving transactions to storage: $e');
    }
  }

  Future<void> loadTransactionsFromStorage() async {
    try {
      final file = await _getTransactionsFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content);
          if (data is Map<String, dynamic>) {
            if (data.containsKey('balance') && data['balance'] is num) {
              _balance = (data['balance'] as num).toDouble();
            }
            if (data.containsKey('transactions') &&
                data['transactions'] is List) {
              final rawList = data['transactions'] as List;
              final loaded = <Transaction>[];
              for (final item in rawList) {
                if (item is Map<String, dynamic>) {
                  loaded.add(Transaction.fromJson(item));
                }
              }
              if (loaded.isNotEmpty) {
                _transactions.clear();
                _transactions.addAll(loaded);
              }
            }
          }
        }
      } else {
        await saveTransactionsToStorage();
      }
    } catch (e) {
      debugPrint('Error loading transactions from storage: $e');
    }
  }

  /// Add new transaction with proper financial rules.
  Future<void> addTransaction(Transaction tx) async {
    _transactions.insert(0, tx);
    if (tx.type == TransactionType.expense) {
      _balance -= tx.amount;
    } else if (tx.type == TransactionType.income) {
      _balance += tx.amount;
    }
    // Note: Transfers do not count as purchases/spending.
    notifyListeners();
    await saveTransactionsToStorage();
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

  // ─── Budgets State & Persistence ───────────────────────────────────────────
  final List<Budget> _budgets = [
    Budget(
      id: 'b_food',
      category: 'Food & Drinks',
      limitAmount: 6000.0,
      period: 'Monthly',
      year: 2026,
      month: 10,
    ),
    Budget(
      id: 'b_shop',
      category: 'Shopping',
      limitAmount: 4000.0,
      period: 'Monthly',
      year: 2026,
      month: 10,
    ),
    Budget(
      id: 'b_trans',
      category: 'Transport',
      limitAmount: 2000.0,
      period: 'Monthly',
      year: 2026,
      month: 10,
    ),
    Budget(
      id: 'b_bills',
      category: 'Bills & Utilities',
      limitAmount: 3000.0,
      period: 'Monthly',
      year: 2026,
      month: 10,
    ),
  ];

  List<Budget> get budgets => List.unmodifiable(_budgets);

  Future<File?> _getBudgetsFile() async {
    try {
      final androidFiles = Directory('/data/user/0/com.spentee.spentee/files');
      if (await androidFiles.exists()) {
        return File('${androidFiles.path}/spentee_budgets.json');
      }
      final androidAppFlutter =
          Directory('/data/user/0/com.spentee.spentee/app_flutter');
      if (await androidAppFlutter.exists()) {
        return File('${androidAppFlutter.path}/spentee_budgets.json');
      }
      final localDir = Directory('.spentee_storage');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      return File('${localDir.path}/spentee_budgets.json');
    } catch (e) {
      debugPrint('Budgets storage lookup error: $e');
      return null;
    }
  }

  Future<void> saveBudgetsToStorage() async {
    try {
      final file = await _getBudgetsFile();
      if (file == null) return;
      final data = _budgets.map((b) => b.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving budgets to storage: $e');
    }
  }

  Future<void> loadBudgetsFromStorage() async {
    try {
      final file = await _getBudgetsFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content);
          if (data is List) {
            final loaded = <Budget>[];
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                loaded.add(Budget.fromJson(item));
              }
            }
            if (loaded.isNotEmpty) {
              _budgets.clear();
              _budgets.addAll(loaded);
            }
          }
        }
      } else {
        await saveBudgetsToStorage();
      }
    } catch (e) {
      debugPrint('Error loading budgets from storage: $e');
    }
  }

  Future<void> addBudget(Budget budget) async {
    final idx = _budgets.indexWhere((b) =>
        b.category.toLowerCase().trim() == budget.category.toLowerCase().trim() &&
        b.year == budget.year &&
        b.month == budget.month);
    if (idx >= 0) {
      _budgets[idx] = budget;
    } else {
      _budgets.add(budget);
    }
    notifyListeners();
    await saveBudgetsToStorage();
  }

  Future<void> updateBudget(Budget budget) async {
    final idx = _budgets.indexWhere((b) => b.id == budget.id);
    if (idx >= 0) {
      _budgets[idx] = budget;
      notifyListeners();
      await saveBudgetsToStorage();
    }
  }

  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
    await saveBudgetsToStorage();
  }

  // ─── Categories State & Persistence ────────────────────────────────────────
  final List<CategoryItem> _customCategories = [
    // Default Expense
    CategoryItem(
      id: 'cat_food',
      name: 'Food & Drinks',
      isExpense: true,
      isCustom: false,
      icon: Icons.restaurant_rounded,
      color: AppTheme.accentPink,
    ),
    CategoryItem(
      id: 'cat_transport',
      name: 'Transport',
      isExpense: true,
      isCustom: false,
      icon: Icons.directions_car_rounded,
      color: AppTheme.accentCyan,
    ),
    CategoryItem(
      id: 'cat_shopping',
      name: 'Shopping',
      isExpense: true,
      isCustom: false,
      icon: Icons.shopping_bag_rounded,
      color: AppTheme.accentPurple,
    ),
    CategoryItem(
      id: 'cat_bills',
      name: 'Bills & Utilities',
      isExpense: true,
      isCustom: false,
      icon: Icons.receipt_long_rounded,
      color: AppTheme.accentOrange,
    ),
    CategoryItem(
      id: 'cat_ent',
      name: 'Entertainment',
      isExpense: true,
      isCustom: false,
      icon: Icons.sports_esports_rounded,
      color: AppTheme.accentBlue,
    ),
    CategoryItem(
      id: 'cat_groc',
      name: 'Groceries',
      isExpense: true,
      isCustom: false,
      icon: Icons.local_grocery_store_rounded,
      color: const Color(0xFF10B981),
    ),
    CategoryItem(
      id: 'cat_health',
      name: 'Health & Care',
      isExpense: true,
      isCustom: false,
      icon: Icons.medical_services_rounded,
      color: const Color(0xFFEF4444),
    ),
    CategoryItem(
      id: 'cat_others',
      name: 'Others',
      isExpense: true,
      isCustom: false,
      icon: Icons.more_horiz_rounded,
      color: AppTheme.textGrey,
    ),
    // Default Income
    CategoryItem(
      id: 'cat_salary',
      name: 'Salary',
      isExpense: false,
      isCustom: false,
      icon: Icons.account_balance_wallet_rounded,
      color: AppTheme.primaryMint,
    ),
    CategoryItem(
      id: 'cat_freelance',
      name: 'Freelance',
      isExpense: false,
      isCustom: false,
      icon: Icons.laptop_mac_rounded,
      color: AppTheme.accentCyan,
    ),
    CategoryItem(
      id: 'cat_invest',
      name: 'Investments',
      isExpense: false,
      isCustom: false,
      icon: Icons.trending_up_rounded,
      color: AppTheme.accentPurple,
    ),
    CategoryItem(
      id: 'cat_gift',
      name: 'Gift / Bonus',
      isExpense: false,
      isCustom: false,
      icon: Icons.card_giftcard_rounded,
      color: AppTheme.accentOrange,
    ),
  ];

  List<CategoryItem> get customCategories => List.unmodifiable(_customCategories);

  Future<File?> _getCategoriesFile() async {
    try {
      final androidFiles = Directory('/data/user/0/com.spentee.spentee/files');
      if (await androidFiles.exists()) {
        return File('${androidFiles.path}/spentee_categories.json');
      }
      final androidAppFlutter =
          Directory('/data/user/0/com.spentee.spentee/app_flutter');
      if (await androidAppFlutter.exists()) {
        return File('${androidAppFlutter.path}/spentee_categories.json');
      }
      final localDir = Directory('.spentee_storage');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      return File('${localDir.path}/spentee_categories.json');
    } catch (e) {
      debugPrint('Categories storage lookup error: $e');
      return null;
    }
  }

  Future<void> saveCategoriesToStorage() async {
    try {
      final file = await _getCategoriesFile();
      if (file == null) return;
      final data = _customCategories.map((c) => c.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving categories to storage: $e');
    }
  }

  Future<void> loadCategoriesFromStorage() async {
    try {
      final file = await _getCategoriesFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content);
          if (data is List) {
            final loaded = <CategoryItem>[];
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                loaded.add(CategoryItem.fromJson(item));
              }
            }
            if (loaded.isNotEmpty) {
              _customCategories.clear();
              _customCategories.addAll(loaded);
            }
          }
        }
      } else {
        await saveCategoriesToStorage();
      }
    } catch (e) {
      debugPrint('Error loading categories from storage: $e');
    }
  }

  Future<void> addCustomCategory(CategoryItem cat) async {
    _customCategories.add(cat);
    notifyListeners();
    await saveCategoriesToStorage();
  }

  Future<void> renameCategory(String id, String newName) async {
    final idx = _customCategories.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      final oldName = _customCategories[idx].name;
      _customCategories[idx] = _customCategories[idx].copyWith(name: newName);

      // Protect historical transactions: update any matching old category name
      bool txsUpdated = false;
      for (int i = 0; i < _transactions.length; i++) {
        if (_transactions[i].category.toLowerCase().trim() ==
            oldName.toLowerCase().trim()) {
          _transactions[i] = Transaction(
            id: _transactions[i].id,
            title: _transactions[i].title == oldName ? newName : _transactions[i].title,
            amount: _transactions[i].amount,
            type: _transactions[i].type,
            category: newName,
            icon: _transactions[i].icon,
            categoryColor: _transactions[i].categoryColor,
            date: _transactions[i].date,
            note: _transactions[i].note,
          );
          txsUpdated = true;
        }
      }

      notifyListeners();
      await saveCategoriesToStorage();
      if (txsUpdated) {
        await saveTransactionsToStorage();
      }
    }
  }

  Future<void> deleteCategory(String id) async {
    final idx = _customCategories.indexWhere((c) => c.id == id && c.isCustom);
    if (idx >= 0) {
      final oldName = _customCategories[idx].name;
      _customCategories.removeAt(idx);

      // Reassign transactions referencing the deleted custom category to 'Others' to maintain data integrity
      bool txsUpdated = false;
      for (int i = 0; i < _transactions.length; i++) {
        if (_transactions[i].category.toLowerCase().trim() ==
            oldName.toLowerCase().trim()) {
          _transactions[i] = Transaction(
            id: _transactions[i].id,
            title: _transactions[i].title == oldName ? 'Others' : _transactions[i].title,
            amount: _transactions[i].amount,
            type: _transactions[i].type,
            category: 'Others',
            icon: Icons.more_horiz_rounded,
            categoryColor: AppTheme.textGrey,
            date: _transactions[i].date,
            note: _transactions[i].note,
          );
          txsUpdated = true;
        }
      }

      notifyListeners();
      await saveCategoriesToStorage();
      if (txsUpdated) {
        await saveTransactionsToStorage();
      }
    }
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

  // AI Chat Messages & Session Management
  final List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  bool _isAiResponding = false;
  bool get isAiResponding => _isAiResponding;

  bool _userConsentedToDataAnalysis = false;
  bool get userConsentedToDataAnalysis => _userConsentedToDataAnalysis;

  void setConsentForAnalysis(bool consented) {
    _userConsentedToDataAnalysis = consented;
    notifyListeners();
  }

  String _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
  String get currentSessionId => _currentSessionId;

  List<ChatSession> _chatHistorySessions = [];
  List<ChatSession> get chatHistorySessions =>
      List.unmodifiable(_chatHistorySessions);

  Future<void> loadChatSessionsFromDisk() async {
    final sessions = await AiChatService.instance.loadSessions();
    _chatHistorySessions = sessions;
    notifyListeners();
  }

  Future<void> saveCurrentSessionToDisk() async {
    if (_chatMessages.isEmpty) return;

    // Use first user message as session title
    String title = 'Financial Conversation';
    for (final m in _chatMessages) {
      if (m.isUser && m.text.isNotEmpty) {
        title = m.text.length > 32 ? '${m.text.substring(0, 32)}...' : m.text;
        break;
      }
    }

    final session = ChatSession(
      id: _currentSessionId,
      title: title,
      createdAt: _chatMessages.first.timestamp,
      updatedAt: DateTime.now(),
      messages: List.from(_chatMessages),
    );

    final index = _chatHistorySessions.indexWhere((s) => s.id == _currentSessionId);
    if (index >= 0) {
      _chatHistorySessions[index] = session;
    } else {
      _chatHistorySessions.insert(0, session);
    }

    await AiChatService.instance.saveSessions(_chatHistorySessions);
    notifyListeners();
  }

  Future<void> sendUserChatMessage(String userQuery, {String? attachment}) async {
    final trimmed = userQuery.trim();
    if (trimmed.isEmpty && attachment == null) return;
    if (_isAiResponding) return;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      attachmentName: attachment,
    );

    _chatMessages.add(userMsg);
    _isAiResponding = true;
    notifyListeners();

    try {
      final aiMsg = await AiChatService.instance.generateResponse(
        query: trimmed,
        transactions: _transactions,
        userConsentedToDataAnalysis: _userConsentedToDataAnalysis,
        userMascot: _selectedMascot,
      );
      _chatMessages.add(aiMsg);
    } catch (e) {
      _chatMessages.add(
        ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          text:
              '⚠️ Unable to process request. Please check connection and retry.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      _isAiResponding = false;
      notifyListeners();
      await saveCurrentSessionToDisk();
    }
  }

  void toggleMessageHelpful(String messageId) {
    final idx = _chatMessages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      final current = _chatMessages[idx];
      final newHelpful = !(current.isHelpful ?? false);
      _chatMessages[idx] = current.copyWith(
        isHelpful: newHelpful,
        isUnhelpful: false,
      );
      notifyListeners();
      saveCurrentSessionToDisk();
    }
  }

  void toggleMessageUnhelpful(String messageId) {
    final idx = _chatMessages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      final current = _chatMessages[idx];
      final newUnhelpful = !(current.isUnhelpful ?? false);
      _chatMessages[idx] = current.copyWith(
        isUnhelpful: newUnhelpful,
        isHelpful: false,
      );
      notifyListeners();
      saveCurrentSessionToDisk();
    }
  }

  Future<void> regenerateLastResponse() async {
    if (_isAiResponding) return;
    String? lastUserQuery;
    for (int i = _chatMessages.length - 1; i >= 0; i--) {
      if (_chatMessages[i].isUser) {
        lastUserQuery = _chatMessages[i].text;
        break;
      }
    }
    if (lastUserQuery == null) return;

    // Remove last AI message if present
    if (_chatMessages.isNotEmpty && !_chatMessages.last.isUser) {
      _chatMessages.removeLast();
    }

    _isAiResponding = true;
    notifyListeners();

    try {
      final aiMsg = await AiChatService.instance.generateResponse(
        query: lastUserQuery,
        transactions: _transactions,
        userConsentedToDataAnalysis: _userConsentedToDataAnalysis,
        userMascot: _selectedMascot,
      );
      _chatMessages.add(aiMsg);
    } catch (e) {
      _chatMessages.add(
        ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          text: '⚠️ Regeneration failed. Tap to retry.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      _isAiResponding = false;
      notifyListeners();
      await saveCurrentSessionToDisk();
    }
  }

  void startNewChat() {
    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _chatMessages.clear();
    _isAiResponding = false;
    notifyListeners();
  }

  void loadSession(ChatSession session) {
    _currentSessionId = session.id;
    _chatMessages.clear();
    _chatMessages.addAll(session.messages);
    _isAiResponding = false;
    notifyListeners();
  }

  Future<void> deleteChatSession(String sessionId) async {
    _chatHistorySessions.removeWhere((s) => s.id == sessionId);
    await AiChatService.instance.saveSessions(_chatHistorySessions);
    if (_currentSessionId == sessionId) {
      startNewChat();
    }
    notifyListeners();
  }

  Future<void> clearAllChatHistory() async {
    _chatHistorySessions.clear();
    await AiChatService.instance.saveSessions([]);
    startNewChat();
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
