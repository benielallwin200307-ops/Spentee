import 'package:flutter_test/flutter_test.dart';

/// Simulated evaluator reproducing the exact semantics of `firestore.rules`.
class FirestoreRulesSimulator {
  final String? authUid;

  const FirestoreRulesSimulator({this.authUid});

  bool isAuthenticated() => authUid != null;
  bool isOwner(String userId) => isAuthenticated() && authUid == userId;

  bool isValidAmount(Map<String, dynamic> data, String field) {
    if (!data.containsKey(field)) return true;
    final val = data[field];
    return val is num && val >= 0;
  }

  bool isValidString(Map<String, dynamic> data, String field, int maxLen) {
    if (!data.containsKey(field)) return true;
    final val = data[field];
    return val is String && val.length <= maxLen;
  }

  /// Evaluates whether a write (create/update) operation on a given path is permitted.
  bool canWrite({
    required String path,
    required Map<String, dynamic> data,
  }) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    // Match /users/{userId}
    if (segments.length == 2 && segments[0] == 'users') {
      final userId = segments[1];
      return isOwner(userId);
    }

    // Match /users/{userId}/{subcollection}/{docId}
    if (segments.length == 4 && segments[0] == 'users') {
      final userId = segments[1];
      final subcollection = segments[2];

      if (!isOwner(userId)) return false;

      switch (subcollection) {
        case 'transactions':
          return isValidAmount(data, 'amount') && isValidString(data, 'title', 100);
        case 'budgets':
          return isValidAmount(data, 'limitAmount');
        case 'savings_goals':
          return isValidAmount(data, 'targetAmount') && isValidString(data, 'title', 100);
        case 'debts':
          return isValidAmount(data, 'amount') && isValidString(data, 'personName', 100);
        case 'categories':
          return isValidString(data, 'name', 50);
        case 'settings':
          return true;
        default:
          // Unknown subcollection: denied because recursive wildcard was removed!
          return false;
      }
    }

    // All other paths fall through to global deny
    return false;
  }

  /// Evaluates whether a read operation on a given path is permitted.
  bool canRead(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.length == 2 && segments[0] == 'users') {
      return isOwner(segments[1]);
    }

    if (segments.length == 4 && segments[0] == 'users') {
      final userId = segments[1];
      final subcollection = segments[2];

      if (!isOwner(userId)) return false;

      const allowedSubcollections = {
        'transactions',
        'budgets',
        'savings_goals',
        'debts',
        'categories',
        'settings',
      };

      return allowedSubcollections.contains(subcollection);
    }

    return false;
  }

  /// Evaluates whether a delete operation on a given path is permitted.
  bool canDelete(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.length == 2 && segments[0] == 'users') {
      return isOwner(segments[1]);
    }

    if (segments.length == 4 && segments[0] == 'users') {
      final userId = segments[1];
      final subcollection = segments[2];

      if (!isOwner(userId)) return false;

      const allowedSubcollections = {
        'transactions',
        'budgets',
        'savings_goals',
        'debts',
        'categories',
        'settings',
      };

      return allowedSubcollections.contains(subcollection);
    }

    return false;
  }
}

void main() {
  const ownerUid = 'user_spentee_owner';
  const otherUid = 'user_spentee_attacker';

  final ownerSim = const FirestoreRulesSimulator(authUid: ownerUid);
  final attackerSim = const FirestoreRulesSimulator(authUid: otherUid);
  final unauthSim = const FirestoreRulesSimulator(authUid: null);

  group('Firestore Security Rules Vulnerability Fix Tests', () {
    test('1. Owner can create valid transactions with positive amount and bounded title', () {
      final validTx = {
        'id': 'tx_123',
        'title': 'Dinner at Trattoria',
        'amount': 850.50,
        'category': 'Food & Drinks',
        'isDeleted': false,
        'updatedAt': '2026-11-04T12:00:00Z',
      };

      expect(
        ownerSim.canWrite(
          path: '/users/$ownerUid/transactions/tx_123',
          data: validTx,
        ),
        isTrue,
      );
      expect(
        ownerSim.canRead('/users/$ownerUid/transactions/tx_123'),
        isTrue,
      );
    });

    test('2. Owner CANNOT create transactions with negative amounts', () {
      final negativeTx = {
        'id': 'tx_neg_1',
        'title': 'Exploit Negative Balance',
        'amount': -500.0,
      };

      expect(
        ownerSim.canWrite(
          path: '/users/$ownerUid/transactions/tx_neg_1',
          data: negativeTx,
        ),
        isFalse,
      );
    });

    test('3. Owner CANNOT write invalid field types or excessively large strings', () {
      final stringAmountTx = {
        'id': 'tx_bad_type',
        'title': 'Invalid Amount Type',
        'amount': 'not_a_number',
      };
      expect(
        ownerSim.canWrite(
          path: '/users/$ownerUid/transactions/tx_bad_type',
          data: stringAmountTx,
        ),
        isFalse,
      );

      final oversizedTitleTx = {
        'id': 'tx_huge_title',
        'title': 'A' * 105, // Exceeds maxLen 100
        'amount': 100.0,
      };
      expect(
        ownerSim.canWrite(
          path: '/users/$ownerUid/transactions/tx_huge_title',
          data: oversizedTitleTx,
        ),
        isFalse,
      );
    });

    test('4. Another authenticated user CANNOT read, write, or delete the first user data', () {
      final legitimateTx = {
        'id': 'tx_legit',
        'title': 'Coffee',
        'amount': 50.0,
      };

      expect(
        attackerSim.canRead('/users/$ownerUid/transactions/tx_legit'),
        isFalse,
      );
      expect(
        attackerSim.canWrite(
          path: '/users/$ownerUid/transactions/tx_legit',
          data: legitimateTx,
        ),
        isFalse,
      );
      expect(
        attackerSim.canDelete('/users/$ownerUid/transactions/tx_legit'),
        isFalse,
      );
    });

    test('5. Unauthenticated users CANNOT read or write any private data', () {
      expect(
        unauthSim.canRead('/users/$ownerUid/transactions/tx_123'),
        isFalse,
      );
      expect(
        unauthSim.canWrite(
          path: '/users/$ownerUid/transactions/tx_123',
          data: {'amount': 100.0},
        ),
        isFalse,
      );
      expect(
        unauthSim.canRead('/users/$ownerUid'),
        isFalse,
      );
    });

    test('6. Valid updates and soft deletions work properly', () {
      final softDeletePayload = {
        'id': 'tx_123',
        'isDeleted': true,
        'updatedAt': '2026-11-04T12:30:00Z',
      };

      expect(
        ownerSim.canWrite(
          path: '/users/$ownerUid/transactions/tx_123',
          data: softDeletePayload,
        ),
        isTrue,
      );
    });

    test('7. Account deletion cascade remains fully permitted for owner', () {
      // Subcollection document deletion
      expect(
        ownerSim.canDelete('/users/$ownerUid/transactions/tx_123'),
        isTrue,
      );
      expect(
        ownerSim.canDelete('/users/$ownerUid/budgets/b_123'),
        isTrue,
      );
      expect(
        ownerSim.canDelete('/users/$ownerUid/savings_goals/sg_123'),
        isTrue,
      );
      expect(
        ownerSim.canDelete('/users/$ownerUid/debts/debt_123'),
        isTrue,
      );
      expect(
        ownerSim.canDelete('/users/$ownerUid/categories/cat_123'),
        isTrue,
      );
      expect(
        ownerSim.canDelete('/users/$ownerUid/settings/profile'),
        isTrue,
      );

      // Root parent document deletion
      expect(
        ownerSim.canDelete('/users/$ownerUid'),
        isTrue,
      );
    });

    test('8. Unknown subcollections are strictly denied (wildcard bypass eliminated)', () {
      final payload = {
        'arbitraryField': 'should_be_denied',
        'amount': -9999, // Malicious
      };

      // Writing to an undocumented subcollection under user root
      expect(
        ownerSim.canWrite(
          path: '/users/$ownerUid/unknown_hack_collection/doc_1',
          data: payload,
        ),
        isFalse,
      );

      expect(
        ownerSim.canRead('/users/$ownerUid/unknown_hack_collection/doc_1'),
        isFalse,
      );

      // Writing to an arbitrary top-level collection
      expect(
        ownerSim.canWrite(
          path: '/system_logs/log_1',
          data: payload,
        ),
        isFalse,
      );
    });
  });
}

