import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/screens/help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget() {
    return const MaterialApp(
      home: HelpSupportScreen(),
    );
  }

  group('Help & Support Screen Tests', () {
    testWidgets('1. Direct Assistance section displays correct heading, description, and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Heading and description
      expect(find.text('Need Direct Assistance?'), findsOneWidget);
      expect(
        find.text('Reach out directly to the Spentee support team.'),
        findsOneWidget,
      );

      // Buttons
      expect(find.text('Copy Support Email'), findsOneWidget);
      expect(find.text('Feedback'), findsOneWidget);
    });

    testWidgets('2. Copy Support Email triggers confirmation snackbar',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy Support Email'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Copied support@spentee.app to clipboard!'),
        findsOneWidget,
      );
    });

    testWidgets('3. Feedback button opens feedback bottom sheet and submits',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Feedback'));
      await tester.pumpAndSettle();

      // Bottom sheet content
      expect(find.text('Send Feedback or Bug Report'), findsOneWidget);
      expect(
        find.text('Tell us how we can improve your Spentee experience.'),
        findsOneWidget,
      );
      expect(find.text('Submit Feedback'), findsOneWidget);

      // Type feedback text
      await tester.enterText(
        find.byType(TextField),
        'Spentee is awesome and works great offline!',
      );
      await tester.pumpAndSettle();

      // Submit feedback
      await tester.tap(find.text('Submit Feedback'));
      await tester.pumpAndSettle();

      // Bottom sheet is dismissed and snackbar shown
      expect(find.text('Send Feedback or Bug Report'), findsNothing);
      expect(
        find.text('Thank you! Your feedback has been received. 🚀'),
        findsOneWidget,
      );
    });

    testWidgets('4. All 10 FAQ questions are present and no mascot FAQ exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final expectedQuestions = [
        'How does Budget Management work?',
        'Is my financial data secure and private?',
        'How do I add and manage transactions?',
        'How does Lend & Repay work?',
        'How do Transfers and Investments work?',
        'How does Spentee AI work?',
        'Can I use Spentee without an internet connection?',
        'Can I create my own categories?',
        'What happens if I delete my account?',
        'Why does Spentee show advertisements?',
      ];

      for (final q in expectedQuestions) {
        // Scroll until visible if needed
        await tester.scrollUntilVisible(
          find.text(q),
          100.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(q), findsOneWidget);
      }

      // Verify mascot is NOT mentioned anywhere
      expect(find.textContaining(RegExp('mascot', caseSensitive: false)), findsNothing);
      expect(find.textContaining(RegExp('Male', caseSensitive: false)), findsNothing);
      expect(find.textContaining(RegExp('Female', caseSensitive: false)), findsNothing);
    });

    testWidgets('5. FAQ accordion opens one at a time and toggles properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially, FAQ 0 (Budget Management) is expanded
      expect(
        find.textContaining('Spentee lets you set monthly spending limits'),
        findsOneWidget,
      );

      // FAQ 1 (Data secure and private) answer is not yet visible
      expect(
        find.textContaining('Your financial information is associated with your account.'),
        findsNothing,
      );

      // Tap FAQ 1
      await tester.tap(find.text('Is my financial data secure and private?'));
      await tester.pumpAndSettle();

      // FAQ 1 is now expanded, and FAQ 0 is collapsed
      expect(
        find.textContaining('Your financial information is associated with your account.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Spentee lets you set monthly spending limits'),
        findsNothing,
      );

      // Tap FAQ 1 again to collapse it
      await tester.tap(find.text('Is my financial data secure and private?'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Your financial information is associated with your account.'),
        findsNothing,
      );
    });

    testWidgets('6. Screen is responsive on small screen sizes without overflow',
        (WidgetTester tester) async {
      // Simulate small Android screen (320 x 480)
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify header and initial elements render cleanly without assertion errors
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Need Direct Assistance?'), findsOneWidget);
    });
  });
}
