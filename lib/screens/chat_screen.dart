import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../state/app_state.dart';
import '../models/roast.dart';

/// Screen 10 — Spentee AI Chatbot Screen
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = const [
    'Yes, create a plan',
    'Show examples',
    'Make it stricter',
    'How to cut food bills?',
    'Give me a spending roast 🔥',
  ];

  void _sendMessage(String query, AppState state) {
    if (query.trim().isEmpty) return;
    state.sendUserChatMessage(query);
    _inputController.clear();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isFemale = appState.selectedMascot == 'female';
    final aiAvatar = isFemale ? 'Assets/extracted/female_ai.png' : 'Assets/extracted/avatar_ai.png';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        titleSpacing: 0,
        title: Row(
          children: [
            MascotAvatar(
              size: 38,
              imagePath: aiAvatar,
              hasGlow: true,
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Spentee AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    PillBadge(
                      text: 'Beta',
                      backgroundColor: Color(0x3300E676),
                      textColor: AppTheme.primaryMint,
                    ),
                  ],
                ),
                Text(
                  'Your witty money mentor',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppTheme.textGrey),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history is kept locally on your device.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.bgCard,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: appState.chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = appState.chatMessages[index];
                  return _ChatMessageBubble(
                    message: msg,
                    aiAvatarPath: aiAvatar,
                  );
                },
              ),
            ),

            // Suggested prompt pills
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedPrompts.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return ActionChip(
                    backgroundColor: AppTheme.bgCard,
                    side: const BorderSide(color: AppTheme.borderColor, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    label: Text(
                      prompt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _sendMessage(prompt, appState),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.bgSurface,
                border: Border(
                  top: BorderSide(color: AppTheme.borderSubtle, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderSubtle, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything about your money...',
                          hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (val) => _sendMessage(val, appState),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryMint,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.bgDark, size: 20),
                      onPressed: () => _sendMessage(_inputController.text, appState),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget to render individual message bubbles.
class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String aiAvatarPath;

  const _ChatMessageBubble({
    required this.message,
    required this.aiAvatarPath,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      // User Message (green bubble, aligned right)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3B2E),
                  border: Border.all(color: AppTheme.primaryMint.withValues(alpha: 0.4), width: 1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Message (dark bubble, mascot avatar on left)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MascotAvatar(size: 32, imagePath: aiAvatarPath),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    border: Border.all(color: AppTheme.borderSubtle, width: 1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),

                // If message has Suggested Plan Card
                if (message.hasPlanCard && message.planData != null) ...[
                  const SizedBox(height: 10),
                  _SuggestedPlanCard(planData: message.planData!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The 50/30/20 Suggested Plan breakdown card matching the reference image.
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor, width: 1),
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
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryMint, size: 16),
            ],
          ),
          const SizedBox(height: 14),

          // Needs row
          _PlanRow(
            icon: Icons.home_rounded,
            color: AppTheme.primaryMint,
            label: needs['label'],
            amount: needs['amount'],
            ratio: (needs['percent'] as num).toDouble(),
          ),
          const SizedBox(height: 10),

          // Wants row
          _PlanRow(
            icon: Icons.coffee_rounded,
            color: AppTheme.accentOrange,
            label: wants['label'],
            amount: wants['amount'],
            ratio: (wants['percent'] as num).toDouble(),
          ),
          const SizedBox(height: 10),

          // Savings row
          _PlanRow(
            icon: Icons.savings_rounded,
            color: AppTheme.accentCyan,
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
            CategoryBadge(icon: icon, color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppTheme.bgCard,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
