import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/roast.dart';
import 'chat_history_screen.dart';

/// Screen 10 — Spentee AI Chatbot Screen
/// Pixel-perfect redesign matching the reference UI:
/// - Deep navy/near-black theme with teal glow gradients
/// - Original Spentee mascot in Welcome Banner and AI message avatar
/// - Header with neon-green 'AI' highlight, Chat History button, and 3-dot menu
/// - Large Welcome Banner with waving Spentee AI mascot
/// - "Try asking" / Popular Questions 2x2 grid with distinct icons
/// - Scrollable conversation with green user bubble and dark teal AI bubble
/// - Functional Copy, Helpful, Not Helpful, Regenerate actions
/// - Contextual Action Cards (Savings Plan, Budget Suggestion, Spend Review)
/// - Capsule composer with attachment support and glowing neon send button
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _attachedReceiptName;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _sendMessage(String query, AppState state) {
    final text = query.trim();
    if (text.isEmpty && _attachedReceiptName == null) return;
    if (state.isAiResponding) return;

    state.sendUserChatMessage(text, attachment: _attachedReceiptName);
    _inputController.clear();
    setState(() {
      _attachedReceiptName = null;
    });
    _scrollToBottom();
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Context to Spentee AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Attach an expense note or recent transaction for personalized advice.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMint.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppTheme.primaryMint),
                ),
                title: const Text('Attach Recent Grocery Bill',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Supermarket Groceries (₹1,292)',
                    style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                onTap: () {
                  setState(() {
                    _attachedReceiptName = 'Grocery Bill (₹1,292)';
                  });
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: AppTheme.accentCyan),
                ),
                title: const Text('Attach Fuel & Transit Recharge',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Commute expense (₹1,418)',
                    style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                onTap: () {
                  setState(() {
                    _attachedReceiptName = 'Commute Pass (₹1,418)';
                  });
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllPopularQuestions(AppState appState) {
    final extraQuestions = [
      {
        'title': 'Emergency Fund: How much do I need?',
        'desc': 'Buffer formula for 3 to 6 months expenses',
        'icon': Icons.shield_rounded,
        'color': AppTheme.primaryMint,
      },
      {
        'title': '50/30/20 Budgeting Rule',
        'desc': 'Needs, wants, and savings framework',
        'icon': Icons.pie_chart_rounded,
        'color': AppTheme.accentCyan,
      },
      {
        'title': 'Debt Snowball vs Avalanche',
        'desc': 'Fastest strategies to pay off loans',
        'icon': Icons.trending_down_rounded,
        'color': AppTheme.accentOrange,
      },
      {
        'title': 'How to cut recurring subscription costs?',
        'desc': 'Find hidden money leakages',
        'icon': Icons.subscriptions_rounded,
        'color': AppTheme.accentPink,
      },
      {
        'title': 'Give me a witty spending roast 🔥',
        'desc': 'Spentee mascot humor on your balance',
        'icon': Icons.local_fire_department_rounded,
        'color': AppTheme.accentPurple,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Financial Prompts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textGrey),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: extraQuestions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = extraQuestions[index];
                    final color = item['color'] as Color;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                            color: AppTheme.borderSubtle, width: 1),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: color, size: 20),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        item['desc'] as String,
                        style: const TextStyle(
                            color: AppTheme.textDim, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppTheme.textDim),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _sendMessage(item['title'] as String, appState);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateSavingsPlanDialog(AppState state) {
    final titleController = TextEditingController(text: 'Emergency Buffer');
    final amountController = TextEditingController(text: '15000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: const Row(
          children: [
            Icon(Icons.savings_rounded, color: AppTheme.primaryMint, size: 22),
            SizedBox(width: 8),
            Text('Create Savings Plan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set a target goal to automate and track with Spentee AI.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                labelStyle: TextStyle(color: AppTheme.primaryMint),
                filled: true,
                fillColor: AppTheme.bgSurface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Target Amount (₹)',
                labelStyle: TextStyle(color: AppTheme.primaryMint),
                filled: true,
                fillColor: AppTheme.bgSurface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final amt = double.tryParse(amountController.text) ?? 5000;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Savings Plan "$title" for ₹${amt.toStringAsFixed(0)} created!'),
                  backgroundColor: AppTheme.bgSurface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              state.sendUserChatMessage(
                  'I set up a savings goal for $title of ₹${amt.toStringAsFixed(0)}. How should I pace my monthly savings?');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMint,
              foregroundColor: AppTheme.bgDark,
            ),
            child: const Text('Confirm Goal'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryMint, size: 22),
            SizedBox(width: 8),
            Text('About Spentee AI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spentee AI is your witty, private money companion designed for modern financial freedom.\n\n'
              '🔒 Privacy & Security:\n'
              '• Conversations are saved locally on your device.\n'
              '• Your financial data stays private and is only inspected on-device when you request a review.\n'
              '• Zero raw API secrets are exposed in client builds.\n\n'
              '⚡ AI Backend Integration:\n'
              'Spentee AI currently uses its high-performance local Financial Intelligence Engine. To connect an external LLM (e.g. Gemini 1.5 Flash or Cloud Functions), point `AiChatService` to your secure proxy endpoint without storing API keys inside Flutter code.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close',
                style: TextStyle(color: AppTheme.primaryMint)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final messages = appState.chatMessages;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Screen 3)
            _buildHeader(appState),

            // 2. Main Scrollable Conversation & Welcome Area
            Expanded(
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Welcome Banner (Screen 4)
                  _buildWelcomeBanner(appState),

                  const SizedBox(height: 18),

                  // Popular Questions Section (Screen 5)
                  _buildPopularQuestionsSection(appState),

                  const SizedBox(height: 18),

                  // Date separator (Screen 6)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Today, Oct 18, 2026',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Render Chat Messages
                  ...messages.map((msg) => _buildMessageRow(msg, appState)),

                  // AI Typing Indicator
                  if (appState.isAiResponding) _buildTypingIndicator(),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // 3. Attachment Pill if selected
            if (_attachedReceiptName != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryMint, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_file_rounded,
                        color: AppTheme.primaryMint, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _attachedReceiptName!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _attachedReceiptName = null),
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.textDim, size: 16),
                    ),
                  ],
                ),
              ),

            // 4. Fixed Message Composer (Screen 8)
            _buildComposer(appState),
          ],
        ),
      ),
    );
  }

  /// Header widget matching Section 3:
  /// Title: “Spentee AI” with AI highlighted in neon green
  /// Subtitle: “Your AI Money Companion”
  /// Chat History button + Three-dot menu
  Widget _buildHeader(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(
          bottom: BorderSide(color: Color(0x1F38BDF8), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontFamily: 'Roboto'),
                        children: [
                          TextSpan(
                            text: 'Spentee ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          TextSpan(
                            text: 'AI',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF00E5FF),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your AI Money Companion',
                  style: TextStyle(
                    color: Color(0xFF8E9DAE),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Chat History pill button
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF071926),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0x3300E676),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: AppTheme.primaryMint,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Chat History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Three-dot menu button
          PopupMenuButton<String>(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF071926),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x1F38BDF8), width: 1),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            color: AppTheme.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            onSelected: (val) {
              if (val == 'new') {
                appState.startNewChat();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Started fresh conversation.'),
                    backgroundColor: AppTheme.bgSurface,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (val == 'clear') {
                appState.startNewChat();
              } else if (val == 'history') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
                );
              } else if (val == 'about') {
                _showAboutDialog();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add_comment_rounded,
                        color: AppTheme.primaryMint, size: 18),
                    SizedBox(width: 10),
                    Text('New Conversation',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        color: AppTheme.accentCyan, size: 18),
                    SizedBox(width: 10),
                    Text('All History',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: AppTheme.accentPink, size: 18),
                    SizedBox(width: 10),
                    Text('Clear Current Screen',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.textGrey, size: 18),
                    SizedBox(width: 10),
                    Text('Privacy & Setup',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Welcome Banner matching Section 4:
  /// Large rounded card with dark teal gradient, neon green border glow,
  /// exact Spentee mascot on the right, and welcoming copy on the left.
  Widget _buildWelcomeBanner(AppState appState) {
    return Container(
      width: double.infinity,
      height: 156,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF04241C),
            Color(0xFF063327),
            Color(0xFF03221B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0x3800E676),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // Left text and copy
            Positioned(
              left: 18,
              top: 14,
              bottom: 14,
              right: 175,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "Hey! I'm ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: "Spentee AI",
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: " 👋",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ask me anything about money, savings, budgeting, investments or even everyday life.',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Exact Spentee mascot on the right with seamless gradient blend
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 176,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment(-0.25, 0.0),
                    colors: [Colors.transparent, Colors.white],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'Assets/extracted/chat_banner_mascot.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'Assets/extracted/ai_insight_mascot.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Popular Questions Section matching Section 5:
  /// Section titled "Try asking" with "See more →",
  /// 2x2 grid of four tappable cards.
  Widget _buildPopularQuestionsSection(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Try asking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            InkWell(
              onTap: () => _showAllPopularQuestions(appState),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'See more',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF00E676),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of Cards matching reference image
        Row(
          children: [
            Expanded(
              child: _buildSuggestionCard(
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFF00E676),
                title: 'How can I save\nmore money?',
                onTap: () => _sendMessage('How can I save more money?', appState),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSuggestionCard(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFFEC4899),
                title: 'Explain SIPs\nfor beginners',
                onTap: () =>
                    _sendMessage('Explain SIPs for beginners', appState),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSuggestionCard(
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'Help me plan\na monthly budget',
                onTap: () =>
                    _sendMessage('Help me plan a monthly budget', appState),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSuggestionCard(
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFFA855F7),
                title: 'Review my\nspending this month',
                onTap: () =>
                    _sendMessage('Review my spending this month', appState),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1E2B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x1F38BDF8),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Message row builder (Section 6)
  Widget _buildMessageRow(ChatMessage message, AppState appState) {
    if (message.isUser) {
      // User Message (Right-aligned, green gradient bubble, double checkmarks)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0A4D3B),
                          Color(0xFF083C2E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: const Color(0x4D00E676),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (message.attachmentName != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_file_rounded,
                                  color: AppTheme.primaryMint, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                message.attachmentName!,
                                style: const TextStyle(
                                  color: AppTheme.primaryMint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.done_all_rounded,
                              color: Color(0xFF00E676),
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // User Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2636),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x2E38BDF8), width: 1),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFFCBD5E1),
                size: 18,
              ),
            ),
          ],
        ),
      );
    }

    // AI Message (Left-aligned, dark teal card, Spentee mascot avatar, actions below)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spentee Mascot Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00E676),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'Assets/extracted/chat_ai_avatar_hd.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'Assets/extracted/chat_ai_avatar.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Bubble + Actions
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1D27),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: message.isError
                          ? const Color(0x66FF3366)
                          : const Color(0x1F38BDF8),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text content formatted
                      _buildFormattedAiText(message.text),

                      // Optional Suggested Plan breakdown card
                      if (message.hasPlanCard && message.planData != null) ...[
                        const SizedBox(height: 12),
                        _SuggestedPlanCard(planData: message.planData!),
                      ],

                      const SizedBox(height: 8),
                      Text(
                        _formatTime(message.timestamp),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contextual Action Buttons (Section 7)
                if (message.actionButtons != null &&
                    message.actionButtons!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: message.actionButtons!.map((action) {
                      return _buildContextualActionChip(action, appState);
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 8),

                // Assistant Action Buttons (Copy, Helpful, Not Helpful, Regenerate)
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.copy_rounded,
                      isActive: false,
                      tooltip: 'Copy',
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied response to clipboard'),
                            backgroundColor: AppTheme.bgSurface,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: message.isHelpful == true
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_alt_outlined,
                      isActive: message.isHelpful == true,
                      activeColor: AppTheme.primaryMint,
                      tooltip: 'Helpful',
                      onTap: () =>
                          appState.toggleMessageHelpful(message.id),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: message.isUnhelpful == true
                          ? Icons.thumb_down_rounded
                          : Icons.thumb_down_alt_outlined,
                      isActive: message.isUnhelpful == true,
                      activeColor: AppTheme.accentPink,
                      tooltip: 'Not helpful',
                      onTap: () =>
                          appState.toggleMessageUnhelpful(message.id),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.refresh_rounded,
                      isActive: false,
                      tooltip: 'Regenerate',
                      onTap: () => appState.regenerateLastResponse(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextualActionChip(String label, AppState appState) {
    Color chipColor = AppTheme.primaryMint;
    if (label.contains('Budget')) chipColor = AppTheme.accentCyan;
    if (label.contains('Analyze') || label.contains('Grant')) {
      chipColor = AppTheme.accentPurple;
    }

    return ActionChip(
      backgroundColor: const Color(0xFF071E2B),
      side: BorderSide(color: chipColor.withValues(alpha: 0.5), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label.contains('Savings')
                ? Icons.savings_rounded
                : (label.contains('Budget')
                    ? Icons.pie_chart_rounded
                    : Icons.query_stats_rounded),
            color: chipColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      onPressed: () {
        if (label == 'Create Savings Plan') {
          _showCreateSavingsPlanDialog(appState);
        } else if (label == 'Grant Permission & Analyze') {
          appState.setConsentForAnalysis(true);
          _sendMessage('Review my spending this month', appState);
        } else {
          _sendMessage(label, appState);
        }
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    Color activeColor = AppTheme.primaryMint,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.2)
              : const Color(0xFF0A1B26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : const Color(0x1F38BDF8),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? activeColor : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  /// AI message formatted text renderer (paragraphs, numbered items, bold)
  Widget _buildFormattedAiText(String rawText) {
    final lines = rawText.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return const SizedBox(height: 6);
        }

        // Numbered list item e.g. "1. Track your expenses..."
        final numberMatch = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(line.trim());
        if (numberMatch != null) {
          final numStr = numberMatch.group(1);
          final content = numberMatch.group(2);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numStr. ',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Expanded(
                  child: Text(
                    content ?? '',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Bullet point item
        if (line.trim().startsWith('• ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.trim().substring(2),
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Standard text line
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryMint, width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                'Assets/extracted/chat_ai_avatar.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1D27),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1F38BDF8), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Spentee AI is analyzing...',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fixed bottom composer matching Section 8:
  /// - Paperclip attachment icon
  /// - "Ask Spentee AI anything..." textfield
  /// - Glowing neon green circular send button
  Widget _buildComposer(AppState appState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(
          top: BorderSide(color: Color(0x1438BDF8), width: 1),
        ),
      ),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF071926),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0x2E38BDF8),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Attachment icon button
            IconButton(
              icon: const Icon(
                Icons.attach_file_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _showAttachmentSheet,
            ),
            const SizedBox(width: 8),

            // Text input field
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask Spentee AI anything...',
                  hintStyle:
                      TextStyle(color: Color(0xFF556980), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (val) => _sendMessage(val, appState),
              ),
            ),

            const SizedBox(width: 8),

            // Glowing neon-green send button
            GestureDetector(
              onTap: appState.isAiResponding
                  ? null
                  : () => _sendMessage(_inputController.text, appState),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: appState.isAiResponding
                      ? const Color(0xFF0A3326)
                      : const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  boxShadow: appState.isAiResponding
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF00E676)
                                .withValues(alpha: 0.6),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: appState.isAiResponding
                      ? const Color(0xFF556980)
                      : const Color(0xFF001422),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }
}

/// The 50/30/20 Suggested Plan breakdown card.
class _SuggestedPlanCard extends StatelessWidget {
  final Map<String, dynamic> planData;

  const _SuggestedPlanCard({required this.planData});

  @override
  Widget build(BuildContext context) {
    final needs = planData['needs'] as Map<String, dynamic>;
    final wants = planData['wants'] as Map<String, dynamic>;
    final savings = planData['savings'] as Map<String, dynamic>;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081724),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2E38BDF8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggested Plan for ${planData['total']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF00E676), size: 16),
            ],
          ),
          const SizedBox(height: 12),

          // Needs row
          _PlanRow(
            icon: Icons.home_rounded,
            color: const Color(0xFF00E676),
            label: needs['label'],
            amount: needs['amount'],
            ratio: (needs['percent'] as num).toDouble(),
          ),
          const SizedBox(height: 10),

          // Wants row
          _PlanRow(
            icon: Icons.coffee_rounded,
            color: const Color(0xFFFF9100),
            label: wants['label'],
            amount: wants['amount'],
            ratio: (wants['percent'] as num).toDouble(),
          ),
          const SizedBox(height: 10),

          // Savings row
          _PlanRow(
            icon: Icons.savings_rounded,
            color: const Color(0xFF00E5FF),
            label: savings['label'],
            amount: savings['amount'],
            ratio: (savings['percent'] as num).toDouble(),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String amount;
  final double ratio;

  const _PlanRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.amount,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: const Color(0xFF0F2636),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
