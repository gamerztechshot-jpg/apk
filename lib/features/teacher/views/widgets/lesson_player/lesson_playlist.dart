import 'package:flutter/material.dart';
import '../../../model/course.dart';

class LessonPlaylist extends StatelessWidget {
  final List<Lesson> playlist;
  final int currentIndex;
  final Function(int) onLessonTap;

  const LessonPlaylist({
    super.key,
    required this.playlist,
    required this.currentIndex,
    required this.onLessonTap,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'Course Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: playlist.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final lesson = playlist[index];
              final isCurrent = index == currentIndex;

              return InkWell(
                onTap: () => onLessonTap(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.orange.shade50
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(color: Colors.orange.shade200)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Colors.orange.shade100
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCurrent
                              ? Icon(
                                  Icons.play_arrow,
                                  size: 16,
                                  color: Colors.orange.shade700,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isCurrent
                                    ? Colors.orange.shade900
                                    : Colors.black87,
                              ),
                            ),
                            // if (lesson.duration != null)
                            //   Text(
                            //     lesson.duration!,
                            //     style: TextStyle(
                            //       fontSize: 12,
                            //       color: Colors.grey.shade500,
                            //     ),
                            //   ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        const Icon(
                          Icons.equalizer,
                          color: Colors.orange,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
