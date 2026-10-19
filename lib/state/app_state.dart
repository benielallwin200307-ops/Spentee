import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/roast.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/ai_chat_service.dart';
import '../services/roast_engine.dart';
import '../services/roast_library.dart';

/// Central state manager with persistent user profile and theme preferences.
class AppState extends ChangeNotifier {
  // Balance (starts strictly at 0.0 for new users)
  double _balance = 0.0;
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
  bool get isFemaleMascot => _selectedMascot == 'female';
  MascotThemeData get mascotTheme =>
      _selectedMascot == 'female' ? MascotThemeData.female : MascotThemeData.male;

  // Isolated per-user profile mapping keyed by user UID
  final Map<String, dynamic> _userProfiles = {};
  Map<String, dynamic> get userProfiles => _userProfiles;
  final Set<String> _legacyUserUids = {
    'dss2jlEKu5MZxx6diMLLBez92vj2',
    'TbAJfw8lhRRYRp4olcHD7zGlCnp2',
    '2SQElZNM3vaItUjEssRvtGZhv3m1',
  };

  AppState() {
    // Listen to Firebase auth state changes to keep session synchronized
    try {
      AuthService.instance.authStateChanges.listen((user) async {
        if (user == null && _isAuthenticated && !_userUid.startsWith('local_')) {
          _isAuthenticated = false;
          _userUid = '';
          _transactions.clear();
          _balance = 0.0;
          _budgets.clear();
          refreshRoast();
          notifyListeners();
        } else if (user != null && (!_isAuthenticated || _userUid != user.uid)) {
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
          await loadTransactionsFromStorage();
          await loadBudgetsFromStorage();
          await loadSavingsGoalsFromStorage();
          refreshRoast();
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Auth listener init error: $e');
    }
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

  Future<void> setUserProfile({
    required String name,
    required String email,
    required String gender,
    String? uid,
  }) async {
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
    await loadTransactionsFromStorage();
    await loadBudgetsFromStorage();
    await loadSavingsGoalsFromStorage();
    refreshRoast();
    notifyListeners();
    await saveToStorage();
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
    _transactions.clear();
    _balance = 0.0;
    _budgets.clear();
    refreshRoast();
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
        'userUid': _userUid,
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
      Map<String, dynamic> data = {};
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          data = jsonDecode(content);
          if (data.containsKey('userProfiles') && data['userProfiles'] is Map) {
            _userProfiles.addAll(Map<String, dynamic>.from(data['userProfiles']));
            for (final k in _userProfiles.keys) {
              if (k.isNotEmpty && !k.startsWith('local_')) {
                _legacyUserUids.add(k);
              }
            }
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

      // Restore session from Firebase Authentication or local session
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
      } else if (data['isAuthenticated'] == true &&
          data['userUid'] is String &&
          (data['userUid'] as String).isNotEmpty) {
        _isAuthenticated = true;
        _userUid = data['userUid'] as String;
        if (_userProfiles.containsKey(_userUid) &&
            _userProfiles[_userUid]['selectedMascot'] != null) {
          _selectedMascot = _userProfiles[_userUid]['selectedMascot'];
          _userGender = _selectedMascot;
        }
      } else {
        _isAuthenticated = false;
        _userUid = '';
      }

      await loadChatSessionsFromDisk();
      await loadTransactionsFromStorage();
      await loadBudgetsFromStorage();
      await loadSavingsGoalsFromStorage();
      await loadCategoriesFromStorage();
      refreshRoast();
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
    refreshRoast();
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

  // In-memory Transactions list (starts empty for genuine zero-data state)
  final List<Transaction> _transactions = [];

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  Future<Directory?> _getAppStorageDirectory() async {
    try {
      final androidFiles = Directory('/data/user/0/com.spentee.spentee/files');
      if (await androidFiles.exists()) {
        return androidFiles;
      }
      final androidAppFlutter =
          Directory('/data/user/0/com.spentee.spentee/app_flutter');
      if (await androidAppFlutter.exists()) {
        return androidAppFlutter;
      }
      final localDir = Directory('.spentee_storage');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      return localDir;
    } catch (e) {
      debugPrint('App storage directory lookup error: $e');
      return null;
    }
  }

  Future<File?> _getTransactionsFile() async {
    try {
      final dir = await _getAppStorageDirectory();
      if (dir == null) return null;

      if (_userUid.isNotEmpty) {
        final userFile = File('${dir.path}/spentee_transactions_$_userUid.json');
        if (await userFile.exists()) {
          return userFile;
        }
        // Preserve legacy shared file for existing registered user
        final legacyFile = File('${dir.path}/spentee_transactions.json');
        if (await legacyFile.exists()) {
          if (_legacyUserUids.contains(_userUid)) {
            return legacyFile;
          }
        }
        return userFile;
      }

      return File('${dir.path}/spentee_transactions_guest.json');
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
              _transactions.clear();
              _transactions.addAll(loaded);
            }
          }
        }
      } else {
        // Zero-state initialization: brand new account starts with zero data
        _transactions.clear();
        _balance = 0.0;
      }
      refreshRoast();
    } catch (e) {
      debugPrint('Error loading transactions from storage: $e');
    }
  }

  /// Add new transaction with deterministic financial calculation.
  Future<void> addTransaction(Transaction tx) async {
    _transactions.insert(0, tx);
    if (tx.type == TransactionType.expense) {
      _balance -= tx.amount;
    } else if (tx.type == TransactionType.income) {
      _balance += tx.amount;
    }
    // Note: Transfers do not count as purchases or earnings.
    refreshRoast();
    notifyListeners();
    await saveTransactionsToStorage();
  }

  /// Delete transaction and adjust balance deterministically.
  Future<void> deleteTransaction(String id) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx >= 0) {
      final tx = _transactions.removeAt(idx);
      if (tx.type == TransactionType.expense) {
        _balance += tx.amount;
      } else if (tx.type == TransactionType.income) {
        _balance -= tx.amount;
      }
      refreshRoast();
      notifyListeners();
      await saveTransactionsToStorage();
    }
  }

  /// Calculate today's spending total (excluding internal transfers).
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

  /// Calculate current month's earned income (strictly excluding internal transfers).
  double get monthIncome {
    final now = DateTime.now();
    double total = 0.0;
    for (final tx in _transactions) {
      if (tx.type == TransactionType.income &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        total += tx.amount;
      }
    }
    return total;
  }

  /// Calculate total earned income (strictly excluding internal transfers).
  double get totalIncome {
    double total = 0.0;
    for (final tx in _transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      }
    }
    return total;
  }

  // ─── Budgets State & Persistence ───────────────────────────────────────────
  final List<Budget> _budgets = [];

  List<Budget> get budgets => List.unmodifiable(_budgets);

  Future<File?> _getBudgetsFile() async {
    try {
      final dir = await _getAppStorageDirectory();
      if (dir == null) return null;

      if (_userUid.isNotEmpty) {
        final userFile = File('${dir.path}/spentee_budgets_$_userUid.json');
        if (await userFile.exists()) {
          return userFile;
        }
        final legacyFile = File('${dir.path}/spentee_budgets.json');
        if (await legacyFile.exists()) {
          if (_legacyUserUids.contains(_userUid)) {
            return legacyFile;
          }
        }
        return userFile;
      }

      return File('${dir.path}/spentee_budgets_guest.json');
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
            _budgets.clear();
            _budgets.addAll(loaded);
          }
        }
      } else {
        _budgets.clear();
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

  // ─── Savings Goals State & Persistence ─────────────────────────────────────
  final List<SavingsGoal> _savingsGoals = [];

  List<SavingsGoal> get savingsGoals => List.unmodifiable(_savingsGoals);

  Future<File?> _getSavingsGoalsFile() async {
    try {
      final dir = await _getAppStorageDirectory();
      if (dir == null) return null;

      if (_userUid.isNotEmpty) {
        final userFile = File('${dir.path}/spentee_savings_goals_$_userUid.json');
        if (await userFile.exists()) {
          return userFile;
        }
        final legacyFile = File('${dir.path}/spentee_savings_goals.json');
        if (await legacyFile.exists()) {
          if (_legacyUserUids.contains(_userUid)) {
            return legacyFile;
          }
        }
        return userFile;
      }

      return File('${dir.path}/spentee_savings_goals_guest.json');
    } catch (e) {
      debugPrint('Savings goals storage lookup error: $e');
      return null;
    }
  }

  Future<void> saveSavingsGoalsToStorage() async {
    try {
      final file = await _getSavingsGoalsFile();
      if (file == null) return;
      final data = _savingsGoals.map((g) => g.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving savings goals to storage: $e');
    }
  }

  Future<void> loadSavingsGoalsFromStorage() async {
    try {
      final file = await _getSavingsGoalsFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content);
          if (data is List) {
            final loaded = <SavingsGoal>[];
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                loaded.add(SavingsGoal.fromJson(item));
              }
            }
            _savingsGoals.clear();
            _savingsGoals.addAll(loaded);
          }
        }
      } else {
        _savingsGoals.clear();
      }
    } catch (e) {
      debugPrint('Error loading savings goals from storage: $e');
    }
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goal.id);
    if (idx >= 0) {
      _savingsGoals[idx] = goal;
    } else {
      _savingsGoals.insert(0, goal);
    }
    notifyListeners();
    await saveSavingsGoalsToStorage();
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final idx = _savingsGoals.indexWhere((g) => g.id == goal.id);
    if (idx >= 0) {
      _savingsGoals[idx] = goal;
      notifyListeners();
      await saveSavingsGoalsToStorage();
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    _savingsGoals.removeWhere((g) => g.id == id);
    notifyListeners();
    await saveSavingsGoalsToStorage();
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

  // Dynamic Roasts State
  RoastItem? _cachedRoast;
  int _roastCycleIndex = 0;
  final List<String> _recentRoastIds = [];

  RoastItem get currentRoast {
    if (_cachedRoast == null ||
        (_cachedRoast!.language.isNotEmpty &&
            RoastLibrary.normalizeLanguage(_cachedRoast!.language) !=
                RoastLibrary.normalizeLanguage(_selectedLanguage))) {
      _cachedRoast = DynamicRoastEngine.generateRoast(
        transactions: _transactions,
        budgets: _budgets,
        savingsGoals: _savingsGoals,
        language: _selectedLanguage,
        recentRoastIds: _recentRoastIds,
      );
      if (_cachedRoast != null && _cachedRoast!.id.isNotEmpty) {
        _recentRoastIds.add(_cachedRoast!.id);
        if (_recentRoastIds.length > 20) {
          _recentRoastIds.removeAt(0);
        }
      }
    }
    return _cachedRoast!;
  }

  void refreshRoast() {
    _cachedRoast = DynamicRoastEngine.generateRoast(
      transactions: _transactions,
      budgets: _budgets,
      savingsGoals: _savingsGoals,
      previousRoastText: _cachedRoast?.text,
      previousRoastId: _cachedRoast?.id,
      language: _selectedLanguage,
      recentRoastIds: _recentRoastIds,
    );
    if (_cachedRoast != null && _cachedRoast!.id.isNotEmpty) {
      _recentRoastIds.add(_cachedRoast!.id);
      if (_recentRoastIds.length > 20) {
        _recentRoastIds.removeAt(0);
      }
    }
    notifyListeners();
  }

  void nextRoast() {
    final matching = DynamicRoastEngine.getMatchingRoasts(
      transactions: _transactions,
      budgets: _budgets,
      savingsGoals: _savingsGoals,
      language: _selectedLanguage,
    );
    if (matching.isNotEmpty) {
      _roastCycleIndex = (_roastCycleIndex + 1) % matching.length;
      _cachedRoast = matching[_roastCycleIndex];
      if (_cachedRoast != null && _cachedRoast!.id.isNotEmpty) {
        _recentRoastIds.add(_cachedRoast!.id);
        if (_recentRoastIds.length > 20) {
          _recentRoastIds.removeAt(0);
        }
      }
    } else {
      _cachedRoast = RoastLibrary.getOnboardingRoast(_selectedLanguage);
    }
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
        budgets: _budgets,
        savingsGoals: _savingsGoals,
        userConsentedToDataAnalysis: _userConsentedToDataAnalysis,
        userMascot: _selectedMascot,
        conversationHistory: _chatMessages,
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
        budgets: _budgets,
        savingsGoals: _savingsGoals,
        userConsentedToDataAnalysis: _userConsentedToDataAnalysis,
        userMascot: _selectedMascot,
        conversationHistory: _chatMessages,
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
