import 'package:flutter/material.dart';
import '../../../model/quiz.dart';
import '../../../service/teacher_service.dart';
import '../lesson_player/resource_card.dart';
import '../../../../../routes.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../lesson_player/pdf_viewer_screen.dart';

class WebinarResourceCard extends StatelessWidget {
  final String? pdfId;
  final String? quizId;

  const WebinarResourceCard({super.key, this.pdfId, this.quizId});

  Future<File> _downloadPdf(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/webinar_material.pdf');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    if (pdfId != null) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: TeacherService().getPdfById(pdfId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return _loading();

          final pdf = snapshot.data!;
          final title = pdf['title'] ?? 'Webinar Material';
          final url = pdf['pdf_url'];

          return ResourceCard(
            icon: Icons.picture_as_pdf,
            color: Colors.orangeAccent,
            title: title,
            subtitle: 'Webinar PDF Document',
            onTap: () async {
              final file = await _downloadPdf(url);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(file: file, title: title),
                ),
              );
            },
          );
        },
      );
    }

    if (quizId != null) {
      return FutureBuilder<Quiz?>(
        future: TeacherService().getQuizById(quizId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return _loading();

          final quiz = snapshot.data!;
          return ResourceCard(
            icon: Icons.quiz,
            color: Colors.purple,
            title: quiz.title,
            subtitle:
                '${quiz.totalQuestions} Questions • ${quiz.duration} mins',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.quizPlayer,
                arguments: {'quiz': quiz, 'courseId': null},
              );
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _loading() => Container(
    height: 70,
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}
