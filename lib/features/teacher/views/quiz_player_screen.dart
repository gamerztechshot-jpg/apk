import 'dart:async';
import 'package:flutter/material.dart';
import 'package:karmasu/features/teacher/service/quiz_service.dart';
import 'quiz_review_screen.dart';

import '../../teacher/model/quiz.dart';
import '../../teacher/model/quiz_attempt.dart';
import 'widgets/quiz_player/quiz_progress_bar.dart';
import 'widgets/quiz_player/quiz_question_card.dart';
import 'widgets/quiz_player/quiz_timer.dart';
import 'widgets/quiz_player/quiz_result_dialog.dart';

class QuizPlayerScreen extends StatefulWidget {
  final Quiz quiz;
  final String? courseId;

  const QuizPlayerScreen({super.key, required this.quiz, this.courseId});

  @override
  State<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<QuizPlayerScreen> {
  late QuizService _quizService;
  QuizAttempt? _attempt;

  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  Map<int, String> _answers = {};
  int _timeRemainingSec = 0;

  Timer? _timer;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    setState(() => _isLoading = true);
    final attempt = await _quizService.startQuiz(
      quizId: widget.quiz.id,
      courseId: widget.courseId,
    );

    setState(() {
      _attempt = attempt;
      _answers = Map<int, String>.from(attempt.answers);
      _currentQuestionIndex = attempt.currentQuestion;
      _timeRemainingSec = attempt.timeRemainingSec;
      _isLoading = false;
    });

    _startTimer();
    _startAutoSave();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemainingSec <= 0) {
        timer.cancel();
        _submitQuiz();
      } else {
        setState(() => _timeRemainingSec--);
      }
    });
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    if (_attempt == null) return;

    await _quizService.saveQuizProgress(
      attemptId: _attempt!.id,
      currentQuestion: _currentQuestionIndex,
      answers: _answers,
      timeRemainingSec: _timeRemainingSec,
    );
  }

  void _selectAnswer(String option) {
    setState(() {
      _answers[_currentQuestionIndex] = option;
    });
    _saveProgress();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  Future<void> _submitQuiz() async {
    if (_attempt == null) return;

    _timer?.cancel();
    _autoSaveTimer?.cancel();

    setState(() => _isLoading = true);

    final result = await _quizService.completeQuiz(
      attemptId: _attempt!.id,
      answers: _answers,
      questions: widget.quiz.questions,
    );

    setState(() {
      _attempt = result;
      _isLoading = false;
    });

    _showResultDialog();
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuizResultDialog(
        totalQuestions: widget.quiz.totalQuestions,
        correctAnswers: _attempt!.correctAnswers!,
        scorePercentage: _attempt!.scorePercentage!,
        onDone: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onRetake: () {
          Navigator.pop(context);
          setState(() {
            _currentQuestionIndex = 0;
            _answers = {};
          });
          _initializeQuiz();
        },
        onReview: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuizReviewScreen(quiz: widget.quiz, userAnswers: _answers),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = widget.quiz.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [QuizTimer(secondsRemaining: _timeRemainingSec)],
      ),
      body: Column(
        children: [
          QuizProgressBar(
            current: _currentQuestionIndex + 1,
            total: widget.quiz.questions.length,
          ),
          Expanded(
            child: QuizQuestionCard(
              questionNumber: _currentQuestionIndex + 1,
              question: question,
              selectedOption: _answers[_currentQuestionIndex],
              onOptionSelected: _selectAnswer,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigationButtons(),
    );
  }

  Widget _buildNavigationButtons() {
    final isLast = _currentQuestionIndex == widget.quiz.questions.length - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentQuestionIndex > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousQuestion,
                  child: const Text('Previous'),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isLast ? _submitQuiz : _nextQuestion,
                child: Text(isLast ? 'Submit' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
