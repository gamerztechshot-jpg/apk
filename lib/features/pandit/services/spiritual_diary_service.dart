// features/pandit/services/spiritual_diary_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cache_service.dart';

class SpiritualDiaryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get spiritual diary activities for a user
  Future<List<Map<String, dynamic>>> getSpiritualDiaryActivities(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Try to get from cache first
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedSpiritualDiary(userId);
        if (cachedData != null) {
          return cachedData;
        }
      }

      // Get all activities in parallel
      final results = await Future.wait([
        _getNaamJapaActivities(userId),
        _getPujaBookings(userId),
        _getAudioEbookPurchases(userId),
      ]);

      final naamJapaActivities = results[0];
      final pujaBookings = results[1];
      final audioEbookPurchases = results[2];

      // Combine all activities
      final allActivities = <Map<String, dynamic>>[];
      allActivities.addAll(naamJapaActivities);
      allActivities.addAll(pujaBookings);
      allActivities.addAll(audioEbookPurchases);

      // Sort by date (most recent first)
      allActivities.sort((a, b) {
        final dateA = DateTime.parse(a['date'] as String);
        final dateB = DateTime.parse(b['date'] as String);
        return dateB.compareTo(dateA);
      });

      // Cache the results
      await CacheService.cacheSpiritualDiary(userId, allActivities);

      return allActivities;
    } catch (e) {
      throw Exception('Failed to fetch spiritual diary activities: $e');
    }
  }

  // Get naam japa activities
  Future<List<Map<String, dynamic>>> _getNaamJapaActivities(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('daily_japa')
          .select('*')
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(50);

      return (response as List).map((record) {
        return {
          'type': 'naam_japa',
          'id': record['id'],
          'title': 'Naam Japa Completed',
          'description': 'Completed ${record['count']} repetitions',
          'date': record['date'],
          'created_at': record['created_at'],
          'count': record['count'],
          'mantra_id': record['mantra_id'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get puja bookings
  Future<List<Map<String, dynamic>>> _getPujaBookings(String userId) async {
    try {
      final response = await _supabase
          .from('puja_payment')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List).map((record) {
        final pujaInfo = Map<String, dynamic>.from(record['puja_info'] ?? {});
        final paymentInfo = Map<String, dynamic>.from(
          record['payment_info'] ?? {},
        );

        return {
          'type': 'puja_booked',
          'id': record['id'],
          'title': 'Puja Booked',
          'description': 'Puja booking completed',
          'date': record['created_at'].toString().split('T')[0],
          'created_at': record['created_at'],
          'puja_id': pujaInfo['puja_id'],
          'package_id': pujaInfo['package_id'],
          'amount': paymentInfo['amount'],
          'status': paymentInfo['payment_status'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get audio/ebook purchases
  Future<List<Map<String, dynamic>>> _getAudioEbookPurchases(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('audio_ebook_purchases')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List).map((record) {
        return {
          'type': 'audio_ebook_purchased',
          'id': record['id'],
          'title': 'Audio/Ebook Purchased',
          'description': 'Purchased ${record['title']}',
          'date': record['created_at'].toString().split('T')[0],
          'created_at': record['created_at'],
          'item_title': record['title'],
          'item_type': record['type'],
          'amount': record['amount'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get today's spiritual activities
  Future<List<Map<String, dynamic>>> getTodaysActivities(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('daily_japa')
          .select('*')
          .eq('user_id', userId)
          .eq('date', today);

      return (response as List).map((record) {
        return {
          'type': 'naam_japa',
          'id': record['id'],
          'title': 'Today\'s Naam Japa',
          'description': 'Completed ${record['count']} repetitions today',
          'date': record['date'],
          'created_at': record['created_at'],
          'count': record['count'],
          'mantra_id': record['mantra_id'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get spiritual diary statistics
  Future<Map<String, dynamic>> getSpiritualDiaryStats(String userId) async {
    try {
      final activities = await getSpiritualDiaryActivities(userId);

      int naamJapaCount = 0;
      int pujaBookingsCount = 0;
      int audioEbookPurchasesCount = 0;
      int totalJapaCount = 0;

      for (final activity in activities) {
        switch (activity['type']) {
          case 'naam_japa':
            naamJapaCount++;
            totalJapaCount += activity['count'] as int? ?? 0;
            break;
          case 'puja_booked':
            pujaBookingsCount++;
            break;
          case 'audio_ebook_purchased':
            audioEbookPurchasesCount++;
            break;
        }
      }

      return {
        'total_activities': activities.length,
        'naam_japa_sessions': naamJapaCount,
        'puja_bookings': pujaBookingsCount,
        'audio_ebook_purchases': audioEbookPurchasesCount,
        'total_japa_count': totalJapaCount,
        'last_activity_date': activities.isNotEmpty
            ? activities.first['date']
            : null,
      };
    } catch (e) {
      return {
        'total_activities': 0,
        'naam_japa_sessions': 0,
        'puja_bookings': 0,
        'audio_ebook_purchases': 0,
        'total_japa_count': 0,
        'last_activity_date': null,
      };
    }
  }

  /// Clear spiritual diary cache
  Future<void> clearSpiritualDiaryCache(String userId) async {
    await CacheService.clearDataTypeCache('spiritual_diary_$userId');
  }
}
