import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../models/lent_borrowed_record.dart';
import '../models/roast.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../config/backend_config.dart';
import 'financial_intelligence_engine.dart';

/// Service managing Spentee AI responses, local storage of chat sessions,
/// deterministic financial intelligence, and connection to the secure backend proxy.
class AiChatService {
  AiChatService._();
  static final AiChatService instance = AiChatService._();

  // Storage file helper for local chat history
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

  /// Central resolved backend URL for Spentee AI.
  /// Android Emulator strictly uses http://10.0.2.2:3000 (never 127.0.0.1).
  String getBackendUrl([String? urlOverride]) {
    return BackendConfig.getDefaultBackendUrl(urlOverride);
  }

  /// Asynchronously resolves definitive backend URL based on device environment.
  Future<String> resolveBackendUrl([String? urlOverride]) async {
    return await BackendConfig.getResolvedBackendUrl(urlOverride);
  }

  /// Backward-compatible list of candidate URLs containing only the central resolved URL.
  List<String> getCandidateBackendUrls([String? urlOverride]) {
    return [BackendConfig.getDefaultBackendUrl(urlOverride)];
  }

  /// Check backend health status against the central resolved URL.
  Future<Map<String, dynamic>> checkBackendHealth([String? urlOverride]) async {
    final baseUrl = await BackendConfig.getResolvedBackendUrl(urlOverride);
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(Uri.parse('$baseUrl/health'));
      final response =
          await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        data['activeUrl'] = baseUrl;
        data['isOnline'] = true;
        return data;
      }
      return {
        'status': 'error',
        'isOnline': false,
        'statusCode': response.statusCode,
        'activeUrl': baseUrl,
      };
    } catch (e) {
      return {
        'status': 'offline',
        'isOnline': false,
        'error': e.toString(),
        'activeUrl': baseUrl,
      };
    } finally {
      client?.close();
    }
  }

  /// Generate a contextual response from Spentee AI.
  /// 1. Tries deterministic personal finance calculation first (100% accurate, local).
  /// 2. If unrelated question, blocks locally with friendly guidance (no backend call).
  /// 3. If general financial question, connects to secure proxy backend (no raw data leaked).
  /// 4. If backend is offline or unconfigured, explains setup cleanly.
  Future<ChatMessage> generateResponse({
    required String query,
    required List<Transaction> transactions,
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
    List<LentBorrowedRecord> debts = const [],
    double? availableBalance,
    List<String> recentRoastIds = const [],
    String language = 'English',
    required bool userConsentedToDataAnalysis,
    required String userMascot,
    List<ChatMessage> conversationHistory = const [],
    String? backendUrlOverride,
  }) async {
    final now = DateTime.now();

    // ─────────────────────────────────────────────────────────────────────────
    // Phase 1: Local Deterministic Financial Engine
    // ─────────────────────────────────────────────────────────────────────────
    final engineResult = FinancialIntelligenceEngine.instance.evaluateQuery(
      query: query,
      transactions: transactions,
      budgets: budgets,
      savingsGoals: savingsGoals,
      debts: debts,
      availableBalance: availableBalance,
      recentRoastIds: recentRoastIds,
      language: language,
      userConsented: userConsentedToDataAnalysis,
    );

    if (engineResult != null) {
      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        text: engineResult.text,
        actionButtons: engineResult.actionButtons,
        hasPlanCard: engineResult.hasPlanCard,
        planData: engineResult.planData,
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Phase 1.5: Pre-Screening: Block Unrelated Questions Locally
    // ─────────────────────────────────────────────────────────────────────────
    if (!FinancialIntelligenceEngine.isFinancialQuery(query)) {
      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        text:
            "I'm Spentee AI 💚 I can help you understand your money, analyse your spending, track budgets, explain financial concepts, and roast your spending habits. Ask me something finance-related!",
        actionButtons: const [
          'How much did I spend this month?',
          'Where did most of my money go?',
          'How much budget do I have left?',
          'What is an SIP?',
        ],
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Phase 2: Secure Backend Proxy for General-Purpose AI
    // ─────────────────────────────────────────────────────────────────────────
    final backendUrl =
        await BackendConfig.getResolvedBackendUrl(backendUrlOverride);

    // Build payload with strict privacy guarantees
    final isPersonalFinancialQuery = _isPersonalFinancialQuery(query);
    final Map<String, dynamic> summaryPayload;
    if (userConsentedToDataAnalysis && isPersonalFinancialQuery) {
      summaryPayload = FinancialIntelligenceEngine.buildMinimalSummary(
        transactions: transactions,
        budgets: budgets,
        userConsented: true,
      )..['include_in_prompt'] = true;
    } else {
      summaryPayload = {
        'consent': userConsentedToDataAnalysis,
        'include_in_prompt': false,
      };
    }

    // Drop the trailing user message if it matches the current query to prevent turn duplication
    final effectiveHistory = conversationHistory.isNotEmpty &&
            conversationHistory.last.isUser &&
            conversationHistory.last.text.trim().toLowerCase() ==
                query.trim().toLowerCase()
        ? conversationHistory.sublist(0, conversationHistory.length - 1)
        : conversationHistory;

    final historyPayload = effectiveHistory
        .where((m) => m.text.isNotEmpty)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    final bodyData = jsonEncode({
      'message': query.trim(),
      'summary': summaryPayload,
      'history': historyPayload,
    });

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final requestUri = Uri.parse('$backendUrl/api/chat');
      final request = await client.postUrl(requestUri);
      request.headers.contentType = ContentType.json;
      request.write(bodyData);
      final response =
          await request.close().timeout(const Duration(seconds: 25));

      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> jsonResponse =
          responseBody.isNotEmpty ? jsonDecode(responseBody) : {};

      if (response.statusCode == 200 && jsonResponse.containsKey('reply')) {
        final replyText = jsonResponse['reply'] as String;
        return ChatMessage(
          id: 'ai_${now.millisecondsSinceEpoch}',
          isUser: false,
          timestamp: now,
          text: replyText,
          actionButtons: const [
            'How can I save ₹800 this month?',
            'Where did most of my money go?',
            'How much budget do I have left?',
          ],
        );
      }

      // Backend running but unconfigured (503)
      if (response.statusCode == 503 ||
          jsonResponse['error'] == 'Backend Unconfigured') {
        return ChatMessage(
          id: 'ai_${now.millisecondsSinceEpoch}',
          isUser: false,
          timestamp: now,
          isError: true,
          text:
              '⚙️ **Spentee AI Backend Setup Required**\n\n'
              'The secure AI backend server is active at `$backendUrl`, but `GEMINI_API_KEY` is not configured in `backend/.env`.\n\n'
              'Please configure your Gemini API key in `backend/.env` to enable general AI conversations.\n\n'
              '💡 *Your local financial calculations, budgets, and savings goals are fully operational offline!*',
          actionButtons: const [
            'Retry Connection',
            'How much did I spend today?',
            'Where did most of my money go?',
            'How much budget do I have left?',
          ],
        );
      }

      // Rate limit (429)
      if (response.statusCode == 429) {
        return ChatMessage(
          id: 'ai_${now.millisecondsSinceEpoch}',
          isUser: false,
          timestamp: now,
          text:
              '⏳ **AI Provider Rate Limit Reached**\n\n'
              'Spentee AI backend has momentarily hit upstream rate limits. Please wait a few seconds and tap Retry.',
          isError: true,
          actionButtons: const [
            'Retry Connection',
            'How much did I spend today?',
            'How much budget do I have left?',
          ],
        );
      }

      // Upstream Gateway Timeout (504)
      if (response.statusCode == 504 ||
          jsonResponse['error'] == 'Gateway Timeout') {
        return ChatMessage(
          id: 'ai_${now.millisecondsSinceEpoch}',
          isUser: false,
          timestamp: now,
          text:
              '⏱️ **AI Response Timed Out**\n\n'
              'The upstream AI service took too long to generate a response. Please tap Retry to try again.',
          isError: true,
          actionButtons: const [
            'Retry Connection',
            'How much did I spend today?',
            'Where did most of my money go?',
          ],
        );
      }

      // Other backend error
      final errMessage =
          jsonResponse['message'] ?? 'Unexpected server response (${response.statusCode}).';
      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        text:
            '⚠️ **AI Backend Service Error**\n\n$errMessage\n\nYou can retry your query or inspect your local financial totals.',
        isError: true,
        actionButtons: const [
          'Retry Connection',
          'How much did I spend today?',
          'Where did most of my money go?',
        ],
      );
    } catch (networkError) {
      debugPrint('AI backend URL $backendUrl unreachable: $networkError');
      return ChatMessage(
        id: 'ai_${now.millisecondsSinceEpoch}',
        isUser: false,
        timestamp: now,
        isError: true,
        text:
            '🔌 **Spentee AI Backend Offline**\n\n'
            'The secure AI backend is currently unreachable at `$backendUrl`.\n\n'
            'General conversational questions require the local backend proxy service. If the server was recently started or restarted, tap **Retry Connection** below to reconnect.\n\n'
            '💡 **Your financial data is completely safe:** all spending totals, budgets, and savings goals continue to calculate deterministically offline.',
        actionButtons: const [
          'Retry Connection',
          'How much did I spend today?',
          'How much did I earn this month?',
          'Where did most of my money go?',
          'How much budget do I have left?',
        ],
      );
    } finally {
      client?.close();
    }
  }

  /// Determines whether a user prompt explicitly requests personal financial advice,
  /// review, or analysis regarding their own accounts, budgets, or spending.
  static bool _isPersonalFinancialQuery(String query) {
    final lower = query.toLowerCase();
    final personalTriggers = [
      'my spend',
      'my budget',
      'my expense',
      'my income',
      'my money',
      'my transaction',
      'my finance',
      'my saving',
      'can i afford',
      'should i buy',
      'did i spend',
      'how much did i',
      'how much do i have',
      'review my',
      'analyze my',
      'break down my',
    ];
    return personalTriggers.any((trigger) => lower.contains(trigger));
  }
}

