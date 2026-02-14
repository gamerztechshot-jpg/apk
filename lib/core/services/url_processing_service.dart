// core/services/url_processing_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UrlProcessingService {
  static final UrlProcessingService _instance =
      UrlProcessingService._internal();
  factory UrlProcessingService() => _instance;
  UrlProcessingService._internal();

  /// Process any URL and return a direct downloadable link
  /// Supports Google Drive, Dropbox, OneDrive, and direct links
  Future<String> processUrl(String originalUrl) async {
    try {
      // Check if it's already a direct link
      if (_isDirectLink(originalUrl)) {
        return originalUrl;
      }

      // Process Google Drive links
      if (_isGoogleDriveLink(originalUrl)) {
        return await _processGoogleDriveUrl(originalUrl);
      }

      // Process Dropbox links
      if (_isDropboxLink(originalUrl)) {
        return await _processDropboxUrl(originalUrl);
      }

      // Process OneDrive links
      if (_isOneDriveLink(originalUrl)) {
        return await _processOneDriveUrl(originalUrl);
      }

      // For other links, try to get direct access
      return await _getDirectAccessUrl(originalUrl);
    } catch (e) {
      return originalUrl; // Return original URL as fallback
    }
  }

  /// Check if URL is already a direct downloadable link
  bool _isDirectLink(String url) {
    final directExtensions = ['.pdf', '.mp3', '.mp4', '.wav', '.m4a', '.aac'];
    return directExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  /// Check if URL is a Google Drive link
  bool _isGoogleDriveLink(String url) {
    return url.contains('drive.google.com') || url.contains('docs.google.com');
  }

  /// Check if URL is a Dropbox link
  bool _isDropboxLink(String url) {
    return url.contains('dropbox.com');
  }

  /// Check if URL is a OneDrive link
  bool _isOneDriveLink(String url) {
    return url.contains('onedrive.live.com') || url.contains('1drv.ms');
  }

  /// Process Google Drive URL to get direct download link
  Future<String> _processGoogleDriveUrl(String url) async {
    try {
      // Extract file ID from Google Drive URL
      String fileId = '';

      if (url.contains('/file/d/')) {
        // Format: https://drive.google.com/file/d/FILE_ID/view
        final match = RegExp(r'/file/d/([a-zA-Z0-9-_]+)').firstMatch(url);
        fileId = match?.group(1) ?? '';
      } else if (url.contains('id=')) {
        // Format: https://drive.google.com/open?id=FILE_ID
        final match = RegExp(r'id=([a-zA-Z0-9-_]+)').firstMatch(url);
        fileId = match?.group(1) ?? '';
      }

      if (fileId.isEmpty) {
        throw Exception('Could not extract file ID from Google Drive URL');
      }

      // Return direct download URL
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    } catch (e) {
      return url;
    }
  }

  /// Process Dropbox URL to get direct download link
  Future<String> _processDropboxUrl(String url) async {
    try {
      // Convert Dropbox sharing link to direct download
      if (url.contains('?dl=0')) {
        return url.replaceAll('?dl=0', '?dl=1');
      } else if (url.contains('?')) {
        return '$url&dl=1';
      } else {
        return '$url?dl=1';
      }
    } catch (e) {
      return url;
    }
  }

  /// Process OneDrive URL to get direct download link
  Future<String> _processOneDriveUrl(String url) async {
    try {
      // Convert OneDrive sharing link to direct download
      if (url.contains('1drv.ms')) {
        // Short URL - need to resolve first
        final response = await http.head(Uri.parse(url));
        final resolvedUrl = response.headers['location'] ?? url;
        return _convertOneDriveToDirect(resolvedUrl);
      } else {
        return _convertOneDriveToDirect(url);
      }
    } catch (e) {
      return url;
    }
  }

  /// Convert OneDrive URL to direct download format
  String _convertOneDriveToDirect(String url) {
    if (url.contains('redir?')) {
      // Extract the actual file URL from redir parameter
      final uri = Uri.parse(url);
      final redirParam = uri.queryParameters['redir'];
      if (redirParam != null) {
        return Uri.decodeComponent(redirParam);
      }
    }

    // Replace /view with /download for direct download
    if (url.contains('/view')) {
      return url.replaceAll('/view', '/download');
    }

    return url;
  }

  /// Try to get direct access URL for other types of links
  Future<String> _getDirectAccessUrl(String url) async {
    try {
      // Make a HEAD request to check if the URL is accessible
      final response = await http.head(Uri.parse(url));

      if (response.statusCode == 200) {
        // Check if it's a redirect
        final location = response.headers['location'];
        if (location != null) {
          return location;
        }
        return url;
      } else {
        throw Exception('URL not accessible: ${response.statusCode}');
      }
    } catch (e) {
      return url;
    }
  }

  /// Download file from URL and save to local storage
  Future<String> downloadFile(String url, String fileName) async {
    try {
      final processedUrl = await processUrl(url);

      // Download the file
      final response = await http.get(Uri.parse(processedUrl));

      if (response.statusCode == 200) {
        // Get local directory
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');

        // Write file to local storage
        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get file extension from URL
  String getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');

      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot + 1).toLowerCase();
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  /// Check if URL is a PDF file
  bool isPdfUrl(String url) {
    final extension = getFileExtension(url);
    return extension == 'pdf' || url.toLowerCase().contains('.pdf');
  }

  /// Check if URL is an audio file
  bool isAudioUrl(String url) {
    final audioExtensions = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'];
    final extension = getFileExtension(url);
    return audioExtensions.contains(extension) ||
        audioExtensions.any((ext) => url.toLowerCase().contains('.$ext'));
  }

  /// Validate if URL is accessible
  Future<bool> isUrlAccessible(String url) async {
    try {
      final processedUrl = await processUrl(url);
      final response = await http.head(Uri.parse(processedUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
