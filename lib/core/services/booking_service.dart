// core/services/booking_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch bookings for a specific user
  Future<List<Map<String, dynamic>>> getUserBookings(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Step 1: Try to get cached bookings first
      if (!forceRefresh) {
        final cachedBookings = await CacheService.getCachedUserBookings(userId);
        if (cachedBookings != null && cachedBookings.isNotEmpty) {
          return cachedBookings;
        } else {}
      }

      // Step 2: Get all payment records for the user (JSON structure)
      final allPaymentsResponse = await _supabase
          .from('puja_payment')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Normalize and filter rows using nested JSON fields
      final normalized = allPaymentsResponse.map<Map<String, dynamic>>((
        payment,
      ) {
        final pujaInfo = Map<String, dynamic>.from(payment['puja_info'] ?? {});
        final paymentInfo = Map<String, dynamic>.from(
          payment['payment_info'] ?? {},
        );
        final customerInfo = Map<String, dynamic>.from(
          payment['customer_info'] ?? {},
        );

        return {
          ...payment,
          'status': (paymentInfo['payment_status'] ?? 'success').toString(),
          'amount': paymentInfo['amount'],
          'razorpay_payment_id': paymentInfo['razorpay_payment_id'],
          'order_id': paymentInfo['order_id'],
          'puja_id': pujaInfo['puja_id'],
          'package_id': pujaInfo['package_id'],
          'customer_info': customerInfo,
        };
      }).toList();

      // Filter for successful payments (or those without explicit status)
      final paymentResponse = normalized
          .where(
            (p) => (p['status'] == 'success' || p['status'] == 'completed'),
          )
          .toList();

      if (paymentResponse.isEmpty) {
        return [];
      }

      // Step 2: Extract unique puja_ids and package_ids
      final pujaIds = paymentResponse
          .map((payment) => payment['puja_id'] as int)
          .toSet()
          .toList();

      final packageIds = paymentResponse
          .map((payment) => payment['package_id'] as int)
          .toSet()
          .toList();

      // Step 3: Fetch puja details
      Map<int, Map<String, dynamic>> pujaDetails = {};
      if (pujaIds.isNotEmpty) {
        final pujaResponse = await _supabase
            .from('puja_booking')
            .select('id, puja_basic, puja_basic_hi, event_date, puja_images')
            .inFilter('id', pujaIds);

        for (var puja in pujaResponse) {
          pujaDetails[puja['id'] as int] = puja;
        }
      }

      // Step 4: Extract package details from puja records (packages are stored as JSON arrays)
      Map<int, Map<String, dynamic>> packageDetails = {};
      for (var puja in pujaDetails.values) {
        final packages =
            puja['puja_basic']?['packages'] as List<dynamic>? ?? [];
        for (var package in packages) {
          final packageMap = package as Map<String, dynamic>;
          final packageId = packageMap['name']?.hashCode ?? 0;
          packageDetails[packageId] = packageMap;
        }
      }

      // Step 5: Combine the results
      List<Map<String, dynamic>> combinedResults = [];
      for (var payment in paymentResponse) {
        final pujaId = payment['puja_id'] as int;
        final packageId = payment['package_id'] as int;


        final combined = {
          ...payment,
          'puja': pujaDetails[pujaId],
          'package': packageDetails[packageId],
        };
        combinedResults.add(combined);
      }

      // Step 6: Cache the results
      await CacheService.cacheUserBookings(userId, combinedResults);

      return combinedResults;
    } catch (e) {
      rethrow;
    }
  }

  // Get booking details by payment ID
  Future<Map<String, dynamic>?> getBookingDetails(
    String paymentId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Step 1: Try to get cached booking details first
      if (!forceRefresh) {
        final cachedBooking = await CacheService.getCachedBookingDetails(
          paymentId,
        );
        if (cachedBooking != null) {
          return cachedBooking;
        }
      }

      // Step 2: Get payment record
      final paymentResponse = await _supabase
          .from('puja_payment')
          .select('*')
          .contains('payment_info', {'razorpay_payment_id': paymentId})
          .single();

      // paymentResponse will be null if no record found, which is handled by the catch block

      final pujaInfo = Map<String, dynamic>.from(
        paymentResponse['puja_info'] ?? {},
      );
      final paymentInfo = Map<String, dynamic>.from(
        paymentResponse['payment_info'] ?? {},
      );
      final pujaId = pujaInfo['puja_id'] as int;
      final packageId = pujaInfo['package_id'] as int;

      // Step 2: Fetch puja details
      final pujaResponse = await _supabase
          .from('puja_booking')
          .select('id, puja_basic, puja_basic_hi, event_date, puja_images')
          .eq('id', pujaId)
          .single();

      // Step 3: Extract package details from puja record
      Map<String, dynamic>? packageDetails;
      final packages =
          pujaResponse['puja_basic']?['packages'] as List<dynamic>? ?? [];
      for (var package in packages) {
        final packageMap = package as Map<String, dynamic>;
        final currentPackageId = packageMap['name']?.hashCode ?? 0;
        if (currentPackageId == packageId) {
          packageDetails = packageMap;
          break;
        }
      }

      // Step 4: Combine results
      final result = {
        ...paymentResponse,
        'status': (paymentInfo['payment_status'] ?? 'success').toString(),
        'amount': paymentInfo['amount'],
        'razorpay_payment_id': paymentInfo['razorpay_payment_id'],
        'order_id': paymentInfo['order_id'],
        'puja_id': pujaId,
        'package_id': packageId,
        'puja': pujaResponse,
        'package': packageDetails,
      };

      // Step 5: Cache the result
      await CacheService.cacheBookingDetails(paymentId, result);

      return result;
    } catch (e) {
      return null;
    }
  }

  // Cancel a booking (if allowed)
  Future<bool> cancelBooking(String paymentId) async {
    try {
      // Fetch the record, update nested payment_info.status
      final record = await _supabase
          .from('puja_payment')
          .select('id, payment_info')
          .contains('payment_info', {'razorpay_payment_id': paymentId})
          .single();

      final info = Map<String, dynamic>.from(record['payment_info'] ?? {});
      info['payment_status'] = 'cancelled';

      await _supabase
          .from('puja_payment')
          .update({'payment_info': info})
          .eq('id', record['id']);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get booking statistics for user
  Future<Map<String, int>> getUserBookingStats(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Step 1: Try to get cached stats first
      if (!forceRefresh) {
        final cachedStats = await CacheService.getCachedUserStats(userId);
        if (cachedStats != null && cachedStats.containsKey('booking_stats')) {
          return Map<String, int>.from(cachedStats['booking_stats']);
        }
      }

      // Step 2: Fetch from database
      final response = await _supabase
          .from('puja_payment')
          .select('payment_info')
          .eq('user_id', userId);

      int total = response.length;
      String _statusOf(Map<String, dynamic> r) =>
          (Map<String, dynamic>.from(
            r['payment_info'] ?? {},
          ))['payment_status']?.toString() ??
          'success';

      int successful = response
          .where((r) => {'success', 'completed'}.contains(_statusOf(r)))
          .length;
      int pending = response.where((r) => _statusOf(r) == 'pending').length;
      int cancelled = response.where((r) => _statusOf(r) == 'cancelled').length;

      final stats = {
        'total': total,
        'successful': successful,
        'pending': pending,
        'cancelled': cancelled,
      };

      // Step 3: Cache the stats
      final existingStats = await CacheService.getCachedUserStats(userId) ?? {};
      existingStats['booking_stats'] = stats;
      await CacheService.cacheUserStats(userId, existingStats);

      return stats;
    } catch (e) {
      return {'total': 0, 'successful': 0, 'pending': 0, 'cancelled': 0};
    }
  }

  // Clear booking cache for a specific user
  Future<void> clearUserBookingCache(String userId) async {
    try {
      await CacheService.clearUserCache(userId);
    } catch (e) {}
  }

  // Clear all booking caches
  Future<void> clearAllBookingCache() async {
    try {
      await CacheService.clearDataTypeCache('user_bookings');
      await CacheService.clearDataTypeCache('booking_details');
      await CacheService.clearDataTypeCache('user_stats');
    } catch (e) {}
  }

  // Invalidate cache when a new booking is made
  Future<void> invalidateBookingCache(String userId) async {
    try {
      await clearUserBookingCache(userId);
    } catch (e) {}
  }
}
