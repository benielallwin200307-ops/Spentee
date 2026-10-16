import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import 'auth_screens.dart';

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
  final String nativeScript;
  final String flagAsset;

  const _LanguageOption({
    required this.name,
    required this.nativeScript,
    required this.flagAsset,
  });
}

/// Screen 5 — Language Selection Screen
/// Exact UI recreation matching the Spentee design specification.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const Color bgNavy = Color(0xFF00111A);
  static const Color mintGreen = Color(0xFF45F59A);

  final List<_LanguageOption> _languages = const [
    _LanguageOption(
      name: 'English',
      nativeScript: '',
      flagAsset: 'Assets/extracted/flag_uk.png',
    ),
    _LanguageOption(
      name: 'Tamil',
      nativeScript: '',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Telugu',
      nativeScript: '',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Hindi',
      nativeScript: '',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Malayalam',
      nativeScript: '',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Kannada',
      nativeScript: '',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
  ];

  late String _selectedLanguage;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = 'English';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final appState = AppStateScope.of(context);
      if (appState.selectedLanguage.isNotEmpty) {
        _selectedLanguage = appState.selectedLanguage;
      }
      _initialized = true;
    }
  }

  void _selectLanguage(String name) {
    setState(() => _selectedLanguage = name);
    final appState = AppStateScope.of(context);
    appState.setLanguage(name);
  }

  void _onContinue() {
    final appState = AppStateScope.of(context);
    appState.setLanguage(_selectedLanguage);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: bgNavy,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgNavy,
        body: Stack(
          children: [
            // 1. Full-screen background artwork matching user mockup
            Positioned.fill(
              child: Image.asset(
                'Assets/onboarding_language_art.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: bgNavy),
              ),
            ),

            // 2. Foreground content layout
            SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // Header section: Heading + Underline only (subtext removed)
                        Positioned(
                          top: math.max(
                            screenHeight * 0.052,
                            mediaQuery.padding.top + 8.0,
                          ),
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
                                        fontSize:
                                            math.min(screenWidth * 0.092, 38.0),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                        height: 1.12,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'language,\n',
                                      style: TextStyle(
                                        color: mintGreen,
                                        fontSize:
                                            math.min(screenWidth * 0.092, 38.0),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                        height: 1.12,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "let's begin!",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            math.min(screenWidth * 0.092, 38.0),
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
                              const CustomPaint(
                                size: Size(116, 5),
                                painter: _CurvedUnderlinePainter(
                                  color: mintGreen,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 6 Language Selection Cards positioned directly under mascot hoodie and foliage
                        Positioned(
                          top: screenHeight * (515.0 / 1024.0),
                          left: 24,
                          right: 24,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_languages.length, (index) {
                              final item = _languages[index];
                              final isSelected = item.name == _selectedLanguage;
                              final cardHeight =
                                  (screenHeight * 0.048).clamp(40.0, 46.0);
                              final cardSpacing =
                                  (screenHeight * 0.007).clamp(4.0, 7.0);

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < _languages.length - 1
                                      ? cardSpacing
                                      : 0,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _selectLanguage(item.name),
                                    borderRadius: BorderRadius.circular(22),
                                    splashColor:
                                        mintGreen.withValues(alpha: 0.1),
                                    highlightColor: Colors.transparent,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      height: cardHeight,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF012421)
                                            : const Color(0xFF021B1E),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: isSelected
                                              ? mintGreen
                                              : const Color(0xFF144144),
                                          width: isSelected ? 1.8 : 1.0,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: mintGreen
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
                                            duration: const Duration(
                                                milliseconds: 180),
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? mintGreen
                                                  : Colors.transparent,
                                              border: isSelected
                                                  ? null
                                                  : Border.all(
                                                      color: const Color(
                                                          0xFF1B4E4F),
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
                    ),
                  ),

                  // Progress indicators with 3rd dot active
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == 2;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: isActive ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              isActive ? mintGreen : const Color(0xFF425154),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Continue button matching previous screen size and position
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
                          onTap: _onContinue,
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  color: Color(0xFF00241D),
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Positioned(
                                right: 24,
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF00241D),
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
        ),
      ),
    );
  }
}
