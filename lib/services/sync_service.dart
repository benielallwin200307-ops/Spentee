import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/lent_borrowed_record.dart';
import '../models/category_model.dart';
import '../services/auth_service.dart';

/// Represents the reconciled results from a two-way synchronization migration.
class MigrationResult {
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<SavingsGoal> savingsGoals;
  final List<LentBorrowedRecord> debts;
  final List<CategoryItem> categories;
  final Map<String, dynamic>? profile;

  const MigrationResult({
    required this.transactions,
    required this.budgets,
    required this.savingsGoals,
    required this.debts,
    required this.categories,
    this.profile,
  });

  static const empty = MigrationResult(
    transactions: [],
    budgets: [],
    savingsGoals: [],
    debts: [],
    categories: [],
    profile: null,
  );
}

/// Centralized Firestore synchronization service for cross-device data sync.
///
/// Architecture:
/// - Local-first: All reads come from local storage for instant offline access.
/// - Write-through: Every local write is also pushed to Firestore.
/// - Real-time listeners: Firestore snapshots update local state on remote changes.
/// - Conflict resolution: Last-write-wins using `updatedAt` timestamps.
/// - Migration: First sync uploads all local records, merges with cloud records.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  FirebaseFirestore? _customFirestore;

  /// Lazily and safely access FirebaseFirestore instance.
  /// Returns null if Firebase is not initialized (e.g. during headless unit tests).
  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  void setFirestoreForTesting(FirebaseFirestore? firestore) {
    _customFirestore = firestore;
  }

  // Stream subscriptions for real-time listeners
  StreamSubscription? _transactionsSub;
  StreamSubscription? _budgetsSub;
  StreamSubscription? _savingsGoalsSub;
  StreamSubscription? _debtsSub;
  StreamSubscription? _categoriesSub;
  StreamSubscription? _profileSub;

  // Callbacks for notifying AppState of remote changes
  void Function(List<Transaction>)? onTransactionsChanged;
  void Function(List<Budget>)? onBudgetsChanged;
  void Function(List<SavingsGoal>)? onSavingsGoalsChanged;
  void Function(List<LentBorrowedRecord>)? onDebtsChanged;
  void Function(List<CategoryItem>)? onCategoriesChanged;
  void Function(Map<String, dynamic>)? onProfileChanged;

  // Flag to suppress listener callbacks during bulk migration
  bool _suppressListeners = false;

  // Track whether initial migration has been performed
  bool _migrationDone = false;

  // Explicitly set UID when available from AppState session
  String? _activeUid;
  void setActiveUid(String? uid) {
    if (_activeUid != uid) {
      _migrationDone = false;
    }
    _activeUid = uid;
  }

  /// Reset migration flag to allow re-reconciliation (e.g. after auth change)
  void resetMigration() {
    _migrationDone = false;
  }

  /// Returns the current authenticated user's UID, or null if not authenticated.
  String? get _uid => _activeUid ?? AuthService.instance.currentUser?.uid;

  /// Reference to user's document root: /users/{uid}
  DocumentReference? get _userDoc {
    final uid = _uid;
    final firestore = _firestore;
    if (uid == null || uid.isEmpty || firestore == null) return null;
    return firestore.collection('users').doc(uid);
  }

  // ─── Collection References ─────────────────────────────────────────────────

  CollectionReference? get _transactionsCol => _userDoc?.collection('transactions');
  CollectionReference? get _budgetsCol => _userDoc?.collection('budgets');
  CollectionReference? get _savingsGoalsCol => _userDoc?.collection('savings_goals');
  CollectionReference? get _debtsCol => _userDoc?.collection('debts');
  CollectionReference? get _categoriesCol => _userDoc?.collection('categories');

  // ─── Initial Migration ─────────────────────────────────────────────────────

  /// Performs robust two-way migration: uploads all local records to Firestore,
  /// downloads any existing cloud records that are missing locally, and returns
  /// the unified, reconciled dataset so the caller updates immediately.
  /// This is additive-only — no records are deleted.
  Future<MigrationResult> performMigration({
    required List<Transaction> localTransactions,
    required List<Budget> localBudgets,
    required List<SavingsGoal> localSavingsGoals,
    required List<LentBorrowedRecord> localDebts,
    required List<CategoryItem> localCategories,
    required Map<String, dynamic> localProfile,
  }) async {
    if (_migrationDone || _userDoc == null) {
      return MigrationResult.empty;
    }

    try {
      _suppressListeners = true;

      // 1. Reconcile transactions
      final reconciledTxs = await _migrateCollection<Transaction>(
        collection: _transactionsCol!,
        localRecords: localTransactions,
        getId: (t) => t.id,
        toJson: (t) => t.toJson(),
        fromJson: (json) => Transaction.fromJson(json),
        getUpdatedAt: (t) => t.updatedAt,
        getIsDeleted: (t) => t.isDeleted,
      );

      // 2. Reconcile budgets
      final reconciledBudgets = await _migrateCollection<Budget>(
        collection: _budgetsCol!,
        localRecords: localBudgets,
        getId: (b) => b.id,
        toJson: (b) => b.toJson(),
        fromJson: (json) => Budget.fromJson(json),
        getUpdatedAt: (b) => b.updatedAt,
        getIsDeleted: (b) => b.isDeleted,
      );

      // 3. Reconcile savings goals
      final reconciledGoals = await _migrateCollection<SavingsGoal>(
        collection: _savingsGoalsCol!,
        localRecords: localSavingsGoals,
        getId: (g) => g.id,
        toJson: (g) => g.toJson(),
        fromJson: (json) => SavingsGoal.fromJson(json),
        getUpdatedAt: (g) => g.updatedAt,
        getIsDeleted: (g) => g.isDeleted,
      );

      // 4. Reconcile debts with deep repayment merging
      final reconciledDebts = await _migrateDebts(
        collection: _debtsCol!,
        localRecords: localDebts,
      );

      // 5. Reconcile custom categories (only custom ones stored in Firestore)
      final customCats = localCategories.where((c) => c.isCustom).toList();
      final reconciledCategories = await _migrateCollection<CategoryItem>(
        collection: _categoriesCol!,
        localRecords: customCats,
        getId: (c) => c.id,
        toJson: (c) => c.toJson(),
        fromJson: (json) => CategoryItem.fromJson(json),
        getUpdatedAt: (c) => c.updatedAt,
        getIsDeleted: (c) => c.isDeleted,
      );

      // 6. Reconcile profile
      final reconciledProfile = await _migrateProfile(localProfile);

      _migrationDone = true;
      debugPrint('[SyncService] Migration completed successfully');

      // Un-suppress listeners before triggering callbacks
      _suppressListeners = false;

      // Dispatch reconciled data directly to callbacks for instantaneous local update
      if (reconciledTxs.isNotEmpty || localTransactions.isNotEmpty) {
        onTransactionsChanged?.call(reconciledTxs);
      }
      if (reconciledBudgets.isNotEmpty || localBudgets.isNotEmpty) {
        onBudgetsChanged?.call(reconciledBudgets);
      }
      if (reconciledGoals.isNotEmpty || localSavingsGoals.isNotEmpty) {
        onSavingsGoalsChanged?.call(reconciledGoals);
      }
      if (reconciledDebts.isNotEmpty || localDebts.isNotEmpty) {
        onDebtsChanged?.call(reconciledDebts);
      }
      if (reconciledCategories.isNotEmpty || customCats.isNotEmpty) {
        onCategoriesChanged?.call(reconciledCategories);
      }
      if (reconciledProfile != null) {
        onProfileChanged?.call(reconciledProfile);
      }

      return MigrationResult(
        transactions: reconciledTxs,
        budgets: reconciledBudgets,
        savingsGoals: reconciledGoals,
        debts: reconciledDebts,
        categories: reconciledCategories,
        profile: reconciledProfile,
      );
    } catch (e) {
      debugPrint('[SyncService] Migration error: $e');
      return MigrationResult.empty;
    } finally {
      _suppressListeners = false;
    }
  }

  /// Generic two-way collection reconciliation: uploads local, merges with cloud.
  Future<List<T>> _migrateCollection<T>({
    required CollectionReference collection,
    required List<T> localRecords,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required DateTime Function(T) getUpdatedAt,
    required bool Function(T) getIsDeleted,
  }) async {
    final reconciledMap = <String, T>{};

    try {
      // 1. Fetch all existing cloud documents
      final cloudSnapshot = await collection.get();
      final cloudDocs = <String, Map<String, dynamic>>{};
      for (final doc in cloudSnapshot.docs) {
        cloudDocs[doc.id] = doc.data() as Map<String, dynamic>;
      }

      // 2. Preload local records
      for (final record in localRecords) {
        reconciledMap[getId(record)] = record;
      }

      // 3. Compare local records against cloud documents
      for (final record in localRecords) {
        final id = getId(record);
        final localJson = toJson(record);
        final localUpdatedAt = getUpdatedAt(record);

        if (cloudDocs.containsKey(id)) {
          final cloudJson = cloudDocs[id]!;
          final cloudUpdatedAtStr = cloudJson['updatedAt'] as String?;
          final cloudUpdatedAt = cloudUpdatedAtStr != null
              ? DateTime.tryParse(cloudUpdatedAtStr) ?? DateTime(2000)
              : DateTime(2000);

          if (localUpdatedAt.isAfter(cloudUpdatedAt)) {
            // Local is newer — update cloud
            await collection.doc(id).set(localJson);
            reconciledMap[id] = record;
          } else if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
            // Cloud is newer — update local state
            final cloudRecord = fromJson(cloudJson);
            reconciledMap[id] = cloudRecord;
          }
          // Remove processed document from cloudDocs
          cloudDocs.remove(id);
        } else {
          // Record doesn't exist in cloud — upload it
          await collection.doc(id).set(localJson);
        }
      }

      // 4. Download cloud records that do not exist locally
      for (final entry in cloudDocs.entries) {
        final cloudRecord = fromJson(entry.value);
        reconciledMap[entry.key] = cloudRecord;
      }
    } catch (e) {
      debugPrint('[SyncService] Collection migration error: $e');
    }

    return reconciledMap.values.where((item) => !getIsDeleted(item)).toList();
  }

  /// Two-way debt reconciliation with deep repayment union.
  Future<List<LentBorrowedRecord>> _migrateDebts({
    required CollectionReference collection,
    required List<LentBorrowedRecord> localRecords,
  }) async {
    final reconciledMap = <String, LentBorrowedRecord>{};

    try {
      final cloudSnapshot = await collection.get();
      final cloudDocs = <String, Map<String, dynamic>>{};
      for (final doc in cloudSnapshot.docs) {
        cloudDocs[doc.id] = doc.data() as Map<String, dynamic>;
      }

      for (final local in localRecords) {
        reconciledMap[local.id] = local;
      }

      for (final local in localRecords) {
        final id = local.id;

        if (cloudDocs.containsKey(id)) {
          final cloudJson = cloudDocs[id]!;
          final cloudRecord = LentBorrowedRecord.fromJson(cloudJson);
          final cloudUpdatedAt = cloudRecord.updatedAt;

          // Merge repayments by ID
          final repMap = <String, RepaymentRecord>{};
          for (final r in local.repayments) {
            repMap[r.id] = r;
          }
          for (final r in cloudRecord.repayments) {
            repMap[r.id] = r;
          }
          final mergedRepayments = repMap.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final bool localIsNewer = local.updatedAt.isAfter(cloudUpdatedAt);
          final baseRecord = localIsNewer ? local : cloudRecord;
          final reconciledDebt = baseRecord.copyWith(repayments: mergedRepayments);

          reconciledMap[id] = reconciledDebt;
          await collection.doc(id).set(reconciledDebt.toJson());
          cloudDocs.remove(id);
        } else {
          await collection.doc(id).set(local.toJson());
        }
      }

      for (final entry in cloudDocs.entries) {
        final cloudRecord = LentBorrowedRecord.fromJson(entry.value);
        reconciledMap[entry.key] = cloudRecord;
      }
    } catch (e) {
      debugPrint('[SyncService] Debts migration error: $e');
    }

    return reconciledMap.values.where((d) => !d.isDeleted).toList();
  }

  /// Migrate user profile to Firestore with two-way merging.
  Future<Map<String, dynamic>?> _migrateProfile(Map<String, dynamic> localProfile) async {
    try {
      final profileDoc = _userDoc?.collection('settings').doc('profile');
      if (profileDoc == null) return localProfile;

      final cloudSnapshot = await profileDoc.get();
      if (!cloudSnapshot.exists) {
        // No cloud profile — upload local
        await profileDoc.set(localProfile);
        return localProfile;
      } else {
        // Cloud profile exists — merge with local
        final cloudData = cloudSnapshot.data() ?? {};
        final mergedProfile = Map<String, dynamic>.from(localProfile)
          ..addAll(cloudData);
        return mergedProfile;
      }
    } catch (e) {
      debugPrint('[SyncService] Profile migration error: $e');
      return localProfile;
    }
  }

  // ─── Real-Time Listeners ───────────────────────────────────────────────────

  /// Start listening for real-time changes on all user collections.
  void startListening() {
    if (_userDoc == null) return;
    _listenTransactions();
    _listenBudgets();
    _listenSavingsGoals();
    _listenDebts();
    _listenCategories();
    _listenProfile();
    debugPrint('[SyncService] Real-time listeners started');
  }

  /// Stop all real-time listeners.
  void stopListening() {
    _transactionsSub?.cancel();
    _budgetsSub?.cancel();
    _savingsGoalsSub?.cancel();
    _debtsSub?.cancel();
    _categoriesSub?.cancel();
    _profileSub?.cancel();
    _transactionsSub = null;
    _budgetsSub = null;
    _savingsGoalsSub = null;
    _debtsSub = null;
    _categoriesSub = null;
    _profileSub = null;
    _migrationDone = false;
    _activeUid = null;
    debugPrint('[SyncService] Real-time listeners stopped');
  }

  void _listenTransactions() {
    _transactionsSub?.cancel();
    final col = _transactionsCol;
    if (col == null) return;

    _transactionsSub = col.snapshots().listen((snapshot) {
      if (_suppressListeners) return;
      final transactions = <Transaction>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          transactions.add(Transaction.fromJson(data));
        } catch (e) {
          debugPrint('[SyncService] Error parsing transaction: $e');
        }
      }
      transactions.sort((a, b) => b.date.compareTo(a.date));
      onTransactionsChanged?.call(transactions);
    }, onError: (e) {
      debugPrint('[SyncService] Transactions listener error: $e');
    });
  }

  void _listenBudgets() {
    _budgetsSub?.cancel();
    final col = _budgetsCol;
    if (col == null) return;

    _budgetsSub = col.snapshots().listen((snapshot) {
      if (_suppressListeners) return;
      final budgets = <Budget>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          budgets.add(Budget.fromJson(data));
        } catch (e) {
          debugPrint('[SyncService] Error parsing budget: $e');
        }
      }
      onBudgetsChanged?.call(budgets);
    }, onError: (e) {
      debugPrint('[SyncService] Budgets listener error: $e');
    });
  }

  void _listenSavingsGoals() {
    _savingsGoalsSub?.cancel();
    final col = _savingsGoalsCol;
    if (col == null) return;

    _savingsGoalsSub = col.snapshots().listen((snapshot) {
      if (_suppressListeners) return;
      final goals = <SavingsGoal>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          goals.add(SavingsGoal.fromJson(data));
        } catch (e) {
          debugPrint('[SyncService] Error parsing savings goal: $e');
        }
      }
      onSavingsGoalsChanged?.call(goals);
    }, onError: (e) {
      debugPrint('[SyncService] Savings goals listener error: $e');
    });
  }

  void _listenDebts() {
    _debtsSub?.cancel();
    final col = _debtsCol;
    if (col == null) return;

    _debtsSub = col.snapshots().listen((snapshot) {
      if (_suppressListeners) return;
      final debts = <LentBorrowedRecord>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          debts.add(LentBorrowedRecord.fromJson(data));
        } catch (e) {
          debugPrint('[SyncService] Error parsing debt record: $e');
        }
      }
      onDebtsChanged?.call(debts);
    }, onError: (e) {
      debugPrint('[SyncService] Debts listener error: $e');
    });
  }

  void _listenCategories() {
    _categoriesSub?.cancel();
    final col = _categoriesCol;
    if (col == null) return;

    _categoriesSub = col.snapshots().listen((snapshot) {
      if (_suppressListeners) return;
      final categories = <CategoryItem>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          categories.add(CategoryItem.fromJson(data));
        } catch (e) {
          debugPrint('[SyncService] Error parsing category: $e');
        }
      }
      onCategoriesChanged?.call(categories);
    }, onError: (e) {
      debugPrint('[SyncService] Categories listener error: $e');
    });
  }

  void _listenProfile() {
    _profileSub?.cancel();
    final doc = _userDoc?.collection('settings').doc('profile');
    if (doc == null) return;

    _profileSub = doc.snapshots().listen((snapshot) {
      if (_suppressListeners || !snapshot.exists) return;
      final data = snapshot.data();
      if (data != null) {
        onProfileChanged?.call(data);
      }
    }, onError: (e) {
      debugPrint('[SyncService] Profile listener error: $e');
    });
  }

  // ─── Write Operations (called by AppState after local save) ────────────────

  /// Upload or update a single transaction document.
  Future<void> syncTransaction(Transaction tx) async {
    try {
      final col = _transactionsCol;
      if (col == null) return;
      await col.doc(tx.id).set(tx.toJson());
    } catch (e) {
      debugPrint('[SyncService] Error syncing transaction ${tx.id}: $e');
    }
  }

  /// Soft-delete a transaction in Firestore.
  Future<void> deleteTransactionRemote(String id) async {
    try {
      final col = _transactionsCol;
      if (col == null) return;
      await col.doc(id).set({
        'id': id,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Error deleting transaction $id: $e');
    }
  }

  /// Upload or update a single budget document.
  Future<void> syncBudget(Budget budget) async {
    try {
      final col = _budgetsCol;
      if (col == null) return;
      await col.doc(budget.id).set(budget.toJson());
    } catch (e) {
      debugPrint('[SyncService] Error syncing budget ${budget.id}: $e');
    }
  }

  /// Soft-delete a budget in Firestore.
  Future<void> deleteBudgetRemote(String id) async {
    try {
      final col = _budgetsCol;
      if (col == null) return;
      await col.doc(id).set({
        'id': id,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Error deleting budget $id: $e');
    }
  }

  /// Upload or update a single savings goal document.
  Future<void> syncSavingsGoal(SavingsGoal goal) async {
    try {
      final col = _savingsGoalsCol;
      if (col == null) return;
      await col.doc(goal.id).set(goal.toJson());
    } catch (e) {
      debugPrint('[SyncService] Error syncing savings goal ${goal.id}: $e');
    }
  }

  /// Soft-delete a savings goal in Firestore.
  Future<void> deleteSavingsGoalRemote(String id) async {
    try {
      final col = _savingsGoalsCol;
      if (col == null) return;
      await col.doc(id).set({
        'id': id,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Error deleting savings goal $id: $e');
    }
  }

  /// Upload or update a single debt record document.
  Future<void> syncDebt(LentBorrowedRecord debt) async {
    try {
      final col = _debtsCol;
      if (col == null) return;
      await col.doc(debt.id).set(debt.toJson());
    } catch (e) {
      debugPrint('[SyncService] Error syncing debt ${debt.id}: $e');
    }
  }

  /// Soft-delete a debt record in Firestore.
  Future<void> deleteDebtRemote(String id) async {
    try {
      final col = _debtsCol;
      if (col == null) return;
      await col.doc(id).set({
        'id': id,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Error deleting debt $id: $e');
    }
  }

  /// Upload or update a single category document.
  Future<void> syncCategory(CategoryItem category) async {
    try {
      final col = _categoriesCol;
      if (col == null) return;
      await col.doc(category.id).set(category.toJson());
    } catch (e) {
      debugPrint('[SyncService] Error syncing category ${category.id}: $e');
    }
  }

  /// Delete a category document from Firestore (soft-delete).
  Future<void> deleteCategoryRemote(String id) async {
    try {
      final col = _categoriesCol;
      if (col == null) return;
      await col.doc(id).set({
        'id': id,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Error deleting category $id: $e');
    }
  }

  /// Upload profile settings to Firestore.
  Future<void> syncProfile(Map<String, dynamic> profileData) async {
    try {
      final doc = _userDoc?.collection('settings').doc('profile');
      if (doc == null) return;
      await doc.set(profileData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SyncService] Error syncing profile: $e');
    }
  }

  /// Sync all transactions at once (used after bulk operations like balance recalculation).
  Future<void> syncAllTransactions(List<Transaction> transactions) async {
    try {
      final col = _transactionsCol;
      final firestore = _firestore;
      if (col == null || firestore == null) return;

      // Use batched writes for efficiency (max 500 per batch)
      final batches = <WriteBatch>[];
      var currentBatch = firestore.batch();
      var count = 0;

      for (final tx in transactions) {
        currentBatch.set(col.doc(tx.id), tx.toJson());
        count++;
        if (count >= 450) {
          batches.add(currentBatch);
          currentBatch = firestore.batch();
          count = 0;
        }
      }
      if (count > 0) {
        batches.add(currentBatch);
      }

      for (final batch in batches) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('[SyncService] Error bulk syncing transactions: $e');
    }
  }

  /// Delete all remote Firestore data associated with a user UID:
  /// queries and deletes all documents in all subcollections (transactions, budgets,
  /// savings_goals, debts, categories, settings) and deletes the root user document.
  Future<void> deleteAllUserData(String uid) async {
    final firestore = _firestore;
    if (firestore == null || uid.isEmpty) return;

    final userDoc = firestore.collection('users').doc(uid);
    final subcollections = [
      'transactions',
      'budgets',
      'savings_goals',
      'debts',
      'categories',
      'settings',
    ];

    for (final sub in subcollections) {
      final col = userDoc.collection(sub);
      final snapshot = await col.get();
      if (snapshot.docs.isNotEmpty) {
        final batches = <WriteBatch>[];
        var batch = firestore.batch();
        var count = 0;
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
          count++;
          if (count >= 450) {
            batches.add(batch);
            batch = firestore.batch();
            count = 0;
          }
        }
        if (count > 0) {
          batches.add(batch);
        }
        for (final b in batches) {
          await b.commit();
        }
      }
    }

    // Finally delete the parent user document itself
    await userDoc.delete();
    debugPrint('[SyncService] Successfully wiped all Firestore records for user $uid');
  }
}

