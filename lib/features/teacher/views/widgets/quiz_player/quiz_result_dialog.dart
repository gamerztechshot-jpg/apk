import 'package:flutter/material.dart';

class QuizResultDialog extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final VoidCallback onDone;
  final VoidCallback onRetake;
  final VoidCallback onReview;

  const QuizResultDialog({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.onDone,
    required this.onRetake,
    required this.onReview,
  });
  @override
  Widget build(BuildContext context) {
    final isPassed = scorePercentage >= 60;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPassed ? Icons.celebration : Icons.sentiment_dissatisfied,
              size: 64,
              color: isPassed ? Colors.green : Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              isPassed ? 'Congratulations!' : 'Keep Practicing!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Your Score', style: TextStyle(color: Colors.grey)),
            Text(
              '${scorePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text('$correctAnswers / $totalQuestions correct'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: onReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 48),
                elevation: 0,
              ),
              child: Text('Review Correct Options'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetake,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade50,
                foregroundColor: Colors.orange,
                minimumSize: Size(double.infinity, 48),
                elevation: 0,
              ),
              child: Text('Retake Quiz'),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
