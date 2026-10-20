import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentee/main.dart';
import 'package:spentee/screens/auth_screens.dart';
import 'package:spentee/screens/onboarding_screens.dart';
import 'package:spentee/screens/home_screen.dart';
import 'package:spentee/screens/budget_management_screen.dart';
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

  testWidgets('HomeScreen replaces Scan Bill with Budgets and navigates to BudgetManagementScreen',
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
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.textContaining('Scan'), findsNothing);

    // Tap Budgets button
    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();

    // Verify BudgetManagementScreen opened
    expect(find.byType(BudgetManagementScreen), findsOneWidget);
    expect(find.text('Manage Budget'), findsOneWidget);

    // Verify back navigation returns to HomeScreen
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetManagementScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('HomeScreen displays clean mascot images for both Male and Female selections without text',
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

    // Verify Male mascot clean image is displayed and no happy/ai avatar text assets
    final maleMainImages = find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName ==
            'Assets/extracted/mascot_main.png');
    // Top avatar, Total balance card, and AI banner all use clean mascot_main.png
    expect(maleMainImages, findsAtLeastNWidgets(2));

    final maleTextImages = find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        ((widget.image as AssetImage).assetName ==
                'Assets/extracted/avatar_happy.png' ||
            (widget.image as AssetImage).assetName ==
                'Assets/extracted/avatar_ai.png'));
    expect(maleTextImages, findsNothing);

    // Switch to Female mascot (as done in Profile Settings)
    appState.setSelectedMascot('female');
    await tester.pumpAndSettle();

    // Verify Female mascot clean image is displayed reactively
    final femaleMainImages = find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName ==
            'Assets/extracted/female_main.png');
    expect(femaleMainImages, findsAtLeastNWidgets(2));

    final femaleTextImages = find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        ((widget.image as AssetImage).assetName ==
                'Assets/extracted/female_happy.png' ||
            (widget.image as AssetImage).assetName ==
                'Assets/extracted/female_ai.png'));
    expect(femaleTextImages, findsNothing);
  });
}


