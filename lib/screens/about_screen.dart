import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Screen displaying Spentee version, creators, mission, privacy architecture, and open source licenses.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = '1.0.0+1';
  static const String appName = 'Spentee';

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF091C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Terms of Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Welcome to Spentee!\n\n1. Purpose: Spentee provides personal expense tracking, budgeting, and AI assistance for informational purposes.\n\n2. Local Data: Your financial data is stored directly on your device. You are responsible for maintaining device security.\n\n3. AI Recommendations: Mascot feedback and budgeting tips are educational and do not constitute certified financial or investment advisory.\n\n4. Updates: We continually update Spentee to bring new budgeting tools, insights, and mascot features.',
            style: TextStyle(color: Color(0xFF8DAAB6), fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Understood',
              style: TextStyle(color: AppTheme.primaryMint, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF091C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Privacy & Security Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Spentee is designed Privacy-First.\n\n• Zero Bank Linking Required: Spentee does not scrape your bank SMS or credentials without your explicit consent.\n\n• Local Storage: All transactions, budgets, custom categories, and reminder configurations are stored securely in local JSON storage.\n\n• No Data Selling: We do not sell, rent, or monetize your personal financial records to third-party advertisers.\n\n• User Control: You have complete freedom to export, edit, or reset your records at any time.',
            style: TextStyle(color: Color(0xFF8DAAB6), fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryMint, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF092027),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF133C47)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Spentee',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Logo Banner
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0C242D),
                  border: Border.all(color: AppTheme.primaryMint, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryMint.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.primaryMint,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Spentee',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryMint.withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  'Version 1.0.0+1 (Build 1)',
                  style: TextStyle(
                    color: AppTheme.primaryMint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your AI Money Companion',
                style: TextStyle(
                  color: Color(0xFF7A9CA8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Description Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF081820),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF102E3A)),
                ),
                child: const Text(
                  'Spentee empowers you to track every rupee without stress. Set custom category budgets, monitor live spending, and interact with your AI mascot for smart tips and entertaining roasts that build lifelong financial health.',
                  style: TextStyle(
                    color: Color(0xFF94B2BE),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Technical Details Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF081820),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF102E3A)),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.code_rounded,
                      label: 'Framework',
                      value: 'Flutter 3.x / Dart',
                    ),
                    const Divider(color: Color(0xFF0E2732), height: 1),
                    _InfoRow(
                      icon: Icons.android_rounded,
                      label: 'Package ID',
                      value: 'com.spentee.spentee',
                    ),
                    const Divider(color: Color(0xFF0E2732), height: 1),
                    _InfoRow(
                      icon: Icons.groups_rounded,
                      label: 'Engineered By',
                      value: 'Team Seven',
                    ),
                    const Divider(color: Color(0xFF0E2732), height: 1),
                    _InfoRow(
                      icon: Icons.storage_rounded,
                      label: 'Database',
                      value: 'Local JSON Storage',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Policy Actions
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _showPrivacyDialog(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071922),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF133644)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.privacy_tip_outlined,
                              color: AppTheme.primaryMint,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _showTermsDialog(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071922),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF133644)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: Color(0xFF00E5FF),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Terms of Use',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                '© 2026 Spentee. All rights reserved.',
                style: TextStyle(
                  color: Color(0xFF4C6873),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7597A4)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF88A8B4),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
