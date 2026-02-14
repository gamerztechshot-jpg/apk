// core/services/url_processing_test.dart
import 'url_processing_service.dart';

class UrlProcessingTest {
  static final UrlProcessingService _urlService = UrlProcessingService();

  /// Test Google Drive link processing
  static Future<void> testGoogleDriveLinks() async {
    // Test different Google Drive URL formats
    final testUrls = [
      'https://drive.google.com/file/d/1ABC123DEF456GHI789JKL/view?usp=sharing',
      'https://drive.google.com/open?id=1ABC123DEF456GHI789JKL',
      'https://docs.google.com/document/d/1ABC123DEF456GHI789JKL/edit',
    ];

    for (final url in testUrls) {
      try {
        final processedUrl = await _urlService.processUrl(url);
      } catch (e) {}
    }
  }

  /// Test Dropbox link processing
  static Future<void> testDropboxLinks() async {
    final testUrls = [
      'https://www.dropbox.com/s/abc123def456/file.pdf?dl=0',
      'https://www.dropbox.com/s/abc123def456/file.pdf',
    ];

    for (final url in testUrls) {
      try {
        final processedUrl = await _urlService.processUrl(url);
      } catch (e) {}
    }
  }

  /// Test direct link detection
  static Future<void> testDirectLinks() async {
    final testUrls = [
      'https://example.com/file.pdf',
      'https://example.com/audio.mp3',
      'https://example.com/video.mp4',
    ];

    for (final url in testUrls) {
      try {
        final processedUrl = await _urlService.processUrl(url);
        final isDirect = url == processedUrl;
      } catch (e) {}
    }
  }

  /// Test file type detection
  static Future<void> testFileTypeDetection() async {
    final testUrls = [
      'https://example.com/document.pdf',
      'https://example.com/audio.mp3',
      'https://example.com/music.wav',
      'https://example.com/song.m4a',
    ];

    for (final url in testUrls) {
      final isPdf = _urlService.isPdfUrl(url);
      final isAudio = _urlService.isAudioUrl(url);
      final extension = _urlService.getFileExtension(url);
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    await testDirectLinks();
    await testGoogleDriveLinks();
    await testDropboxLinks();
    await testFileTypeDetection();
  }
}
