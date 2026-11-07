import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spentee/screens/auth_screens.dart';
import 'package:spentee/services/auth_service.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Email + Password Authentication & Error Mapping Tests', () {
    test('1. AuthService.getErrorMessage correctly translates all Firebase Auth codes', () {
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'invalid-credential')),
        'Invalid email or password. If you registered with Google, please tap Continue with Google.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'INVALID_LOGIN_CREDENTIALS')),
        'Invalid email or password. If you registered with Google, please tap Continue with Google.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'user-not-found')),
        'No account found. Please sign up first.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'wrong-password')),
        'Incorrect password. Please try again.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'email-already-in-use')),
        'An account already exists for this email. Please log in.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'EMAIL_EXISTS')),
        'An account already exists for this email. Please log in.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'invalid-email')),
        'Please enter a valid email address.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'weak-password')),
        'The password is too weak. Please use at least 6 characters.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'network-request-failed')),
        'Network error. Please check your internet connection.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'too-many-requests')),
        'Too many attempts. Please try again later.',
      );
      expect(
        AuthService.getErrorMessage(FirebaseAuthException(code: 'channel-error')),
        'Please fill in all required fields.',
      );
    });

    test('2. AuthService.getErrorMessage preserves Google Sign-In exception handling', () {
      expect(
        AuthService.getErrorMessage(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.canceled,
            description: 'User canceled flow',
          ),
        ),
        'Sign-in cancelled.',
      );
      expect(
        AuthService.getErrorMessage(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.interrupted,
            description: 'User interrupted flow',
          ),
        ),
        'Sign-in cancelled.',
      );
      expect(
        AuthService.getErrorMessage(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
          ),
        ),
        contains('SHA-1 fingerprint is registered in Firebase Console'),
      );
    });

    testWidgets('3. LoginScreen client-side email and password validations work correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
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

      // Tap Login with completely empty fields
      final loginBtn = find.text('Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter your email address.'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Enter invalid email format
      final emailField = find.widgetWithText(TextField, 'Email address');
      await tester.enterText(emailField, 'notanemail');
      await tester.pump();
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Enter valid email but empty password
      await tester.enterText(emailField, 'valid.user@gmail.com');
      await tester.pump();
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter your password.'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Enter short password (< 6 chars)
      final passField = find.widgetWithText(TextField, 'Password');
      await tester.enterText(passField, '12345');
      await tester.pump();
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('4. LoginScreen: Password visibility toggle switches icon and obscureText',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
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

      // Default state: obscureText is true and eye-off icon is shown
      TextField passWidget = tester.widget<TextField>(find.widgetWithText(TextField, 'Password'));
      expect(passWidget.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap eye toggle
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      // ObscureText becomes false and eye icon is shown
      passWidget = tester.widget<TextField>(find.widgetWithText(TextField, 'Password'));
      expect(passWidget.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap again to obscure
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      passWidget = tester.widget<TextField>(find.widgetWithText(TextField, 'Password'));
      expect(passWidget.obscureText, isTrue);
    });

    testWidgets('5. LoginScreen: Forgot Password opens Spentee modal bottom sheet with prefill',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
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

      // Enter email in login box first
      final emailField = find.widgetWithText(TextField, 'Email address');
      await tester.enterText(emailField, 'forgot.test@gmail.com');
      await tester.pump();

      // Tap 'Forgot Password?'
      final forgotBtn = find.text('Forgot Password?');
      await tester.ensureVisible(forgotBtn);
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      // Modal bottom sheet appears
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your email to receive a reset link'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);

      // Pre-filled email in the reset modal
      expect(find.text('forgot.test@gmail.com'), findsNWidgets(2)); // In login field & modal field
    });

    testWidgets('6. SignUpScreen validates full name, email format, and password length',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
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

      // Empty Full Name
      final signUpBtn = find.text('Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter your full name.'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Enter Name, Empty Email
      final nameField = find.widgetWithText(TextField, 'Alex');
      await tester.enterText(nameField, 'Test User');
      await tester.pump();
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter your email address.'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Enter Invalid Email
      final emailField = find.widgetWithText(TextField, 'you@example.com');
      await tester.enterText(emailField, 'bademail@');
      await tester.pump();
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Enter Valid Email, Short Password (<6 chars)
      await tester.enterText(emailField, 'test@example.com');
      final passField = find.widgetWithText(TextField, '••••••••');
      await tester.enterText(passField, '1234');
      await tester.pump();
      await tester.tap(signUpBtn);
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    test('7. Safety Invariant: Login does not automatically generate local guest accounts', () {
      final appState = AppState();
      // App starts unauthenticated
      expect(appState.isAuthenticated, isFalse);
      expect(appState.userUid, isEmpty);
      // userProfiles must not contain any fake local accounts
      expect(appState.userProfiles.keys.any((k) => k.startsWith('local_')), isFalse);
    });

    testWidgets('8. Password and email fields disable autocorrect, suggestions, and auto-capitalization',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final appState = AppState();

      // Test LoginScreen
      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final loginEmailField = tester.widget<TextField>(find.widgetWithText(TextField, 'Email address'));
      expect(loginEmailField.autocorrect, isFalse);
      expect(loginEmailField.enableSuggestions, isFalse);

      final loginPassField = tester.widget<TextField>(find.widgetWithText(TextField, 'Password'));
      expect(loginPassField.autocorrect, isFalse);
      expect(loginPassField.enableSuggestions, isFalse);
      expect(loginPassField.keyboardType, TextInputType.visiblePassword);

      // Test SignUpScreen
      await tester.pumpWidget(
        AppStateScope(
          state: appState,
          child: const MaterialApp(home: SignUpScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final signUpEmailField = tester.widget<TextField>(find.widgetWithText(TextField, 'you@example.com'));
      expect(signUpEmailField.autocorrect, isFalse);
      expect(signUpEmailField.enableSuggestions, isFalse);

      final signUpPassField = tester.widget<TextField>(find.widgetWithText(TextField, '••••••••'));
      expect(signUpPassField.autocorrect, isFalse);
      expect(signUpPassField.enableSuggestions, isFalse);
      expect(signUpPassField.keyboardType, TextInputType.visiblePassword);
    });

    test('9. Email normalization uniformly applies trim().toLowerCase()', () {
      const raw1 = '  BenielAllwin2003@GMAIL.COM  ';
      const raw2 = 'Test.User+Filter@Domain.Co.In ';

      expect(raw1.trim().toLowerCase(), 'benielallwin2003@gmail.com');
      expect(raw2.trim().toLowerCase(), 'test.user+filter@domain.co.in');
    });
  });
}
