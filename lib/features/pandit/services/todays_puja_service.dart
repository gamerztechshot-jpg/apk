// features/pandit/services/todays_puja_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/models/puja_model.dart';

class TodaysPujaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get today's puja suggestions
  Future<List<PujaModel>> getTodaysPujaSuggestions({
    bool forceRefresh = false,
  }) async {
    try {
      // Try to get from cache first
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedTodaysPujas();
        if (cachedData != null) {
          return cachedData.map((json) => PujaModel.fromJson(json)).toList();
        }
      }

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final response = await _supabase
          .from('puja_booking')
          .select()
          .gte('event_date', todayStart.toIso8601String())
          .lt('event_date', todayEnd.toIso8601String())
          .order('event_date', ascending: true);

      final pujas = (response as List)
          .map((json) => PujaModel.fromJson(json))
          .toList();

      // Cache the data for future use
      await CacheService.cacheTodaysPujas(response);

      return pujas;
    } catch (e) {
      throw Exception('Failed to fetch today\'s puja suggestions: $e');
    }
  }

  // Get upcoming puja suggestions (next 7 days, excluding today)
  Future<List<PujaModel>> getUpcomingPujaSuggestions({
    bool forceRefresh = false,
  }) async {
    try {
      // Try to get from cache first
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedUpcomingPujas();
        if (cachedData != null) {
          return cachedData.map((json) => PujaModel.fromJson(json)).toList();
        }
      }

      final today = DateTime.now();
      final tomorrow = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(const Duration(days: 1));
      final nextWeek = tomorrow.add(const Duration(days: 7));

      final response = await _supabase
          .from('puja_booking')
          .select()
          .gte('event_date', tomorrow.toIso8601String())
          .lte('event_date', nextWeek.toIso8601String())
          .order('event_date', ascending: true);

      final pujas = (response as List)
          .map((json) => PujaModel.fromJson(json))
          .toList();

      // Cache the data for future use
      await CacheService.cacheUpcomingPujas(response);

      return pujas;
    } catch (e) {
      throw Exception('Failed to fetch upcoming puja suggestions: $e');
    }
  }

  // Get puja suggestions by category
  Future<List<PujaModel>> getPujaSuggestionsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('puja_booking')
          .select()
          .eq('category', category)
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date', ascending: true);

      return (response as List)
          .map((json) => PujaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch puja suggestions by category: $e');
    }
  }

  // Get featured puja suggestions
  Future<List<PujaModel>> getFeaturedPujaSuggestions() async {
    try {
      final response = await _supabase
          .from('puja_booking')
          .select()
          .gte('event_date', DateTime.now().toIso8601String())
          .order('devotee_count', ascending: false)
          .limit(5);

      return (response as List)
          .map((json) => PujaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured puja suggestions: $e');
    }
  }

  // Get puja suggestions based on user preferences
  Future<List<PujaModel>> getPersonalizedPujaSuggestions(String userId) async {
    try {
      // Get user's booking history to understand preferences
      final userBookings = await _supabase
          .from('puja_payment')
          .select('puja_info')
          .eq('user_id', userId);

      // Extract categories from user's previous bookings
      final userCategories = <String>{};
      for (final booking in userBookings) {
        final pujaInfo = Map<String, dynamic>.from(booking['puja_info'] ?? {});
        final pujaId = pujaInfo['puja_id'];
        if (pujaId != null) {
          final pujaDetails = await _supabase
              .from('puja_booking')
              .select('category')
              .eq('id', pujaId)
              .single();
          userCategories.add(pujaDetails['category'] as String? ?? '');
        }
      }

      // Get puja suggestions based on user's preferred categories
      if (userCategories.isNotEmpty) {
        final response = await _supabase
            .from('puja_booking')
            .select()
            .inFilter('category', userCategories.toList())
            .gte('event_date', DateTime.now().toIso8601String())
            .order('event_date', ascending: true);

        return (response as List)
            .map((json) => PujaModel.fromJson(json))
            .toList();
      } else {
        // If no user preferences, return featured pujas
        return await getFeaturedPujaSuggestions();
      }
    } catch (e) {
      return await getFeaturedPujaSuggestions();
    }
  }

  /// Force refresh today's puja data
  Future<List<PujaModel>> refreshTodaysPujaData() async {
    return await getTodaysPujaSuggestions(forceRefresh: true);
  }

  /// Clear today's puja cache
  Future<void> clearTodaysPujaCache() async {
    await CacheService.clearDataTypeCache('todays_pujas');
    await CacheService.clearDataTypeCache('upcoming_pujas');
  }
}
