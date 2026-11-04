import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Help & Support Screen featuring interactive FAQ accordions and direct contact support.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How does Budget Management work?',
      answer:
          'Spentee lets you set monthly spending limits for individual categories such as Food, Shopping and Transport. Track your spending, view your remaining budget and receive alerts when you approach or exceed your budget limit.',
      category: 'Finances',
    ),
    _FaqItem(
      question: 'Is my financial data secure and private?',
      answer:
          'Your financial information is associated with your account. Spentee stores data locally on your device and uses Firebase to sync your information across devices when connected to the internet. Spentee does not access your SMS messages to track transactions.',
      category: 'Privacy',
    ),
    _FaqItem(
      question: 'How do I add and manage transactions?',
      answer:
          'You can manually add income and expenses, select categories, enter amounts and choose dates. You can also edit or delete transactions whenever needed.',
      category: 'Transactions',
    ),
    _FaqItem(
      question: 'How does Lend & Repay work?',
      answer:
          'Use Lend & Repay to record money you lend to others or borrow from them. Track money to collect and money to repay separately without mixing these amounts with your regular income and expenses. You can also record repayments and track outstanding amounts.',
      category: 'Lend & Repay',
    ),
    _FaqItem(
      question: 'How do Transfers and Investments work?',
      answer:
          'Record transfers between your own accounts and track investments such as Gold, Mutual Funds, SIPs, Stocks, ETFs, Savings and Retirement Investments. These records are handled separately from regular spending.',
      category: 'Finances',
    ),
    _FaqItem(
      question: 'How does Spentee AI work?',
      answer:
          'Spentee AI helps you understand your financial activity, analyse spending, check budgets and discover ways to save money. It focuses on money-related questions and uses your available financial data to provide relevant insights.',
      category: 'AI Assistant',
    ),
    _FaqItem(
      question: 'Can I use Spentee without an internet connection?',
      answer:
          'Yes. You can access supported features and manage your locally stored financial data offline. Changes will sync with your account when an internet connection becomes available.',
      category: 'General',
    ),
    _FaqItem(
      question: 'Can I create my own categories?',
      answer:
          'Yes. You can create custom income and expense categories to organise your transactions according to your needs.',
      category: 'Customization',
    ),
    _FaqItem(
      question: 'What happens if I delete my account?',
      answer:
          'Deleting your account is intended to permanently remove your account and associated financial data. This action cannot be undone. Make sure you export or save any information you want to keep before proceeding.',
      category: 'Account',
    ),
    _FaqItem(
      question: 'Why does Spentee show advertisements?',
      answer:
          'Spentee is free to use and displays advertisements to support the app. Advertisements help us maintain and improve the service.',
      category: 'General',
    ),
  ];

  int? _expandedIndex = 0;

  void _copySupportEmail() {
    Clipboard.setData(const ClipboardData(text: 'support@spentee.app'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.primaryMint, size: 20),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Copied support@spentee.app to clipboard!',
                style: TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF0C2B36),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFeedbackModal() {
    final feedbackController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1C22),
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
                'Send Feedback or Bug Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tell us how we can improve your Spentee experience.',
                style: TextStyle(color: Color(0xFF7C9BA6), fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type your feedback or describe an issue...',
                  hintStyle: const TextStyle(color: Color(0xFF55707A)),
                  filled: true,
                  fillColor: const Color(0xFF051318),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF153844)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryMint),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final text = feedbackController.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Thank you! Your feedback has been received. 🚀',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: Color(0xFF0C2B36),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMint,
                    foregroundColor: const Color(0xFF03161C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Submit Feedback',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCopyEmailButton() {
    return InkWell(
      onTap: _copySupportEmail,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryMint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_rounded, color: Color(0xFF03161C), size: 16),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Copy Support Email',
                style: TextStyle(
                  color: Color(0xFF03161C),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackButton({bool isFullWidth = false}) {
    return InkWell(
      onTap: _showFeedbackModal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF061B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1A4554),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: const [
            Icon(Icons.rate_review_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Feedback',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
          'Help & Support',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Support Banner Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B2E28), Color(0xFF051C22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryMint.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMint.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: AppTheme.primaryMint,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need Direct Assistance?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Reach out directly to the Spentee support team.',
                                style: TextStyle(
                                  color: Color(0xFF88AAB6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 260) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCopyEmailButton(),
                              const SizedBox(height: 10),
                              _buildFeedbackButton(isFullWidth: true),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: _buildCopyEmailButton()),
                            const SizedBox(width: 10),
                            _buildFeedbackButton(isFullWidth: false),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // FAQ Section Header
              const Row(
                children: [
                  Icon(
                    Icons.quiz_rounded,
                    color: AppTheme.primaryMint,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Frequently Asked Questions',
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

              // FAQ List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final faq = _faqs[index];
                  final isExpanded = _expandedIndex == index;

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF071922),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isExpanded
                            ? AppTheme.primaryMint.withValues(alpha: 0.3)
                            : const Color(0xFF102D38),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _expandedIndex = isExpanded ? null : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    faq.question,
                                    style: TextStyle(
                                      color: isExpanded
                                          ? AppTheme.primaryMint
                                          : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: isExpanded
                                        ? AppTheme.primaryMint
                                        : const Color(0xFF7293A0),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            ClipRect(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: isExpanded
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 12),
                                          const Divider(
                                            color: Color(0xFF0F303B),
                                            height: 1,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            faq.answer,
                                            style: const TextStyle(
                                              color: Color(0xFF9CB8C4),
                                              fontSize: 13,
                                              height: 1.45,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF04141A),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              faq.category,
                                              style: const TextStyle(
                                                color: Color(0xFF5A808E),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  final String category;

  _FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}
