import 'package:flutter/material.dart';
import '../../../model/course.dart';

class CourseMetrics extends StatelessWidget {
  final Course course;

  const CourseMetrics({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            Icons.play_circle_fill,
            '${course.playlist.length} Lessons',
            Colors.blue.shade600,
          ),
          _buildMetricItem(
            Icons.groups,
            '${course.fakeEnrolledCount}+ Students',
            Colors.purple.shade600,
          ),
          _buildMetricItem(
            Icons.star,
            '${course.ratings} Rating',
            Colors.orange.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
