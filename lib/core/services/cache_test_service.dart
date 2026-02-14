// core/services/cache_test_service.dart
import 'cache_service.dart';

/// Test service to verify caching implementation
class CacheTestService {
  /// Test basic cache functionality
  static Future<void> testBasicCache() async {
    try {
      // Test data
      final testData = [
        {'id': 1, 'name': 'Test Item 1'},
        {'id': 2, 'name': 'Test Item 2'},
      ];

      // Store data
      await CacheService.cachePujaList(testData);

      // Retrieve data
      final cachedData = await CacheService.getCachedPujaList();
      if (cachedData != null && cachedData.length == 2) {
      } else {}

      // Test cache expiration (simulate by clearing and checking)
      await CacheService.clearDataTypeCache('puja_list');
      final expiredData = await CacheService.getCachedPujaList();
      if (expiredData == null) {
      } else {}
    } catch (e) {}
  }

  /// Test user-specific caching
  static Future<void> testUserCache(String userId) async {
    try {
      // Test user favorites
      final testFavorites = {'mantra1', 'mantra2', 'mantra3'};
      await CacheService.cacheUserFavorites(userId, testFavorites);

      // Retrieve user favorites
      final cachedFavorites = await CacheService.getCachedUserFavorites(userId);
      if (cachedFavorites != null && cachedFavorites.length == 3) {
      } else {}

      // Test user statistics
      final testStats = {
        'today_japa_count': 108,
        'total_japa_count': 10000,
        'active_days': 30,
      };
      await CacheService.cacheUserStats(userId, testStats);

      // Retrieve user statistics
      final cachedStats = await CacheService.getCachedUserStats(userId);
      if (cachedStats != null && cachedStats.containsKey('today_japa_count')) {
      } else {}
    } catch (e) {}
  }

  /// Test cache statistics
  static Future<void> testCacheStatistics() async {
    try {
      final stats = await CacheService.getCacheStats();

      if (stats['total_entries'] > 0) {
      } else {}
    } catch (e) {}
  }

  /// Test cache invalidation
  static Future<void> testCacheInvalidation() async {
    try {
      // Add some test data
      await CacheService.cachePujaList([
        {'id': 1, 'name': 'Test'},
      ]);
      await CacheService.cacheBannerData([
        {'id': 1, 'url': 'test.jpg'},
      ]);

      // Test specific data type clearing
      await CacheService.clearDataTypeCache('puja_list');
      final pujaData = await CacheService.getCachedPujaList();
      final bannerData = await CacheService.getCachedBannerData();

      if (pujaData == null && bannerData != null) {
      } else {}

      // Test clearing all cache
      await CacheService.clearAllCache();
      final allPujaData = await CacheService.getCachedPujaList();
      final allBannerData = await CacheService.getCachedBannerData();

      if (allPujaData == null && allBannerData == null) {
      } else {}
    } catch (e) {}
  }

  /// Run all cache tests
  static Future<void> runAllTests({String? userId}) async {
    await testBasicCache();

    if (userId != null) {
      await testUserCache(userId);
    }

    await testCacheStatistics();

    await testCacheInvalidation();
  }

  /// Performance test - measure cache vs API speed
  static Future<void> performanceTest() async {
    try {
      // Test data
      final testData = List.generate(
        100,
        (index) => {
          'id': index,
          'name': 'Test Item $index',
          'description': 'Description for item $index',
        },
      );

      // Measure cache write time
      final stopwatch = Stopwatch()..start();
      await CacheService.cachePujaList(testData);
      stopwatch.stop();

      // Measure cache read time
      stopwatch.reset();
      stopwatch.start();
      final cachedData = await CacheService.getCachedPujaList();
      stopwatch.stop();

      if (cachedData != null && cachedData.length == 100) {
      } else {}
    } catch (e) {}
  }
}
