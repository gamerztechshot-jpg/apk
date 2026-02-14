// features/mantra_generator/models/user_ai_usage_model.dart
import 'chat_message_model.dart';

class UserAIUsage {
  final String id;
  final String userId;
  final int freeCreditsLeft;
  final int topupCredits;
  final int creditsConsumed;
  final int accessedCount;
  final List<String> accessedProblems; // Array of problem IDs
  final List<ChatMessage> chatHistory; // Array of chat messages
  final List<Map<String, dynamic>> chatQuestions; // Array of questions
  final Map<String, dynamic> planDetails; // Package details JSONB
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserAIUsage({
    required this.id,
    required this.userId,
    this.freeCreditsLeft = 0,
    this.topupCredits = 0,
    this.creditsConsumed = 0,
    this.accessedCount = 0,
    this.accessedProblems = const [],
    this.chatHistory = const [],
    this.chatQuestions = const [],
    this.planDetails = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory UserAIUsage.fromJson(Map<String, dynamic> json) {
    // Parse accessed_problems JSONB array
    List<String> accessedProblemsList = [];
    if (json['accessed_problems'] != null) {
      if (json['accessed_problems'] is List) {
        accessedProblemsList = (json['accessed_problems'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      }
    }

    // Parse chat_history JSONB array
    List<ChatMessage> chatHistoryList = [];
    if (json['chat_history'] != null) {
      if (json['chat_history'] is List) {
        chatHistoryList = (json['chat_history'] as List<dynamic>)
            .map<ChatMessage>((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    // Parse chat_question JSONB array
    List<Map<String, dynamic>> chatQuestionsList = [];
    if (json['chat_question'] != null) {
      if (json['chat_question'] is List) {
        chatQuestionsList = (json['chat_question'] as List<dynamic>)
            .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
            .toList();
      }
    }

    // Parse plan_details JSONB
    Map<String, dynamic> planDetailsMap = {};
    if (json['plan_details'] != null) {
      if (json['plan_details'] is Map) {
        planDetailsMap = Map<String, dynamic>.from(
          json['plan_details'] as Map<dynamic, dynamic>,
        );
      }
    }

    return UserAIUsage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      freeCreditsLeft: json['free_credits_left'] as int? ?? 0,
      topupCredits: json['topup_credits'] as int? ?? 0,
      creditsConsumed: json['credits_consumed'] as int? ?? 0,
      accessedCount: json['accessed_count'] as int? ?? 0,
      accessedProblems: accessedProblemsList,
      chatHistory: chatHistoryList,
      chatQuestions: chatQuestionsList,
      planDetails: planDetailsMap,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'free_credits_left': freeCreditsLeft,
      'topup_credits': topupCredits,
      'credits_consumed': creditsConsumed,
      'accessed_count': accessedCount,
      'accessed_problems': accessedProblems,
      'chat_history': chatHistory.map((msg) => msg.toJson()).toList(),
      'chat_question': chatQuestions,
      'plan_details': planDetails,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get total available credits
  int get totalCredits => freeCreditsLeft + topupCredits;

  /// Check if user has accessed a problem
  bool hasAccessedProblem(String problemId) {
    return accessedProblems.contains(problemId);
  }

  /// Check if user has enough credits
  bool hasEnoughCredits(int required) {
    return totalCredits >= required;
  }

  /// Get AI question limit from plan details
  int? get aiQuestionLimit {
    return planDetails['aiQuestionLimit'] as int? ??
        planDetails['ai_question_limit'] as int?;
  }

  /// Get content access from plan details
  List<String> get contentAccess {
    final access = planDetails['contentAccess'] ?? planDetails['content_access'];
    if (access is List) {
      return access.map((e) => e.toString()).toList();
    }
    return [];
  }
}
