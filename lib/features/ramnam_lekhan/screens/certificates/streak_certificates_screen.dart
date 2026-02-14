// features/ramnam_lekhan/screens/certificates/streak_certificates_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/streak_certificate_model.dart';
import '../../../../core/services/certificate_service.dart';
import '../../../../core/widgets/streak_certificate_card_widget.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/auth_service.dart';

class StreakCertificatesScreen extends StatefulWidget {
  const StreakCertificatesScreen({super.key});

  @override
  State<StreakCertificatesScreen> createState() =>
      _StreakCertificatesScreenState();
}

class _StreakCertificatesScreenState extends State<StreakCertificatesScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? 'स्ट्रीक प्रमाणपत्र' : 'Streak Certificates',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<StreakService>(
        builder: (context, streakService, child) {
          final currentStreakDays = streakService.currentStreak;
          final unlockedCertificates =
              CertificateService.getUnlockedStreakCertificates(
                [],
                currentStreakDays,
              );
          final nextCertificate = CertificateService.getNextStreakCertificate(
            [],
            currentStreakDays,
          );

          return Column(
            children: [
              // Header section
              Container(
                width: double.infinity,
                color: Colors.white,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          isHindi
                              ? 'स्ट्रीक प्रमाणपत्र'
                              : 'Streak Certificates',
                          style: const TextStyle(
                            color: Color(0xFF2C3E50),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Subtitle
                        Text(
                          isHindi
                              ? 'लगातार अभ्यास के आधार पर प्रमाणपत्र अनलॉक करें'
                              : 'Unlock certificates based on continuous practice',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Stats cards
                        Row(
                          children: [
                            // Current streak
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF2E7D32),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isHindi
                                              ? 'वर्तमान स्ट्रीक'
                                              : 'Current Streak',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$currentStreakDays ${isHindi ? 'दिन' : 'days'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Unlocked certificates count
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2196F3),
                                      Color(0xFF1976D2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2196F3,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isHindi ? 'खुले' : 'Unlocked',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${unlockedCertificates.length}/${StreakCertificateModel.allCertificates.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Next certificate preview
              if (nextCertificate != null) ...[
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isHindi ? 'अगला प्रमाणपत्र' : 'Next Certificate',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nextCertificate.getName(isHindi: isHindi),
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHindi
                            ? 'अनलॉक करने के लिए ${(nextCertificate?.streakDays ?? 0) - currentStreakDays} और दिनों का अभ्यास करें'
                            : 'Practice ${(nextCertificate?.streakDays ?? 0) - currentStreakDays} more days to unlock',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Certificates list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: StreakCertificateModel.allCertificates.length,
                  itemBuilder: (context, index) {
                    final certificate =
                        StreakCertificateModel.allCertificates[index];
                    return StreakCertificateCardWidget(
                      certificate: certificate,
                      currentStreakDays: currentStreakDays,
                      onDownload: _isLoading
                          ? null
                          : () => _downloadCertificate(
                              certificate: certificate,
                              currentStreakDays: currentStreakDays,
                            ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadCertificate({
    required StreakCertificateModel certificate,
    required int currentStreakDays,
  }) async {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!CertificateService.hasAchievedStreakCertificateModel(
      certificate,
      currentStreakDays,
    )) {
      _showSnackBar(
        languageService.isHindi
            ? 'प्रमाणपत्र अभी तक नहीं खुला!'
            : 'Certificate not unlocked yet!',
        isError: true,
      );
      return;
    }

    // Get actual user name from auth service
    final currentUser = authService.getCurrentUser();
    final userName =
        currentUser?.userMetadata?['name'] ??
        currentUser?.email?.split('@')[0] ??
        'User';

    setState(() {
      _isLoading = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating streak certificate...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate PDF
      final pdfBytes =
          await CertificateService.generateStreakCertificateModelPdf(
            certificate,
            userName,
            'assets/images/logo.jpg',
            isHindi: languageService.isHindi,
          );

      // Get file name
      final fileName = _getStreakCertificateFileName(
        certificate: certificate,
        userName: userName,
      );

      // Try to save to device, fallback to share if on web
      try {
        await CertificateService.saveCertificateToDevice(pdfBytes, fileName);
      } catch (e) {
        // If saving fails (e.g., on web), use share functionality
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              '🔥 Check out my streak certificate!\n\n📿 Join me on KARMASU - Digital Hindu Gurukul\n🔗 Download: https://play.google.com/store/apps/details?id=com.app.mokshada',
          subject: 'My Streak Achievement Certificate',
        );
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        _showSnackBar(
          languageService.isHindi
              ? 'प्रमाणपत्र सफलतापूर्वक सहेजा गया!'
              : 'Certificate saved successfully!',
          isError: false,
        );
      }

      // Provide haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        _showSnackBar(
          languageService.isHindi
              ? 'प्रमाणपत्र बनाने में विफल: $e'
              : 'Failed to generate certificate: $e',
          isError: true,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStreakCertificateFileName({
    required StreakCertificateModel certificate,
    required String userName,
  }) {
    final sanitizedName = userName
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${certificate.name.replaceAll(' ', '_')}_${sanitizedName}_$timestamp.pdf';
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade600
              : Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // If ScaffoldMessenger fails, just print the message
    }
  }
}
