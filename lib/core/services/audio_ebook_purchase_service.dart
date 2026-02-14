// core/services/audio_ebook_purchase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AudioEbookPurchaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> savePurchaseRecord({
    required String userId,
    required int itemId,
    required String itemType,
    required Map<String, dynamic> paymentInfo,
    String status = 'success',
  }) async {
    try {
      final purchaseData = {
        'user_id': userId,
        'audio_id': itemType == 'audio' ? itemId : null,
        'ebook_id': itemType == 'ebook' ? itemId : null,
        'payment_info': paymentInfo,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (userId.isEmpty) {
        throw Exception('user_id is empty');
      }
      if (itemId <= 0) {
        throw Exception('item_id is invalid: $itemId');
      }
      if (!['audio', 'ebook'].contains(itemType)) {
        throw Exception('item_type must be "audio" or "ebook"');
      }

      await _supabase
          .from('audio_ebook_purchases')
          .insert(purchaseData)
          .select();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasAudioAccess({
    required String userId,
    required int audioId,
  }) async {
    try {
      final response = await _supabase
          .from('audio_ebook_purchases')
          .select()
          .eq('user_id', userId)
          .eq('audio_id', audioId)
          .eq('status', 'success');

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasEbookAccess({
    required String userId,
    required int ebookId,
  }) async {
    try {
      final response = await _supabase
          .from('audio_ebook_purchases')
          .select()
          .eq('user_id', userId)
          .eq('ebook_id', ebookId)
          .eq('status', 'success');

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasItemAccess({
    required String userId,
    required int itemId,
    required String itemType,
  }) async {
    if (itemType == 'audio') {
      return await hasAudioAccess(userId: userId, audioId: itemId);
    } else if (itemType == 'ebook') {
      return await hasEbookAccess(userId: userId, ebookId: itemId);
    } else {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserPurchasedAudios(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('audio_ebook_purchases')
          .select()
          .eq('user_id', userId)
          .not('audio_id', 'is', null)
          .eq('status', 'success')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserPurchasedEbooks(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('audio_ebook_purchases')
          .select()
          .eq('user_id', userId)
          .not('ebook_id', 'is', null)
          .eq('status', 'success')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserPurchasedItems(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('audio_ebook_purchases')
          .select()
          .eq('user_id', userId)
          .eq('status', 'success')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, int>> getUserPurchaseStats(String userId) async {
    try {
      final response = await _supabase
          .from('audio_ebook_purchases')
          .select('audio_id, ebook_id, status')
          .eq('user_id', userId);

      int totalPurchases = response.length;
      int audioPurchases = response.where((r) => r['audio_id'] != null).length;
      int ebookPurchases = response.where((r) => r['ebook_id'] != null).length;
      int successfulPurchases = response
          .where((r) => r['status'] == 'success')
          .length;

      return {
        'total_purchases': totalPurchases,
        'audio_purchases': audioPurchases,
        'ebook_purchases': ebookPurchases,
        'successful_purchases': successfulPurchases,
      };
    } catch (e) {
      return {
        'total_purchases': 0,
        'audio_purchases': 0,
        'ebook_purchases': 0,
        'successful_purchases': 0,
      };
    }
  }

  Future<bool> updatePurchaseStatus({
    required String userId,
    required int itemId,
    required String itemType,
    required String newStatus,
  }) async {
    try {
      final updateData = {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      var query = _supabase
          .from('audio_ebook_purchases')
          .update(updateData)
          .eq('user_id', userId)
          .eq('status', 'success');

      if (itemType == 'audio') {
        query = query.eq('audio_id', itemId);
      } else if (itemType == 'ebook') {
        query = query.eq('ebook_id', itemId);
      } else {
        throw Exception('Invalid item type: $itemType');
      }

      await query.select();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasAnyPurchases(String userId) async {
    try {
      final response = await _supabase
          .from('audio_ebook_purchases')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'success')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
