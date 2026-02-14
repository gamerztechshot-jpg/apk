import 'dart:convert';

class QuizQuestion {
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;

  QuizQuestion({
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // Support various naming conventions for options
    String getOption(String key, String fallbackKey, String numKey, int index) {
      if (json.containsKey(key)) return json[key]?.toString() ?? '';
      if (json.containsKey(fallbackKey))
        return json[fallbackKey]?.toString() ?? '';
      if (json.containsKey(numKey)) return json[numKey]?.toString() ?? '';
      if (json.containsKey('option_$numKey'))
        return json['option_$numKey']?.toString() ?? '';

      final options = json['options'];
      if (options != null) {
        if (options is List && options.length > index) {
          return options[index]?.toString() ?? '';
        }
        if (options is Map) {
          final letters = ['A', 'B', 'C', 'D'];
          final letter = letters[index];
          return options[letter]?.toString() ??
              options[letter.toLowerCase()]?.toString() ??
              options[numKey]?.toString() ??
              '';
        }
      }
      return '';
    }

    return QuizQuestion(
      question: json['question'] ?? '',
      optionA: getOption('option_a', 'optionA', '1', 0),
      optionB: getOption('option_b', 'optionB', '2', 1),
      optionC: getOption('option_c', 'optionC', '3', 2),
      optionD: getOption('option_d', 'optionD', '4', 3),
      correctOption: json['correct_option'] ?? json['correctOption'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
    };
  }
}

class Quiz {
  final String quizId;
  final String category;
  final String title;
  final String description;
  final int totalQuestions;
  final int duration;
  final List<QuizQuestion> questions;
  final String status;
  final DateTime createdAt;
  final String teacherId;
  final bool isAdmin;

  Quiz({
    required this.quizId,
    required this.category,
    required this.title,
    required this.description,
    required this.totalQuestions,
    required this.duration,
    required this.questions,
    required this.status,
    required this.createdAt,
    required this.teacherId,
    required this.isAdmin,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      quizId: json['quiz_id'] ?? '',
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      totalQuestions: json['total_questions'] ?? 0,
      duration: json['duration'] ?? 0,
      questions: _parseQuestions(json['questions']),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      teacherId: json['teacher_id'] ?? '',
      isAdmin: json['is_admin'] ?? false,
    );
  }

  static List<QuizQuestion> _parseQuestions(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data
          .map((i) => QuizQuestion.fromJson(i as Map<String, dynamic>))
          .toList();
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return decoded
              .map((i) => QuizQuestion.fromJson(i as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
      }
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_id': quizId,
      'category': category,
      'title': title,
      'description': description,
      'total_questions': totalQuestions,
      'duration': duration,
      'questions': questions.map((i) => i.toJson()).toList(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'teacher_id': teacherId,
      'is_admin': isAdmin,
    };
  }

  // Convenience getters
  String get id => quizId;
  int get timeLimitSec =>
      duration * 60; // duration is in minutes, convert to seconds
}
