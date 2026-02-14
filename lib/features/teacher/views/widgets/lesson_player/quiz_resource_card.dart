import 'package:flutter/material.dart';
import '../../../service/teacher_service.dart';
import '../../../model/quiz.dart';
import 'resource_card.dart';

class QuizResourceCard extends StatelessWidget {
  final String quizId;

  const QuizResourceCard({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Quiz?>(
      future: TeacherService().getQuizById(quizId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final quiz = snapshot.data!;
        return ResourceCard(
          icon: Icons.quiz,
          color: Colors.purple,
          title: quiz.title,
          subtitle: '${quiz.totalQuestions} Questions • ${quiz.duration} mins',
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Starting Quiz...')));
          },
        );
      },
    );
  }
}
