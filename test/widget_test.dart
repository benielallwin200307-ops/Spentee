import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/main.dart';

void main() {
  testWidgets('Spentee welcome screen branding and content test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SpenteeApp());

    // Verify main heading and tagline
    expect(find.text('Welcome to Spentee'), findsOneWidget);
    expect(find.text('Your AI Money Companion'), findsOneWidget);

    // Verify brand message
    expect(
      find.text('Track your money. Get roasted. Think wiser. Save smarter.'),
      findsOneWidget,
    );

    // Verify pillars
    expect(find.text('Track your money'), findsOneWidget);
    expect(find.text('Get roasted'), findsOneWidget);
    expect(find.text('Think wiser'), findsOneWidget);
    expect(find.text('Save smarter'), findsOneWidget);

    // Verify Get Started button
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started button and verify SnackBar
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome to Spentee!'), findsOneWidget);
  });
}
