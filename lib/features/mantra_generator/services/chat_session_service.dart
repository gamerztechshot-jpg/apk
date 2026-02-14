// features/mantra_generator/services/chat_session_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import '../repositories/user_ai_usage_repository.dart';

class ChatSession {
  final String sessionId;
  final String? problemId;
  final String? problemTitle;
  final String firstMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.sessionId,
    this.problemId,
    this.problemTitle,
    required this.firstMessage,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'problemId': problemId,
      'problemTitle': problemTitle,
      'firstMessage': firstMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'messageCount': messages.length,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId'] as String,
      problemId: json['problemId'] as String?,
      problemTitle: json['problemTitle'] as String?,
      firstMessage: json['firstMessage'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

class ChatSessionService {
  final UserAIUsageRepository _repository = UserAIUsageRepository();

  /// Generate a unique session ID
  String generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Get all chat sessions for a user
  Future<List<ChatSession>> getChatSessions(String userId) async {
    try {
      final usage = await _repository.getUserAIUsage(userId);
      if (usage == null) {
        return [];
      }

      // Get chat_question array which contains session info
      final chatQuestions = usage.chatQuestions;
      
      final allMessages = usage.chatHistory;
      
      final sessions = <ChatSession>[];

      // Create sessions from chat_question array
      // Process in reverse order (newest first) but only show unique sessions
      final seenSessionIds = <String>{};
      
      for (final question in chatQuestions.reversed) {
        final sessionId = question['sessionId'] as String?;
        final problemId = question['problemId'] as String?;
        final firstMessage = question['question'] as String? ?? '';
        final timestamp = question['timestamp'] as String?;
        
        
        // Only include sessions that have a valid sessionId and haven't been seen
        if (firstMessage.isNotEmpty && 
            timestamp != null && 
            sessionId != null &&
            !seenSessionIds.contains(sessionId)) {
          
          seenSessionIds.add(sessionId);
          
          // Filter messages by sessionId (not timestamp) - this ensures proper isolation
          final sessionMessagesList = allMessages
              .where((msg) {
                // Match by sessionId - this is the key to preventing merging
                return msg.sessionId == sessionId;
              })
              .toList();
          
          // Sort messages by timestamp to ensure correct order
          sessionMessagesList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          
          final sessionTime = DateTime.parse(timestamp);
          sessions.add(ChatSession(
            sessionId: sessionId,
            problemId: problemId,
            problemTitle: question['problemTitle'] as String?,
            firstMessage: firstMessage,
            createdAt: sessionTime,
            updatedAt: sessionMessagesList.isNotEmpty
                ? sessionMessagesList.last.timestamp
                : sessionTime,
            messages: sessionMessagesList,
          ));
        } else {
        }
      }

      return sessions;
    } catch (e) {
      return [];
    }
  }

  /// Save a chat session
  Future<void> saveChatSession({
    required String userId,
    required String sessionId,
    required String firstMessage,
    String? problemId,
    String? problemTitle,
    required List<ChatMessage> messages,
  }) async {
    try {
      
      final usage = await _repository.getUserAIUsage(userId);
      if (usage == null) {
        return;
      }

      final chatQuestions = List<Map<String, dynamic>>.from(usage.chatQuestions);
      
      // Check if session already exists
      final existingIndex = chatQuestions.indexWhere(
        (q) => q['sessionId'] == sessionId,
      );

      // Use the first message timestamp if available, otherwise use current time
      final sessionTimestamp = chatQuestions
          .where((q) => q['sessionId'] == sessionId)
          .map((q) => q['timestamp'] as String?)
          .firstOrNull ?? DateTime.now().toIso8601String();

      final sessionData = {
        'sessionId': sessionId,
        'question': firstMessage,
        'problemId': problemId,
        'problemTitle': problemTitle,
        'timestamp': sessionTimestamp, // Keep original timestamp if updating
        'messageCount': messages.length,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (existingIndex >= 0) {
        // Update existing session - preserve original timestamp
        final existingSession = chatQuestions[existingIndex];
        chatQuestions[existingIndex] = {
          ...existingSession,
          ...sessionData,
          'timestamp': existingSession['timestamp'] ?? sessionTimestamp, // Preserve original timestamp
        };
      } else {
        // Add new session - use current time for new sessions
        chatQuestions.add({
          ...sessionData,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      await _repository.updateChatQuestions(
        userId: userId,
        chatQuestions: chatQuestions,
      );
      
    } catch (e) {
    }
  }

  /// Delete a chat session
  Future<void> deleteChatSession({
    required String userId,
    required String sessionId,
  }) async {
    try {
      final usage = await _repository.getUserAIUsage(userId);
      if (usage == null) return;

      final chatQuestions = usage.chatQuestions
          .where((q) => q['sessionId'] != sessionId)
          .toList();

      await _repository.updateChatQuestions(
        userId: userId,
        chatQuestions: chatQuestions,
      );
    } catch (e) {
      // Silent fail
    }
  }
}
