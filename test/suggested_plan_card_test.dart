import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/screens/chat_screen.dart';
import 'package:spentee/services/financial_intelligence_engine.dart';
import 'package:spentee/models/transaction.dart';
import 'package:spentee/models/budget.dart';
import 'package:spentee/models/savings_goal.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }

  group('SuggestedPlanCard Null-Safety & Regression Tests', () {
    testWidgets('1. Renders gracefully when needs & total are present, but wants and savings are missing (Regression Test)',
        (WidgetTester tester) async {
      final incompletePlan = {
        'total': '₹800',
        'needs': {
          'label': 'Target Goal',
          'amount': '₹800',
          'percent': 1.0,
        },
        // 'wants' and 'savings' are intentionally omitted
      };

      // Must not throw exception
      await tester.pumpWidget(
        buildTestableWidget(SuggestedPlanCard(planData: incompletePlan)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suggested Plan for ₹800'), findsOneWidget);
      expect(find.text('Target Goal'), findsOneWidget);
      expect(find.text('Wants (30%)'), findsOneWidget);
      expect(find.text('Savings (20%)'), findsOneWidget);
    });

    testWidgets('2. Renders gracefully when all optional sections are explicitly null',
        (WidgetTester tester) async {
      final nullSectionPlan = <String, dynamic>{
        'total': null,
        'needs': null,
        'wants': null,
        'savings': null,
      };

      await tester.pumpWidget(
        buildTestableWidget(SuggestedPlanCard(planData: nullSectionPlan)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suggested Plan for Plan'), findsOneWidget);
      expect(find.text('Needs (50%)'), findsOneWidget);
      expect(find.text('Wants (30%)'), findsOneWidget);
      expect(find.text('Savings (20%)'), findsOneWidget);
    });

    testWidgets('3. Renders gracefully with completely empty planData map',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const SuggestedPlanCard(planData: {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suggested Plan for Plan'), findsOneWidget);
      expect(find.text('Needs (50%)'), findsOneWidget);
    });

    testWidgets('4. Renders gracefully when section maps contain malformed types',
        (WidgetTester tester) async {
      final malformedPlan = <String, dynamic>{
        'total': 12345, // int instead of String
        'needs': {
          'label': 999, // int instead of String
          'amount': false, // bool instead of String
          'percent': 'invalid_percent', // String instead of num
        },
        'wants': 'not_even_a_map', // String instead of Map
        'savings': 42.5, // double instead of Map
      };

      await tester.pumpWidget(
        buildTestableWidget(SuggestedPlanCard(planData: malformedPlan)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suggested Plan for 12345'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.text('false'), findsOneWidget);
    });

    testWidgets('5. Renders all custom sections when all fields are fully populated',
        (WidgetTester tester) async {
      final fullPlan = {
        'total': '₹50,000',
        'needs': {
          'label': 'Essential Living (50%)',
          'amount': '₹25,000',
          'percent': 0.5,
        },
        'wants': {
          'label': 'Lifestyle & Fun (30%)',
          'amount': '₹15,000',
          'percent': 0.3,
        },
        'savings': {
          'label': 'Wealth & Investments (20%)',
          'amount': '₹10,000',
          'percent': 0.2,
        },
      };

      await tester.pumpWidget(
        buildTestableWidget(SuggestedPlanCard(planData: fullPlan)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suggested Plan for ₹50,000'), findsOneWidget);
      expect(find.text('Essential Living (50%)'), findsOneWidget);
      expect(find.text('₹25,000'), findsOneWidget);
      expect(find.text('Lifestyle & Fun (30%)'), findsOneWidget);
      expect(find.text('₹15,000'), findsOneWidget);
      expect(find.text('Wealth & Investments (20%)'), findsOneWidget);
      expect(find.text('₹10,000'), findsOneWidget);
    });

    test('6. FinancialIntelligenceEngine returns normalized planData with all sections', () {
      final res = FinancialIntelligenceEngine.instance.evaluateQuery(
        query: 'How can I save ₹800 this month?',
        transactions: <Transaction>[],
        budgets: <Budget>[],
        savingsGoals: <SavingsGoal>[],
        userConsented: true,
        referenceDate: DateTime(2026, 10, 19),
      );

      expect(res, isNotNull);
      expect(res!.hasPlanCard, isTrue);
      expect(res.planData, isNotNull);

      final plan = res.planData!;
      expect(plan.containsKey('total'), isTrue);
      expect(plan.containsKey('needs'), isTrue);
      expect(plan.containsKey('wants'), isTrue);
      expect(plan.containsKey('savings'), isTrue);
      expect(plan.containsKey('status'), isTrue);

      expect(plan['total'], '₹800');
      expect((plan['needs'] as Map)['amount'], '₹800');
      expect((plan['wants'] as Map)['amount'], '₹800');
      expect((plan['savings'] as Map)['amount'], '₹800');

      // Crucial requirement: recommendations must not claim savings are achieved
      expect(res.text, contains('proposed budget reduction targets, not realized savings'));
    });
  });
}
