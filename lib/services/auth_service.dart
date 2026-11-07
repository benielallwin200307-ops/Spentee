import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Centralized Firebase Authentication and Google Sign-In service
/// utilizing Android Credential Manager.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Web OAuth Client ID from google-services.json for Firebase ID token verification.
  static const String serverClientId =
      '46636408233-epfqboouuh20ucfnnfppm8ih45q0oem0.apps.googleusercontent.com';

  bool _initialized = false;

  /// Initialize Google Sign-In with Android Credential Manager support.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Google Sign-In initialization error: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  FirebaseAuth get auth => _auth;
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges().handleError((_) {});
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Create a new user with email and password, setting the display name.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (credential.user != null && fullName.trim().isNotEmpty) {
      await credential.user!.updateDisplayName(fullName.trim());
      await credential.user!.reload();
    }

    return credential;
  }

  /// Sign in existing user with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  /// Authenticate using Google Android Credential Manager and Firebase credentials.
  /// Used for general sign in. Returns null if user cancelled.
  Future<UserCredential?> signInWithGoogle() async {
    await _ensureInitialized();
    try {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// Sign in an existing Google user from the Login screen using Android Credential Manager.
  /// If the Google account does not already exist in Firebase Authentication,
  /// the transiently created auth record is immediately purged and a
  /// `FirebaseAuthException` with code 'user-not-found' is thrown,
  /// preventing unintended automatic account registration.
  Future<UserCredential?> signInWithGoogleForLogin() async {
    await _ensureInitialized();
    try {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Verify if this is an existing registered user or a brand new account
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNew) {
        // User tapped Login but has never registered on Sign Up: abort and purge transient user
        try {
          await userCredential.user?.delete();
        } catch (e) {
          debugPrint('Error deleting transient Google user on login: $e');
        }
        await signOut();
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found. Please sign up first.',
        );
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// Sign up a new user using Google credentials on the Sign Up screen using Android Credential Manager.
  /// If the account already exists, the user is signed in to their existing account.
  Future<UserCredential?> signUpWithGoogle() async {
    await _ensureInitialized();
    try {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google Sign-In sign out error: $e');
    }
    await _auth.signOut();
  }

  /// Delete the current authenticated Firebase user account.
  /// Handles reauthentication if required (`requires-recent-login`).
  Future<void> deleteAccount({String? passwordForReauth}) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final providers = user.providerData.map((p) => p.providerId).toList();

        if (providers.contains('google.com')) {
          await _ensureInitialized();
          try {
            final GoogleSignInAccount googleUser =
                await GoogleSignIn.instance.authenticate();
            final GoogleSignInAuthentication googleAuth =
                googleUser.authentication;
            final OAuthCredential credential = GoogleAuthProvider.credential(
              idToken: googleAuth.idToken,
            );
            await user.reauthenticateWithCredential(credential);
            await user.delete();
          } on GoogleSignInException catch (e) {
            if (e.code == GoogleSignInExceptionCode.canceled ||
                e.code == GoogleSignInExceptionCode.interrupted) {
              throw FirebaseAuthException(
                code: 'reauth-cancelled',
                message: 'Google re-authentication was cancelled.',
              );
            }
            rethrow;
          }
        } else if (passwordForReauth != null &&
            passwordForReauth.isNotEmpty &&
            user.email != null) {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: passwordForReauth,
          );
          await user.reauthenticateWithCredential(credential);
          await user.delete();
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  /// Translate Firebase, Google Sign-In, and auth errors into user-friendly error messages.
  static String getErrorMessage(dynamic error) {
    if (error is GoogleSignInException) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return 'Sign-in cancelled.';
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'Google Sign-In configuration error. Please ensure SHA-1 fingerprint is registered in Firebase Console.';
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'Authentication UI is currently unavailable. Please try again.';
        case GoogleSignInExceptionCode.userMismatch:
          return 'Account mismatch during authentication. Please select your own account.';
        default:
          return error.description ?? 'Google authentication failed (${error.code}).';
      }
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No account found. Please sign up first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Invalid email or password. If you registered with Google, please tap Continue with Google.';
        case 'email-already-in-use':
        case 'EMAIL_EXISTS':
          return 'An account already exists for this email. Please log in.';
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled. Please contact support.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'channel-error':
          return 'Please fill in all required fields.';
        case 'requires-recent-login':
          return 'Please verify your credentials before deleting your account.';
        case 'reauth-cancelled':
          return 'Re-authentication was cancelled.';
        default:
          return error.message ?? 'Authentication error (${error.code}).';
      }
    }
    final str = error?.toString() ?? '';
    if (str.contains('INVALID_LOGIN_CREDENTIALS') || str.contains('invalid-credential')) {
      return 'Invalid email or password. If you registered with Google, please tap Continue with Google.';
    }
    if (str.contains('EMAIL_EXISTS') || str.contains('email-already-in-use')) {
      return 'An account already exists for this email. Please log in.';
    }
    if (str.contains('INVALID_EMAIL') || str.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (str.contains('WEAK_PASSWORD') || str.contains('weak-password')) {
      return 'The password is too weak. Please use at least 6 characters.';
    }
    if (str.contains('network_error') || str.contains('network-request-failed') || str.contains('ApiException: 7')) {
      return 'Network error. Please check your internet connection.';
    }
    if (str.contains('sign_in_failed') || str.contains('ApiException: 10')) {
      return 'Google Sign-In failed (code 10). Please ensure SHA-1 fingerprint is registered in Firebase Console.';
    }
    return 'Authentication failed. Please try again.';
  }
}
