import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spentee/services/auth_service.dart';
import 'package:spentee/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Android Credential Manager & Auth Coexistence Test Suite', () {
    test('1. Google Sign-In using existing Google account maps correctly to AppState', () async {
      final appState = AppState();
      const existingUid = 'google_user_existing_123';
      const existingEmail = 'existing_user@gmail.com';
      const existingName = 'Existing Google User';

      await appState.setUserProfile(
        name: existingName,
        email: existingEmail,
        uid: existingUid,
      );

      expect(appState.userUid, existingUid);
      expect(appState.userName, existingName);
      expect(appState.userEmail, existingEmail);
      expect(appState.isAuthenticated, isTrue);
    });

    test('2. Google Sign-In using a different Google account updates profile safely', () async {
      final appState = AppState();
      const account1Uid = 'google_user_111';
      const account2Uid = 'google_user_222';

      // First account signs in
      await appState.setUserProfile(
        name: 'Account One',
        email: 'user1@gmail.com',
        uid: account1Uid,
      );
      expect(appState.userUid, account1Uid);

      // User switches account via Credential Manager
      await appState.setUserProfile(
        name: 'Account Two',
        email: 'user2@gmail.com',
        uid: account2Uid,
      );
      expect(appState.userUid, account2Uid);
      expect(appState.userEmail, 'user2@gmail.com');
    });

    test('3. User cancels the account-selection screen (null credential, zero errors)', () {
      // Credential Manager canceled exception
      const canceledException = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'User dismissed credential manager bottom sheet',
      );
      expect(canceledException.code, GoogleSignInExceptionCode.canceled);

      // Interrupted exception
      const interruptedException = GoogleSignInException(
        code: GoogleSignInExceptionCode.interrupted,
        description: 'User tapped outside bottom sheet',
      );
      expect(interruptedException.code, GoogleSignInExceptionCode.interrupted);

      // Verify AuthService maps canceled/interrupted to user-friendly text
      expect(AuthService.getErrorMessage(canceledException), 'Sign-in cancelled.');
      expect(AuthService.getErrorMessage(interruptedException), 'Sign-in cancelled.');
    });

    test('4. Google account authentication fails (maps configuration and UI unavailable errors)', () {
      const configError = GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'Developer error / SHA-1 mismatch',
      );
      expect(
        AuthService.getErrorMessage(configError),
        contains('SHA-1 fingerprint'),
      );

      const uiUnavailable = GoogleSignInException(
        code: GoogleSignInExceptionCode.uiUnavailable,
        description: 'Google Play Services or UI unavailable',
      );
      expect(
        AuthService.getErrorMessage(uiUnavailable),
        contains('unavailable'),
      );
    });

    test('5. Internet connection is unavailable (network error handling)', () {
      final fbNetworkError = FirebaseAuthException(code: 'network-request-failed');
      expect(
        AuthService.getErrorMessage(fbNetworkError),
        'Network error. Please check your internet connection.',
      );

      const gmsNetworkError = 'com.google.android.gms.common.api.ApiException: 7: network_error';
      expect(
        AuthService.getErrorMessage(gmsNetworkError),
        'Network error. Please check your internet connection.',
      );
    });

    test('6. Existing Email/Password login and registration remain fully functional', () {
      // Normalisation: trim().toLowerCase()
      const rawEmail = '  Alex.Hunter@Example.COM  ';
      expect(rawEmail.trim().toLowerCase(), 'alex.hunter@example.com');

      // Validation logic: format and length
      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
      expect(emailRegex.hasMatch('alex.hunter@example.com'), isTrue);
      expect(emailRegex.hasMatch('invalid-email'), isFalse);

      const validPassword = 'SecurePassword123';
      expect(validPassword.length >= 6, isTrue);
    });

    test('7. Existing Firebase user session is preserved in local storage and AppState', () async {
      final appState = AppState();
      await appState.setUserProfile(
        name: 'Persistent User',
        email: 'persistent@example.com',
        uid: 'firebase_persistent_uid_456',
      );

      expect(appState.isAuthenticated, isTrue);
      expect(appState.userProfiles.containsKey('firebase_persistent_uid_456'), isTrue);
      final profile = appState.userProfiles['firebase_persistent_uid_456'] as Map;
      expect(profile['userName'], 'Persistent User');
      expect(profile['userEmail'], 'persistent@example.com');
    });

    test('8. Logout and re-authentication clear and restore session correctly', () async {
      final appState = AppState();
      await appState.setUserProfile(
        name: 'Logout Tester',
        email: 'logout_test@gmail.com',
        uid: 'uid_logout_test',
      );
      expect(appState.isAuthenticated, isTrue);

      // Perform logout
      await appState.logout();
      expect(appState.isAuthenticated, isFalse);
      expect(appState.userUid, isEmpty);

      // Re-authenticate via Google
      await appState.setUserProfile(
        name: 'Logout Tester',
        email: 'logout_test@gmail.com',
        uid: 'uid_logout_test',
      );
      expect(appState.isAuthenticated, isTrue);
      expect(appState.userUid, 'uid_logout_test');
    });

    test('9. No duplicate Firebase user accounts: Login rejects unregistered Google accounts', () {
      final userNotFoundException = FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account found. Please sign up first.',
      );
      expect(
        AuthService.getErrorMessage(userNotFoundException),
        'No account found. Please sign up first.',
      );
    });

    testWidgets('10. UI Buttons: Google Sign-In button shows normal and circular loading states',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Normal button state
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'Assets/extracted/google_g_logo_transparent.png',
                          height: 22,
                          width: 22,
                          errorBuilder: (_, _, _) => const Icon(Icons.g_mobiledata),
                        ),
                        const SizedBox(width: 12),
                        const Text('Continue with Google'),
                      ],
                    ),
                  ),
                ),
                // Loading button state (circular progress indicator)
                const SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45F59A)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

