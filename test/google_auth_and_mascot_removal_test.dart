import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spentee/screens/auth_screens.dart';
import 'package:spentee/screens/profile_screen.dart';
import 'package:spentee/services/auth_service.dart';
import 'package:spentee/state/app_state.dart';
import 'package:spentee/theme/mascot_theme.dart';
import 'package:spentee/widgets/spentee_loading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Login Separation and Mascot Removal Tests', () {
    test('1. AuthService error message for user-not-found prompts sign up', () {
      final message = AuthService.getErrorMessage(
        FirebaseAuthException(code: 'user-not-found'),
      );
      expect(message, 'No account found. Please sign up first.');
    });

    test('2. MascotThemeData has canonical defaultTheme with signature Neon Mint', () {
      const theme = MascotThemeData.defaultTheme;
      expect(theme.primaryAccent, const Color(0xFF00E676));
      expect(theme.type, MascotType.male);
    });

    test('3. AppState mascotTheme always provides canonical Spentee theme', () {
      final state = AppState();
      expect(state.mascotTheme, MascotThemeData.defaultTheme);
      expect(state.mascotTheme.primaryAccent, const Color(0xFF00E676));
    });

    testWidgets('4. SignUpScreen has NO gender cards or male/female selectors',
        (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: SignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Form fields exist
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign Up'), findsAtLeastNWidgets(1));
      expect(find.text('Continue with Google'), findsOneWidget);

      // Gender selection options are completely removed
      expect(find.text('Gender'), findsNothing);
      expect(find.text('Male'), findsNothing);
      expect(find.text('Female'), findsNothing);
      expect(find.byIcon(Icons.male_rounded), findsNothing);
      expect(find.byIcon(Icons.female_rounded), findsNothing);
    });

    testWidgets('5. LoginScreen renders without mascot theme picker dialogs',
        (WidgetTester tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Login form fields exist
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsAtLeastNWidgets(1));
      expect(find.text('Continue with Google'), findsOneWidget);

      // No gender or mascot theme prompt text anywhere
      expect(find.text('Choose Your Mascot Theme'), findsNothing);
      expect(find.text('Male'), findsNothing);
      expect(find.text('Female'), findsNothing);
    });

    testWidgets('6. ProfileScreen has NO Theme Accent or Mascot Switch sheet',
        (WidgetTester tester) async {
      final appState = AppState();
      appState.initSyncForTesting('test_user_profile_no_mascot');

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Profile options exist
      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);

      // Mascot and Theme Accent are completely removed
      expect(find.text('Theme Accent'), findsNothing);
      expect(find.text('Mascot Companion'), findsNothing);
      expect(find.text('Neon Mint (Male)'), findsNothing);
      expect(find.text('Rose Pink (Female)'), findsNothing);
      expect(find.byIcon(Icons.palette_rounded), findsNothing);
    });

    testWidgets('7. LoginScreen password visibility toggle works correctly with matching icons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appState = AppState();

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find password field by finding TextField with hint 'Password'
      final passwordFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Password',
      );
      expect(passwordFinder, findsOneWidget);

      // 1. By default, password must be hidden
      TextField passField = tester.widget<TextField>(passwordFinder);
      expect(passField.obscureText, isTrue);

      // 2. Hidden password -> Eye-off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // 3. Tap the eye-off icon
      await tester.ensureVisible(find.byIcon(Icons.visibility_off_outlined));
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      // Password should become visible, icon should be eye icon
      passField = tester.widget<TextField>(passwordFinder);
      expect(passField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // 4. Tap the eye icon again
      await tester.ensureVisible(find.byIcon(Icons.visibility_outlined));
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Password should become hidden again, icon should be eye-off icon
      passField = tester.widget<TextField>(passwordFinder);
      expect(passField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('8. SignUpScreen password visibility toggle works correctly with matching icons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appState = AppState();

      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(
            home: SignUpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find password field by finding TextField with hint '••••••••'
      final passwordFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '••••••••',
      );
      expect(passwordFinder, findsOneWidget);

      // 1. By default, password must be hidden
      TextField passField = tester.widget<TextField>(passwordFinder);
      expect(passField.obscureText, isTrue);

      // 2. Hidden password -> Eye-off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // 3. Tap the eye-off icon
      await tester.ensureVisible(find.byIcon(Icons.visibility_off_outlined));
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      // Password should become visible, icon should be eye icon
      passField = tester.widget<TextField>(passwordFinder);
      expect(passField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // 4. Tap the eye icon again
      await tester.ensureVisible(find.byIcon(Icons.visibility_outlined));
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Password should become hidden again, icon should be eye-off icon
      passField = tester.widget<TextField>(passwordFinder);
      expect(passField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    test('9. AuthService translates Credential Manager GoogleSignInException correctly', () {
      expect(
        AuthService.getErrorMessage(const GoogleSignInException(code: GoogleSignInExceptionCode.canceled)),
        'Sign-in cancelled.',
      );
      expect(
        AuthService.getErrorMessage(const GoogleSignInException(code: GoogleSignInExceptionCode.clientConfigurationError)),
        contains('SHA-1 fingerprint'),
      );
      expect(
        AuthService.getErrorMessage(const GoogleSignInException(code: GoogleSignInExceptionCode.uiUnavailable)),
        contains('unavailable'),
      );
      expect(
        AuthService.getErrorMessage('com.google.android.gms.common.api.ApiException: 10:'),
        contains('SHA-1 fingerprint'),
      );
      expect(
        AuthService.getErrorMessage('com.google.android.gms.common.api.ApiException: 7: network_error'),
        contains('Network error'),
      );
    });

    testWidgets('10. SpenteeLoading renders inline and full modes correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SpenteeLoading.inline(size: 24, message: 'Saving...'),
                SpenteeLoading.full(size: 64, message: 'Syncing data...'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SpenteeLoading), findsNWidgets(2));
      expect(find.text('Saving...'), findsOneWidget);
      expect(find.text('Syncing data...'), findsOneWidget);
    });
  });
}
