// core/services/onboarding_cache_service.dart
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class OnboardingCacheService {
  OnboardingCacheService._();

  static final CacheManager _cacheManager = DefaultCacheManager();

  static Future<File> getFile(String url) {
    return _cacheManager.getSingleFile(url);
  }

  static Future<File?> getFileFromCache(String url) {
    return _cacheManager.getFileFromCache(url).then((value) => value?.file);
  }
}
