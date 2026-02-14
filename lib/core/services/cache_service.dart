// core/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _cachePrefix = 'karmasu_cache_';
  static const String _timestampPrefix = 'karmasu_ts_';

  static const Duration _shortCache = Duration(minutes: 5);
  static const Duration _mediumCache = Duration(hours: 1);
  static const Duration _longCache = Duration(hours: 6);
  static const Duration _veryLongCache = Duration(hours: 12);

  static const String _pujaListKey = 'puja_list';
  static const String _panchangDataKey = 'panchang_data';
  static const String _leaderboardKey = 'leaderboard';
  static const String _audioEbookKey = 'audio_ebook';
  static const String _bannerKey = 'banner';
  static const String _festivalBannerKey = 'festival_banner';
  static const String _pujaBannerKey = 'puja_banner';
  static const String _courseBannerKey = 'course_banner';
  static const String _favoritesKey = 'favorites';
  static const String _userStatsKey = 'user_stats';
  static const String _certificatesKey = 'certificates';
  static const String _userProfileKey = 'user_profile';
  static const String _userBookingsKey = 'user_bookings';
  static const String _bookingDetailsKey = 'booking_details';
  static const String _articlesKey = 'articles';
  static const String _articleCategoriesKey = 'article_categories';
  static const String _panditListKey = 'pandit_list';
  static const String _spiritualDiaryKey = 'spiritual_diary';
  static const String _todaysPujasKey = 'todays_pujas';
  static const String _upcomingPujasKey = 'upcoming_pujas';
  static const String _familyPanditKey = 'family_pandit';
  static const String _panditBookingsKey = 'pandit_bookings';
  static const String _teachersKey = 'teachers';
  static const String _webinarsKey = 'webinars';

  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Duration _getCacheDuration(String dataType) {
    switch (dataType) {
      case _pujaListKey:
      case _audioEbookKey:
      case _teachersKey:
      case _webinarsKey:
        return _longCache; // 6 hours - content doesn't change frequently
      case _panchangDataKey:
        return _veryLongCache; // 24 hours - panchang data is static
      case _leaderboardKey:
        return _shortCache; // 5 minutes - leaderboard changes frequently
      case _bannerKey:
      case _festivalBannerKey:
      case _pujaBannerKey:
      case _courseBannerKey:
        return _mediumCache; // 1 hour - banners may change
      case _favoritesKey:
        return _mediumCache; // 1 hour - user favorites
      case _userStatsKey:
        return _shortCache; // 5 minutes - user stats change frequently
      case _certificatesKey:
        return _longCache; // 6 hours - certificates don't change often
      case _userProfileKey:
        return _mediumCache; // 1 hour - profile data
      case _userBookingsKey:
        return _mediumCache; // 1 hour - bookings may change
      case _bookingDetailsKey:
        return _longCache; // 6 hours - booking details are stable
      case _articlesKey:
        return _longCache; // 6 hours - articles don't change frequently
      case _articleCategoriesKey:
        return _veryLongCache; // 24 hours - categories are stable
      case _panditListKey:
        return _longCache; // 6 hours - pandit list doesn't change frequently
      case _spiritualDiaryKey:
        return _mediumCache; // 1 hour - spiritual diary may change
      case _todaysPujasKey:
      case _upcomingPujasKey:
        return _shortCache; // 5 minutes - puja suggestions change frequently
      case _familyPanditKey:
        return _mediumCache; // 1 hour - family pandit assignment may change
      case _panditBookingsKey:
        return _shortCache; // 5 minutes - bookings change frequently
      default:
        return _mediumCache; // Default to 1 hour
    }
  }

  static String _generateKey(String baseKey, {String? userId}) {
    if (userId != null) {
      return '${_cachePrefix}${baseKey}_$userId';
    }
    return '$_cachePrefix$baseKey';
  }

  static String _generateTimestampKey(String baseKey, {String? userId}) {
    if (userId != null) {
      return '${_timestampPrefix}${baseKey}_$userId';
    }
    return '$_timestampPrefix$baseKey';
  }

  static bool _isCacheValid(String key, Duration cacheDuration) {
    final timestampKey = _generateTimestampKey(key);
    final timestamp = _prefs?.getInt(timestampKey);

    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return now.difference(cacheTime) < cacheDuration;
  }

  static Future<void> _storeData(
    String key,
    dynamic data,
    Duration cacheDuration,
  ) async {
    if (_prefs == null) await initialize();

    try {
      final jsonString = jsonEncode(data);
      final timestampKey = _generateTimestampKey(key);

      await _prefs!.setString(key, jsonString);
      await _prefs!.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {}
  }

  static Future<T?> _getData<T>(String key, Duration cacheDuration) async {
    if (_prefs == null) await initialize();

    try {
      if (!_isCacheValid(key, cacheDuration)) {
        return null;
      }

      final jsonString = _prefs!.getString(key);
      if (jsonString == null) return null;

      final data = jsonDecode(jsonString);

      return data as T?;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _clearCache(String key) async {
    if (_prefs == null) await initialize();

    try {
      await _prefs!.remove(key);
      await _prefs!.remove(_generateTimestampKey(key));
    } catch (e) {}
  }

  static Future<void> cachePujaList(List<dynamic> pujaList) async {
    final key = _generateKey(_pujaListKey);
    final duration = _getCacheDuration(_pujaListKey);
    await _storeData(key, pujaList, duration);
  }

  static Future<List<dynamic>?> getCachedPujaList() async {
    final key = _generateKey(_pujaListKey);
    final duration = _getCacheDuration(_pujaListKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cachePanchangData(
    String language,
    List<dynamic> panchangData,
  ) async {
    final key = _generateKey('${_panchangDataKey}_$language');
    final duration = _getCacheDuration(_panchangDataKey);
    await _storeData(key, panchangData, duration);
  }

  static Future<List<dynamic>?> getCachedPanchangData(String language) async {
    final key = _generateKey('${_panchangDataKey}_$language');
    final duration = _getCacheDuration(_panchangDataKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheLeaderboard(
    String period,
    List<dynamic> leaderboardData, {
    String? userId,
  }) async {
    final key = _generateKey('${_leaderboardKey}_$period', userId: userId);
    final duration = _getCacheDuration(_leaderboardKey);
    await _storeData(key, leaderboardData, duration);
  }

  static Future<List<dynamic>?> getCachedLeaderboard(
    String period, {
    String? userId,
  }) async {
    final key = _generateKey('${_leaderboardKey}_$period', userId: userId);
    final duration = _getCacheDuration(_leaderboardKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheAudioEbookData(
    String type,
    List<dynamic> data,
  ) async {
    final key = _generateKey('${_audioEbookKey}_$type');
    final duration = _getCacheDuration(_audioEbookKey);
    await _storeData(key, data, duration);
  }

  static Future<List<dynamic>?> getCachedAudioEbookData(String type) async {
    final key = _generateKey('${_audioEbookKey}_$type');
    final duration = _getCacheDuration(_audioEbookKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheBannerData(List<dynamic> bannerData) async {
    final key = _generateKey(_bannerKey);
    final duration = _getCacheDuration(_bannerKey);
    await _storeData(key, bannerData, duration);
  }

  static Future<List<dynamic>?> getCachedBannerData() async {
    final key = _generateKey(_bannerKey);
    final duration = _getCacheDuration(_bannerKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheFestivalBannerData(
    List<dynamic> festivalBannerData,
  ) async {
    final key = _generateKey(_festivalBannerKey);
    final duration = _getCacheDuration(_festivalBannerKey);
    await _storeData(key, festivalBannerData, duration);
  }

  static Future<List<dynamic>?> getCachedFestivalBannerData() async {
    final key = _generateKey(_festivalBannerKey);
    final duration = _getCacheDuration(_festivalBannerKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cachePujaBannerData(List<dynamic> pujaBannerData) async {
    final key = _generateKey(_pujaBannerKey);
    final duration = _getCacheDuration(_pujaBannerKey);
    await _storeData(key, pujaBannerData, duration);
  }

  static Future<List<dynamic>?> getCachedPujaBannerData() async {
    final key = _generateKey(_pujaBannerKey);
    final duration = _getCacheDuration(_pujaBannerKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheCourseBannerData(
    List<dynamic> courseBannerData,
  ) async {
    final key = _generateKey(_courseBannerKey);
    final duration = _getCacheDuration(_courseBannerKey);
    await _storeData(key, courseBannerData, duration);
  }

  static Future<List<dynamic>?> getCachedCourseBannerData() async {
    final key = _generateKey(_courseBannerKey);
    final duration = _getCacheDuration(_courseBannerKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheUserFavorites(
    String userId,
    Set<String> favorites,
  ) async {
    final key = _generateKey(_favoritesKey, userId: userId);
    final duration = _getCacheDuration(_favoritesKey);
    await _storeData(key, favorites.toList(), duration);
  }

  static Future<Set<String>?> getCachedUserFavorites(String userId) async {
    final key = _generateKey(_favoritesKey, userId: userId);
    final duration = _getCacheDuration(_favoritesKey);
    final data = await _getData<List<dynamic>>(key, duration);
    return data?.map((e) => e.toString()).toSet();
  }

  static Future<void> cacheUserStats(
    String userId,
    Map<String, dynamic> stats,
  ) async {
    final key = _generateKey(_userStatsKey, userId: userId);
    final duration = _getCacheDuration(_userStatsKey);
    await _storeData(key, stats, duration);
  }

  static Future<Map<String, dynamic>?> getCachedUserStats(String userId) async {
    final key = _generateKey(_userStatsKey, userId: userId);
    final duration = _getCacheDuration(_userStatsKey);
    return await _getData<Map<String, dynamic>>(key, duration);
  }

  static Future<void> cacheUserCertificates(
    String userId,
    List<dynamic> certificates,
  ) async {
    final key = _generateKey(_certificatesKey, userId: userId);
    final duration = _getCacheDuration(_certificatesKey);
    await _storeData(key, certificates, duration);
  }

  static Future<List<dynamic>?> getCachedUserCertificates(String userId) async {
    final key = _generateKey(_certificatesKey, userId: userId);
    final duration = _getCacheDuration(_certificatesKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheUserProfile(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    final key = _generateKey(_userProfileKey, userId: userId);
    final duration = _getCacheDuration(_userProfileKey);
    await _storeData(key, profile, duration);
  }

  static Future<Map<String, dynamic>?> getCachedUserProfile(
    String userId,
  ) async {
    final key = _generateKey(_userProfileKey, userId: userId);
    final duration = _getCacheDuration(_userProfileKey);
    return await _getData<Map<String, dynamic>>(key, duration);
  }

  static Future<void> clearUserCache(String userId) async {
    if (_prefs == null) await initialize();

    try {
      final keys = _prefs!.getKeys();
      final userKeys = keys.where((key) => key.contains('_$userId')).toList();

      for (final key in userKeys) {
        await _prefs!.remove(key);
      }
    } catch (e) {}
  }

  static Future<void> clearDataTypeCache(String dataType) async {
    if (_prefs == null) await initialize();

    try {
      final keys = _prefs!.getKeys();
      final dataKeys = keys.where((key) => key.contains(dataType)).toList();

      for (final key in dataKeys) {
        await _prefs!.remove(key);
      }
    } catch (e) {}
  }

  static Future<void> clearAllCache() async {
    if (_prefs == null) await initialize();

    try {
      final keys = _prefs!.getKeys();
      final cacheKeys = keys
          .where(
            (key) =>
                key.startsWith(_cachePrefix) ||
                key.startsWith(_timestampPrefix),
          )
          .toList();

      for (final key in cacheKeys) {
        await _prefs!.remove(key);
      }
    } catch (e) {}
  }

  static Future<void> forceRefreshCache(
    String dataType, {
    String? userId,
  }) async {
    final key = _generateKey(dataType, userId: userId);
    await _clearCache(key);
  }

  static Future<Map<String, dynamic>> getCacheStats() async {
    if (_prefs == null) await initialize();

    try {
      final keys = _prefs!.getKeys();
      final cacheKeys = keys
          .where((key) => key.startsWith(_cachePrefix))
          .toList();
      final timestampKeys = keys
          .where((key) => key.startsWith(_timestampPrefix))
          .toList();

      int validEntries = 0;
      int expiredEntries = 0;

      for (final key in cacheKeys) {
        final dataType = key.replaceFirst(_cachePrefix, '').split('_').first;
        final duration = _getCacheDuration(dataType);

        if (_isCacheValid(key, duration)) {
          validEntries++;
        } else {
          expiredEntries++;
        }
      }

      return {
        'total_entries': cacheKeys.length,
        'valid_entries': validEntries,
        'expired_entries': expiredEntries,
        'timestamp_entries': timestampKeys.length,
      };
    } catch (e) {
      return {};
    }
  }

  static Future<void> preloadCriticalData(String userId) async {}

  static Future<void> cacheUserBookings(
    String userId,
    List<Map<String, dynamic>> bookings,
  ) async {
    final key = _generateKey(_userBookingsKey, userId: userId);
    final duration = _getCacheDuration(_userBookingsKey);
    await _storeData(key, bookings, duration);
  }

  static Future<List<Map<String, dynamic>>?> getCachedUserBookings(
    String userId,
  ) async {
    final key = _generateKey(_userBookingsKey, userId: userId);
    final duration = _getCacheDuration(_userBookingsKey);

    try {
      final data = await _getData<List<dynamic>>(key, duration);
      if (data == null) return null;

      // Convert List<dynamic> to List<Map<String, dynamic>>
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> cacheBookingDetails(
    String paymentId,
    Map<String, dynamic> bookingDetails,
  ) async {
    final key = _generateKey(_bookingDetailsKey, userId: paymentId);
    final duration = _getCacheDuration(_bookingDetailsKey);
    await _storeData(key, bookingDetails, duration);
  }

  static Future<Map<String, dynamic>?> getCachedBookingDetails(
    String paymentId,
  ) async {
    final key = _generateKey(_bookingDetailsKey, userId: paymentId);
    final duration = _getCacheDuration(_bookingDetailsKey);
    return await _getData<Map<String, dynamic>>(key, duration);
  }

  static Future<void> cacheArticlesData(List<dynamic> articlesData) async {
    final key = _generateKey(_articlesKey);
    final duration = _getCacheDuration(_articlesKey);
    await _storeData(key, articlesData, duration);
  }

  static Future<List<dynamic>?> getCachedArticlesData() async {
    final key = _generateKey(_articlesKey);
    final duration = _getCacheDuration(_articlesKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheArticleCategories(List<dynamic> categories) async {
    final key = _generateKey(_articleCategoriesKey);
    final duration = _getCacheDuration(_articleCategoriesKey);
    await _storeData(key, categories, duration);
  }

  static Future<List<dynamic>?> getCachedArticleCategories() async {
    final key = _generateKey(_articleCategoriesKey);
    final duration = _getCacheDuration(_articleCategoriesKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cachePanditList(List<dynamic> panditData) async {
    final key = _generateKey(_panditListKey);
    final duration = _getCacheDuration(_panditListKey);
    await _storeData(key, panditData, duration);
  }

  static Future<List<dynamic>?> getCachedPanditList() async {
    final key = _generateKey(_panditListKey);
    final duration = _getCacheDuration(_panditListKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheSpiritualDiary(
    String userId,
    List<Map<String, dynamic>> diaryData,
  ) async {
    final key = _generateKey(_spiritualDiaryKey, userId: userId);
    final duration = _getCacheDuration(_spiritualDiaryKey);
    await _storeData(key, diaryData, duration);
  }

  static Future<List<Map<String, dynamic>>?> getCachedSpiritualDiary(
    String userId,
  ) async {
    final key = _generateKey(_spiritualDiaryKey, userId: userId);
    final duration = _getCacheDuration(_spiritualDiaryKey);

    try {
      final data = await _getData<List<dynamic>>(key, duration);
      if (data == null) return null;

      // Convert List<dynamic> to List<Map<String, dynamic>>
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> cacheTodaysPujas(List<dynamic> pujaData) async {
    final key = _generateKey(_todaysPujasKey);
    final duration = _getCacheDuration(_todaysPujasKey);
    await _storeData(key, pujaData, duration);
  }

  static Future<List<dynamic>?> getCachedTodaysPujas() async {
    final key = _generateKey(_todaysPujasKey);
    final duration = _getCacheDuration(_todaysPujasKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheUpcomingPujas(List<dynamic> pujaData) async {
    final key = _generateKey(_upcomingPujasKey);
    final duration = _getCacheDuration(_upcomingPujasKey);
    await _storeData(key, pujaData, duration);
  }

  static Future<List<dynamic>?> getCachedUpcomingPujas() async {
    final key = _generateKey(_upcomingPujasKey);
    final duration = _getCacheDuration(_upcomingPujasKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> cacheFamilyPandit(
    String userId,
    Map<String, dynamic> panditData,
  ) async {
    final key = _generateKey(_familyPanditKey, userId: userId);
    final duration = _getCacheDuration(_familyPanditKey);
    await _storeData(key, panditData, duration);
  }

  static Future<Map<String, dynamic>?> getCachedFamilyPandit(
    String userId,
  ) async {
    final key = _generateKey(_familyPanditKey, userId: userId);
    final duration = _getCacheDuration(_familyPanditKey);
    return await _getData<Map<String, dynamic>>(key, duration);
  }

  static Future<void> clearFamilyPanditCache(String userId) async {
    final key = _generateKey(_familyPanditKey, userId: userId);
    await _clearCache(key);
  }

  static Future<void> cachePanditBookings(
    String userId,
    List<Map<String, dynamic>> bookings,
  ) async {
    final key = _generateKey(_panditBookingsKey, userId: userId);
    final duration = _getCacheDuration(_panditBookingsKey);
    await _storeData(key, bookings, duration);
  }

  static Future<List<Map<String, dynamic>>?> getCachedPanditBookings(
    String userId,
  ) async {
    final key = _generateKey(_panditBookingsKey, userId: userId);
    final duration = _getCacheDuration(_panditBookingsKey);

    try {
      final data = await _getData<List<dynamic>>(key, duration);
      if (data == null) return null;

      // Convert List<dynamic> to List<Map<String, dynamic>>
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearPanditBookingsCache(String userId) async {
    final key = _generateKey(_panditBookingsKey, userId: userId);
    await _clearCache(key);
  }

  // Teachers cache methods
  static Future<void> cacheTeachers(List<dynamic> teachers) async {
    final key = _generateKey(_teachersKey);
    final duration = _getCacheDuration(_teachersKey);
    await _storeData(key, teachers, duration);
  }

  static Future<List<dynamic>?> getCachedTeachers() async {
    final key = _generateKey(_teachersKey);
    final duration = _getCacheDuration(_teachersKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> clearTeachersCache() async {
    final key = _generateKey(_teachersKey);
    await _clearCache(key);
  }

  // Webinars cache methods
  static Future<void> cacheWebinars(List<dynamic> webinars) async {
    final key = _generateKey(_webinarsKey);
    final duration = _getCacheDuration(_webinarsKey);
    await _storeData(key, webinars, duration);
  }

  static Future<List<dynamic>?> getCachedWebinars() async {
    final key = _generateKey(_webinarsKey);
    final duration = _getCacheDuration(_webinarsKey);
    return await _getData<List<dynamic>>(key, duration);
  }

  static Future<void> clearWebinarsCache() async {
    final key = _generateKey(_webinarsKey);
    await _clearCache(key);
  }
}
