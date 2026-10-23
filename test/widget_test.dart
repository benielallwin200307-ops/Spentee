import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/main.dart';
import 'package:spentee/screens/auth_screens.dart';
import 'package:spentee/screens/onboarding_screens.dart';
import 'package:spentee/screens/home_screen.dart';
import 'package:spentee/screens/lent_borrowed_screen.dart';
import 'package:spentee/state/app_state.dart';

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

  testWidgets('Onboarding 3-step flow (Welcome -> Roast -> Language -> Login) without mascot step',
      (WidgetTester tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      AppStateScope(
        state: appState,
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 0: Welcome to Spentee
    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next -> Step 1: Get roasted
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Get roasted'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next -> Step 2: Pick your language
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pick your'), findsOneWidget);
    expect(find.textContaining('language'), findsOneWidget);

    // Verify "Choose your" or "mascot" does not exist
    expect(find.text('Choose your'), findsNothing);
    expect(find.text('Neon Mint Theme'), findsNothing);
    expect(find.text('Rose Pink Theme'), findsNothing);

    // On the final step (Step 2: Language), the button is "Get Started"
    expect(find.text('Get Started'), findsOneWidget);

    // Tap "Get Started" -> transitions to LoginScreen
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('HomeScreen replaces Budgets with Lend & Repay and navigates to LentBorrowedScreen',
      (WidgetTester tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      AppStateScope(
        state: appState,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 3 quick-action buttons exist
    expect(find.text('Add\nExpense'), findsOneWidget);
    expect(find.text('Add\nIncome'), findsOneWidget);
    expect(find.text('Lend\n& Repay'), findsOneWidget);
    expect(find.text('Budgets'), findsNothing);

    // Verify separate Lent & Borrowed Money summary card is removed
    expect(find.text('Lent & Borrowed Money'), findsNothing);

    // Tap Lend & Repay button
    await tester.tap(find.text('Lend\n& Repay'));
    await tester.pumpAndSettle();

    // Verify LentBorrowedScreen opened
    expect(find.byType(LentBorrowedScreen), findsOneWidget);

    // Verify back navigation returns to HomeScreen
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(LentBorrowedScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('HomeScreen displays clean fintech icons and no mascot character illustrations',
      (WidgetTester tester) async {
    final appState = AppState();
    appState.setSelectedMascot('male');

    await tester.pumpWidget(
      AppStateScope(
        state: appState,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no character images are displayed on Home
    final maleMainImages = find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName ==
            'Assets/extracted/mascot_main.png');
    expect(maleMainImages, findsNothing);

    // Verify clean fintech balance wallet icon and AI spark icon are displayed
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.auto_awesome_rounded), findsAtLeastNWidgets(1));

    // Switch to Female theme (as done in Profile Settings)
    appState.setSelectedMascot('female');
    await tester.pumpAndSettle();

    // Verify still zero character illustrations on Home
    final femaleMainImages = find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName ==
            'Assets/extracted/female_main.png');
    expect(femaleMainImages, findsNothing);

    // Verify clean icons persist
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsAtLeastNWidgets(1));
  });
}


