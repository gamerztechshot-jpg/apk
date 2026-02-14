// features/mantra_generator/services/chat_service.dart
import '../repositories/user_ai_usage_repository.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final UserAIUsageRepository _repository = UserAIUsageRepository();

  /// Save chat message to chat history
  Future<void> saveChatMessage({
    required String userId,
    required ChatMessage message,
  }) async {
    try {
      await _repository.addChatMessage(
        userId: userId,
        message: message,
      );
    } catch (e) {
      throw Exception('Failed to save chat message: $e');
    }
  }

  /// Get chat history for user
  Future<List<ChatMessage>> getChatHistory(String userId) async {
    try {
      final usage = await _repository.getUserAIUsage(userId);
      if (usage == null) {
        // Initialize user if not exists
        await _repository.createUserAIUsage(userId);
        return [];
      }
      return usage.chatHistory;
    } catch (e) {
      return [];
    }
  }

  /// Get chat history for a specific problem
  Future<List<ChatMessage>> getChatHistoryForProblem(
    String userId,
    String problemId,
  ) async {
    try {
      final allHistory = await getChatHistory(userId);
      return allHistory
          .where((msg) => msg.problemId == problemId)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear chat history
  Future<void> clearChatHistory(String userId) async {
    try {
      await _repository.updateChatHistory(
        userId: userId,
        chatHistory: [],
      );
    } catch (e) {
      throw Exception('Failed to clear chat history: $e');
    }
  }

  /// Clear chat history for a specific problem
  Future<void> clearChatHistoryForProblem(
    String userId,
    String problemId,
  ) async {
    try {
      final allHistory = await getChatHistory(userId);
      final filteredHistory = allHistory
          .where((msg) => msg.problemId != problemId)
          .toList();

      await _repository.updateChatHistory(
        userId: userId,
        chatHistory: filteredHistory,
      );
    } catch (e) {
      throw Exception('Failed to clear chat history for problem: $e');
    }
  }

  /// Update accessed problems (add problem ID to accessed list)
  Future<void> updateAccessedProblems({
    required String userId,
    required String problemId,
  }) async {
    try {
      await _repository.addAccessedProblem(
        userId: userId,
        problemId: problemId,
      );
    } catch (e) {
      throw Exception('Failed to update accessed problems: $e');
    }
  }

  /// Check if problem has been accessed
  Future<bool> hasAccessedProblem(String userId, String problemId) async {
    try {
      final usage = await _repository.getUserAIUsage(userId);
      if (usage == null) return false;
      return usage.hasAccessedProblem(problemId);
    } catch (e) {
      return false;
    }
  }
}
