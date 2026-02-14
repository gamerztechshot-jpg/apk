// core/services/puja_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/puja_model.dart';
import 'cache_service.dart';

class PujaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PujaModel>> getAllPujas({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedPujaList();
        if (cachedData != null) {
          return cachedData.map((json) => PujaModel.fromJson(json)).toList();
        }
      }
      final response = await _supabase
          .from('puja_booking')
          .select()
          .order('created_at', ascending: false);

      final pujas = (response as List)
          .map((json) => PujaModel.fromJson(json))
          .toList();

      await CacheService.cachePujaList(response);

      return pujas;
    } catch (e) {
      throw Exception('Failed to fetch pujas: $e');
    }
  }

  Future<PujaModel?> getPujaById(int id) async {
    try {
      final response = await _supabase
          .from('puja_booking')
          .select()
          .eq('id', id)
          .single();

      return PujaModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<PujaModel>> getUpcomingPujas() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('puja_booking')
          .select()
          .gte('event_date', now)
          .order('event_date', ascending: true);

      return (response as List)
          .map((json) => PujaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming pujas: $e');
    }
  }

  Future<List<PujaModel>> searchPujas(String query, bool isHindi) async {
    try {
      if (query.isEmpty) return getAllPujas();

      final response = await _supabase
          .from('puja_booking')
          .select()
          .or(
            isHindi
                ? 'puja_basic_hi->name.ilike.%$query%,puja_basic_hi->title.ilike.%$query%,puja_basic_hi->location.ilike.%$query%'
                : 'puja_basic->name.ilike.%$query%,puja_basic->title.ilike.%$query%,puja_basic->location.ilike.%$query%',
          )
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PujaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search pujas: $e');
    }
  }

  Future<List<PujaModel>> getPujasByCategory(String category) async {
    try {
      final response = await _supabase
          .from('puja_booking')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PujaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pujas by category: $e');
    }
  }

  Future<Map<String, dynamic>> bookPuja({
    required int pujaId,
    required String userId,
    required int packageId,
    required Map<String, dynamic> bookingDetails,
  }) async {
    try {
      final response = await _supabase
          .from('puja_bookings')
          .insert({
            'puja_id': pujaId,
            'user_id': userId,
            'package_id': packageId,
            'booking_details': bookingDetails,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      await CacheService.clearDataTypeCache('puja_list');

      return response;
    } catch (e) {
      throw Exception('Failed to book puja: $e');
    }
  }

  Future<List<PujaModel>> refreshPujaData() async {
    return await getAllPujas(forceRefresh: true);
  }

  Future<void> clearPujaCache() async {
    await CacheService.clearDataTypeCache('puja_list');
  }
}
