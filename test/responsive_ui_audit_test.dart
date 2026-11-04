// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/models/lent_borrowed_record.dart';
import 'package:spentee/state/app_state.dart';
import 'package:spentee/screens/home_screen.dart';
import 'package:spentee/screens/main_shell.dart';
import 'package:spentee/screens/transactions_screen.dart';
import 'package:spentee/screens/add_transaction_screen.dart';
import 'package:spentee/screens/edit_transaction_screen.dart';
import 'package:spentee/screens/budget_management_screen.dart';
import 'package:spentee/screens/category_management_screen.dart';
import 'package:spentee/screens/analytics_screen.dart';
import 'package:spentee/screens/insights_screen.dart';
import 'package:spentee/screens/lent_borrowed_screen.dart';
import 'package:spentee/screens/chat_screen.dart';
import 'package:spentee/screens/profile_screen.dart';
import 'package:spentee/screens/help_support_screen.dart';
import 'package:spentee/screens/about_screen.dart';

class LayoutIssue {
  final String screen;
  final Size viewport;
  final String description;
  final String overflowDetails;

  LayoutIssue({
    required this.screen,
    required this.viewport,
    required this.description,
    required this.overflowDetails,
  });

  @override
  String toString() => '[$screen @ ${viewport.width.toInt()}x${viewport.height.toInt()}] $description\n$overflowDetails';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final recordedIssues = <LayoutIssue>[];

  AppState createPopulatedState() {
    final state = AppState();
    state.initSyncForTesting('audit_test_user');
    
    // Add realistic seed data for rendering lists, cards, charts
    state.addTransaction(
      Transaction(
        id: 'tx_1',
        title: 'Supermarket Groceries & Household Essentials',
        amount: 2850.50,
        type: TransactionType.expense,
        category: 'Food & Dining',
        icon: Icons.restaurant_rounded,
        categoryColor: Colors.orange,
        date: DateTime.now(),
      ),
    );
    state.addTransaction(
      Transaction(
        id: 'tx_2',
        title: 'Monthly Tech Salary Deposit',
        amount: 85000.0,
        type: TransactionType.income,
        category: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        categoryColor: Colors.green,
        date: DateTime.now(),
      ),
    );
    state.addTransaction(
      Transaction(
        id: 'tx_3',
        title: 'Mutual Fund SIP Investment',
        amount: 5000.0,
        type: TransactionType.transfer,
        category: 'Mutual Fund / SIP',
        icon: Icons.auto_graph_rounded,
        categoryColor: Colors.blue,
        date: DateTime.now(),
        sourceAccount: 'Primary Bank Account',
      ),
    );
    state.addDebt(
      LentBorrowedRecord(
        id: 'debt_1',
        type: DebtType.lent,
        personName: 'Alexander Montgomery',
        amount: 4500.0,
        date: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 10)),
        note: 'Weekend dinner split & cabs',
      ),
    );
    return state;
  }

  const viewports = <String, Size>{
    'Small (360x740)': Size(360, 740),
    'Standard (393x852)': Size(393, 852),
    'Large (432x960)': Size(432, 960),
  };

  Future<void> auditScreen(
    WidgetTester tester, {
    required String screenName,
    required Widget Function(AppState state) builder,
  }) async {
    for (final entry in viewports.entries) {
      final size = entry.value;

      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      final caughtErrors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtErrors.add(details);
      };

      try {
        final state = createPopulatedState();
        await tester.pumpWidget(
          AppStateScope(
            state: state,
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: builder(state),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        for (final err in caughtErrors) {
          final summary = err.summary.toString();
          final isOverflow = summary.contains('overflowed') ||
              summary.contains('RenderFlex');
          
          // Extract widget/creator information from error
          String creatorInfo = '';
          final str = err.toString();
          final creatorMatch = RegExp(r'The relevant error-causing widget was:\s*([^\n]+)').firstMatch(str);
          if (creatorMatch != null) {
            creatorInfo = ' | Widget: ${creatorMatch.group(1)}';
          }

          // Extract error summary and first 3 lines of stack/context
          final strLines = err.toString().split('\n');
          final locationLine = strLines.firstWhere((l) => l.contains('lib/screens/'), orElse: () => '');
          
          recordedIssues.add(
            LayoutIssue(
              screen: screenName,
              viewport: size,
              description: isOverflow ? 'RenderFlex Overflow$creatorInfo' : 'Layout Exception',
              overflowDetails: '$summary\n${locationLine.isNotEmpty ? "Location: $locationLine" : ""}',
            ),
          );
        }
      } catch (e, stack) {
        recordedIssues.add(
          LayoutIssue(
            screen: screenName,
            viewport: size,
            description: 'Exception during pump',
            overflowDetails: '$e\n$stack',
          ),
        );
      } finally {
        FlutterError.onError = originalOnError;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    }
  }

  group('Complete Responsive UI Audit Suite', () {
    tearDownAll(() {
      print('\n===============================================================');
      print('RESPONSIVE AUDIT RESULTS:');
      print('Total Layout / Overflow Issues Found: ${recordedIssues.length}');
      for (final issue in recordedIssues) {
        print('---------------------------------------------------------------');
        print(issue);
      }
      print('===============================================================\n');
    });

    testWidgets('1. Audit Home Dashboard (HomeScreen & MainShell)', (tester) async {
      await auditScreen(
        tester,
        screenName: 'HomeScreen',
        builder: (_) => const HomeScreen(),
      );
      await auditScreen(
        tester,
        screenName: 'MainShell',
        builder: (_) => const MainShell(),
      );
    });

    testWidgets('2. Audit Transactions Screen', (tester) async {
      await auditScreen(
        tester,
        screenName: 'TransactionsScreen',
        builder: (_) => const TransactionsScreen(),
      );
    });

    testWidgets('3. Audit Add & Edit Transaction Screens', (tester) async {
      await auditScreen(
        tester,
        screenName: 'AddTransactionScreen (Expense)',
        builder: (_) => const AddTransactionScreen(initialType: TransactionType.expense),
      );
      await auditScreen(
        tester,
        screenName: 'AddTransactionScreen (Income)',
        builder: (_) => const AddTransactionScreen(initialType: TransactionType.income),
      );
      await auditScreen(
        tester,
        screenName: 'AddTransactionScreen (Transfer)',
        builder: (_) => const AddTransactionScreen(initialType: TransactionType.transfer),
      );
      await auditScreen(
        tester,
        screenName: 'EditTransactionScreen',
        builder: (state) => EditTransactionScreen(transaction: state.transactions.first),
      );
    });

    testWidgets('4. Audit Categories & Budgets Screens', (tester) async {
      await auditScreen(
        tester,
        screenName: 'CategoryManagementScreen',
        builder: (_) => const CategoryManagementScreen(),
      );
      await auditScreen(
        tester,
        screenName: 'BudgetManagementScreen',
        builder: (_) => const BudgetManagementScreen(),
      );
    });

    testWidgets('5. Audit Analytics & Insights Screens', (tester) async {
      await auditScreen(
        tester,
        screenName: 'AnalyticsScreen',
        builder: (_) => const AnalyticsScreen(),
      );
      await auditScreen(
        tester,
        screenName: 'InsightsScreen',
        builder: (_) => const InsightsScreen(),
      );
    });

    testWidgets('6. Audit Lend & Repay (Debts) Screen', (tester) async {
      await auditScreen(
        tester,
        screenName: 'LentBorrowedScreen',
        builder: (_) => const LentBorrowedScreen(),
      );
    });

    testWidgets('7. Audit Spentee AI Chat Screen', (tester) async {
      await auditScreen(
        tester,
        screenName: 'ChatScreen',
        builder: (_) => const ChatScreen(),
      );
    });

    testWidgets('8. Audit Profile Screen', (tester) async {
      await auditScreen(
        tester,
        screenName: 'ProfileScreen',
        builder: (_) => const ProfileScreen(),
      );
    });

    testWidgets('9. Audit Help & Support Screen', (tester) async {
      await auditScreen(
        tester,
        screenName: 'HelpSupportScreen',
        builder: (_) => const HelpSupportScreen(),
      );
    });

    testWidgets('10. Audit About Screen', (tester) async {
      await auditScreen(
        tester,
        screenName: 'AboutScreen',
        builder: (_) => const AboutScreen(),
      );
    });
  });
}
