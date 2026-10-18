import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/roast.dart';
import '../models/transaction.dart';

/// Service managing Spentee AI responses, local storage of chat sessions,
/// financial intelligence, and optional secure backend configuration.
class AiChatService {
  AiChatService._();
  static final AiChatService instance = AiChatService._();

  // Storage file helper
  Future<File?> _getHistoryFile() async {
    try {
      final androidFiles = Directory('/data/user/0/com.spentee.spentee/files');
      if (await androidFiles.exists()) {
        return File('${androidFiles.path}/spentee_chat_history.json');
      }
      final androidAppFlutter =
          Directory('/data/user/0/com.spentee.spentee/app_flutter');
      if (await androidAppFlutter.exists()) {
        return File('${androidAppFlutter.path}/spentee_chat_history.json');
      }
      final localDir = Directory('.spentee_storage');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      return File('${localDir.path}/spentee_chat_history.json');
    } catch (e) {
      debugPrint('Chat history storage error: $e');
      return null;
    }
  }

  /// Load all saved sessions from local disk.
  Future<List<ChatSession>> loadSessions() async {
    try {
      final file = await _getHistoryFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final List<dynamic> list = jsonDecode(content);
          return list
              .map((item) => ChatSession.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Failed to load chat sessions: $e');
    }
    return [];
  }

  /// Save all sessions to local disk.
  Future<void> saveSessions(List<ChatSession> sessions) async {
    try {
      final file = await _getHistoryFile();
      if (file == null) return;
      final data = sessions.map((s) => s.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save chat sessions: $e');
    }
  }

  /// Generate a contextual response from Spentee AI.
  /// If [transactions] are provided and user gave consent, performs real analysis.
  Future<ChatMessage> generateResponse({
    required String query,
    required List<Transaction> transactions,
    required bool userConsentedToDataAnalysis,
    required String userMascot,
  }) async {
    // Simulate real AI processing latency for natural conversation feel
    await Future.delayed(const Duration(milliseconds: 650));

    final q = query.trim().toLowerCase();
    final now = DateTime.now();

    // 1. "How can I save more money?"
    if (q.contains('save more money') ||
        (q.contains('save') && q.contains('more')) ||
        (q.contains('how') && q.contains('save'))) {
      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        text:
            'Here are a few simple ways to save more money:\n\n'
            '1. Track your daily expenses so you know where your money goes.\n'
            '2. Reduce frequent small spends (like food delivery or unnecessary subscriptions).\n'
            '3. Set a monthly savings goal and move a fixed amount right after you get paid.\n'
            '4. Use the 50/30/20 rule - 50% needs, 30% wants, 20% savings/investments.\n\n'
            'Want me to create a personalised savings plan based on your spending?',
        actionButtons: const [
          'Create Savings Plan',
          'Monthly Budget Suggestion',
          'Analyze My Spending',
        ],
      );
    }

    // 2. "Explain SIPs for beginners"
    if (q.contains('sip') || q.contains('systematic investment')) {
      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        text:
            'A Systematic Investment Plan (SIP) allows you to invest a fixed amount regularly (usually monthly) into mutual funds.\n\n'
            'Key benefits of SIPs:\n'
            '1. Rupee Cost Averaging: You automatically purchase more units when markets drop, and fewer when markets rise.\n'
            '2. Power of Compounding: Reinvested returns generate additional returns over time, multiplying your wealth.\n'
            '3. Financial Discipline: Fixed automatic debits right after salary day build consistent wealth effortlessly.\n'
            '4. Low Entry Barrier: Start with as little as ₹500/month.\n\n'
            '💡 Pro Tip: For beginners, broad-market index funds (like Nifty 50 or S&P 500) give reliable diversification with minimal fees.',
        actionButtons: const [
          'Create Savings Plan',
          'Help me plan a monthly budget',
        ],
      );
    }

    // 3. "Help me plan a monthly budget"
    if (q.contains('budget') ||
        q.contains('plan') && q.contains('month') ||
        q.contains('50/30/20')) {
      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        text:
            'Here is the classic 50/30/20 budget framework adapted for your financial health:\n\n'
            '1. Needs (50%): Rent, groceries, utility bills, commute, and health cover.\n'
            '2. Wants (30%): Dining out, shopping, streaming subscriptions, and fun outings.\n'
            '3. Savings & Investments (20%): Emergency savings, SIP investments, and retirement.\n\n'
            'Here is a suggested allocation for an estimated ₹25,000 monthly income:',
        hasPlanCard: true,
        planData: {
          'total': '₹25,000',
          'needs': {'label': 'Needs (50%)', 'amount': '₹12,500', 'percent': 0.5},
          'wants': {'label': 'Wants (30%)', 'amount': '₹7,500', 'percent': 0.3},
          'savings': {'label': 'Savings (20%)', 'amount': '₹5,000', 'percent': 0.2},
        },
        actionButtons: const [
          'Create Savings Plan',
          'Analyze My Spending',
        ],
      );
    }

    // 4. "Review my spending this month" or Spending Analysis
    if (q.contains('review') && q.contains('spending') ||
        q.contains('spend') && q.contains('month') ||
        q.contains('analyze') && q.contains('spending')) {
      if (!userConsentedToDataAnalysis) {
        return ChatMessage(
          id: 'ai_${now.millisecondsSinceEpoch}',
          isUser: false,
          timestamp: now,
          text:
              '🔒 Data Privacy Notice:\n\n'
              'To review your spending, Spentee AI needs your explicit permission to analyze your local transaction records on this device.\n\n'
              '• Your financial data never leaves your device.\n'
              '• No transaction details are uploaded to external servers without consent.',
          actionButtons: const [
            'Grant Permission & Analyze',
            'Cancel',
          ],
        );
      }

      // Compute actual spending from current transactions
      final currentMonthTx = transactions.where((tx) =>
          tx.type == TransactionType.expense &&
          tx.date.month == now.month &&
          tx.date.year == now.year).toList();

      final totalExpense = currentMonthTx.fold<double>(
          0.0, (sum, tx) => sum + tx.amount);

      final Map<String, double> categoryTotals = {};
      for (final tx in currentMonthTx) {
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0.0) + tx.amount;
      }

      String topCategory = 'None';
      double topAmount = 0.0;
      categoryTotals.forEach((cat, amt) {
        if (amt > topAmount) {
          topAmount = amt;
          topCategory = cat;
        }
      });

      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        text:
            '📊 Spentee Spending Audit for This Month:\n\n'
            '• Total Outflow: ₹${totalExpense.toStringAsFixed(0)} across ${currentMonthTx.length} transactions.\n'
            '• Top Expense Area: $topCategory (₹${topAmount.toStringAsFixed(0)}).\n'
            '• Trend Note: Your discretionary spending is concentrated in $topCategory.\n\n'
            'Recommendation: Trimming non-essential spends in $topCategory by just 15% would free up an extra ₹${(topAmount * 0.15).toStringAsFixed(0)} for your savings goal!',
        actionButtons: const [
          'Create Savings Plan',
          'Monthly Budget Suggestion',
        ],
      );
    }

    // 5. Emergency Fund questions
    if (q.contains('emergency') || q.contains('rainy day')) {
      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        text:
            'An Emergency Fund is your personal safety buffer. Here is how to build one:\n\n'
            '1. Target Amount: Strive to save 3 to 6 months of mandatory living expenses (rent + food + utilities + EMIs).\n'
            '2. Where to park it: High-yield savings accounts or low-risk liquid mutual funds for instant access.\n'
            '3. Golden Rule: Touch this money ONLY for genuine emergencies (unforeseen medical bills, job transitions, urgent repairs).',
        actionButtons: const [
          'Create Savings Plan',
          'How can I save more money?',
        ],
      );
    }

    // 6. Roast request
    if (q.contains('roast') || q.contains('funny') || q.contains('joke')) {
      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        text:
            '😎 Spentee Roast Mode Activated:\n\n'
            '"You tap \'Pay Now\' with the confidence of a billionaire, then check your balance with one eye closed hoping the minus sign is just a speck of dust on the screen." 💀💸\n\n'
            'Ready to put your wallet on a healthy diet?',
        actionButtons: const [
          'Help me plan a monthly budget',
          'Review my spending this month',
        ],
      );
    }

    // 7. General Financial / Conversational Fallback
    return ChatMessage(
      id: 'ai_${now.millisecondsSinceEpoch}',
      isUser: false,
      timestamp: now,
      text:
          'That is a great financial inquiry! A solid financial life comes down to three core principles:\n\n'
          '1. Live below your income and track recurring leakages.\n'
          '2. Put idle cash into automated monthly investments.\n'
          '3. Keep an emergency fund so market dips never force you into high-interest debt.\n\n'
          'Would you like me to analyze your monthly spending or help plan a budget breakdown?',
      actionButtons: const [
        'How can I save more money?',
        'Help me plan a monthly budget',
        'Review my spending this month',
      ],
    );
  }
}
