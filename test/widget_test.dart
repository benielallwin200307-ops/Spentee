import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/main.dart';

void main() {
  testWidgets('Spentee splash screen branding and content test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SpenteeApp());

    // Verify tagline and Get Started button
    expect(find.text('Your AI Money Companion'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started button and pump navigation
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
