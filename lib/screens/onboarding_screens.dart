import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'language_screen.dart';

/// Full 4-step Onboarding flow (Screens 2–4 + Language entry)
/// Matching the Spentee storyboard reference exactly.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late final PageController _pageController;
  late final AnimationController _fadeCtrl;

  static const Color bgNavy = Color(0xFF00111A);
  static const Color mintGreen = Color(0xFF9EFAAB);
  static const Color darkText = Color(0xFF082618);

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      heading: 'Welcome to',
      highlight: 'Spentee',
      subtitle: 'Track every rupee,\nwithout the stress.',
      mascotAsset: 'Assets/onboarding_welcome_mascot.png',
      fallbackEmoji: '💰',
    ),
    _OnboardingStep(
      heading: 'Get roasted',
      highlight: '(with love)',
      subtitle: 'Fun insights and meme-style\nroasts to keep you on track.',
      mascotAsset: 'Assets/extracted/avatar_roast.png',
      fallbackEmoji: '🔥',
    ),
    _OnboardingStep(
      heading: 'Play, compete',
      highlight: 'and grow',
      subtitle: 'Solve puzzles, challenge others\nand climb the global leaderboard.',
      mascotAsset: 'Assets/extracted/avatar_win.png',
      fallbackEmoji: '🏆',
    ),
    _OnboardingStep(
      heading: 'Choose your',
      highlight: 'language',
      subtitle: 'Get roasts, insights and the app\nin your preferred language.',
      mascotAsset: 'Assets/extracted/avatar_ai.png',
      fallbackEmoji: '🌐',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < _steps.length - 1) {
      _fadeCtrl.reverse().then((_) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        _fadeCtrl.forward();
      });
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
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgNavy,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            return Stack(
              children: [
                // Atmospheric background
                Positioned.fill(
                  child: Image.asset(
                    'Assets/onboarding_bg_art.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: bgNavy),
                  ),
                ),

                // Dark overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          bgNavy.withValues(alpha: 0.3),
                          bgNavy.withValues(alpha: 0.6),
                          bgNavy.withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Top: Heading & mascot
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _steps.length,
                          itemBuilder: (context, index) {
                            return _OnboardingPageView(
                              step: _steps[index],
                              screenHeight: screenHeight,
                              screenWidth: screenWidth,
                              isFirst: index == 0,
                            );
                          },
                        ),
                      ),

                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_steps.length, (index) {
                          final isActive = index == _currentStep;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? mintGreen
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 28),

                      // Next / Continue Button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 0),
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
                                    right: 22,
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
                      const SizedBox(height: 24),
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

class _OnboardingStep {
  final String heading;
  final String highlight;
  final String subtitle;
  final String mascotAsset;
  final String fallbackEmoji;

  const _OnboardingStep({
    required this.heading,
    required this.highlight,
    required this.subtitle,
    required this.mascotAsset,
    required this.fallbackEmoji,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingStep step;
  final double screenHeight;
  final double screenWidth;
  final bool isFirst;

  const _OnboardingPageView({
    required this.step,
    required this.screenHeight,
    required this.screenWidth,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final mascotSize = math.min(screenWidth * 0.68, 280.0);

    return Column(
      children: [
        SizedBox(height: screenHeight * 0.04),

        // Heading
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                step.heading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              // Highlight text (Spentee wordmark or highlight phrase)
              isFirst
                  ? Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'Assets/spentee_splash_wordmark.png',
                        width: math.min(screenWidth * 0.64, 270.0),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          step.highlight,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      step.highlight,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.primaryMint,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
              const SizedBox(height: 12),
              Text(
                step.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),

        // Mascot illustration
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Image.asset(
                isFirst
                    ? 'Assets/onboarding_welcome_mascot.png'
                    : step.mascotAsset,
                width: mascotSize,
                height: mascotSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: mascotSize * 0.7,
                  height: mascotSize * 0.7,
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
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
