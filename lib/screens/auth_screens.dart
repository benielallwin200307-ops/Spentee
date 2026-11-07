import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../widgets/spentee_loading.dart';
import 'main_shell.dart';

/// Screen 7 — Login Screen (Recreated from reference design)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (_isLoading || _isGoogleLoading) return;
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text;

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (pass.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    if (pass.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);
    final appState = AppStateScope.of(context);

    try {
      final credential = await AuthService.instance.signInWithEmail(
        email: email,
        password: pass,
      );
      final user = credential.user!;

      await appState.setUserProfile(
        name: user.displayName?.isNotEmpty == true
            ? user.displayName!
            : (email.split('@')[0]),
        email: user.email ?? email,
        uid: user.uid,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    final appState = AppStateScope.of(context);

    try {
      final credential = await AuthService.instance.signInWithGoogleForLogin();
      if (credential == null) {
        // User cancelled selection or dismissed bottom sheet
        return;
      }

      final user = credential.user!;
      await appState.setUserProfile(
        name: user.displayName?.isNotEmpty == true
            ? user.displayName!
            : (user.email?.split('@')[0] ?? 'User'),
        email: user.email ?? '',
        uid: user.uid,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        _showNoAccountFoundDialog();
      } else {
        _showError(AuthService.getErrorMessage(e));
      }
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showNoAccountFoundDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF091C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF65FFA7), size: 22),
            SizedBox(width: 8),
            Text(
              'No Account Found',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'No account found. Please sign up first.',
          style: TextStyle(color: Color(0xFF88A8B6), fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF88A8B6))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onSignUp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF65FFA7),
              foregroundColor: const Color(0xFF00241D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go to Sign Up', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _onForgotPassword() {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim().toLowerCase());
    bool isResetting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF091C24),
      barrierColor: Colors.black.withValues(alpha: 0.75),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3842),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Color(0xFF00E676),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Enter your email to receive a reset link',
                              style: TextStyle(
                                color: Color(0xFF88A0A8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2329),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF163E44),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: resetEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.mail_outline_rounded,
                          color: Color(0xFF88A0A8),
                          size: 20,
                        ),
                        hintText: 'Enter your account email',
                        hintStyle: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isResetting
                          ? null
                          : () async {
                              final email = resetEmailCtrl.text.trim().toLowerCase();
                              if (email.isEmpty) {
                                _showError('Please enter your email address.');
                                return;
                              }
                              final emailRegex =
                                  RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                              if (!emailRegex.hasMatch(email)) {
                                _showError('Please enter a valid email address.');
                                return;
                              }

                              setModalState(() => isResetting = true);
                              try {
                                await AuthService.instance.sendPasswordReset(email);
                                if (!sheetCtx.mounted) return;
                                Navigator.pop(sheetCtx);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Password reset link sent to $email. Please check your inbox.'),
                                    backgroundColor: const Color(0xFF0D3528),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => isResetting = false);
                                _showError(AuthService.getErrorMessage(e));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: const Color(0xFF00241D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isResetting
                          ? const SpenteeLoading.inline(
                              size: 20,
                              color: Color(0xFF00241D),
                            )
                          : const Text(
                              'Send Reset Link',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final topArtHeight = screenWidth * (416.0 / 504.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF000F14),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF011319),
                Color(0xFF000E13),
                Color(0xFF00090D),
              ],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Top status bar breathing room so clock/battery don't overlap Spentee wordmark
                SizedBox(height: mediaQuery.padding.top * 0.75),

                // Top mascot artwork (room, window, plants, lamp, mascot, chart, piggy, receipt)
                SizedBox(
                  width: double.infinity,
                  height: topArtHeight,
                  child: Image.asset(
                    'Assets/extracted/login_top_art.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),

                // Main Login Panel overlapping top artwork
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF01181D),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0xFF146A58),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF45F59A).withValues(alpha: 0.08),
                          blurRadius: 24,
                          spreadRadius: 1,
                          offset: const Offset(0, -2),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Heading: Welcome Back
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Welcome ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Back',
                                style: TextStyle(
                                  color: Color(0xFF45F59A),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        const Text(
                          'Login to continue to Spentee',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF88A0A8),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email Field
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF011417),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF124345),
                              width: 1.2,
                            ),
                          ),
                          child: TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                color: Color(0xFF88A0A8),
                                size: 20,
                              ),
                              hintText: 'Email address',
                              hintStyle: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF011417),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF124345),
                              width: 1.2,
                            ),
                          ),
                          child: TextField(
                            controller: _passCtrl,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            enableSuggestions: false,
                            onSubmitted: (_) => _onLogin(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF88A0A8),
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _obscurePass
                                      ? const Color(0xFF88A0A8)
                                      : const Color(0xFF45F59A),
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                              ),
                              hintText: 'Password',
                              hintStyle: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _onForgotPassword,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0xFF45F59A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Login Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF55FAA8), Color(0xFF38E594)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF45F59A).withValues(alpha: 0.42),
                                blurRadius: 18,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: (_isLoading || _isGoogleLoading) ? null : _onLogin,
                              child: Center(
                                child: _isLoading
                                    ? const SpenteeLoading.inline(
                                        size: 22,
                                        color: Color(0xFF002219),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Login',
                                            style: TextStyle(
                                              color: Color(0xFF002219),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Color(0xFF002219),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider (OR)
                        const Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Color(0xFF144548),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Color(0xFF88A0A8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Color(0xFF144548),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Google Sign-In Button (Android Only)
                        Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF01181D),
                            borderRadius: BorderRadius.circular(27),
                            border: Border.all(
                              color: const Color(0xFF144548),
                              width: 1.2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(27),
                              onTap: (_isLoading || _isGoogleLoading)
                                  ? null
                                  : _onGoogleSignIn,
                              child: _isGoogleLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SpenteeLoading.inline(size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'Connecting with Google...',
                                          style: TextStyle(
                                            color: Color(0xFF45F59A),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'Assets/extracted/google_g_logo_transparent.png',
                                          height: 22,
                                          width: 22,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                            Icons.g_mobiledata_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Sign Up navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Color(0xFF88A0A8),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _onSignUp,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Color(0xFF45F59A),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom padding for smooth scrolling
                SizedBox(height: mediaQuery.padding.bottom + 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 8 — Sign Up Screen (Recreated exactly from design reference)
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    if (_isLoading || _isGoogleLoading) return;
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text;

    if (name.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (pass.isEmpty) {
      _showError('Please enter a password.');
      return;
    }

    if (pass.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);
    final appState = AppStateScope.of(context);

    try {
      final credential = await AuthService.instance.signUpWithEmail(
        email: email,
        password: pass,
        fullName: name,
      );
      final user = credential.user!;

      await appState.setUserProfile(
        name: name,
        email: email,
        uid: user.uid,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    final appState = AppStateScope.of(context);

    try {
      final credential = await AuthService.instance.signUpWithGoogle();
      if (credential == null) {
        // User cancelled account selection or dismissed bottom sheet
        return;
      }

      final user = credential.user!;
      await appState.setUserProfile(
        name: user.displayName?.isNotEmpty == true
            ? user.displayName!
            : (_nameCtrl.text.trim().isNotEmpty
                ? _nameCtrl.text.trim()
                : 'User'),
        email: user.email ?? _emailCtrl.text.trim(),
        uid: user.uid,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    // Top illustration extends to top of screen filling the gap while preserving desk edge position
    final topArtHeight = mediaQuery.padding.top + (screenWidth * (570.0 / 1024.0));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF00151B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF00151B),
        body: Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Artwork extending to very top of screen, filling the gap
                  SizedBox(
                    width: double.infinity,
                    height: topArtHeight,
                    child: Image.asset(
                      'Assets/extracted/signup_top_art_clean.png',
                      width: screenWidth,
                      height: topArtHeight,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: const Color(0xFF00151B)),
                    ),
                  ),

                  // Main Form Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading: "Create your Spentee account" positioned immediately below the illustration with 5 px spacing
                        const SizedBox(height: 5.0),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Create your\n',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: math.min(screenWidth * 0.082, 32.0),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  height: 1.15,
                                ),
                              ),
                              TextSpan(
                                text: 'Spentee ',
                                style: TextStyle(
                                  color: const Color(0xFF65FFA7),
                                  fontSize: math.min(screenWidth * 0.082, 32.0),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  height: 1.15,
                                ),
                              ),
                              TextSpan(
                                text: 'account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: math.min(screenWidth * 0.082, 32.0),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),

                        // Subtitle
                        const Text(
                          'Start your journey to smarter money habits.',
                          style: TextStyle(
                            color: Color(0xFFB8CBD8),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 27),

                        // Full Name Field
                        _buildLabel('Full name'),
                        const SizedBox(height: 5.5),
                        _buildInputField(
                          controller: _nameCtrl,
                          hint: 'Alex',
                          prefixIcon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 11),

                        // Email Address Field
                        _buildLabel('Email address'),
                        const SizedBox(height: 5.5),
                        _buildInputField(
                          controller: _emailCtrl,
                          hint: 'you@example.com',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                        ),
                        const SizedBox(height: 11),

                        // Password Field
                        _buildLabel('Password'),
                        const SizedBox(height: 5.5),
                        _buildInputField(
                          controller: _passCtrl,
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _isPasswordVisible
                                  ? const Color(0xFF65FFA7)
                                  : const Color(0xFF8FA8B2),
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sign Up Pill Button (Mint gradient with green glow)
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF65FFA7), Color(0xFF00E98B)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E98B)
                                    .withValues(alpha: 0.45),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap: (_isLoading || _isGoogleLoading)
                                  ? null
                                  : _onSignUp,
                              child: Center(
                                child: _isLoading
                                    ? const SpenteeLoading.inline(
                                        size: 22,
                                        color: Color(0xFF00241D),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              color: Color(0xFF00241D),
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Color(0xFF00241D),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),

                        // OR Divider
                        const Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Color(0xFF17465A),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Color(0xFF8FA8B2),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Color(0xFF17465A),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),

                        // Continue with Google Button (Android only, NO Apple sign-in)
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF031F32),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color(0xFF17465A),
                              width: 1.2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: (_isLoading || _isGoogleLoading)
                                  ? null
                                  : _onGoogleSignIn,
                              child: _isGoogleLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SpenteeLoading.inline(size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'Connecting with Google...',
                                          style: TextStyle(
                                            color: Color(0xFF45F59A),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'Assets/extracted/google_g_logo_transparent.png',
                                          height: 22,
                                          width: 22,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                            Icons.g_mobiledata_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Already have an account? Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Color(0xFFB8CBD8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Color(0xFF65FFA7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Bottom breathing room
                        SizedBox(height: mediaQuery.padding.bottom + 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Circular Back Button pinned in upper-left
            Positioned(
              top: mediaQuery.padding.top + 8,
              left: 18,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF092024).withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFB8CBD8),
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    bool autocorrect = true,
    bool enableSuggestions = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF031F32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF17465A),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        textCapitalization: textCapitalization,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: const Color(0xFF65FFA7),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF5C7885),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF8FA8B2),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

