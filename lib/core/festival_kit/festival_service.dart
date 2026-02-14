// core/festival_kit/festival_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/festival_kit/models/festival_config_model.dart';

class FestivalService {
  static const String _festivalJsonUrl =
      'https://fwhblztexcyxjrfhrrsb.supabase.co/storage/v1/object/public/images/festival.json';
  static const String _cacheKey = 'festival_config';
  static const String _cacheTimestampKey = 'festival_config_timestamp';
  static const Duration _cacheDuration = Duration(hours: 6);

  /// Fetch festival configuration from the JSON URL
  Future<FestivalConfig?> fetchFestivalConfig({
    bool forceRefresh = false,
  }) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedConfig = await _getCachedConfig();
        if (cachedConfig != null) {
          return cachedConfig;
        }
      }

      // Fetch from network with timeout
      final response = await http
          .get(Uri.parse(_festivalJsonUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Request timeout - please check your internet connection',
              );
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch festival config: ${response.statusCode}',
        );
      }

      // Parse JSON response
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final festivalConfig = FestivalConfig.fromJson(jsonData);

      // Cache the data for future use
      await _cacheConfig(festivalConfig);

      return festivalConfig;
    } catch (e) {
      rethrow;
    }
  }

  /// Get cached festival configuration
  Future<FestivalConfig?> _getCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedJson == null || timestamp == null) {
        return null;
      }

      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      if (now.difference(cacheTime) > _cacheDuration) {
        return null;
      }

      final jsonData = json.decode(cachedJson) as Map<String, dynamic>;
      return FestivalConfig.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Cache festival configuration
  Future<void> _cacheConfig(FestivalConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(config.toJson());
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {}
  }

  /// Clear festival config cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {}
  }

  /// Check if festival is active (always fetches fresh data for reliability)
  Future<bool> isFestivalActive({bool forceRefresh = true}) async {
    try {
      final config = await fetchFestivalConfig(forceRefresh: forceRefresh);
      return config?.isCurrentlyActive ?? false;
    } catch (e) {
      return false;
    }
  }
}
