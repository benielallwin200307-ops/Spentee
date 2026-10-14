import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding_screens.dart';
import 'auth_screens.dart';

/// Screen 1 — Splash / Welcome Screen
/// Pixel-perfect implementation based on the Pixel 10 Pro design reference.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Uniform brand background color matching the design reference (#001422)
  static const Color splashBgColor = Color(0xFF001422);

  void _onGetStarted(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }


  void _onExistingUser(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: splashBgColor,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: splashBgColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: splashBgColor,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;

              // Proportional responsive sizes
              final logoWidth = math.min(screenWidth * 0.78, 330.0);
              // Further zoomed-in illustration dimensions
              final illustrationHeight = (screenHeight * 0.57).clamp(380.0, 580.0);
              final illustrationWidth = screenWidth * 1.42;

              return Stack(
                children: [
                  // Atmospheric dark teal radial glow behind the illustration
                  Positioned(
                    top: screenHeight * 0.40,
                    left: -screenWidth * 0.20,
                    right: -screenWidth * 0.20,
                    child: Center(
                      child: Container(
                        width: screenWidth * 1.35,
                        height: screenHeight * 0.52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00B87A).withValues(alpha: 0.26),
                              const Color(0xFF004D36).withValues(alpha: 0.13),
                              Colors.transparent,
                            ],
                            radius: 0.65,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating ambient sparkles matching the design aesthetic
                  // Upper-left sparkle
                  Positioned(
                    left: screenWidth * 0.08,
                    top: screenHeight * 0.26,
                    child: const SparkleStar(
                      size: 20,
                      color: Color(0xFF00E676),
                      opacity: 0.9,
                    ),
                  ),
                  // Lower-left tiny sparkle
                  Positioned(
                    left: screenWidth * 0.045,
                    top: screenHeight * 0.42,
                    child: const SparkleStar(
                      size: 14,
                      color: Color(0xFF00E676),
                      opacity: 0.75,
                    ),
                  ),
                  // Right sparkle
                  Positioned(
                    right: screenWidth * 0.08,
                    top: screenHeight * 0.29,
                    child: const SparkleStar(
                      size: 18,
                      color: Color(0xFF00E676),
                      opacity: 0.85,
                    ),
                  ),

                  // Main UI Content
                  SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. Top Section: Logo & Tagline moved lower
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                SizedBox(height: math.max(36.0, screenHeight * 0.078)),
                                // Spentee Wordmark Logo with green sparkle
                                Hero(
                                  tag: 'app_logo',
                                  child: Image.asset(
                                    'Assets/spentee_splash_wordmark.png',
                                    width: logoWidth,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Text(
                                      'Spentee',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Subtitle: Lime green
                                const Text(
                                  'Your AI Money Companion',
                                  style: TextStyle(
                                    color: Color(0xFFD4F660),
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.15,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. Middle Section: Extra Zoomed-in Character Illustration
                          SizedBox(
                            height: illustrationHeight,
                            width: screenWidth,
                            child: OverflowBox(
                              maxWidth: illustrationWidth,
                              maxHeight: illustrationHeight,
                              child: Image.asset(
                                'Assets/splash_character.png',
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(
                                  'Assets/extracted/splash_hero.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          // 3. Bottom Section: Pill Button & Secondary Action
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                // Primary Pill Button with Arrow and Glow
                                Container(
                                  width: double.infinity,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF94FBA3)
                                            .withValues(alpha: 0.40),
                                        blurRadius: 26,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: const Color(0xFF94FBA3),
                                    borderRadius: BorderRadius.circular(36),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(36),
                                      onTap: () => _onGetStarted(context),
                                      splashColor: Colors.white.withValues(alpha: 0.3),
                                      child: const Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            'Get Started',
                                            style: TextStyle(
                                              color: Color(0xFF071B12),
                                              fontSize: 18.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          Positioned(
                                            right: 24,
                                            child: Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Color(0xFF071B12),
                                              size: 26,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // Secondary Action Text
                                GestureDetector(
                                  onTap: () => _onExistingUser(context),
                                  behavior: HitTestBehavior.opaque,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'I already have an account',
                                      style: TextStyle(
                                        color: Color(0xFFD3DFE8),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: math.max(16.0, screenHeight * 0.024)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
    );
  }
}

/// A 4-pointed sparkle star widget matching the Spentee design aesthetic.
class SparkleStar extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const SparkleStar({
    super.key,
    required this.size,
    this.color = const Color(0xFF00E676),
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(size, size),
        painter: _SparklePainter(color: color),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;

  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy, w, cy);
    path.quadraticBezierTo(cx, cy, cx, h);
    path.quadraticBezierTo(cx, cy, 0, cy);
    path.quadraticBezierTo(cx, cy, cx, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

