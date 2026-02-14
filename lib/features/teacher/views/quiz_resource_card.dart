import 'package:flutter/material.dart';
import 'package:karmasu/features/teacher/model/quiz.dart';
import 'package:karmasu/features/teacher/views/quiz_player_screen.dart';

class QuizResourceCard extends StatelessWidget {
  final Quiz quiz;

  const QuizResourceCard({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(quiz.title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizPlayerScreen(quiz: quiz, courseId: null),
          ),
        );
      },
    );
  }
}
