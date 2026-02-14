import 'package:flutter/material.dart';
import '../model/webinar.dart';
import 'widgets/app_video_player.dart';
import 'widgets/webinar_detail/webinar_resource_card.dart';

class WebinarPlayerScreen extends StatelessWidget {
  final Webinar webinar;

  const WebinarPlayerScreen({super.key, required this.webinar});

  @override
  Widget build(BuildContext context) {
    bool hasQuiz = webinar.quizId != null && webinar.quizId!.isNotEmpty;
    bool hasPdf = webinar.pdfId != null && webinar.pdfId!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          webinar.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Section
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: webinar.videoLink.isNotEmpty
                    ? AppVideoPlayer(
                        url: webinar.videoLink,
                        title: webinar.title,
                      )
                    : _buildPlaceholderVideo(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About this Webinar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    webinar.description,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  if (hasPdf || hasQuiz) ...[
                    const Row(
                      children: [
                        Icon(Icons.folder_copy, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          'Webinar Resources',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (hasPdf) WebinarResourceCard(pdfId: webinar.pdfId),
                    if (hasQuiz) ...[
                      if (hasPdf) const SizedBox(height: 12),
                      WebinarResourceCard(quizId: webinar.quizId),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderVideo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Interactive content will be available during/after session',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
