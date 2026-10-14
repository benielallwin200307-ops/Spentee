import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import 'notifications_screen.dart';

class _LanguageOption {
  final String name;
  final String nativeScript;
  final String flag;

  const _LanguageOption({
    required this.name,
    required this.nativeScript,
    required this.flag,
  });
}

/// Screen 5 — Language Selection Screen
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final List<_LanguageOption> _languages = const [
    _LanguageOption(name: 'English', nativeScript: 'English', flag: '🇬🇧'),
    _LanguageOption(name: 'Hindi', nativeScript: 'हिन्दी', flag: '🇮🇳'),
    _LanguageOption(name: 'Telugu', nativeScript: 'తెలుగు', flag: '🇮🇳'),
    _LanguageOption(name: 'Tamil', nativeScript: 'தமிழ்', flag: '🇮🇳'),
    _LanguageOption(name: 'Kannada', nativeScript: 'ಕನ್ನಡ', flag: '🇮🇳'),
  ];

  void _onContinue() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final selectedLanguage = appState.selectedLanguage;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Choose your\nlanguage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Get roasts, insights and the app\nin your preferred language.',
                style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Language options list
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _languages.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _languages[index];
                    final isSelected = item.name == selectedLanguage;

                    return GestureDetector(
                      onTap: () {
                        appState.setLanguage(item.name);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryMint.withValues(alpha: 0.12)
                              : AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryMint
                                : AppTheme.borderSubtle,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryMint.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              item.flag,
                              style: const TextStyle(fontSize: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    item.nativeScript,
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.primaryMint : AppTheme.textDim,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryMint,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppTheme.bgDark,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: NeonButton(
                  text: 'Continue',
                  onPressed: _onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
