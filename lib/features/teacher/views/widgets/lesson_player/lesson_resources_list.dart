import 'package:flutter/material.dart';
import '../../../model/course.dart';
import 'pdf_resource_card.dart';
import 'quiz_resource_card.dart';

class LessonResourcesList extends StatelessWidget {
  final Lesson lesson;

  const LessonResourcesList({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    if ((lesson.pdfId?.isEmpty ?? true) && (lesson.quizId?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.folder_copy, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Lesson Resources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (lesson.pdfId != null) PdfResourceCard(pdfId: lesson.pdfId!),
        if (lesson.quizId != null) const SizedBox(height: 12),
        if (lesson.quizId != null) QuizResourceCard(quizId: lesson.quizId!),
      ],
    );
  }
}
