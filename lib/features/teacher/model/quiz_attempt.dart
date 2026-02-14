class QuizAttempt {
  final String id;
  final String userId;
  final String orderId;
  final String quizId;
  final String? courseId;
  final String status;
  final int totalQuestions;
  final int? correctAnswers;
  final double? scorePercentage;
  final Map<int, String> answers;
  final int currentQuestion;
  final int timeRemainingSec;
  final DateTime startedAt;
  final DateTime? completedAt;
  String? quizTitle;

  QuizAttempt({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.quizId,
    this.courseId,
    required this.status,
    required this.totalQuestions,
    this.correctAnswers,
    this.scorePercentage,
    required this.answers,
    required this.currentQuestion,
    required this.timeRemainingSec,
    required this.startedAt,
    this.completedAt,
    this.quizTitle,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};

    return QuizAttempt(
      id: json['id'],
      userId: json['user_id'],
      orderId: json['order_id'] ?? '',
      quizId: json['quiz_id'],
      courseId: json['course_id'],
      status: json['status'],
      totalQuestions: json['total_questions'],
      correctAnswers: json['correct_answers'],
      scorePercentage: json['score_percentage']?.toDouble(),
      answers: rawAnswers.map(
        (key, value) => MapEntry(int.parse(key), value as String),
      ),
      currentQuestion: json['current_question'],
      timeRemainingSec: json['time_remaining_sec'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      quizTitle: json['quizzes']?['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_id': orderId,
      'quiz_id': quizId,
      'course_id': courseId,
      'status': status,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'score_percentage': scorePercentage,
      'answers': answers.map((key, value) => MapEntry(key.toString(), value)),
      'current_question': currentQuestion,
      'time_remaining_sec': timeRemainingSec,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  bool get canResume => status == 'in_progress';
  bool get isCompleted => status == 'completed';
}
