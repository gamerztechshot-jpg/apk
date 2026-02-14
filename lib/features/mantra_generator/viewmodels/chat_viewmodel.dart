// features/mantra_generator/viewmodels/chat_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/language_service.dart';
import '../models/chat_message_model.dart';
import '../services/mantra_ai_service.dart';
import '../services/chat_service.dart';
import '../services/credit_service.dart';
import '../services/access_control_service.dart';
import '../services/chat_session_service.dart';
import '../repositories/user_ai_usage_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final MantraAIService _aiService = MantraAIService();
  final ChatService _chatService = ChatService();
  final CreditService _creditService = CreditService();
  final UserAIUsageRepository _usageRepository = UserAIUsageRepository();
  final ChatSessionService _sessionService = ChatSessionService();

  List<ChatMessage> _messages = [];
  dynamic _currentProblem; // MainProblem or SubProblem
  int _credits = 0;
  bool _isLoading = false;
  String? _error;
  String? _userId;
  String? _sessionId;
  String? _firstMessage;
  String? _language; // "hi" or "en"
  
  // Method to update language dynamically
  void updateLanguage(String languageCode) {
    if (_language != languageCode) {
      _language = languageCode;
      notifyListeners();
    }
  }

  // Getters
  List<ChatMessage> get messages => _messages;
  dynamic get currentProblem => _currentProblem;
  int get credits => _credits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize chat for a problem (always starts new chat unless sessionId provided)
  Future<void> initializeChat({
    required String userId,
    required dynamic problem, // MainProblem or SubProblem
    String? sessionId, // If provided, load existing session
    String? language, // "hi" or "en"
  }) async {
    _language = language ?? "hi"; // Default to Hindi
    _userId = userId;
    _currentProblem = problem;

    try {
      // If sessionId provided, load that session's messages
      if (sessionId != null && sessionId.isNotEmpty) {
        final sessions = await _sessionService.getChatSessions(userId);
        final session = sessions.where((s) => s.sessionId == sessionId).firstOrNull;
        if (session != null) {
          // Load messages and ensure they all have the correct sessionId
          _messages = session.messages.map((msg) {
            // Ensure sessionId is set on all loaded messages
            if (msg.sessionId != sessionId) {
              return ChatMessage(
                id: msg.id,
                text: msg.text,
                isUser: msg.isUser,
                timestamp: msg.timestamp,
                problemId: msg.problemId,
                sessionId: sessionId, // Ensure sessionId is set
                creditsDeducted: msg.creditsDeducted,
              );
            }
            return msg;
          }).toList();
          _firstMessage = session.firstMessage;
          _sessionId = sessionId; // Ensure sessionId is set
        } else {
          // Session not found, start new
          _messages = [];
          _sessionId = _sessionService.generateSessionId();
          _firstMessage = null;
        }
      } else {
        // Always start with empty messages for new chat - generate NEW sessionId
        _messages = [];
        _sessionId = _sessionService.generateSessionId();
        _firstMessage = null;
      }

      // Load credits
      await _loadCredits();

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize chat: ${e.toString()}');
    }
  }

  // Save chat session
  Future<void> saveChatSession() async {
    if (_userId == null) {
      return;
    }
    
    // Save even if messages are empty (might be a new session that was just started)
    if (_messages.isEmpty) {
    }

    try {
      
      // Get problem title
      String? problemTitle;
      String? problemId;
      if (_currentProblem != null) {
        problemId = _currentProblem.id;
        // Try to get title from problem object
        try {
          problemTitle = _currentProblem.getTitle('en') ?? 
                        _currentProblem.getTitle('hi');
        } catch (e) {
          problemTitle = null;
        }
      }

      // Get first user message
      String finalFirstMessage;
      if (_firstMessage != null && _firstMessage!.isNotEmpty) {
        finalFirstMessage = _firstMessage!;
      } else if (_messages.isNotEmpty) {
        final firstUserMessage = _messages.firstWhere(
          (msg) => msg.isUser,
          orElse: () => ChatMessage.user(text: 'New Chat'),
        );
        finalFirstMessage = firstUserMessage.text;
      } else {
        finalFirstMessage = 'New Chat';
      }

      final finalSessionId = _sessionId ?? _sessionService.generateSessionId();
      _sessionId = finalSessionId; // Ensure sessionId is set


      await _sessionService.saveChatSession(
        userId: _userId!,
        sessionId: finalSessionId,
        firstMessage: finalFirstMessage,
        problemId: problemId,
        problemTitle: problemTitle,
        messages: _messages,
      );
      
    } catch (e) {
    }
  }

  // Send message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _userId == null || _currentProblem == null) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      // Ensure sessionId is set before creating messages
      if (_sessionId == null || _sessionId!.isEmpty) {
        _sessionId = _sessionService.generateSessionId();
      }

      // Create user message with sessionId
      final userMessage = ChatMessage.user(
        text: text.trim(),
        problemId: _currentProblem.id,
        sessionId: _sessionId,
      );

      // Store first message for session
      if (_firstMessage == null && _messages.isEmpty) {
        _firstMessage = text.trim();
      }

      // Add user message to UI immediately
      _messages.add(userMessage);
      notifyListeners();

      // Check credits before sending
      const aiQuestionCreditCost = 1;
      final hasCredits = await _creditService.checkCreditsAvailable(
        _userId!,
        aiQuestionCreditCost,
      );

      if (!hasCredits) {
        _setError(
          'Insufficient credits. You need $aiQuestionCreditCost credit to ask a question.',
        );
        _messages.removeLast(); // Remove user message
        notifyListeners();
        return;
      }

      // Generate mantra using AI
      // Build chat history from all messages (including the new user message)
      final chatHistory = _messages;


      // Edge Function now handles credit deduction and storage
      final mantra = await _aiService.generateMantra(
        text: text.trim(),
        problemId: _currentProblem.id,
        userId: _userId,
        sessionId: _sessionId,
        chatHistory: chatHistory.isNotEmpty ? chatHistory : null,
        language: _language ?? "hi", // Pass language parameter
      );
      

      
      // Create AI message with sessionId
      final aiMessage = ChatMessage.ai(
        text: mantra,
        problemId: _currentProblem.id,
        sessionId: _sessionId,
        creditsDeducted: aiQuestionCreditCost,
      );


      // Add AI message to UI
      _messages.add(aiMessage);

      // Refresh credits (Edge Function already deducted)
      await _loadCredits();

      // Ensure loading state is cleared
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to send message: ${e.toString()}');
      // Remove user message if error
      if (_messages.isNotEmpty && _messages.last.isUser) {
        _messages.removeLast();
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Clear chat
  Future<void> clearChat() async {
    if (_userId == null || _currentProblem == null) return;

    try {
      await _chatService.clearChatHistoryForProblem(
        _userId!,
        _currentProblem.id,
      );
      _messages.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear chat: ${e.toString()}');
    }
  }

  // Load chat history
  Future<void> loadChatHistory() async {
    if (_userId == null || _currentProblem == null) return;

    try {
      final history = await _chatService.getChatHistoryForProblem(
        _userId!,
        _currentProblem.id,
      );
      _messages = history;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load chat history: ${e.toString()}');
    }
  }

  // Load credits
  Future<void> _loadCredits() async {
    if (_userId == null) return;

    try {
      _credits = await _creditService.getTotalCredits(_userId!);
      notifyListeners();
    } catch (e) {
      // Silent fail for credits
    }
  }

  // Refresh credits
  Future<void> refreshCredits() async {
    await _loadCredits();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Handle initial message from navigation
  Future<void> handleInitialMessage(String? message) async {
    if (message != null && message.trim().isNotEmpty) {
      // Wait a bit for initialization to complete if needed
      await Future.delayed(const Duration(milliseconds: 500));
      await sendMessage(message);
    }
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
}
