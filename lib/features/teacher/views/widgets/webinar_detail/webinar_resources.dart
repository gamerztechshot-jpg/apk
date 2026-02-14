import 'package:flutter/material.dart';
import '../../../model/webinar.dart';

class WebinarResources extends StatelessWidget {
  final Webinar webinar;
  final bool isEnrolled;

  const WebinarResources({
    super.key,
    required this.webinar,
    required this.isEnrolled,
  });

  @override
  Widget build(BuildContext context) {
    bool hasQuiz = webinar.quizId != null && webinar.quizId!.isNotEmpty;
    bool hasPdf = webinar.pdfId != null && webinar.pdfId!.isNotEmpty;

    if (!hasQuiz && !hasPdf) return const SizedBox.shrink();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                'Resources',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (!isEnrolled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.orange.shade800),
                      const SizedBox(width: 4),
                      Text(
                        'LOCKED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isEnrolled)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Enroll now to get access to PDF materials and practice quizzes.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 8),
          if (hasPdf)
            _buildResourceItem(
              Icons.picture_as_pdf,
              'Webinar Material (PDF)',
              isEnrolled ? Colors.red : Colors.grey,
              isEnrolled,
              () {
                // This shouldn't really be called if !isEnrolled but good practice
              },
            ),
          if (hasQuiz) ...[
            if (hasPdf) const SizedBox(height: 12),
            _buildResourceItem(
              Icons.quiz,
              'Practice Quiz',
              isEnrolled ? Colors.deepPurple : Colors.grey,
              isEnrolled,
              () {},
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourceItem(
    IconData icon,
    String label,
    Color color,
    bool enabled,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const Spacer(),
          if (!enabled)
            Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400)
          else
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color.withOpacity(0.6),
            ),
        ],
      ),
    );
  }
}
