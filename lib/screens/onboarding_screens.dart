import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Screen 2 — Spentee Welcome & Onboarding Screen
/// Pixel-perfect implementation based on the Pixel 10 Pro design reference.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  /// Deep navy and teal background palette matching reference design
  static const Color bgDarkNavy = Color(0xFF00111A);
  static const Color bgDarkTeal = Color(0xFF011A20);
  static const Color bgMidTeal = Color(0xFF012420);
  static const Color bgBottomNavy = Color(0xFF00141B);
  static const Color mintGreen = Color(0xFF9EFAAB);
  static const Color darkText = Color(0xFF082618);

  void _onNext(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OnboardingStep2PlaceholderScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: bgBottomNavy,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgDarkNavy,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final logoWidth = math.min(screenWidth * 0.64, 270.0);

            return Stack(
              children: [
                // 1. Full-bleed atmospheric background artwork
                Positioned.fill(
                  child: Image.asset(
                    'Assets/onboarding_bg_art.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: bgDarkNavy,
                    ),
                  ),
                ),

                // 2. Real native Flutter UI inside SafeArea
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Section: Heading and Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SizedBox(height: math.max(16.0, screenHeight * 0.024)),
                            // "Welcome to" heading
                            const Text(
                              'Welcome to',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // "Spentee" wordmark with neon-green sparkle accent
                            Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                'Assets/spentee_splash_wordmark.png',
                                width: logoWidth,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'Spentee',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 44,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    SparkleStar(
                                      size: 18,
                                      color: Color(0xFF00E676),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Subtitle: "Track every rupee, without the stress."
                            const Text(
                              'Track every rupee,\nwithout the stress.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w500,
                                height: 1.32,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Flexible breathing room for illustration
                      const Spacer(),

                      // Bottom Section: Wide rounded mint-green Next button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: mintGreen.withValues(alpha: 0.35),
                                blurRadius: 24,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: mintGreen,
                            borderRadius: BorderRadius.circular(36),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(36),
                              onTap: () => _onNext(context),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Text(
                                    'Next',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Positioned(
                                    right: 22,
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: darkText,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

  }
}

/// Placeholder screen for Onboarding Step 2 ("Get roasted (with love)")
/// Kept clean and functional with back navigation for Task 2.
class OnboardingStep2PlaceholderScreen extends StatelessWidget {
  const OnboardingStep2PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Onboarding Step 2',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF012420),
                    border: Border.all(
                      color: const Color(0xFF9EFAAB).withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9EFAAB).withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'Assets/extracted/avatar_roast.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF9EFAAB),
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Get roasted\n(with love)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fun insights and meme-style roasts to keep you on track.\n\nStep 2 will be designed in the next task.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9EFAAB),
                    side: const BorderSide(color: Color(0xFF9EFAAB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text(
                    'Back to Welcome',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
