import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../service/teacher_service.dart';
import 'resource_card.dart';
import 'pdf_viewer_screen.dart';

class PdfResourceCard extends StatelessWidget {
  final String pdfId;

  const PdfResourceCard({super.key, required this.pdfId});

  Future<File> _downloadPdf(String url) async {
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/lesson.pdf');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: TeacherService().getPdfById(pdfId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loading();

        final pdf = snapshot.data!;
        final title = pdf['title'] ?? 'Lesson Material';
        final url = pdf['pdf_url'];

        return ResourceCard(
          icon: Icons.picture_as_pdf,
          color: Colors.orangeAccent,
          title: title,
          subtitle: 'PDF Document',
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

  Widget _loading() => Container(
    height: 70,
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Center(child: CircularProgressIndicator()),
  );
}
