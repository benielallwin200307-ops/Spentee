import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'help_support_screen.dart';

/// Screen displaying Spentee version, features, technical architecture, and legal policies.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
            'Welcome to Spentee!\n\n1. Purpose: Spentee provides personal expense tracking, budgeting, and financial intelligence for informational and planning purposes.\n\n2. Local & Cloud Data: Your financial data is stored locally on your device and synchronized securely with your authenticated account via Firebase. You remain in full control of your records.\n\n3. AI Recommendations: Insights and budgeting suggestions provided by Spentee AI are for educational and self-management purposes and do not constitute certified financial or investment advisory.\n\n4. Updates: We continually update Spentee to bring advanced analytics, investment tracking, and smarter financial tools.',
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
            'Spentee is designed Privacy-First.\n\n• Zero Bank Linking Required: Spentee operates without scraping your private SMS messages or requesting bank credentials.\n\n• Local-First & Cloud Sync: All transactions, budgets, categories, and settings are stored locally on your device and securely synced with Firebase when online.\n\n• No Data Selling: We do not sell, rent, or monetize your personal financial records to third-party advertisers.\n\n• User Control: You have complete freedom to export, edit, or reset your records at any time.',
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

              // 1. App Identity Section
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
              Text(
                AppConfig.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppConfig.appTagline,
                style: const TextStyle(
                  color: Color(0xFF7A9CA8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryMint.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  'Version: ${AppConfig.version}',
                  style: const TextStyle(
                    color: AppTheme.primaryMint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. About Spentee Description Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF081820),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF102E3A)),
                ),
                child: const Text(
                  'Spentee helps you take control of your money, one transaction at a time. Track income and expenses, manage budgets, monitor investments, keep track of money lent and borrowed, and discover smarter ways to manage your finances with Spentee AI.',
                  style: TextStyle(
                    color: Color(0xFF94B2BE),
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 28),

              // 3. Key Features Section Header
              const Row(
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: AppTheme.primaryMint,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'What You Can Do with Spentee',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4 Compact Feature Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  const card1 = _FeatureCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Smart Money Tracking',
                    description:
                        'Manually track your income, expenses and transactions.',
                  );
                  const card2 = _FeatureCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Spending Analytics',
                    description:
                        'Understand your spending habits, monitor budgets and discover where your money goes.',
                  );
                  const card3 = _FeatureCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Financial Insights',
                    description:
                        'Get money-related insights, spending analysis and smarter saving suggestions with Spentee AI.',
                  );
                  const card4 = _FeatureCard(
                    icon: Icons.cloud_sync_rounded,
                    title: 'Offline Access & Cloud Sync',
                    description:
                        'Access supported features offline and synchronise your financial data across devices using Firebase.',
                  );

                  if (constraints.maxWidth < 340) {
                    return const Column(
                      children: [
                        card1,
                        SizedBox(height: 10),
                        card2,
                        SizedBox(height: 10),
                        card3,
                        SizedBox(height: 10),
                        card4,
                      ],
                    );
                  }

                  return const Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: card1),
                          SizedBox(width: 10),
                          Expanded(child: card2),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: card3),
                          SizedBox(width: 10),
                          Expanded(child: card4),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // 4. Technical Information Section
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF081820),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF102E3A)),
                ),
                child: const Column(
                  children: [
                    _InfoRow(
                      icon: Icons.storage_rounded,
                      label: 'Storage',
                      value: AppConfig.storage,
                    ),
                    Divider(color: Color(0xFF0E2732), height: 1),
                    _InfoRow(
                      icon: Icons.cloud_done_rounded,
                      label: 'Cloud Sync',
                      value: AppConfig.cloudSync,
                    ),
                    Divider(color: Color(0xFF0E2732), height: 1),
                    _InfoRow(
                      icon: Icons.android_rounded,
                      label: 'Platform',
                      value: AppConfig.platform,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. Bottom Section (Contact Support + Privacy Policy + Terms of Use)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF092923),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryMint.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: AppTheme.primaryMint,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Contact Support',
                        style: TextStyle(
                          color: AppTheme.primaryMint,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

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
                            Flexible(
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                            Flexible(
                              child: Text(
                                'Terms of Use',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
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

              // 6. Copyright
              const Text(
                AppConfig.copyright,
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF081820),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF102E3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primaryMint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryMint, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF7D9DAA),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
