// features/teacher/views/view_all_quizzes_screen.dart
import 'package:flutter/material.dart';
import '../../../../routes.dart';
import '../model/quiz.dart';
import 'widgets/quiz_card.dart';

class ViewAllQuizzesScreen extends StatelessWidget {
  final List<Quiz> quizzes;

  const ViewAllQuizzesScreen({super.key, required this.quizzes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Quizzes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: quizzes.isEmpty
          ? const Center(child: Text('No quizzes available'))
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.15,
              ),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return QuizCard(
                  quiz: quiz,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.quizPlayer,
                      arguments: {'quiz': quiz, 'courseId': null},
                    );
                  },
                );
              },
            ),
    );
  }
}
