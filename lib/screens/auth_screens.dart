import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final email = _emailCtrl.text.trim();
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
      final savedMascot = appState.getSavedMascotForUser(user.uid) ?? 'male';

      appState.setUserProfile(
        name: user.displayName?.isNotEmpty == true
            ? user.displayName!
            : (email.split('@')[0]),
        email: user.email ?? email,
        gender: savedMascot,
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
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final appState = AppStateScope.of(context);

    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential == null) {
        // User cancelled selection
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final user = credential.user!;
      if (appState.hasSavedMascotForUser(user.uid)) {
        final savedMascot = appState.getSavedMascotForUser(user.uid)!;
        appState.setUserProfile(
          name: user.displayName?.isNotEmpty == true
              ? user.displayName!
              : (user.email?.split('@')[0] ?? 'User'),
          email: user.email ?? '',
          gender: savedMascot,
          uid: user.uid,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else {
        // No saved mascot selection: ask user to choose Male or Female
        if (!mounted) return;
        _showMascotThemePickerForGoogle(user);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMascotThemePickerForGoogle(User user) {
    String tempGender = 'male';
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF00151B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Mascot Theme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Google sign-in does not infer your gender. Please pick your preferred mascot companion.',
                  style: TextStyle(
                    color: Color(0xFFB8CBD8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _GenderCard(
                        label: 'Male',
                        symbol: Icons.male_rounded,
                        symbolColor: const Color(0xFF2997FF),
                        isSelected: tempGender == 'male',
                        onTap: () => setModalState(() => tempGender = 'male'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _GenderCard(
                        label: 'Female',
                        symbol: Icons.female_rounded,
                        symbolColor: const Color(0xFFFF528E),
                        isSelected: tempGender == 'female',
                        onTap: () => setModalState(() => tempGender = 'female'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF65FFA7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      final appState = AppStateScope.of(context);
                      appState.setUserProfile(
                        name: user.displayName?.isNotEmpty == true
                            ? user.displayName!
                            : (user.email?.split('@')[0] ?? 'User'),
                        email: user.email ?? '',
                        gender: tempGender,
                        uid: user.uid,
                      );
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Continue to Spentee',
                      style: TextStyle(
                        color: Color(0xFF00241D),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address to reset your password.');
      return;
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to $email.'),
          backgroundColor: const Color(0xFF012026),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.getErrorMessage(e));
    }
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
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.done,
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
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
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
                            onTap: _onForgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF45F59A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                              onTap: _isLoading ? null : _onLogin,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF002219),
                                        ),
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
                              onTap: _isLoading ? null : _onGoogleSignIn,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'Assets/extracted/google_g_logo_transparent.png',
                                    height: 22,
                                    width: 22,
                                    errorBuilder: (context, error, stackTrace) =>
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
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
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

    if (_selectedGender == null) {
      _showError('Please select your gender (Male or Female).');
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

      // Successfully authenticated: save profile and switch mascot theme
      appState.setUserProfile(
        name: name,
        email: email,
        gender: _selectedGender!,
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
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final appState = AppStateScope.of(context);

    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential == null) {
        // User cancelled account selection
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final user = credential.user!;
      if (_selectedGender != null) {
        // Apply the mascot selected on this screen
        appState.setUserProfile(
          name: user.displayName?.isNotEmpty == true
              ? user.displayName!
              : (_nameCtrl.text.trim().isNotEmpty
                  ? _nameCtrl.text.trim()
                  : 'User'),
          email: user.email ?? _emailCtrl.text.trim(),
          gender: _selectedGender!,
          uid: user.uid,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else if (appState.hasSavedMascotForUser(user.uid)) {
        final savedMascot = appState.getSavedMascotForUser(user.uid)!;
        appState.setUserProfile(
          name: user.displayName?.isNotEmpty == true
              ? user.displayName!
              : (_nameCtrl.text.trim().isNotEmpty
                  ? _nameCtrl.text.trim()
                  : 'User'),
          email: user.email ?? _emailCtrl.text.trim(),
          gender: savedMascot,
          uid: user.uid,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else {
        // Prompt user to choose Male or Female without inferring
        if (!mounted) return;
        _showMascotThemePickerForGoogle(user);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMascotThemePickerForGoogle(User user) {
    String tempGender = 'male';
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF00151B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Mascot Theme',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Google sign-in does not infer your gender. Please pick your preferred mascot companion.',
                  style: TextStyle(
                    color: Color(0xFFB8CBD8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _GenderCard(
                        label: 'Male',
                        symbol: Icons.male_rounded,
                        symbolColor: const Color(0xFF2997FF),
                        isSelected: tempGender == 'male',
                        onTap: () => setModalState(() => tempGender = 'male'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _GenderCard(
                        label: 'Female',
                        symbol: Icons.female_rounded,
                        symbolColor: const Color(0xFFFF528E),
                        isSelected: tempGender == 'female',
                        onTap: () => setModalState(() => tempGender = 'female'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF65FFA7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedGender = tempGender);
                      final appState = AppStateScope.of(context);
                      appState.setUserProfile(
                        name: user.displayName?.isNotEmpty == true
                            ? user.displayName!
                            : (_nameCtrl.text.trim().isNotEmpty
                                ? _nameCtrl.text.trim()
                                : 'User'),
                        email: user.email ?? _emailCtrl.text.trim(),
                        gender: tempGender,
                        uid: user.uid,
                      );
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Continue to Spentee',
                      style: TextStyle(
                        color: Color(0xFF00241D),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    // Top illustration aspect ratio based on 504x360 source
    final topArtHeight = screenWidth * (355.0 / 504.0);

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
                  // Top Artwork with Mascot, Window, Lamp, Laptop & Mug
                  SizedBox(
                    width: double.infinity,
                    height: topArtHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'Assets/extracted/signup_top_art_clean.png',
                            width: screenWidth,
                            height: topArtHeight,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: const Color(0xFF00151B)),
                          ),
                        ),

                        // Heading: "Create your\nSpentee account" overlaid at the bottom-left of the desk
                        Positioned(
                          left: 22,
                          right: screenWidth * 0.28,
                          bottom: 6,
                          child: RichText(
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
                        ),
                      ],
                    ),
                  ),

                  // Main Form Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),

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
                        const SizedBox(height: 16),

                        // Full Name Field
                        _buildLabel('Full name'),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _nameCtrl,
                          hint: 'Alex',
                          prefixIcon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),

                        // Email Address Field
                        _buildLabel('Email address'),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _emailCtrl,
                          hint: 'you@example.com',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        _buildLabel('Password'),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _passCtrl,
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
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
                        const SizedBox(height: 14),

                        // Gender Selection Section
                        _buildLabel('Gender'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _GenderCard(
                                label: 'Male',
                                symbol: Icons.male_rounded,
                                symbolColor: const Color(0xFF2997FF),
                                isSelected: _selectedGender == 'male',
                                onTap: () {
                                  setState(() => _selectedGender = 'male');
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _GenderCard(
                                label: 'Female',
                                symbol: Icons.female_rounded,
                                symbolColor: const Color(0xFFFF528E),
                                isSelected: _selectedGender == 'female',
                                onTap: () {
                                  setState(() => _selectedGender = 'female');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

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
                              onTap: _isLoading ? null : _onSignUp,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF00241D),
                                        ),
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
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 15),

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
                              onTap: _isLoading ? null : _onGoogleSignIn,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 16),

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

/// Gender Selection Card matching reference design
class _GenderCard extends StatelessWidget {
  final String label;
  final IconData symbol;
  final Color symbolColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.symbol,
    required this.symbolColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF031F32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF65FFA7) : const Color(0xFF17465A),
          width: isSelected ? 1.6 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  symbol,
                  color: symbolColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                // Circular Radio Indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF65FFA7)
                          : const Color(0xFF235565),
                      width: isSelected ? 2.0 : 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF65FFA7),
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
