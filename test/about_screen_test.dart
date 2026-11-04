import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/config/app_config.dart';
import 'package:spentee/screens/about_screen.dart';
import 'package:spentee/screens/help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({Key? key}) {
    return MaterialApp(
      home: AboutScreen(key: key),
    );
  }

  group('About Spentee Screen Tests', () {
    testWidgets('1. App identity section renders branding and dynamic version',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // App Branding
      expect(find.text('Spentee'), findsAtLeastNWidgets(1));
      expect(find.text('Your AI Money Companion'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsAtLeastNWidgets(1));

      // Dynamic Version
      expect(find.text('Version: ${AppConfig.version}'), findsOneWidget);

      // Verify changing AppConfig dynamically changes the displayed version
      final originalVersion = AppConfig.version;
      AppConfig.version = '1.0.1';
      await tester.pumpWidget(buildTestWidget(key: const ValueKey('updated_version')));
      await tester.pumpAndSettle();
      expect(find.text('Version: 1.0.1'), findsOneWidget);

      // Restore original version
      AppConfig.version = originalVersion;
    });

    testWidgets('2. About description text matches current Spentee V1 identity',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      const expectedDescription =
          'Spentee helps you take control of your money, one transaction at a time. Track income and expenses, manage budgets, monitor investments, keep track of money lent and borrowed, and discover smarter ways to manage your finances with Spentee AI.';

      expect(find.text(expectedDescription), findsOneWidget);
    });

    testWidgets('3. What You Can Do with Spentee features 4 compact cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Section header
      expect(find.text('What You Can Do with Spentee'), findsOneWidget);

      // Feature 1
      expect(find.text('Smart Money Tracking'), findsOneWidget);
      expect(
        find.text('Manually track your income, expenses and transactions.'),
        findsOneWidget,
      );

      // Feature 2
      expect(find.text('Spending Analytics'), findsOneWidget);
      expect(
        find.text(
          'Understand your spending habits, monitor budgets and discover where your money goes.',
        ),
        findsOneWidget,
      );

      // Feature 3
      expect(find.text('AI Financial Insights'), findsOneWidget);
      expect(
        find.text(
          'Get money-related insights, spending analysis and smarter saving suggestions with Spentee AI.',
        ),
        findsOneWidget,
      );

      // Feature 4
      expect(find.text('Offline Access & Cloud Sync'), findsOneWidget);
      expect(
        find.text(
          'Access supported features offline and synchronise your financial data across devices using Firebase.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('4. Technical Information displays only Storage, Cloud Sync, and Platform',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Displayed values
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('Local-First Storage'), findsOneWidget);

      expect(find.text('Cloud Sync'), findsOneWidget);
      expect(find.text('Firebase'), findsOneWidget);

      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Android'), findsOneWidget);

      // Outdated details removed
      expect(find.text('Framework'), findsNothing);
      expect(find.text('Flutter 3.x / Dart'), findsNothing);
      expect(find.text('Package ID'), findsNothing);
      expect(find.text('com.spentee.spentee'), findsNothing);
      expect(find.text('Database'), findsNothing);
      expect(find.text('Local JSON Storage'), findsNothing);
      expect(find.text('Engineered By'), findsNothing);
    });

    testWidgets('5. Bottom buttons trigger respective actions correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to Privacy Policy and tap
      await tester.scrollUntilVisible(
        find.text('Privacy Policy'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy & Security Policy'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy & Security Policy'), findsNothing);

      // Scroll to Terms of Use and tap
      await tester.scrollUntilVisible(
        find.text('Terms of Use'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Terms of Use'));
      await tester.pumpAndSettle();
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.text('Terms of Service'), findsNothing);

      // Scroll to Contact Support and tap
      await tester.scrollUntilVisible(
        find.text('Contact Support'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Contact Support'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpSupportScreen), findsOneWidget);
      expect(find.text('Need Direct Assistance?'), findsOneWidget);
    });

    testWidgets('6. Copyright text is displayed and no mascot references exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('© 2026 Spentee. All rights reserved.'),
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('© 2026 Spentee. All rights reserved.'), findsOneWidget);

      // Verify no mascot references exist on screen
      expect(find.textContaining(RegExp('mascot', caseSensitive: false)), findsNothing);
    });

    testWidgets('7. Responsive layout on small screen dimensions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('About Spentee'), findsOneWidget);
      expect(find.text('What You Can Do with Spentee'), findsOneWidget);
    });
  });
}
