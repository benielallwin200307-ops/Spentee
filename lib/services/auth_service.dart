import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Centralized Firebase Authentication and Google Sign-In service.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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
      email: email.trim(),
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
      email: email.trim(),
      password: password,
    );
  }

  /// Authenticate using Google account selection and Firebase credentials.
  /// Returns null if the user cancelled the account selection.
  Future<UserCredential?> signInWithGoogle() async {
    // 1. Trigger the native Google account selection
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the prompt
      return null;
    }

    // 2. Obtain the auth details (tokens) from the Google account
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // 3. Create a credential for Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Sign in to Firebase Authentication
    return await _auth.signInWithCredential(credential);
  }

  /// Send password reset email.
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Google Sign-In sign out error: $e');
    }
    await _auth.signOut();
  }

  /// Translate Firebase and auth errors into user-friendly error messages.
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No account found with this email. Please sign up first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password. Please verify your credentials.';
        case 'email-already-in-use':
          return 'An account already exists for this email. Please log in.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled in Firebase Console.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'Authentication error (${error.code}).';
      }
    }
    final str = error?.toString() ?? '';
    if (str.contains('sign_in_failed') || str.contains('ApiException: 10')) {
      return 'Google Sign-In failed (code 10). Please ensure SHA-1 fingerprint is registered in Firebase Console.';
    }
    if (str.contains('network_error') || str.contains('ApiException: 7')) {
      return 'Network error during Google Sign-In. Please check your connection.';
    }
    return 'Authentication failed. Please try again.';
  }
}
