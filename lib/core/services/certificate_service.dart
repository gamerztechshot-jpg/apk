// core/services/certificate_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/certificate_model.dart';
import '../models/streak_certificate_model.dart';
import 'cache_service.dart';

class CertificateService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _currentUserId;
  List<CertificateModel> _certificates = [];
  List<CertificateModel> _streakCertificates = [];

  List<CertificateModel> get certificates => _certificates;
  List<CertificateModel> get streakCertificates => _streakCertificates;

  void _initializeService() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _currentUserId = data.session?.user.id;
        _loadCertificates();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUserId = null;
        _certificates.clear();
        notifyListeners();
      }
    });
  }

  CertificateService() {
    _initializeService();
  }

  // Convert user_achievements record to CertificateModel
  CertificateModel _convertAchievementToCertificate(
    Map<String, dynamic> achievement,
  ) {
    return CertificateModel(
      id: achievement['id'] as String,
      userId: achievement['user_id'] as String,
      type: achievement['achievement_type'] as String,
      title: achievement['title'] as String,
      description: achievement['description'] as String,
      japaCount: achievement['milestone_value'] as int,
      streakDays: achievement['current_streak'] as int,
      points: achievement['total_points'] as int,
      achievedAt: DateTime.parse(achievement['achieved_at'] as String),
      eventName: achievement['metadata']?['event_name'] as String?,
      mantraName: achievement['metadata']?['mantra_name'] as String?,
      metadata: Map<String, dynamic>.from(
        achievement['metadata'] as Map? ?? {},
      ),
    );
  }

  Future<void> _loadCertificates({bool forceRefresh = false}) async {
    if (_currentUserId == null) return;

    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedCertificates = await CacheService.getCachedUserCertificates(
          _currentUserId!,
        );
        if (cachedCertificates != null) {
          _certificates = cachedCertificates
              .map((item) => _convertAchievementToCertificate(item))
              .toList();
          notifyListeners();
          return;
        }
      }

      final response = await _supabase
          .from('user_achievements')
          .select()
          .eq('user_id', _currentUserId!)
          .order('achieved_at', ascending: false);

      _certificates = response
          .map((item) => _convertAchievementToCertificate(item))
          .toList();

      // Cache the certificates for future use
      await CacheService.cacheUserCertificates(_currentUserId!, response);

      notifyListeners();
    } catch (e) {}
  }

  // Check and generate certificates based on japa completion
  Future<void> checkJapaCompletionCertificates(int totalJapaCount) async {
    if (_currentUserId == null) return;

    // Check for specific japa milestones: 108, 1008, 1 Lakh, etc.
    final japaMilestones = [108, 1008, 11000, 100000, 1000000, 10000000];

    for (final milestone in japaMilestones) {
      if (totalJapaCount >= milestone) {
        await _generateJapaCompletionCertificate(milestone, totalJapaCount);
      }
    }
  }

  // Check and generate certificates based on daily streak
  Future<void> checkStreakCertificates(int currentStreak) async {
    if (_currentUserId == null) return;

    // Check for specific streak milestones: 7 days, 21 days
    final streakMilestones = [7, 21];

    for (final milestone in streakMilestones) {
      if (currentStreak >= milestone) {
        await _generateStreakCertificate(milestone, currentStreak);
      }
    }
  }

  // Check and generate certificates based on points
  Future<void> checkPointsCertificates(int totalPoints) async {
    if (_currentUserId == null) return;

    // Check for specific points threshold: 500 points
    final pointsThresholds = [500];

    for (final threshold in pointsThresholds) {
      if (totalPoints >= threshold) {
        await _generatePointsCertificate(threshold, totalPoints);
      }
    }
  }

  Future<void> _generateJapaCompletionCertificate(
    int milestone,
    int totalJapaCount,
  ) async {
    if (_currentUserId == null) return;

    // Check if certificate already exists
    final existing = await _supabase
        .from('user_achievements')
        .select()
        .eq('user_id', _currentUserId!)
        .eq('achievement_type', 'japa_completion')
        .eq('milestone_value', milestone)
        .maybeSingle();

    if (existing != null) return; // Certificate already exists

    final achievement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': _currentUserId!,
      'achievement_type': 'japa_completion',
      'title': 'Japa Completion Certificate - ${_formatJapaCount(milestone)}',
      'description':
          'Congratulations! You have completed ${_formatJapaCount(milestone)} japa.',
      'milestone_value': milestone,
      'current_streak': 0,
      'longest_streak': 0,
      'total_points': 0,
      'achieved_at': DateTime.now().toIso8601String(),
      'is_certificate_generated': true,
      'metadata': {
        'milestone_count': milestone,
        'total_japa_count': totalJapaCount,
        'certificate_type': 'japa_completion',
      },
    };

    await _saveAchievement(achievement);
  }

  Future<void> _generateStreakCertificate(
    int milestone,
    int currentStreak,
  ) async {
    if (_currentUserId == null) return;

    // Check if certificate already exists
    final existing = await _supabase
        .from('user_achievements')
        .select()
        .eq('user_id', _currentUserId!)
        .eq('achievement_type', 'daily_streak')
        .eq('milestone_value', milestone)
        .maybeSingle();

    if (existing != null) return; // Certificate already exists

    final achievement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': _currentUserId!,
      'achievement_type': 'daily_streak',
      'title': 'Consistency Certificate - ${milestone} Days',
      'description': 'Amazing! You have maintained a ${milestone}-day streak.',
      'milestone_value': milestone,
      'current_streak': currentStreak,
      'longest_streak': currentStreak,
      'total_points': 0,
      'achieved_at': DateTime.now().toIso8601String(),
      'is_certificate_generated': true,
      'metadata': {
        'milestone_days': milestone,
        'current_streak': currentStreak,
        'certificate_type': 'daily_streak',
      },
    };

    await _saveAchievement(achievement);
  }

  Future<void> _generatePointsCertificate(
    int threshold,
    int totalPoints,
  ) async {
    if (_currentUserId == null) return;

    // Check if certificate already exists
    final existing = await _supabase
        .from('user_achievements')
        .select()
        .eq('user_id', _currentUserId!)
        .eq('achievement_type', 'points_threshold')
        .eq('milestone_value', threshold)
        .maybeSingle();

    if (existing != null) return; // Certificate already exists

    final achievement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': _currentUserId!,
      'achievement_type': 'points_threshold',
      'title': 'Points Achievement - ${threshold} Points',
      'description': 'Excellent! You have earned ${threshold} points.',
      'milestone_value': threshold,
      'current_streak': 0,
      'longest_streak': 0,
      'total_points': totalPoints,
      'achieved_at': DateTime.now().toIso8601String(),
      'is_certificate_generated': true,
      'metadata': {
        'threshold': threshold,
        'total_points': totalPoints,
        'certificate_type': 'points_threshold',
      },
    };

    await _saveAchievement(achievement);
  }

  Future<void> _saveAchievement(Map<String, dynamic> achievement) async {
    try {
      await _supabase.from('user_achievements').insert(achievement);

      // Convert to CertificateModel and add to list
      final certificate = _convertAchievementToCertificate(achievement);
      _certificates.insert(0, certificate);
      notifyListeners();
    } catch (e) {}
  }

  // Generate PDF certificate
  Future<Uint8List> generatePdfCertificate(
    CertificateModel certificate,
    String userName,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.orange, width: 4),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(50),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Decorative border
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.orange, width: 2),
                      borderRadius: pw.BorderRadius.circular(15),
                    ),
                    padding: const pw.EdgeInsets.all(30),
                    child: pw.Column(
                      children: [
                        // Header with decorative elements
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 40,
                              height: 40,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.orange,
                                shape: pw.BoxShape.circle,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '🏆',
                                  style: pw.TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 20),
                            pw.Text(
                              'CERTIFICATE OF ACHIEVEMENT',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.orange,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.SizedBox(width: 20),
                            pw.Container(
                              width: 40,
                              height: 40,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.orange,
                                shape: pw.BoxShape.circle,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '🏆',
                                  style: pw.TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 30),

                        // Decorative line
                        pw.Container(
                          height: 3,
                          decoration: pw.BoxDecoration(
                            gradient: pw.LinearGradient(
                              colors: [
                                PdfColors.orange,
                                PdfColors.deepOrange,
                                PdfColors.orange,
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 40),

                        // Main content
                        pw.Text(
                          'This is to certify that',
                          style: pw.TextStyle(
                            fontSize: 18,
                            color: PdfColors.grey800,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 15),

                        pw.Text(
                          userName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 25),

                        pw.Text(
                          'has successfully achieved',
                          style: pw.TextStyle(
                            fontSize: 18,
                            color: PdfColors.grey800,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 15),

                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.orange.shade(0.1),
                            borderRadius: pw.BorderRadius.circular(10),
                            border: pw.Border.all(
                              color: PdfColors.orange,
                              width: 1,
                            ),
                          ),
                          child: pw.Text(
                            certificate.title.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.SizedBox(height: 20),

                        pw.Text(
                          certificate.description,
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.grey700,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),

                        // Achievement details
                        pw.SizedBox(height: 30),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(20),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          child: pw.Column(
                            children: [
                              if (certificate.japaCount > 0) ...[
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      'Total Japa Count:',
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.grey800,
                                      ),
                                    ),
                                    pw.Text(
                                      _formatJapaCount(certificate.japaCount),
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 10),
                              ],

                              if (certificate.streakDays > 0) ...[
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      'Streak Days:',
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.grey800,
                                      ),
                                    ),
                                    pw.Text(
                                      '${certificate.streakDays} Days',
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 10),
                              ],

                              if (certificate.points > 0) ...[
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      'Total Points:',
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.grey800,
                                      ),
                                    ),
                                    pw.Text(
                                      '${certificate.points} Points',
                                      style: pw.TextStyle(
                                        fontSize: 16,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 10),
                              ],

                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Achievement Date:',
                                    style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                  pw.Text(
                                    _formatDate(certificate.achievedAt),
                                    style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        pw.SizedBox(height: 40),

                        // Footer
                        pw.Container(
                          padding: const pw.EdgeInsets.all(15),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.orange.shade(0.05),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Text(
                            'Karmasu - Spiritual Journey Tracker\nYour Digital Companion for Spiritual Growth',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.grey600,
                            ),
                            textAlign: pw.TextAlign.center,
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

    return pdf.save();
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Share certificate as PDF
  Future<void> shareCertificate(
    CertificateModel certificate,
    String userName,
  ) async {
    try {
      final pdfBytes = await generatePdfCertificate(certificate, userName);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/certificate_${certificate.id}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '🏆 Check out my spiritual achievement certificate!\n\n📱 Join me on KARMASU - Digital Hindu Gurukul\n🔗 Download: https://play.google.com/store/apps/details?id=com.app.mokshada',
        subject: 'My ${certificate.title} Certificate',
      );
    } catch (e) {}
  }

  // Print certificate
  Future<void> printCertificate(
    CertificateModel certificate,
    String userName,
  ) async {
    try {
      final pdfBytes = await generatePdfCertificate(certificate, userName);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {}
  }

  // Generate event-based certificate (e.g., Mahashivratri Japa Completion)
  Future<void> generateEventBasedCertificate(
    String eventName,
    int japaCount,
  ) async {
    if (_currentUserId == null) return;

    // Check if certificate already exists for this event
    final existing = await _supabase
        .from('user_achievements')
        .select()
        .eq('user_id', _currentUserId!)
        .eq('achievement_type', 'event_based')
        .eq('metadata->>event_name', eventName)
        .maybeSingle();

    if (existing != null) return; // Certificate already exists

    final achievement = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': _currentUserId!,
      'achievement_type': 'event_based',
      'title': '$eventName Certificate',
      'description':
          'Special certificate for completing japa during $eventName.',
      'milestone_value': japaCount,
      'current_streak': 0,
      'longest_streak': 0,
      'total_points': 0,
      'achieved_at': DateTime.now().toIso8601String(),
      'is_certificate_generated': true,
      'metadata': {
        'event_name': eventName,
        'japa_count': japaCount,
        'certificate_type': 'event_based',
      },
    };

    await _saveAchievement(achievement);
  }

  // Helper method to format japa count
  String _formatJapaCount(int count) {
    if (count >= 10000000) {
      return '${(count / 10000000).toStringAsFixed(1)} Crore';
    } else if (count >= 100000) {
      return '${(count / 100000).toStringAsFixed(1)} Lakh';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  // Get user's total points (for points-based certificates)
  int calculatePoints(int japaCount) {
    // 1 point per japa, bonus points for milestones
    int points = japaCount;

    // Bonus points for milestones
    final japaMilestones = [108, 1008, 11000, 100000, 1000000, 10000000];
    for (final milestone in japaMilestones) {
      if (japaCount >= milestone) {
        points += milestone ~/ 10; // 10% bonus
      }
    }

    return points;
  }

  // Auto-generate certificates when japa count is updated
  Future<void> checkAndGenerateCertificates(
    int totalJapaCount,
    int currentStreak,
  ) async {
    if (_currentUserId == null) return;

    final totalPoints = calculatePoints(totalJapaCount);

    // Check all certificate types
    await checkJapaCompletionCertificates(totalJapaCount);
    await checkStreakCertificates(currentStreak);
    await checkPointsCertificates(totalPoints);
  }

  // Method to manually trigger event-based certificates (for special occasions)
  Future<void> triggerEventCertificate(String eventName, int japaCount) async {
    await generateEventBasedCertificate(eventName, japaCount);
  }

  // Example method for Mahashivratri event
  Future<void> checkMahashivratriCertificate(int japaCount) async {
    if (japaCount >= 108) {
      // Minimum 108 japa for Mahashivratri certificate
      await generateEventBasedCertificate(
        'Mahashivratri Japa Completion',
        japaCount,
      );
    }
  }

  /// Force refresh certificates (clears cache and fetches fresh data)
  Future<void> refreshCertificates() async {
    await _loadCertificates(forceRefresh: true);
  }

  /// Clear certificates cache
  Future<void> clearCertificatesCache() async {
    if (_currentUserId != null) {
      await CacheService.clearUserCache(_currentUserId!);
    }
  }

  // Static methods for certificate operations
  static List<CertificateModel> getUnlockedCertificates(
    List<CertificateModel> allCertificates,
    int userJapaCount,
  ) {
    return allCertificates
        .where((cert) => userJapaCount >= cert.japaCount)
        .toList();
  }

  static CertificateModel? getNextCertificate(
    List<CertificateModel> allCertificates,
    int userJapaCount,
  ) {
    final unlockedCertificates = allCertificates
        .where((cert) => userJapaCount < cert.japaCount)
        .toList();
    if (unlockedCertificates.isEmpty) return null;
    unlockedCertificates.sort((a, b) => a.japaCount.compareTo(b.japaCount));
    return unlockedCertificates.first;
  }

  static List<CertificateModel> getUnlockedStreakCertificates(
    List<CertificateModel> allCertificates,
    int userStreakDays,
  ) {
    return allCertificates
        .where((cert) => userStreakDays >= cert.streakDays)
        .toList();
  }

  static CertificateModel? getNextStreakCertificate(
    List<CertificateModel> allCertificates,
    int userStreakDays,
  ) {
    final unlockedCertificates = allCertificates
        .where((cert) => userStreakDays < cert.streakDays)
        .toList();
    if (unlockedCertificates.isEmpty) return null;
    unlockedCertificates.sort((a, b) => a.streakDays.compareTo(b.streakDays));
    return unlockedCertificates.first;
  }

  static bool hasAchievedCertificate(
    CertificateModel certificate,
    int userJapaCount,
  ) {
    return userJapaCount >= certificate.japaCount;
  }

  static bool hasAchievedStreakCertificate(
    CertificateModel certificate,
    int userStreakDays,
  ) {
    return userStreakDays >= certificate.streakDays;
  }

  // Method specifically for StreakCertificateModel
  static bool hasAchievedStreakCertificateModel(
    StreakCertificateModel certificate,
    int userStreakDays,
  ) {
    return userStreakDays >= certificate.requiredStreakDays;
  }

  // Generate PDF for StreakCertificateModel
  static Future<Uint8List> generateStreakCertificateModelPdf(
    StreakCertificateModel certificate,
    String userName,
    String logoAssetPath, {
    bool isHindi = false,
  }) async {
    // Convert StreakCertificateModel to CertificateModel for PDF generation
    final certificateModel = CertificateModel(
      id: certificate.id,
      userId: '',
      type: 'streak',
      title: isHindi ? certificate.nameHindi : certificate.name,
      description: isHindi
          ? certificate.descriptionHindi
          : certificate.description,
      japaCount: 0,
      streakDays: certificate.requiredStreakDays,
      points: 0,
      achievedAt: certificate.unlockedAt ?? DateTime.now(),
    );

    final certificateService = CertificateService();
    return await certificateService.generatePdfCertificate(
      certificateModel,
      userName,
    );
  }

  static double getProgressPercentage(
    CertificateModel certificate,
    int userJapaCount,
  ) {
    if (certificate.japaCount == 0) return 1.0;
    return (userJapaCount / certificate.japaCount).clamp(0.0, 1.0);
  }

  static Future<Uint8List> generateCertificatePdf(
    CertificateModel certificate,
    String userName,
    String logoAssetPath, {
    bool isHindi = false,
  }) async {
    final certificateService = CertificateService();
    return await certificateService.generatePdfCertificate(
      certificate,
      userName,
    );
  }

  static Future<Uint8List> generateStreakCertificatePdf(
    CertificateModel certificate,
    String userName,
    String logoAssetPath, {
    bool isHindi = false,
  }) async {
    final certificateService = CertificateService();
    return await certificateService.generatePdfCertificate(
      certificate,
      userName,
    );
  }

  static String getCertificateFileName(
    CertificateModel certificate,
    String userName,
  ) {
    final sanitizedName = userName
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${certificate.type}_${certificate.title.replaceAll(' ', '_')}_${sanitizedName}_$timestamp.pdf';
  }

  static Future<String> saveCertificateToDevice(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final certificatesDir = Directory('${directory.path}/KarmasuCertificates');
    if (!await certificatesDir.exists()) {
      await certificatesDir.create(recursive: true);
    }
    final file = File('${certificatesDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }
}
