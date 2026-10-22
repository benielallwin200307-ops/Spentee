import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'budget_management_screen.dart';
import 'category_management_screen.dart';
import 'help_support_screen.dart';
import 'lent_borrowed_screen.dart';
import 'reminders_screen.dart';
import 'splash_screen.dart';

/// Screen 15 — Spentee Profile & Preferences Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final theme = MascotThemeData.of(context);
    final mascotLabel = theme.isFemale ? 'Radiant Pink' : 'Neon Mint';

    return Scaffold(
      backgroundColor: const Color(0xFF030D11),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row: Title + "Edit Profile" Pill Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your account and preferences.',
                        style: TextStyle(
                          color: Color(0xFF7E9DAA),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showEditProfileModal(context, appState),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.isFemale
                            ? const Color(0xFF260D1E)
                            : const Color(0xFF041E1C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.primaryAccent,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryAccent.withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: theme.primaryAccent,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. User Profile Card
              InkWell(
                onTap: () => _showEditProfileModal(context, appState),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: theme.cardGradient,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: theme.subtleBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryAccent.withValues(alpha: 0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Mascot Avatar with glowing ring
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.primaryAccent,
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  theme.primaryAccent.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            appState.userName.isNotEmpty
                                ? appState.userName[0].toUpperCase()
                                : 'A',
                            style: TextStyle(
                              color: theme.primaryAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.userName.isNotEmpty
                                  ? appState.userName
                                  : 'Team Seven',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appState.userEmail.isNotEmpty
                                  ? appState.userEmail
                                  : 'teamseven7official@gmail.com',
                              style: const TextStyle(
                                color: Color(0xFF7E9DA9),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.primaryAccent,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Section 1: Finance
              _SectionHeader(
                title: 'Finance',
                subtitle: 'Manage how you track your money',
              ),
              const SizedBox(height: 10),
              _GroupCard(
                children: [
                  _ProfileOptionTile(
                    icon: Icons.account_balance_wallet_rounded,
                    iconBg: const Color(0xFF08332A),
                    iconColor: AppTheme.primaryMint,
                    title: 'Manage Budget',
                    subtitle: 'Set budgets and track your goals',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BudgetManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const _CardDivider(),
                  _ProfileOptionTile(
                    icon: Icons.category_rounded,
                    iconBg: const Color(0xFF24163E),
                    iconColor: const Color(0xFFA855F7),
                    title: 'Categories',
                    subtitle: 'Manage your transaction categories',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoryManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const _CardDivider(),
                  _ProfileOptionTile(
                    icon: Icons.handshake_rounded,
                    iconBg: const Color(0xFF0D323A),
                    iconColor: const Color(0xFF00E5FF),
                    title: 'Lent & Borrowed',
                    subtitle: 'Track loans, repayments & funny reminders',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LentBorrowedScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Section 2: App Settings
              _SectionHeader(
                title: 'App Settings',
                subtitle: 'Personalize your Spentee experience',
              ),
              const SizedBox(height: 10),
              _GroupCard(
                children: [
                  _ProfileOptionTile(
                    icon: Icons.palette_rounded,
                    iconBg: theme.isFemale
                        ? const Color(0xFF2D1022)
                        : const Color(0xFF08332A),
                    iconColor: theme.primaryAccent,
                    title: 'Theme Accent',
                    subtitle: 'Choose your color accent',
                    trailingText: mascotLabel,
                    trailingTextColor: theme.primaryAccent,
                    onTap: () => _showMascotSwitchSheet(context, appState),
                  ),
                  const _CardDivider(),
                  _ProfileOptionTile(
                    icon: Icons.notifications_rounded,
                    iconBg: const Color(0xFF33220A),
                    iconColor: const Color(0xFFFFB300),
                    title: 'Reminders',
                    subtitle: 'Get notified and stay on track',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RemindersScreen(),
                        ),
                      );
                    },
                  ),
                  const _CardDivider(),
                  _ProfileOptionTile(
                    icon: Icons.language_rounded,
                    iconBg: const Color(0xFF072B36),
                    iconColor: const Color(0xFF00E5FF),
                    title: 'Language',
                    subtitle: 'Choose your preferred language',
                    trailingText: appState.selectedLanguage,
                    trailingTextColor: AppTheme.primaryMint,
                    onTap: () => _showLanguageSheet(context, appState),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 5. Section 3: Support
              _SectionHeader(
                title: 'Support',
                subtitle: "We're here to help",
              ),
              const SizedBox(height: 10),
              _GroupCard(
                children: [
                  _ProfileOptionTile(
                    icon: Icons.help_rounded,
                    iconBg: const Color(0xFF2E270A),
                    iconColor: const Color(0xFFFFD600),
                    title: 'Help & Support',
                    subtitle: 'FAQs, contact support and more',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  const _CardDivider(),
                  _ProfileOptionTile(
                    icon: Icons.info_rounded,
                    iconBg: const Color(0xFF13222B),
                    iconColor: const Color(0xFF88A8B4),
                    title: 'About Spentee',
                    subtitle: 'App version, terms and privacy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 6. Section 4: Logout
              InkWell(
                onTap: () => _confirmLogout(context, appState),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF260D14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF4D6D).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFF4D6D),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: Color(0xFFFF4D6D),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL: Edit Profile ---
  void _showEditProfileModal(BuildContext context, AppState appState) {
    final nameController = TextEditingController(text: appState.userName);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A181D),
      barrierColor: Colors.black.withValues(alpha: 0.7),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3842),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Update your display name across Spentee.',
                style: TextStyle(color: Color(0xFF7A9BA8), fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Text(
                'Full Name',
                style: TextStyle(
                  color: Color(0xFF90B0BC),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                autofocus: false,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF061418),
                  hintText: 'Enter your name',
                  hintStyle: const TextStyle(color: Color(0xFF4C6B77)),
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primaryMint,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF143540)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryMint),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Email Address (Linked Account)',
                style: TextStyle(
                  color: Color(0xFF90B0BC),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF041014),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0F262F)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      color: Color(0xFF5B7D8A),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        appState.userEmail.isNotEmpty
                            ? appState.userEmail
                            : 'teamseven7official@gmail.com',
                        style: const TextStyle(
                          color: Color(0xFF829FA8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF4B6974),
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.isNotEmpty) {
                      await appState.updateUserName(newName);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Profile updated to "$newName" ✨',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: const Color(0xFF092E27),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMint,
                    foregroundColor: const Color(0xFF03161C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- MODAL: Mascot Switch ---
  void _showMascotSwitchSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A181D),
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentMascot = appState.selectedMascot;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3842),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Theme Accent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Personalize your color palette. All your financial data remains completely safe.',
                  style: TextStyle(color: Color(0xFF7E9DAA), fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Mint Option
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          appState.setSelectedMascot('male');
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Switched to Neon Mint Theme ✨'),
                              backgroundColor: Color(0xFF092E27),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: currentMascot == 'male'
                                ? const Color(0xFF062B25)
                                : const Color(0xFF06151B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: currentMascot == 'male'
                                  ? AppTheme.primaryMint
                                  : const Color(0xFF14333F),
                              width: currentMascot == 'male' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryMint.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: currentMascot == 'male'
                                        ? AppTheme.primaryMint
                                        : AppTheme.primaryMint.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.eco_rounded,
                                    color: AppTheme.primaryMint,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Neon Mint',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentMascot == 'male' ? 'Active' : 'Select',
                                style: TextStyle(
                                  color: currentMascot == 'male'
                                      ? AppTheme.primaryMint
                                      : const Color(0xFF6B8B97),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Pink Option
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          appState.setSelectedMascot('female');
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Switched to Radiant Pink Theme 💖'),
                              backgroundColor: Color(0xFF092E27),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: currentMascot == 'female'
                                ? const Color(0xFF260D1E)
                                : const Color(0xFF06151B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: currentMascot == 'female'
                                  ? const Color(0xFFFF528E)
                                  : const Color(0xFF14333F),
                              width: currentMascot == 'female' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF528E).withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: currentMascot == 'female'
                                        ? const Color(0xFFFF528E)
                                        : const Color(0xFFFF528E).withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFFFF528E),
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Radiant Pink',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentMascot == 'female' ? 'Active' : 'Select',
                                style: TextStyle(
                                  color: currentMascot == 'female'
                                      ? const Color(0xFFFF528E)
                                      : const Color(0xFF6B8B97),
                                  fontSize: 12,
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
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- MODAL: Language ---
  void _showLanguageSheet(BuildContext context, AppState appState) {
    final languages = [
      {'code': 'English', 'native': 'English'},
      {'code': 'Hindi', 'native': 'हिंदी (Hindi)'},
      {'code': 'Telugu', 'native': 'తెలుగు (Telugu)'},
      {'code': 'Tamil', 'native': 'தமிழ் (Tamil)'},
      {'code': 'Kannada', 'native': 'ಕನ್ನಡ (Kannada)'},
      {'code': 'Malayalam', 'native': 'മലയാളം (Malayalam)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A181D),
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3842),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...languages.map((lang) {
                  final code = lang['code']!;
                  final isSelected = appState.selectedLanguage == code;
                  return InkWell(
                    onTap: () {
                      appState.setSelectedLanguage(code);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Language updated to $code'),
                          backgroundColor: const Color(0xFF092E27),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF082B24)
                            : const Color(0xFF06151B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryMint
                              : const Color(0xFF122C38),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lang['native']!,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryMint
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryMint,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LOGOUT CONFIRMATION ---
  void _confirmLogout(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF091C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out of Spentee?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to log out? Your recorded transactions and financial budgets will remain safely stored on this device.',
          style: TextStyle(color: Color(0xFF88A8B6), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF88A8B6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D6D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// --- REUSABLE PROFILE WIDGETS ---

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B8B97),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071820),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0F2B38),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailingText;
  final Color? trailingTextColor;
  final VoidCallback onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.trailingTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6C8C98),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: TextStyle(
                  color: trailingTextColor ?? AppTheme.primaryMint,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF5B7D8C),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Color(0xFF0D2530),
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
