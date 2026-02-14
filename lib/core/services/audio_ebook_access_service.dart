// core/services/audio_ebook_access_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audio_ebook_purchase_service.dart';
import '../models/audio_ebook_model.dart';

class AudioEbookAccessService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioEbookPurchaseService _purchaseService =
      AudioEbookPurchaseService();

  Future<bool> hasAccess({
    required String userId,
    required AudioEbookModel item,
  }) async {
    try {
      if (!item.paid) {
        return true;
      }

      final hasPurchased = await _purchaseService.hasItemAccess(
        userId: userId,
        itemId: item.id,
        itemType: item.type.toLowerCase(),
      );

      return hasPurchased;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasAudioAccess({
    required String userId,
    required int audioId,
  }) async {
    try {
      return await _purchaseService.hasAudioAccess(
        userId: userId,
        audioId: audioId,
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasEbookAccess({
    required String userId,
    required int ebookId,
  }) async {
    try {
      return await _purchaseService.hasEbookAccess(
        userId: userId,
        ebookId: ebookId,
      );
    } catch (e) {
      return false;
    }
  }

  Future<List<AudioEbookModel>> getAccessibleItems({
    required String userId,
    required List<AudioEbookModel> allItems,
  }) async {
    try {
      List<AudioEbookModel> accessibleItems = [];

      for (final item in allItems) {
        final hasItemAccess = await hasAccess(userId: userId, item: item);
        if (hasItemAccess) {
          accessibleItems.add(item);
        }
      }

      return accessibleItems;
    } catch (e) {
      return [];
    }
  }

  Future<List<AudioEbookModel>> getPurchasedItems({
    required String userId,
    required List<AudioEbookModel> allItems,
  }) async {
    try {
      List<AudioEbookModel> purchasedItems = [];

      for (final item in allItems) {
        if (item.paid) {
          final hasPurchased = await _purchaseService.hasItemAccess(
            userId: userId,
            itemId: item.id,
            itemType: item.type.toLowerCase(),
          );
          if (hasPurchased) {
            purchasedItems.add(item);
          }
        }
      }

      return purchasedItems;
    } catch (e) {
      return [];
    }
  }

  Future<List<AudioEbookModel>> getItemsRequiringPurchase({
    required String userId,
    required List<AudioEbookModel> allItems,
  }) async {
    try {
      List<AudioEbookModel> itemsRequiringPurchase = [];

      for (final item in allItems) {
        if (item.paid) {
          final hasItemAccess = await hasAccess(userId: userId, item: item);
          if (!hasItemAccess) {
            itemsRequiringPurchase.add(item);
          }
        }
      }

      return itemsRequiringPurchase;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPurchaseHistoryWithDetails(
    String userId,
  ) async {
    try {
      final purchases = await _purchaseService.getUserPurchasedItems(userId);

      if (purchases.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> purchaseHistory = [];

      for (final purchase in purchases) {
        try {
          final itemId = purchase['audio_id'] ?? purchase['ebook_id'];
          final itemType = purchase['audio_id'] != null ? 'audio' : 'ebook';
          final tableName = itemType == 'audio' ? 'audiobooks' : 'ebooks';

          final itemResponse = await _supabase
              .from(tableName)
              .select()
              .eq('id', itemId)
              .single();

          final item = AudioEbookModel.fromMap(itemResponse, itemType);

          final purchaseWithDetails = {
            ...purchase,
            'item_details': {
              'id': item.id,
              'title': item.title,
              'description': item.description,
              'category': item.category,
              'language': item.language,
              'type': item.type,
              'images': item.images,
              'url': item.url,
              'price': item.priceText,
            },
          };

          purchaseHistory.add(purchaseWithDetails);
        } catch (e) {
          purchaseHistory.add(purchase);
        }
      }

      return purchaseHistory;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAccessInfo({
    required String userId,
    required AudioEbookModel item,
  }) async {
    try {
      final hasItemAccess = await hasAccess(userId: userId, item: item);

      return {
        'hasAccess': hasItemAccess,
        'isFree': !item.paid,
        'isPurchased': item.paid && hasItemAccess,
        'requiresPurchase': item.paid && !hasItemAccess,
        'item': item,
      };
    } catch (e) {
      return {
        'hasAccess': false,
        'isFree': !item.paid,
        'isPurchased': false,
        'requiresPurchase': item.paid,
        'item': item,
      };
    }
  }

  Future<Map<String, dynamic>> getAccessSummary({
    required String userId,
    required List<AudioEbookModel> allItems,
  }) async {
    try {
      final accessibleItems = await getAccessibleItems(
        userId: userId,
        allItems: allItems,
      );
      final purchasedItems = await getPurchasedItems(
        userId: userId,
        allItems: allItems,
      );
      final itemsRequiringPurchase = await getItemsRequiringPurchase(
        userId: userId,
        allItems: allItems,
      );
      final purchaseStats = await _purchaseService.getUserPurchaseStats(userId);

      final summary = {
        'total_items': allItems.length,
        'accessible_items': accessibleItems.length,
        'purchased_items': purchasedItems.length,
        'free_items': allItems.where((item) => !item.paid).length,
        'items_requiring_purchase': itemsRequiringPurchase.length,
        'purchase_stats': purchaseStats,
        'access_percentage': allItems.isNotEmpty
            ? (accessibleItems.length / allItems.length * 100).round()
            : 0,
      };

      return summary;
    } catch (e) {
      return {
        'total_items': 0,
        'accessible_items': 0,
        'purchased_items': 0,
        'free_items': 0,
        'items_requiring_purchase': 0,
        'purchase_stats': {},
        'access_percentage': 0,
      };
    }
  }

  Future<bool> validateAccess({
    required String userId,
    required int itemId,
    required String itemType,
  }) async {
    try {
      final hasAccess = await _purchaseService.hasItemAccess(
        userId: userId,
        itemId: itemId,
        itemType: itemType,
      );

      return hasAccess;
    } catch (e) {
      return false;
    }
  }
}
