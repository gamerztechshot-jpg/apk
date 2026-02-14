// core/services/image_cache_service.dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheService {
  static const String _cacheKey = 'karmasu_images';
  static const Duration _cacheDuration = Duration(hours: 12);
  static const int _maxCacheObjects = 100;

  static CacheManager? _cacheManager;

  static CacheManager get cacheManager {
    _cacheManager ??= CacheManager(
      Config(
        _cacheKey,
        stalePeriod: _cacheDuration,
        maxNrOfCacheObjects: _maxCacheObjects,
        repo: JsonCacheInfoRepository(databaseName: _cacheKey),
        fileService: HttpFileService(),
      ),
    );
    return _cacheManager!;
  }

  /// Clear all cached images
  static Future<void> clearCache() async {
    await cacheManager.emptyCache();
  }

  /// Get cache info
  static Future<FileInfo?> getFileFromCache(String url) async {
    return await cacheManager.getFileFromCache(url);
  }

  /// Preload an image into cache
  static Future<void> preloadImage(String url) async {
    await cacheManager.getSingleFile(url);
  }

  /// Check if image is cached
  static Future<bool> isImageCached(String url) async {
    final fileInfo = await getFileFromCache(url);
    return fileInfo != null;
  }

  /// Get cache size (simplified)
  static Future<int> getCacheSize() async {
    // Simplified implementation - cache manager handles size internally
    return 0;
  }
}
