import 'package:flutter/material.dart';
import 'package:karmasu/features/teacher/model/quiz.dart';
import 'quiz_option_tile.dart';

class QuizQuestionCard extends StatelessWidget {
  final int questionNumber;
  final QuizQuestion question;
  final String? selectedOption;
  final Function(String) onOptionSelected;

  const QuizQuestionCard({
    super.key,
    required this.questionNumber,
    required this.question,
    this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question $questionNumber',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          QuizOptionTile(
            option: 'A',
            text: question.optionA,
            isSelected: selectedOption == 'A',
            onTap: () => onOptionSelected('A'),
          ),
          QuizOptionTile(
            option: 'B',
            text: question.optionB,
            isSelected: selectedOption == 'B',
            onTap: () => onOptionSelected('B'),
          ),
          QuizOptionTile(
            option: 'C',
            text: question.optionC,
            isSelected: selectedOption == 'C',
            onTap: () => onOptionSelected('C'),
          ),
          QuizOptionTile(
            option: 'D',
            text: question.optionD,
            isSelected: selectedOption == 'D',
            onTap: () => onOptionSelected('D'),
          ),
        ],
      ),
    );
  }
}
