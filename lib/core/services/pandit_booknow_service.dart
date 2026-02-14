// core/services/pandit_booknow_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class PanditBookNowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> submitBookingRequest({
    required String userId,
    required String panditId,
    required String name,
    required String pujaDetails,
    Map<String, dynamic>? additionalDetails,
  }) async {
    try {
      final bookingData = {
        'user_id': userId,
        'pandit_id': panditId,
        'details': {
          'name': name,
          'puja_details': pujaDetails,
          'booking_date': DateTime.now().toIso8601String(),
          'status': 'pending',
          ...?additionalDetails,
        },
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('pandit_booknow')
          .insert(bookingData)
          .select()
          .single();

      await _invalidateCachesAfterBooking(userId, panditId);

      return {
        'success': true,
        'data': response,
        'message': 'Booking request submitted successfully',
      };
    } catch (e) {
      if (kDebugMode) {
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to submit booking request: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getPanditBookings(String panditId) async {
    try {
      final response = await _supabase
          .from('pandit_booknow')
          .select()
          .eq('pandit_id', panditId)
          .order('created_at', ascending: false);

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getUserBookings(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedPanditBookings(userId);
        if (cachedData != null) {
          return {'success': true, 'data': cachedData};
        }
      }

      final response = await _supabase
          .from('pandit_booknow')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> bookingsData = response
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      await CacheService.cachePanditBookings(userId, bookingsData);

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String status,
    String? notes,
  }) async {
    try {
      final updateData = {
        'details': {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
          if (notes != null) 'notes': notes,
        },
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('pandit_booknow')
          .update(updateData)
          .eq('id', bookingId)
          .select()
          .single();

      return {
        'success': true,
        'data': response,
        'message': 'Booking status updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to update booking status',
      };
    }
  }

  Future<Map<String, dynamic>> deleteBooking(String bookingId) async {
    try {
      await _supabase.from('pandit_booknow').delete().eq('id', bookingId);

      return {'success': true, 'message': 'Booking deleted successfully'};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to delete booking',
      };
    }
  }

  Future<Map<String, dynamic>> refreshUserBookings(String userId) async {
    return await getUserBookings(userId, forceRefresh: true);
  }

  Future<void> clearPanditBookingsCache(String userId) async {
    await CacheService.clearPanditBookingsCache(userId);
  }

  Future<void> _invalidateCachesAfterBooking(
    String userId,
    String panditId,
  ) async {
    try {
      await CacheService.clearPanditBookingsCache(userId);
      await CacheService.clearFamilyPanditCache(userId);
      await CacheService.clearDataTypeCache('pandit_list');
    } catch (e) {
      // Silent error handling
    }
  }
}
