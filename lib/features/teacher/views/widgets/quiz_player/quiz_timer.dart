import 'package:flutter/material.dart';

class QuizTimer extends StatelessWidget {
  final int secondsRemaining;

  const QuizTimer({super.key, required this.secondsRemaining});

  String get _formattedTime {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _color {
    if (secondsRemaining <= 60) return Colors.red;
    if (secondsRemaining <= 300) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(Icons.timer, color: _color),
          const SizedBox(width: 4),
          Text(
            _formattedTime,
            style: TextStyle(color: _color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
