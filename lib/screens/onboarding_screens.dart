import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'auth_screens.dart';

/// Full 3-step Onboarding flow (Welcome, Roast, and Language selection)
/// Pixel-perfect recreation of Image 1 using Image 2 (onboarding_welcome_art.png) as background.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  late final PageController _pageController;
  String _selectedLanguage = 'English';
  bool _initializedLanguage = false;

  static const Color bgNavy = Color(0xFF00111A);
  static const Color mintGreen = Color(0xFF65FFA7);
  static const Color subtitleMint = Color(0xFF5CFFA9);
  static const Color darkText = Color(0xFF00241D);

  static const List<_LanguageOption> _languages = [
    _LanguageOption(
      name: 'English',
      flagAsset: 'Assets/extracted/flag_uk.png',
    ),
    _LanguageOption(
      name: 'Tamil',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Telugu',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Hindi',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Malayalam',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Kannada',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
  ];

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
      heading: 'Pick your',
      highlight: 'language',
      subtitleLine1: '',
      subtitleLine2: '',
      mascotAsset: 'Assets/extracted/lang_top_bg_clean.png',
      fallbackEmoji: '🌐',
    ),
    _OnboardingStep(
      heading: 'Choose your',
      highlight: 'mascot',
      subtitleLine1: 'Select your companion',
      subtitleLine2: '& personalized theme.',
      mascotAsset: 'Assets/extracted/mascot_main.png',
      fallbackEmoji: '⚡',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedLanguage) {
      final appState = AppStateScope.of(context);
      if (appState.selectedLanguage.isNotEmpty) {
        _selectedLanguage = appState.selectedLanguage;
      }
      _initializedLanguage = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSelectLanguage(String name) {
    setState(() => _selectedLanguage = name);
    final appState = AppStateScope.of(context);
    appState.setLanguage(name);
  }

  void _onNext() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      final appState = AppStateScope.of(context);
      appState.setLanguage(_selectedLanguage);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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

              // Main speech bubble fitted snugly to the text
              final bubbleLeft = offsetX + (205.0 / 502.0) * renderedW;
              final bubbleTop = offsetY + (348.0 / 1024.0) * renderedH;
              final bubbleWidth = (212.0 / 502.0) * renderedW;
              final bubbleHeight = (138.0 / 1024.0) * renderedH;

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

                  // 4. Background artwork for Step 2 (Language Selection) matching user mockup
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: _currentStep == 2 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(
                        'Assets/onboarding_language_art.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: bgNavy),
                      ),
                    ),
                  ),

                  // 5. Roast speech bubble overlay for Step 1
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

                  // 6. Subtle ambient sparkles for Step 0 only
                  if (_currentStep == 0) ...[
                    Positioned(
                      left: screenWidth * 0.11,
                      top: screenHeight * 0.188,
                      child: const SparkleStar(
                        size: 15,
                        color: Color(0xFF00E676),
                        opacity: 0.85,
                      ),
                    ),
                    Positioned(
                      right: screenWidth * 0.11,
                      top: screenHeight * 0.198,
                      child: const SparkleStar(
                        size: 13,
                        color: Color(0xFF00E676),
                        opacity: 0.85,
                      ),
                    ),
                  ],

                  // 7. Main content overlaid on the background
                  SafeArea(
                    top: false,
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
                              if (index == 2) {
                                return _LanguageStepView(
                                  screenHeight: screenHeight,
                                  screenWidth: screenWidth,
                                  languages: _languages,
                                  selectedLanguage: _selectedLanguage,
                                  onSelectLanguage: _onSelectLanguage,
                                );
                              }
                              if (index == 3) {
                                return _MascotStepView(
                                  screenHeight: screenHeight,
                                  screenWidth: screenWidth,
                                );
                              }
                              return _OnboardingPageView(
                                step: _steps[index],
                                screenHeight: screenHeight,
                                screenWidth: screenWidth,
                                stepIndex: index,
                              );
                            },
                          ),
                        ),

                        // Progress indicators matching step count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_steps.length, (index) {
                            final isActive = index == _currentStep;
                            final activeColor = _currentStep == 3
                                ? AppStateScope.of(context).mascotTheme.primaryAccent
                                : mintGreen;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              width: isActive ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? activeColor
                                    : const Color(0xFF425154),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        // Next / Continue button with adaptive accent glow
                        Builder(
                          builder: (context) {
                            final activeThemeColor = _currentStep == 3
                                ? AppStateScope.of(context).mascotTheme.primaryAccent
                                : mintGreen;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Container(
                                width: double.infinity,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(36),
                                  boxShadow: [
                                    BoxShadow(
                                      color: activeThemeColor.withValues(alpha: 0.38),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: activeThemeColor,
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
                                              : 'Get Started',
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
                            );
                          },
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
      final topPadding = MediaQuery.paddingOf(context).top;
      // Step 1: "Get roasted (with love)" recreation matching Image 2
      return Column(
        children: [
          SizedBox(height: topPadding + math.max(52.0, screenHeight * 0.062)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Get roasted\n(with love)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: math.min(screenWidth * 0.087, 36.0),
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
                          fontSize: math.min(screenWidth * 0.038, 15.5),
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                          letterSpacing: -0.1,
                        ),
                      ),
                      TextSpan(
                        text: 'keep you on track.',
                        style: TextStyle(
                          color: _OnboardingScreenState.mintGreen,
                          fontSize: math.min(screenWidth * 0.038, 15.5),
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
    final topPadding = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        SizedBox(
          height: topPadding +
              (isFirst
                  ? math.max(26.0, screenHeight * 0.038)
                  : math.max(16.0, screenHeight * 0.024)),
        ),

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
                      (step.mascotAsset.contains('roast') &&
                              AppStateScope.of(context).selectedMascot == 'female')
                          ? 'Assets/extracted/female_roast.png'
                          : step.mascotAsset,
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

/// Custom-painted Roast Speech Bubble fitting text snugly
class _RoastSpeechBubble extends StatelessWidget {
  final double width;
  final double height;

  const _RoastSpeechBubble({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = (width * 0.092).clamp(17.5, 19.5);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: const _RoastBubblePainter(),
        child: Padding(
          padding: EdgeInsets.only(
            left: width * 0.075,
            top: height * 0.09,
            right: width * 0.075,
            bottom: height * 0.27,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
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
                          fontSize: fontSize * 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: const Color(0xFF00241D),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
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

    // Main rounded rectangle height (leaving room for tail at the bottom)
    final rectH = h * 0.78;
    final r = math.min(20.0, w * 0.11);

    // Tail anchor points on bottom edge pointing down towards mascot
    final xtip = w * 0.44;
    final ytip = h;
    final x1 = xtip - (w * 0.12);
    final x2 = xtip + (w * 0.28);

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
      x2 - (w * 0.08),
      rectH + (h * 0.08),
      xtip + (w * 0.10),
      h - (h * 0.06),
      xtip,
      ytip,
    );

    // Curve up-left to left side of tail
    path.cubicTo(
      xtip + (w * 0.03),
      h - (h * 0.08),
      x1 + (w * 0.08),
      rectH + (h * 0.06),
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
    canvas.drawShadow(path, const Color(0x35000000), 12.0, true);

    // Solid white fill
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CurvedUnderlinePainter extends CustomPainter {
  final Color color;

  const _CurvedUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.5,
      -size.height * 0.35,
      size.width,
      size.height * 0.55,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.15,
      0,
      size.height * 0.85,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedUnderlinePainter oldDelegate) =>
      color != oldDelegate.color;
}

class _LanguageOption {
  final String name;
  final String flagAsset;

  const _LanguageOption({
    required this.name,
    required this.flagAsset,
  });
}

class _LanguageStepView extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final List<_LanguageOption> languages;
  final String selectedLanguage;
  final ValueChanged<String> onSelectLanguage;

  const _LanguageStepView({
    required this.screenHeight,
    required this.screenWidth,
    required this.languages,
    required this.selectedLanguage,
    required this.onSelectLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    // Responsive card dimensions to fit 6 cards comfortably without overlap
    final cardHeight = (screenHeight * 0.048).clamp(40.0, 46.0);
    final cardSpacing = (screenHeight * 0.007).clamp(4.0, 7.0);

    return Stack(
      children: [
        // 1. Header: Heading + Underline only (subtext completely removed)
        Positioned(
          top: math.max(screenHeight * 0.052, topPadding + 8.0),
          left: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heading: 3 lines ("Pick your\nlanguage,\nlet's begin!")
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pick your\n',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: math.min(screenWidth * 0.092, 38.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.12,
                      ),
                    ),
                    TextSpan(
                      text: 'language,\n',
                      style: TextStyle(
                        color: _OnboardingScreenState.mintGreen,
                        fontSize: math.min(screenWidth * 0.092, 38.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.12,
                      ),
                    ),
                    TextSpan(
                      text: "let's begin!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: math.min(screenWidth * 0.092, 38.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              // Curved mint underline
              CustomPaint(
                size: const Size(116, 5),
                painter: _CurvedUnderlinePainter(
                  color: _OnboardingScreenState.mintGreen,
                ),
              ),
            ],
          ),
        ),

        // 2. 6 Language Selection Cards positioned directly under mascot hoodie and foliage
        Positioned(
          top: screenHeight * (515.0 / 1024.0),
          left: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(languages.length, (index) {
              final item = languages[index];
              final isSelected = item.name == selectedLanguage;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < languages.length - 1 ? cardSpacing : 0,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelectLanguage(item.name),
                    borderRadius: BorderRadius.circular(22),
                    splashColor:
                        _OnboardingScreenState.mintGreen.withValues(alpha: 0.1),
                    highlightColor: Colors.transparent,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: cardHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF012421)
                            : const Color(0xFF021B1E),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? _OnboardingScreenState.mintGreen
                              : const Color(0xFF144144),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _OnboardingScreenState.mintGreen
                                      .withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Circular flag icon
                          Image.asset(
                            item.flagAsset,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 14),

                          // Language name in English ONLY
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),

                          // Radio selection indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? _OnboardingScreenState.mintGreen
                                  : Colors.transparent,
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFF1B4E4F),
                                      width: 1.6,
                                    ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(
                                      Icons.check,
                                      size: 13,
                                      color: Color(0xFF012421),
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
            }),
          ),
        ),
      ],
    );
  }
}

/// Step 4 — Interactive Mascot & Theme Selection View
class _MascotStepView extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;

  const _MascotStepView({
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final selectedMascot = appState.selectedMascot;

    return Stack(
      children: [
        Positioned(
          top: math.max(screenHeight * 0.052, topPadding + 8.0),
          left: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Choose your\n',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: math.min(screenWidth * 0.092, 34.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                    TextSpan(
                      text: 'mascot,\n',
                      style: TextStyle(
                        color: _OnboardingScreenState.mintGreen,
                        fontSize: math.min(screenWidth * 0.092, 34.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                    TextSpan(
                      text: "your finance guide!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: math.min(screenWidth * 0.092, 34.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 3,
                decoration: BoxDecoration(
                  color: _OnboardingScreenState.mintGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Personalize your companion & visual theme.\nChange anytime in Profile Settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF90A4AE),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: screenHeight * 0.28,
          left: 18,
          right: 18,
          bottom: 16,
          child: Center(
            child: Row(
              children: [
                Expanded(
                  child: _buildMascotCard(
                    context: context,
                    id: 'male',
                    name: 'Male Mascot',
                    themeName: 'Neon Mint Theme',
                    avatarAsset: 'Assets/extracted/mascot_main.png',
                    accentColor: AppTheme.primaryMint,
                    isSelected: selectedMascot != 'female',
                    onTap: () => appState.setSelectedMascot('male'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMascotCard(
                    context: context,
                    id: 'female',
                    name: 'Female Mascot',
                    themeName: 'Rose Pink Theme',
                    avatarAsset: 'Assets/extracted/female_main.png',
                    accentColor: const Color(0xFFFF528E),
                    isSelected: selectedMascot == 'female',
                    onTap: () => appState.setSelectedMascot('female'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMascotCard({
    required BuildContext context,
    required String id,
    required String name,
    required String themeName,
    required String avatarAsset,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : const Color(0xFF071922),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? accentColor
                : const Color(0xFF133543),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.28),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? accentColor.withValues(alpha: 0.18)
                    : const Color(0xFF0F2633),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.6)
                      : const Color(0xFF1E4255),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  avatarAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.face_rounded,
                    color: accentColor,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              themeName,
              style: TextStyle(
                color: isSelected ? accentColor : const Color(0xFF7E97A0),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFF2E5365),
                        width: 1.8,
                      ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF012421),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

