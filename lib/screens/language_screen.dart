import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import 'notifications_screen.dart';

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
      name: 'Hindi',
      nativeScript: 'हिन्दी',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Telugu',
      nativeScript: 'తెలుగు',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Tamil',
      nativeScript: 'தமிழ்',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Malayalam',
      nativeScript: 'മലയാളം',
      flagAsset: 'Assets/extracted/flag_india.png',
    ),
    _LanguageOption(
      name: 'Kannada',
      nativeScript: 'ಕನ್ನಡ',
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
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final topPadding = mediaQuery.padding.top;

    // Aspect ratio scaled to give comfortable breathing room above the mascot
    final topArtHeight = screenWidth * (485.0 / 504.0);
    final textTopOffset = math.max(topPadding * 0.72, 26.0);

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
            // Dark teal gradient background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF00151C),
                      Color(0xFF00191B),
                      Color(0xFF000F14),
                    ],
                  ),
                ),
              ),
            ),

            // Foreground content with scroll support
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Top Section: Artwork with Heading and Subtitle overlaid
                    SizedBox(
                      width: double.infinity,
                      height: topArtHeight,
                      child: Stack(
                        children: [
                          // Background illustration (window frame, leaves, mascot, speech bubbles, sparkles)
                          Positioned.fill(
                            child: Image.asset(
                              'Assets/extracted/lang_top_bg_clean.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.bottomCenter,
                            ),
                          ),

                          // Heading, curved underline, and subtitle widgets
                          Positioned(
                            top: textTopOffset,
                            left: 16,
                            right: 16,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Top Heading: 3 lines
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Pick your\n',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.8,
                                          height: 1.08,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: 'language,\n',
                                        style: TextStyle(
                                          color: mintGreen,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.8,
                                          height: 1.08,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: 'let’s begin!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.8,
                                          height: 1.08,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 3),

                                // Thin curved mint-green underline beneath 'let’s begin!'
                                const CustomPaint(
                                  size: Size(160, 7.5),
                                  painter: _CurvedUnderlinePainter(color: mintGreen),
                                ),

                                const SizedBox(height: 10),

                                // Subtitle: 3 lines
                                Text.rich(
                                  const TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            'Get personalized roasts, smart insights\nand the full Spentee experience in\n',
                                        style: TextStyle(
                                          color: Color(0xFFC7DBD7),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          height: 1.32,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'your preferred language.',
                                        style: TextStyle(
                                          color: mintGreen,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          height: 1.32,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 2),

                    // 6 Language Selection Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: List.generate(_languages.length, (index) {
                          final item = _languages[index];
                          final isSelected = item.name == _selectedLanguage;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 7.5),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectLanguage(item.name),
                                borderRadius: BorderRadius.circular(26),
                                splashColor: mintGreen.withValues(alpha: 0.1),
                                highlightColor: Colors.transparent,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF012421)
                                        : const Color(0xFF021B1E),
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: isSelected
                                          ? mintGreen
                                          : const Color(0xFF144144),
                                      width: isSelected ? 1.8 : 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: mintGreen.withValues(alpha: 0.35),
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
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 14),

                                      // Language name & native script
                                      Expanded(
                                        child: item.nativeScript.isEmpty
                                            ? Text(
                                                item.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.2,
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: -0.2,
                                                      height: 1.15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    item.nativeScript,
                                                    style: const TextStyle(
                                                      color: Color(0xFF7FA7A2),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      height: 1.15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),

                                      // Radio selection indicator
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? mintGreen : Colors.transparent,
                                          border: isSelected
                                              ? null
                                              : Border.all(
                                                  color: const Color(0xFF1B4E4F),
                                                  width: 1.8,
                                                ),
                                        ),
                                        child: isSelected
                                            ? const Center(
                                                child: Icon(
                                                  Icons.check,
                                                  size: 16,
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

                    const SizedBox(height: 22),

                    // Continue button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _onContinue,
                        child: Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6DFDB5),
                                Color(0xFF38EE91),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38EE91).withValues(alpha: 0.45),
                                blurRadius: 24,
                                spreadRadius: 3,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  color: Color(0xFF002B21),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Positioned(
                                right: 24,
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF002B21),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: math.max(mediaQuery.padding.bottom + 16, 28)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the thin, curved mint-green underline beneath "let’s begin!"
class _CurvedUnderlinePainter extends CustomPainter {
  final Color color;

  const _CurvedUnderlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // Arched brush shape tapering at ends and thicker in center
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
