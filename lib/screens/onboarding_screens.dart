import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'language_screen.dart';

/// Full 4-step Onboarding flow (Screens 2–4 + Language entry)
/// Pixel-perfect recreation of Image 1 using Image 2 (onboarding_welcome_art.png) as background.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  late final PageController _pageController;

  static const Color bgNavy = Color(0xFF00111A);
  static const Color mintGreen = Color(0xFF65FFA7);
  static const Color subtitleMint = Color(0xFF5CFFA9);
  static const Color darkText = Color(0xFF00241D);

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      heading: 'Welcome to',
      highlight: 'Spentee',
      subtitleLine1: 'Track your money,',
      subtitleLine2: 'without the stress.',
      mascotAsset: 'Assets/onboarding_welcome_art.png',
      fallbackEmoji: '💰',
    ),
    _OnboardingStep(
      heading: 'Get roasted',
      highlight: '(with love)',
      subtitleLine1: 'Fun insights and meme-style',
      subtitleLine2: 'roasts to keep you on track.',
      mascotAsset: 'Assets/extracted/avatar_roast.png',
      fallbackEmoji: '🔥',
    ),
    _OnboardingStep(
      heading: 'Play, compete',
      highlight: 'and grow',
      subtitleLine1: 'Solve puzzles, challenge others',
      subtitleLine2: 'and climb the global leaderboard.',
      mascotAsset: 'Assets/extracted/avatar_win.png',
      fallbackEmoji: '🏆',
    ),
    _OnboardingStep(
      heading: 'Choose your',
      highlight: 'language',
      subtitleLine1: 'Get roasts, insights and the app',
      subtitleLine2: 'in your preferred language.',
      mascotAsset: 'Assets/extracted/avatar_ai.png',
      fallbackEmoji: '🌐',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LanguageScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: bgNavy,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: _currentStep == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentStep > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Scaffold(
          backgroundColor: bgNavy,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              final screenWidth = constraints.maxWidth;

              // Calculate aspect ratio geometry for background artwork alignment
              const imageAspect = 502.0 / 1024.0;
              final screenAspect = screenWidth / screenHeight;
              final double renderedW;
              final double renderedH;
              final double offsetX;
              final double offsetY;

              if (screenAspect < imageAspect) {
                // Taller screen: fit height, center horizontally
                renderedH = screenHeight;
                renderedW = screenHeight * imageAspect;
                offsetX = (screenWidth - renderedW) / 2.0;
                offsetY = 0.0;
              } else {
                // Wider screen: fit width, center vertically
                renderedW = screenWidth;
                renderedH = screenWidth / imageAspect;
                offsetX = 0.0;
                offsetY = (screenHeight - renderedH) / 2.0;
              }

              // Main speech bubble mathematically mapped to Image 1 / Image 2
              final bubbleLeft = offsetX + (189.0 / 502.0) * renderedW;
              final bubbleTop = offsetY + (332.0 / 1024.0) * renderedH;
              final bubbleWidth = (281.0 / 502.0) * renderedW;
              final bubbleHeight = (193.0 / 1024.0) * renderedH;

              return Stack(
                children: [
                  // 1. Dark solid background layer
                  Positioned.fill(
                    child: Container(
                      color: bgNavy,
                    ),
                  ),

                  // 2. Background artwork for Step 0 (Welcome)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: _currentStep == 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(
                        'Assets/onboarding_welcome_art.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: bgNavy),
                      ),
                    ),
                  ),

                  // 3. Image 1 as background artwork for Step 1 (Roast)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: _currentStep == 1 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(
                        'Assets/onboarding_roast_art.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: bgNavy),
                      ),
                    ),
                  ),

                  // 4. Roast speech bubble overlay for Step 1
                  if (_currentStep == 1)
                    Positioned(
                      left: bubbleLeft,
                      top: bubbleTop,
                      width: bubbleWidth,
                      height: bubbleHeight,
                      child: AnimatedOpacity(
                        opacity: _currentStep == 1 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: _RoastSpeechBubble(
                          width: bubbleWidth,
                          height: bubbleHeight,
                        ),
                      ),
                    ),

                  // 5. Subtle radial glow for steps > 1
                  if (_currentStep > 1)
                    Positioned(
                      top: screenHeight * 0.32,
                      left: -screenWidth * 0.20,
                      right: -screenWidth * 0.20,
                      child: Center(
                        child: Container(
                          width: screenWidth * 1.35,
                          height: screenHeight * 0.46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF00B87A).withValues(alpha: 0.18),
                                const Color(0xFF004D36).withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                              radius: 0.65,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 6. Subtle ambient sparkles for Step 0 only
                  if (_currentStep == 0) ...[
                    Positioned(
                      left: screenWidth * 0.11,
                      top: screenHeight * 0.155,
                      child: const SparkleStar(
                        size: 15,
                        color: Color(0xFF00E676),
                        opacity: 0.85,
                      ),
                    ),
                    Positioned(
                      right: screenWidth * 0.11,
                      top: screenHeight * 0.165,
                      child: const SparkleStar(
                        size: 13,
                        color: Color(0xFF00E676),
                        opacity: 0.85,
                      ),
                    ),
                  ],

                  // 7. Main content overlaid on the background
                  SafeArea(
                    child: Column(
                      children: [
                        // Header & central content in PageView
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _steps.length,
                            onPageChanged: (index) {
                              setState(() => _currentStep = index);
                            },
                            itemBuilder: (context, index) {
                              return _OnboardingPageView(
                                step: _steps[index],
                                screenHeight: screenHeight,
                                screenWidth: screenWidth,
                                stepIndex: index,
                              );
                            },
                          ),
                        ),

                        // Four progress indicators with first one highlighted mint green
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_steps.length, (index) {
                            // In Image 2 and Section 6: First indicator is an elongated mint-green pill,
                            // remaining three are small dark-grey circles.
                            final isActive = (_currentStep == 1)
                                ? (index == 0)
                                : (index == _currentStep);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              width: isActive ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? mintGreen
                                    : const Color(0xFF425154),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        // Next / Continue button with subtle green glow
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            width: double.infinity,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: mintGreen.withValues(alpha: 0.38),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: mintGreen,
                              borderRadius: BorderRadius.circular(36),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(36),
                                onTap: _onNext,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      _currentStep < _steps.length - 1
                                          ? 'Next'
                                          : 'Continue',
                                      style: const TextStyle(
                                        color: darkText,
                                        fontSize: 18.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const Positioned(
                                      right: 24,
                                      child: Icon(
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String heading;
  final String highlight;
  final String subtitleLine1;
  final String subtitleLine2;
  final String mascotAsset;
  final String fallbackEmoji;

  const _OnboardingStep({
    required this.heading,
    required this.highlight,
    required this.subtitleLine1,
    required this.subtitleLine2,
    required this.mascotAsset,
    required this.fallbackEmoji,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingStep step;
  final double screenHeight;
  final double screenWidth;
  final int stepIndex;

  const _OnboardingPageView({
    required this.step,
    required this.screenHeight,
    required this.screenWidth,
    required this.stepIndex,
  });

  Widget _buildFallbackEmoji(double size) {
    return Container(
      width: size * 0.7,
      height: size * 0.7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryMint.withValues(alpha: 0.12),
        border: Border.all(
          color: AppTheme.primaryMint.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          step.fallbackEmoji,
          style: const TextStyle(fontSize: 64),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (stepIndex == 1) {
      // Step 1: "Get roasted (with love)" recreation matching Image 2
      return Column(
        children: [
          SizedBox(height: screenHeight * 0.034),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Get roasted\n(with love)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: math.min(screenWidth * 0.092, 38.0),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Fun insights and meme-style\nroasts to ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: math.min(screenWidth * 0.043, 17.5),
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                          letterSpacing: -0.1,
                        ),
                      ),
                      TextSpan(
                        text: 'keep you on track.',
                        style: TextStyle(
                          color: _OnboardingScreenState.mintGreen,
                          fontSize: math.min(screenWidth * 0.043, 17.5),
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Centre Area is transparent because Image 1 background artwork
          // contains the mascot, smiling house bubble, and rising analytics chart.
          const Expanded(child: SizedBox.expand()),
        ],
      );
    }

    final isFirst = stepIndex == 0;
    return Column(
      children: [
        SizedBox(height: screenHeight * 0.016),

        // Header section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                step.heading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              // Spentee wordmark logo with star
              isFirst
                  ? Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        const Positioned(
                          left: -14,
                          top: -2,
                          child: SparkleStar(
                            size: 16,
                            color: Color(0xFF00E676),
                            opacity: 0.95,
                          ),
                        ),
                        const Positioned(
                          left: 10,
                          bottom: -6,
                          child: SparkleStar(
                            size: 11,
                            color: Color(0xFF00E676),
                            opacity: 0.85,
                          ),
                        ),
                        const Positioned(
                          right: -14,
                          top: 6,
                          child: SparkleStar(
                            size: 13,
                            color: Color(0xFF00E676),
                            opacity: 0.90,
                          ),
                        ),
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'Assets/spentee_splash_wordmark.png',
                            width: math.min(screenWidth * 0.64, 260.0),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Text(
                              step.highlight,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      step.highlight,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.primaryMint,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
              const SizedBox(height: 10),
              // Subtitle with 2 lines matching Image 1: white line 1, mint green line 2
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${step.subtitleLine1}\n',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.1,
                      ),
                    ),
                    TextSpan(
                      text: step.subtitleLine2,
                      style: TextStyle(
                        color: isFirst
                            ? _OnboardingScreenState.subtitleMint
                            : AppTheme.primaryMint,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Centre Area
        Expanded(
          child: isFirst
              ? const SizedBox.expand()
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Image.asset(
                      step.mascotAsset,
                      width: math.min(screenWidth * 0.68, 280.0),
                      height: math.min(screenWidth * 0.68, 280.0),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackEmoji(
                              math.min(screenWidth * 0.68, 280.0)),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Custom-painted Roast Speech Bubble exactly reproducing Image 2
class _RoastSpeechBubble extends StatelessWidget {
  final double width;
  final double height;

  const _RoastSpeechBubble({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: const _RoastBubblePainter(),
        child: Padding(
          padding: EdgeInsets.only(
            left: width * (32.0 / 281.0),
            top: height * (23.0 / 193.0),
            right: width * (22.0 / 281.0),
            bottom: height * ((193.0 - 153.0 + 8.0) / 193.0),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Your wallet\nneeds emotional\nsupport. ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Text(
                        '😂',
                        style: TextStyle(
                          fontSize: width * (24.0 / 281.0),
                        ),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: const Color(0xFF00241D),
                  fontSize: width * (23.5 / 281.0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Precise bezier painter for the speech bubble and downward tail
class _RoastBubblePainter extends CustomPainter {
  const _RoastBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Based on reference metrics: width=281, height=193, main rect height=153, r=32
    final rectH = h * (153.0 / 193.0);
    final r = 32.0 * (w / 281.0);

    // Anchor points on bottom edge: x1 = 92, x2 = 170. Tip = (107, 193)
    final x1 = w * (92.0 / 281.0);
    final x2 = w * (170.0 / 281.0);
    final xtip = w * (107.0 / 281.0);
    final ytip = h;

    final path = Path();
    // Top-left to top-right
    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));

    // Right edge
    path.lineTo(w, rectH - r);
    path.arcToPoint(Offset(w - r, rectH), radius: Radius.circular(r));

    // Bottom edge to right side of tail
    path.lineTo(x2, rectH);

    // Curve down-left to tail tip (concave swoop)
    path.cubicTo(
      x2 - 14.0 * (w / 281.0),
      rectH + 15.0 * (h / 193.0),
      xtip + 24.0 * (w / 281.0),
      h - 12.0 * (h / 193.0),
      xtip,
      ytip,
    );

    // Curve up-left to left side of tail
    path.cubicTo(
      xtip + 6.0 * (w / 281.0),
      h - 15.0 * (h / 193.0),
      x1 + 18.0 * (w / 281.0),
      rectH + 12.0 * (h / 193.0),
      x1,
      rectH,
    );

    // Bottom edge to bottom-left corner
    path.lineTo(r, rectH);
    path.arcToPoint(Offset(0, rectH - r), radius: Radius.circular(r));

    // Left edge
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    path.close();

    // Soft drop shadow
    canvas.drawShadow(path, const Color(0x35000000), 14.0, true);

    // Solid white fill
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

