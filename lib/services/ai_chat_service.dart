import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../models/roast.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
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

  /// Determines candidate backend URLs in priority order.
  /// Precedence:
  /// 1. urlOverride if provided
  /// 2. SPENTEE_AI_BACKEND_URL compile-time define
  /// 3. Android: ['http://10.0.2.2:3000', 'http://127.0.0.1:3000'] (handles QEMU NAT and ADB reverse)
  /// 4. Other platforms: ['http://localhost:3000']
  List<String> getCandidateBackendUrls([String? urlOverride]) {
    if (urlOverride != null && urlOverride.trim().isNotEmpty) {
      return [urlOverride.trim()];
    }
    const envUrl = String.fromEnvironment('SPENTEE_AI_BACKEND_URL');
    if (envUrl.isNotEmpty) {
      return [envUrl];
    }
    if (!kIsWeb && Platform.isAndroid) {
      return const ['http://10.0.2.2:3000', 'http://127.0.0.1:3000'];
    }
    return const ['http://localhost:3000'];
  }

  /// Active default backend URL
  String getBackendUrl([String? urlOverride]) {
    return getCandidateBackendUrls(urlOverride).first;
  }

  /// Check backend health status with multi-candidate fallback.
  Future<Map<String, dynamic>> checkBackendHealth([String? urlOverride]) async {
    final candidateUrls = getCandidateBackendUrls(urlOverride);
    Map<String, dynamic> lastResult = {
      'status': 'offline',
      'error': 'No reachable backend',
    };

    for (final baseUrl in candidateUrls) {
      HttpClient? client;
      try {
        client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
        final request = await client.getUrl(Uri.parse('$baseUrl/health'));
        final response =
            await request.close().timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          data['activeUrl'] = baseUrl;
          return data;
        }
        lastResult = {
          'status': 'error',
          'statusCode': response.statusCode,
          'activeUrl': baseUrl,
        };
      } catch (e) {
        lastResult = {
          'status': 'offline',
          'error': e.toString(),
          'attemptedUrl': baseUrl,
        };
      } finally {
        client?.close();
      }
    }
    return lastResult;
  }

  /// Generate a contextual response from Spentee AI.
  /// 1. Tries deterministic personal finance calculation first (100% accurate, local).
  /// 2. If general question, connects to secure proxy backend (no raw data leaked).
  /// 3. If backend is offline or unconfigured, explains setup cleanly.
  Future<ChatMessage> generateResponse({
    required String query,
    required List<Transaction> transactions,
    List<Budget> budgets = const [],
    List<SavingsGoal> savingsGoals = const [],
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
    // Phase 2: Secure Backend Proxy for General-Purpose AI
    // ─────────────────────────────────────────────────────────────────────────
    final candidateUrls = getCandidateBackendUrls(backendUrlOverride);

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

    String targetUrl = candidateUrls.first;
    dynamic lastNetworkError;

    for (final backendUrl in candidateUrls) {
      targetUrl = backendUrl;
      HttpClient? client;

      try {
        client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
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
            'How much did I spend today?',
            'Where did most of my money go?',
          ],
        );
      } catch (networkError) {
        lastNetworkError = networkError;
        debugPrint('Candidate AI backend URL $backendUrl unreachable: $networkError');
        // If there's another candidate URL (e.g. adb reverse vs 10.0.2.2), try next
        continue;
      } finally {
        client?.close();
      }
    }

    // All candidate URLs failed -> Clean, friendly offline system notice
    debugPrint('All candidate AI backend URLs unreachable. Last error: $lastNetworkError');
    return ChatMessage(
      id: 'ai_${now.millisecondsSinceEpoch}',
      isUser: false,
      timestamp: now,
      isError: true,
      text:
          '🔌 **Spentee AI Backend Offline**\n\n'
          'Could not reach the local Spentee AI backend service at `$targetUrl`.\n\n'
          '• General conversational questions require the local backend service.\n'
          '• You can start the service using **start_backend.bat** (or `cd backend` and run `npm start`).\n\n'
          '💡 **All personal finance features** (spending totals, monthly budgets, savings goals, category insights) calculate deterministically on this device and are 100% active offline.',
      actionButtons: const [
        'How much did I spend today?',
        'How much did I earn this month?',
        'Where did most of my money go?',
        'How much budget do I have left?',
      ],
    );
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
