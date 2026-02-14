// core/services/leaderboard_certificate_service.dart
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_certificate_model.dart';

// Note: dart:html imports removed to avoid platform compatibility issues

class LeaderboardCertificateService extends ChangeNotifier {
  List<LeaderboardCertificateModel> _certificateTypes = [];
  List<ActiveLeaderboardCertificate> _activeCertificates = [];
  List<LeaderboardCertificateHistory> _certificateHistory = [];
  bool _isLoading = false;
  String? _error;

  List<LeaderboardCertificateModel> get certificateTypes => _certificateTypes;
  List<ActiveLeaderboardCertificate> get activeCertificates =>
      _activeCertificates;
  List<LeaderboardCertificateHistory> get certificateHistory =>
      _certificateHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  LeaderboardCertificateService() {
    _initializeService();
  }

  void _initializeService() {
    // Don't load data immediately to prevent build loops
    // Data will be loaded when the UI explicitly requests it
  }

  /// Load certificate types from database
  Future<void> loadCertificateTypes() async {
    try {
      _isLoading = true;

      final response = await Supabase.instance.client
          .from('lb_certificate_types')
          .select()
          .eq('is_active', true)
          .order('type_code');

      _certificateTypes = (response as List)
          .map((json) => LeaderboardCertificateModel.fromJson(json))
          .toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load certificate types: $e';
    } finally {
      _isLoading = false;
    }
  }

  /// Load current certificate holders
  Future<void> loadCurrentCertificateHolders() async {
    try {
      _isLoading = true;

      final response = await Supabase.instance.client.rpc(
        'lb_get_current_certificate_holders',
      );

      _activeCertificates = (response as List)
          .map((json) => ActiveLeaderboardCertificate.fromJson(json))
          .toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load current certificate holders: $e';
    } finally {
      _isLoading = false;
    }
  }

  /// Load user's certificate history
  Future<void> loadUserCertificateHistory({String? userId}) async {
    try {
      _isLoading = true;

      // Get current user if userId is not provided
      final currentUserId =
          userId ?? Supabase.instance.client.auth.currentUser?.id;

      final response = await Supabase.instance.client.rpc(
        'lb_get_user_certificate_history',
        params: {'p_user_id': currentUserId},
      );

      _certificateHistory = (response as List)
          .map((json) => LeaderboardCertificateHistory.fromJson(json))
          .toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load certificate history: $e';
    } finally {
      _isLoading = false;
    }
  }

  /// Load user's current certificates
  Future<List<ActiveLeaderboardCertificate>> loadUserCurrentCertificates({
    String? userId,
  }) async {
    try {
      _isLoading = true;

      // Get current user if userId is not provided
      final currentUserId =
          userId ?? Supabase.instance.client.auth.currentUser?.id;

      final response = await Supabase.instance.client.rpc(
        'lb_get_user_certificates',
        params: {'p_user_id': currentUserId},
      );

      final userCertificates = (response as List)
          .map((json) => ActiveLeaderboardCertificate.fromJson(json))
          .toList();

      _error = null;
      return userCertificates;
    } catch (e) {
      _error = 'Failed to load user certificates: $e';
      return [];
    } finally {
      _isLoading = false;
    }
  }

  /// Process daily certificates
  Future<String?> processDailyCertificates({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      final response = await Supabase.instance.client.rpc(
        'lb_process_daily_certificates',
        params: {
          'p_date': targetDate.toIso8601String().split(
            'T',
          )[0], // YYYY-MM-DD format
        },
      );

      return response as String?;
    } catch (e) {
      setError('Failed to process daily certificates: $e');
      return null;
    }
  }

  /// Process weekly certificates
  Future<String?> processWeeklyCertificates({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? _getWeekStart(DateTime.now());
      final end = endDate ?? _getWeekEnd(DateTime.now());

      final response = await Supabase.instance.client.rpc(
        'lb_process_weekly_certificates',
        params: {
          'p_start_date': start.toIso8601String().split('T')[0],
          'p_end_date': end.toIso8601String().split('T')[0],
        },
      );

      return response as String?;
    } catch (e) {
      setError('Failed to process weekly certificates: $e');
      return null;
    }
  }

  /// Process monthly certificates
  Future<String?> processMonthlyCertificates({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? _getMonthStart(DateTime.now());
      final end = endDate ?? _getMonthEnd(DateTime.now());

      final response = await Supabase.instance.client.rpc(
        'lb_process_monthly_certificates',
        params: {
          'p_start_date': start.toIso8601String().split('T')[0],
          'p_end_date': end.toIso8601String().split('T')[0],
        },
      );

      return response as String?;
    } catch (e) {
      setError('Failed to process monthly certificates: $e');
      return null;
    }
  }

  /// Process yearly certificates
  Future<String?> processYearlyCertificates({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? _getYearStart(DateTime.now());
      final end = endDate ?? _getYearEnd(DateTime.now());

      final response = await Supabase.instance.client.rpc(
        'lb_process_yearly_certificates',
        params: {
          'p_start_date': start.toIso8601String().split('T')[0],
          'p_end_date': end.toIso8601String().split('T')[0],
        },
      );

      return response as String?;
    } catch (e) {
      setError('Failed to process yearly certificates: $e');
      return null;
    }
  }

  /// Process all-time certificates
  Future<String?> processAllTimeCertificates() async {
    try {
      final response = await Supabase.instance.client.rpc(
        'lb_process_alltime_certificates',
      );

      return response as String?;
    } catch (e) {
      setError('Failed to process all-time certificates: $e');
      return null;
    }
  }

  /// Generate a leaderboard certificate PDF
  static Future<Uint8List> generateLeaderboardCertificatePdf({
    required ActiveLeaderboardCertificate certificate,
    required LeaderboardCertificateModel certificateType,
    required String userName,
    required String logoAssetPath,
    bool isHindi = false,
  }) async {
    try {
      // Use the provided user name
      final finalUserName = userName.isNotEmpty
          ? userName
          : 'Certificate Holder';

      // Create PDF document
      final pdf = pw.Document();

      // Load logo image

      final logoBytes = await rootBundle.load(logoAssetPath);
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // Generate certificate content

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return _buildLeaderboardCertificateContent(
              certificate: certificate,
              certificateType: certificateType,
              userName: finalUserName, // Using real user name
              logoImage: logoImage,
              isHindi: isHindi,
            );
          },
        ),
      );

      final bytes = await pdf.save();
      return bytes;
    } catch (e) {
      rethrow;
    }
  }

  /// Build the leaderboard certificate content
  static pw.Widget _buildLeaderboardCertificateContent({
    required ActiveLeaderboardCertificate certificate,
    required LeaderboardCertificateModel certificateType,
    required String userName,
    required pw.MemoryImage logoImage,
    bool isHindi = false,
  }) {
    // BEAUTIFUL CERTIFICATE DESIGN
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange, width: 4),
        borderRadius: pw.BorderRadius.circular(20),
        color: PdfColors.white,
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 20),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange,
                borderRadius: pw.BorderRadius.circular(15),
              ),
              child: pw.Text(
                isHindi ? 'लीडरबोर्ड उपलब्धि प्रमाणपत्र' : 'LEADERBOARD ACHIEVEMENT CERTIFICATE',
                style: pw.TextStyle(
                  fontSize: 28,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            pw.SizedBox(height: 20),

            // Logo
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Image(
                logoImage,
                width: 120,
                height: 60,
                fit: pw.BoxFit.contain,
              ),
            ),

            pw.SizedBox(height: 25),

            // This is to certify that
            pw.Text(
              isHindi ? 'यह प्रमाणित किया जाता है कि' : 'This is to certify that',
              style: pw.TextStyle(
                fontSize: 18,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 20),

            // User name with special styling
            pw.Text(
              userName,
              style: pw.TextStyle(
                fontSize: 36,
                color: PdfColors.red,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 20),

            // Achievement description
            pw.Text(
              isHindi ? 'ने सफलतापूर्वक प्राप्त किया है' : 'has successfully achieved',
              style: pw.TextStyle(
                fontSize: 18,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 20),

            // Certificate name with special styling
            pw.Text(
              certificateType.getName(isHindi: isHindi),
              style: pw.TextStyle(
                fontSize: 32,
                color: PdfColors.orange,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 15),

            // Japa count
            pw.Text(
              '${certificate.formattedJapaCount} ${isHindi ? 'जप' : 'JAPAS'}',
              style: pw.TextStyle(
                fontSize: 24,
                color: PdfColors.blue,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: pw.TextAlign.center,
            ),

            pw.SizedBox(height: 25),

            // Footer with date and signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Date section
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      isHindi ? 'प्रमाणपत्र दिनांक' : 'Certificate Date',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      _formatDate(certificate.awardedAt),
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.blue,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Signature section
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Karmasu App',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      width: 150,
                      height: 2,
                      color: PdfColors.orange,
                    ),
                    pw.Text(
                      isHindi ? 'अधिकृत हस्ताक्षर' : 'Authorized Signature',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get leaderboard certificate color based on type
  static PdfColor _getLeaderboardCertificateColor(String typeCode) {
    switch (typeCode) {
      case 'daily':
        return PdfColors.red; // Red
      case 'weekly':
        return PdfColors.teal; // Teal
      case 'monthly':
        return PdfColors.blue; // Blue
      case 'yearly':
        return PdfColors.green; // Green
      case 'alltime':
        return PdfColors.amber; // Yellow/Gold
      default:
        return PdfColors.grey400;
    }
  }

  /// Format date for certificate
  static String _formatDate(DateTime date) {
    const months = [
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Save certificate to device storage
  static Future<String> saveLeaderboardCertificateToDevice({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      // Check if running on web
      if (kIsWeb) {
        throw UnsupportedError(
          'File saving not supported on web. Use share functionality instead.',
        );
      }

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create certificates folder if it doesn't exist
      final certificatesDir = Directory(
        '${directory.path}/KarmasuCertificates',
      );
      if (!await certificatesDir.exists()) {
        await certificatesDir.create(recursive: true);
      }

      // Save the file
      final file = File('${certificatesDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  /// Share certificate (works on all platforms including web)
  static Future<void> shareLeaderboardCertificate({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        // For web, use direct blob sharing
        await _shareLeaderboardCertificateWeb(pdfBytes, fileName);
      } else {
        // For mobile/desktop, use file-based sharing
        await _shareLeaderboardCertificateMobile(pdfBytes, fileName);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Share certificate on web platform
  static Future<void> _shareLeaderboardCertificateWeb(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      if (kIsWeb) {
        // For web, we'll use direct Share.share as html imports are problematic
        await Share.share(
          'Check out my Leaderboard Certificate!',
          subject: 'Leaderboard Certificate',
        );
      } else {
        // Fallback for non-web platforms
        await Share.share(
          'Check out my Leaderboard Certificate!',
          subject: 'Leaderboard Certificate',
        );
      }
    } catch (e) {
      // Fallback: try share_plus anyway
      await Share.share(
        'Check out my Leaderboard Certificate!',
        subject: 'Leaderboard Certificate',
      );
    }
  }

  /// Share certificate on mobile/desktop platforms
  static Future<void> _shareLeaderboardCertificateMobile(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      // Create a temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(pdfBytes);

      // Share the file
      await Share.shareXFiles([
        XFile(tempFile.path),
      ], text: '🏅 Check out my Leaderboard Certificate!\n\n📱 Join me on KARMASU - Digital Hindu Gurukul\n🔗 Download: https://play.google.com/store/apps/details?id=com.digital.hindugurukul');
    } catch (e) {
      rethrow;
    }
  }

  /// Get formatted file name for leaderboard certificate
  static String getLeaderboardCertificateFileName({
    required ActiveLeaderboardCertificate certificate,
    required LeaderboardCertificateModel certificateType,
    required String userName,
  }) {
    final sanitizedName = userName
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(' ', '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${certificateType.typeCode}_${certificateType.getName().replaceAll(' ', '_')}_${sanitizedName}_$timestamp.pdf';
  }

  // Helper methods for date calculations
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  DateTime _getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  DateTime _getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  DateTime _getYearStart(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  DateTime _getYearEnd(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  // State management methods
  void setLoading(bool loading) {
    _isLoading = loading;
    // Don't notify listeners immediately to prevent build loops
  }

  void setError(String? error) {
    _error = error;
    // Don't notify listeners immediately to prevent build loops
  }

  void clearError() {
    _error = null;
    // Don't notify listeners immediately to prevent build loops
  }

  // Method to manually trigger notifications when safe
  void notifyStateChanged() {
    notifyListeners();
  }
}
