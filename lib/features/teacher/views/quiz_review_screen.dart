import 'package:flutter/material.dart';
import '../model/quiz.dart';

class QuizReviewScreen extends StatelessWidget {
  final Quiz quiz;
  final Map<int, String> userAnswers;

  const QuizReviewScreen({
    super.key,
    required this.quiz,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Review Answers',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade600,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quiz.questions.length,
        itemBuilder: (context, index) {
          final question = quiz.questions[index];
          final userAnswer = userAnswers[index];
          final isCorrect = userAnswer == question.correctOption;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOption(
                    context,
                    'A',
                    question.optionA,
                    userAnswer,
                    question.correctOption,
                  ),
                  _buildOption(
                    context,
                    'B',
                    question.optionB,
                    userAnswer,
                    question.correctOption,
                  ),
                  _buildOption(
                    context,
                    'C',
                    question.optionC,
                    userAnswer,
                    question.correctOption,
                  ),
                  _buildOption(
                    context,
                    'D',
                    question.optionD,
                    userAnswer,
                    question.correctOption,
                  ),
                  const SizedBox(height: 12),
                  if (!isCorrect)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userAnswer == null ? 'Not Answered' : 'Incorrect',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Correct!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String label,
    String text,
    String? userAnswer,
    String correctOption,
  ) {
    bool isUserPick = userAnswer == label;
    bool isCorrect = correctOption == label;

    Color textColor = Colors.black87;
    Color bgColor = Colors.transparent;
    Color borderColor = Colors.grey.shade300;

    if (isCorrect) {
      textColor = Colors.green.shade700;
      bgColor = Colors.green.shade50;
      borderColor = Colors.green;
    } else if (isUserPick && !isCorrect) {
      textColor = Colors.red.shade700;
      bgColor = Colors.red.shade50;
      borderColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor)),
          ),
          if (isCorrect) const Icon(Icons.check, color: Colors.green, size: 16),
        ],
      ),
    );
  }
}
