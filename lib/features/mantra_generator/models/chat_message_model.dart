// features/mantra_generator/models/chat_message_model.dart

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? problemId;
  final String? sessionId; // Add sessionId to track which session this message belongs to
  final int? creditsDeducted;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.problemId,
    this.sessionId,
    this.creditsDeducted,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String,
      isUser: json['isUser'] as bool? ?? json['is_user'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      problemId: json['problemId']?.toString() ?? json['problem_id']?.toString(),
      sessionId: json['sessionId']?.toString() ?? json['session_id']?.toString(),
      creditsDeducted: json['creditsDeducted'] as int? ?? json['credits_deducted'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'problemId': problemId,
      'sessionId': sessionId,
      'creditsDeducted': creditsDeducted,
    };
  }

  /// Create a user message
  factory ChatMessage.user({
    required String text,
    String? problemId,
    String? sessionId,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      problemId: problemId,
      sessionId: sessionId,
    );
  }

  /// Create an AI message
  factory ChatMessage.ai({
    required String text,
    String? problemId,
    String? sessionId,
    int? creditsDeducted,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      problemId: problemId,
      sessionId: sessionId,
      creditsDeducted: creditsDeducted,
    );
  }

  /// Get formatted timestamp
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
