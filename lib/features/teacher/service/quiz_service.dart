import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/quiz_attempt.dart';
import '../model/quiz.dart';

class QuizService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ================= START QUIZ =================

  /// Start a new quiz or resume existing in-progress attempt
  Future<QuizAttempt> startQuiz({
    required String quizId,
    String? courseId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // Check for existing in-progress attempt
    final existing = await getInProgressAttempt(userId, quizId);
    if (existing != null) {
      return existing;
    }

    // Get quiz details to know duration and total questions
    final quizData = await _supabase
        .from('quizzes')
        .select('total_questions, duration')
        .eq('quiz_id', quizId)
        .single();

    final totalQuestions = quizData['total_questions'] ?? 0;
    final durationMinutes = quizData['duration'] ?? 10;

    // Create new attempt
    final res = await _supabase
        .from('quiz_attempts')
        .insert({
          'user_id': userId,
          'quiz_id': quizId,
          'course_id': courseId,
          'status': 'in_progress',
          'total_questions': totalQuestions,
          'answers': {},
          'current_question': 0,
          'time_remaining_sec': durationMinutes * 60,
          'started_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return QuizAttempt.fromJson(res);
  }

  // ================= START / RESUME =================

  Future<QuizAttempt> startOrResumeQuiz({
    required String userId,
    required String quizId,
    String? courseId,
    required int totalQuestions,
    required int durationSeconds,
  }) async {
    final existing = await getInProgressAttempt(userId, quizId);

    if (existing != null) {
      return existing;
    }

    final res = await _supabase
        .from('quiz_attempts')
        .insert({
          'user_id': userId,
          'quiz_id': quizId,
          'course_id': courseId,
          'status': 'in_progress',
          'total_questions': totalQuestions,
          'answers': {},
          'current_question': 0,
          'time_remaining_sec': durationSeconds,
          'started_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return QuizAttempt.fromJson(res);
  }

  // ================= SAVE PROGRESS =================

  Future<bool> saveQuizProgress({
    required String attemptId,
    required int currentQuestion,
    required Map<int, String> answers,
    required int timeRemainingSec,
  }) async {
    try {
      await _supabase
          .from('quiz_attempts')
          .update({
            'current_question': currentQuestion,
            'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
            'time_remaining_sec': timeRemainingSec,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', attemptId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ================= COMPLETE QUIZ =================

  Future<QuizAttempt> completeQuiz({
    required String attemptId,
    required Map<int, String> answers,
    required List<QuizQuestion> questions,
  }) async {
    int correct = 0;

    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i].correctOption) {
        correct++;
      }
    }

    final score = questions.isEmpty ? 0.0 : (correct / questions.length) * 100;

    final res = await _supabase
        .from('quiz_attempts')
        .update({
          'status': 'completed',
          'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
          'correct_answers': correct,
          'score_percentage': score,
          'completed_at': DateTime.now().toIso8601String(),
          'time_remaining_sec': 0,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', attemptId)
        .select()
        .single();

    return QuizAttempt.fromJson(res);
  }

  // ================= ABANDON =================

  Future<void> abandonQuiz(String attemptId) async {
    await _supabase
        .from('quiz_attempts')
        .update({
          'status': 'abandoned',
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', attemptId);
  }

  // ================= HISTORY =================

  Future<List<QuizAttempt>> getUserQuizHistory(String userId) async {
    try {
      final res = await _supabase
          .from('quiz_attempts')
          .select()
          .eq('user_id', userId)
          .neq('status', 'in_progress')
          .order('started_at', ascending: false);

      final attempts = (res as List)
          .map((e) => QuizAttempt.fromJson(e))
          .toList();

      // Fetch all quizzes to map titles (more efficient than joining if relation is missing)
      final quizzesRes = await _supabase
          .from('quizzes')
          .select('quiz_id, title');
      final quizMap = {
        for (var q in (quizzesRes as List))
          q['quiz_id'].toString(): q['title'].toString(),
      };

      return attempts.map((a) {
        a.quizTitle = quizMap[a.quizId];
        return a;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<QuizAttempt?> getBestAttemptForQuiz(
    String userId,
    String quizId,
  ) async {
    final res = await _supabase
        .from('quiz_attempts')
        .select()
        .eq('user_id', userId)
        .eq('quiz_id', quizId)
        .eq('status', 'completed')
        .order('score_percentage', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) return null;
    return QuizAttempt.fromJson(res);
  }

  // ================= IN-PROGRESS =================

  Future<QuizAttempt?> getInProgressAttempt(
    String userId,
    String quizId,
  ) async {
    final res = await _supabase
        .from('quiz_attempts')
        .select()
        .eq('user_id', userId)
        .eq('quiz_id', quizId)
        .eq('status', 'in_progress')
        .maybeSingle();

    if (res == null) return null;
    return QuizAttempt.fromJson(res);
  }
}
