import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/lent_borrowed_record.dart';
import '../models/category_model.dart';
import '../services/auth_service.dart';

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
    _activeUid = uid;
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

  /// Performs first-time migration: uploads all local records to Firestore
  /// and downloads any existing cloud records that are missing locally.
  /// This is additive-only — no records are deleted.
  Future<void> performMigration({
    required List<Transaction> localTransactions,
    required List<Budget> localBudgets,
    required List<SavingsGoal> localSavingsGoals,
    required List<LentBorrowedRecord> localDebts,
    required List<CategoryItem> localCategories,
    required Map<String, dynamic> localProfile,
  }) async {
    if (_migrationDone || _userDoc == null) return;

    try {
      _suppressListeners = true;

      // Migrate transactions
      await _migrateCollection<Transaction>(
        collection: _transactionsCol!,
        localRecords: localTransactions,
        getId: (t) => t.id,
        toJson: (t) => t.toJson(),
        fromJson: (json) => Transaction.fromJson(json),
        getUpdatedAt: (t) => t.updatedAt,
      );

      // Migrate budgets
      await _migrateCollection<Budget>(
        collection: _budgetsCol!,
        localRecords: localBudgets,
        getId: (b) => b.id,
        toJson: (b) => b.toJson(),
        fromJson: (json) => Budget.fromJson(json),
        getUpdatedAt: (b) => b.updatedAt,
      );

      // Migrate savings goals
      await _migrateCollection<SavingsGoal>(
        collection: _savingsGoalsCol!,
        localRecords: localSavingsGoals,
        getId: (g) => g.id,
        toJson: (g) => g.toJson(),
        fromJson: (json) => SavingsGoal.fromJson(json),
        getUpdatedAt: (g) => g.updatedAt,
      );

      // Migrate debts
      await _migrateCollection<LentBorrowedRecord>(
        collection: _debtsCol!,
        localRecords: localDebts,
        getId: (d) => d.id,
        toJson: (d) => d.toJson(),
        fromJson: (json) => LentBorrowedRecord.fromJson(json),
        getUpdatedAt: (d) => d.updatedAt,
      );

      // Migrate custom categories (only custom ones to avoid duplicating defaults)
      final customCats = localCategories.where((c) => c.isCustom).toList();
      await _migrateCollection<CategoryItem>(
        collection: _categoriesCol!,
        localRecords: customCats,
        getId: (c) => c.id,
        toJson: (c) => c.toJson(),
        fromJson: (json) => CategoryItem.fromJson(json),
        getUpdatedAt: (c) => c.updatedAt,
      );

      // Migrate profile
      await _migrateProfile(localProfile);

      _migrationDone = true;
      debugPrint('[SyncService] Migration completed successfully');
    } catch (e) {
      debugPrint('[SyncService] Migration error: $e');
    } finally {
      _suppressListeners = false;
    }
  }

  /// Generic migration for a collection: upload local, merge with cloud.
  Future<List<T>> _migrateCollection<T>({
    required CollectionReference collection,
    required List<T> localRecords,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required DateTime Function(T) getUpdatedAt,
  }) async {
    final newFromCloud = <T>[];

    try {
      // Get all existing cloud documents
      final cloudSnapshot = await collection.get();
      final cloudDocs = <String, Map<String, dynamic>>{};
      for (final doc in cloudSnapshot.docs) {
        cloudDocs[doc.id] = doc.data() as Map<String, dynamic>;
      }

      // Upload local records (set with merge to avoid overwriting newer cloud data)
      for (final record in localRecords) {
        final id = getId(record);
        final localJson = toJson(record);
        final localUpdatedAt = getUpdatedAt(record);

        if (cloudDocs.containsKey(id)) {
          // Record exists in cloud — compare timestamps
          final cloudJson = cloudDocs[id]!;
          final cloudUpdatedAtStr = cloudJson['updatedAt'] as String?;
          final cloudUpdatedAt = cloudUpdatedAtStr != null
              ? DateTime.tryParse(cloudUpdatedAtStr) ?? DateTime(2000)
              : DateTime(2000);

          if (localUpdatedAt.isAfter(cloudUpdatedAt)) {
            // Local is newer — update cloud
            await collection.doc(id).set(localJson);
          } else if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
            // Cloud is newer — this will be picked up by the listener
            newFromCloud.add(fromJson(cloudJson));
          }
          // Same timestamp — no-op
          cloudDocs.remove(id);
        } else {
          // Record doesn't exist in cloud — upload it
          await collection.doc(id).set(localJson);
        }
      }

      // Download cloud records that don't exist locally
      for (final entry in cloudDocs.entries) {
        newFromCloud.add(fromJson(entry.value));
      }
    } catch (e) {
      debugPrint('[SyncService] Collection migration error: $e');
    }

    return newFromCloud;
  }

  /// Migrate user profile to Firestore.
  Future<void> _migrateProfile(Map<String, dynamic> localProfile) async {
    try {
      final profileDoc = _userDoc?.collection('settings').doc('profile');
      if (profileDoc == null) return;

      final cloudSnapshot = await profileDoc.get();
      if (!cloudSnapshot.exists) {
        // No cloud profile — upload local
        await profileDoc.set(localProfile);
      }
      // If cloud profile exists, keep it (don't overwrite user settings)
    } catch (e) {
      debugPrint('[SyncService] Profile migration error: $e');
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
          final tx = Transaction.fromJson(data);
          if (!tx.isDeleted) {
            transactions.add(tx);
          }
        } catch (e) {
          debugPrint('[SyncService] Error parsing transaction: $e');
        }
      }
      // Sort newest first
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
          final budget = Budget.fromJson(data);
          if (!budget.isDeleted) {
            budgets.add(budget);
          }
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
          final goal = SavingsGoal.fromJson(data);
          if (!goal.isDeleted) {
            goals.add(goal);
          }
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
          final debt = LentBorrowedRecord.fromJson(data);
          if (!debt.isDeleted) {
            debts.add(debt);
          }
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

  /// Delete a category document from Firestore.
  Future<void> deleteCategoryRemote(String id) async {
    try {
      final col = _categoriesCol;
      if (col == null) return;
      await col.doc(id).delete();
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
}
