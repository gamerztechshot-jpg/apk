// features/mantra_generator/repositories/user_ai_usage_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_ai_usage_model.dart';
import '../models/chat_message_model.dart';

class UserAIUsageRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's AI usage and credit status
  Future<UserAIUsage?> getUserAIUsage(String userId) async {
    try {
      final response = await _supabase
        .from('user_ai_usage')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

      if (response == null) {
        return null;
      }
      
      final usage = UserAIUsage.fromJson(response as Map<String, dynamic>);
      return usage;
    } catch (e) {
      return null;
    }
  }

  /// Create or initialize user AI usage (credits initialized via backend function)
  Future<UserAIUsage> createUserAIUsage(String userId) async {
    try {
      // Call backend function to initialize credits (gives 11 free credits)
      final response = await _supabase.rpc(
        'initialize_user_credits_on_access',
        params: {'p_user_id': userId},
      );

      if (response == null || (response as List).isEmpty) {
        throw Exception('Failed to initialize user credits');
      }

      // Get the initialized record
      final usageRecord = await getUserAIUsage(userId);
      if (usageRecord == null) {
        throw Exception('Failed to retrieve initialized user AI usage');
      }

      return usageRecord;
    } catch (e) {
      throw Exception('Failed to create user AI usage: $e');
    }
  }

  /// Update user credits
  Future<void> updateCredits({
    required String userId,
    required int freeCreditsLeft,
    required int topupCredits,
    required int creditsConsumed,
  }) async {
    try {
      await _supabase
          .from('user_ai_usage')
          .update({
            'free_credits_left': freeCreditsLeft,
            'topup_credits': topupCredits,
            'credits_consumed': creditsConsumed,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update credits: $e');
    }
  }

  /// Update accessed problems JSONB array
  Future<void> updateAccessedProblems({
    required String userId,
    required List<String> problemIds,
  }) async {
    try {
      await _supabase
          .from('user_ai_usage')
          .update({
            'accessed_problems': problemIds,
            'accessed_count': problemIds.length,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update accessed problems: $e');
    }
  }

  /// Add problem to accessed problems (append to array)
  Future<void> addAccessedProblem({
    required String userId,
    required String problemId,
  }) async {
    try {
      // Get current accessed problems
      final currentUsage = await getUserAIUsage(userId);
      if (currentUsage == null) {
        await createUserAIUsage(userId);
        final newUsage = await getUserAIUsage(userId);
        if (newUsage == null) throw Exception('Failed to create user AI usage');
      }

      final updatedUsage = await getUserAIUsage(userId);
      if (updatedUsage == null) {
        throw Exception('User AI usage not found');
      }

      // Check if already accessed
      if (updatedUsage.accessedProblems.contains(problemId)) {
        return; // Already accessed, no need to update
      }

      // Add to array
      final updatedList = [...updatedUsage.accessedProblems, problemId];

      await updateAccessedProblems(userId: userId, problemIds: updatedList);
    } catch (e) {
      throw Exception('Failed to add accessed problem: $e');
    }
  }

  /// Update chat history JSONB array
  Future<void> updateChatHistory({
    required String userId,
    required List<ChatMessage> chatHistory,
  }) async {
    try {
      final chatHistoryJson = chatHistory.map((msg) => msg.toJson()).toList();

      await _supabase
          .from('user_ai_usage')
          .update({
            'chat_history': chatHistoryJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update chat history: $e');
    }
  }

  /// Add message to chat history (append to array)
  Future<void> addChatMessage({
    required String userId,
    required ChatMessage message,
  }) async {
    try {
      // Get current chat history
      final currentUsage = await getUserAIUsage(userId);
      if (currentUsage == null) {
        await createUserAIUsage(userId);
        final newUsage = await getUserAIUsage(userId);
        if (newUsage == null) throw Exception('Failed to create user AI usage');
      }

      final updatedUsage = await getUserAIUsage(userId);
      if (updatedUsage == null) {
        throw Exception('User AI usage not found');
      }

      // Add to chat history
      final updatedHistory = [...updatedUsage.chatHistory, message];

      await updateChatHistory(userId: userId, chatHistory: updatedHistory);
    } catch (e) {
      throw Exception('Failed to add chat message: $e');
    }
  }

  /// Update chat questions JSONB array
  Future<void> updateChatQuestions({
    required String userId,
    required List<Map<String, dynamic>> chatQuestions,
  }) async {
    try {
      await _supabase
          .from('user_ai_usage')
          .update({
            'chat_question': chatQuestions,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update chat questions: $e');
    }
  }

  /// Add question to chat questions (append to array)
  Future<void> addChatQuestion({
    required String userId,
    required Map<String, dynamic> question,
  }) async {
    try {
      // Get current chat questions
      final currentUsage = await getUserAIUsage(userId);
      if (currentUsage == null) {
        await createUserAIUsage(userId);
        final newUsage = await getUserAIUsage(userId);
        if (newUsage == null) throw Exception('Failed to create user AI usage');
      }

      final updatedUsage = await getUserAIUsage(userId);
      if (updatedUsage == null) {
        throw Exception('User AI usage not found');
      }

      // Add to chat questions
      final updatedQuestions = [...updatedUsage.chatQuestions, question];

      await updateChatQuestions(
        userId: userId,
        chatQuestions: updatedQuestions,
      );
    } catch (e) {
      throw Exception('Failed to add chat question: $e');
    }
  }

  /// Update plan details JSONB
  Future<void> updatePlanDetails({
    required String userId,
    required Map<String, dynamic> planDetails,
  }) async {
    try {
      await _supabase
          .from('user_ai_usage')
          .update({
            'plan_details': planDetails,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update plan details: $e');
    }
  }

  /// Apply purchased package limits and details
  Future<void> applyPackagePurchase({
    required String userId,
    required Map<String, dynamic> planDetails,
    required int additionalQuestions,
    Map<String, dynamic>? contentAccess,
  }) async {
    try {
      final currentUsage = await getUserAIUsage(userId);
      if (currentUsage == null) {
        throw Exception('User AI usage not found');
      }

      await _supabase
          .from('user_ai_usage')
          .update({
            'plan_details': planDetails,
            'topup_credits': currentUsage.topupCredits + additionalQuestions,
            'content_access': contentAccess,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to apply package purchase: $e');
    }
  }

  /// Record AI usage (update credits and add to chat history)
  Future<void> recordAIUsage({
    required String userId,
    required String question,
    required String response,
    required int creditsDeducted,
    String? problemId,
  }) async {
    try {
      // Get current usage
      var currentUsage = await getUserAIUsage(userId);
      if (currentUsage == null) {
        currentUsage = await createUserAIUsage(userId);
      }

      // Create chat messages
      final userMessage = ChatMessage.user(
        text: question,
        problemId: problemId,
      );
      final aiMessage = ChatMessage.ai(
        text: response,
        problemId: problemId,
        creditsDeducted: creditsDeducted,
      );

      // Add to chat history
      await addChatMessage(userId: userId, message: userMessage);
      await addChatMessage(userId: userId, message: aiMessage);

      // Add to chat questions
      await addChatQuestion(
        userId: userId,
        question: {
          'question': question,
          'problemId': problemId,
          'timestamp': DateTime.now().toIso8601String(),
          'creditsDeducted': creditsDeducted,
        },
      );

      // Update credits consumed
      await _supabase
          .from('user_ai_usage')
          .update({
            'credits_consumed': currentUsage.creditsConsumed + creditsDeducted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to record AI usage: $e');
    }
  }
}
