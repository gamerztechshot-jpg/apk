// features/dharma_store/services/cart_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';

class CartService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<CartItem> _items = [];
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  String? _currentUserId;

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Initialize the cart service with caching
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {}
  }

  /// Get cache key for current user
  String _getCacheKey(String userId) => 'cart_cache_$userId';

  /// Save cart to cache
  Future<void> _saveToCache() async {
    if (!_isInitialized || _currentUserId == null) return;

    try {
      final cacheKey = _getCacheKey(_currentUserId!);
      final cartData = {
        'items': _items
            .map(
              (item) => {
                'id': item.id,
                'itemId': item.itemId,
                'nameEn': item.nameEn,
                'nameHi': item.nameHi,
                'price': item.price,
                'imageUrl': item.imageUrl,
                'quantity': item.quantity,
                'addedAt': item.addedAt.toIso8601String(),
              },
            )
            .toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'userId': _currentUserId,
      };

      await _prefs!.setString(cacheKey, json.encode(cartData));
    } catch (e) {}
  }

  /// Load cart from cache
  Future<void> _loadFromCache() async {
    if (!_isInitialized || _currentUserId == null) return;

    try {
      final cacheKey = _getCacheKey(_currentUserId!);
      final cachedData = _prefs!.getString(cacheKey);

      if (cachedData != null) {
        final cartData = json.decode(cachedData);
        final items = cartData['items'] as List<dynamic>;

        _items.clear();
        for (final itemData in items) {
          final cartItem = CartItem(
            id: itemData['id'] ?? '',
            itemId: itemData['itemId'] ?? '',
            nameEn: itemData['nameEn'] ?? '',
            nameHi: itemData['nameHi'] ?? '',
            price: (itemData['price'] ?? 0.0).toDouble(),
            imageUrl: itemData['imageUrl'],
            quantity: itemData['quantity'] ?? 1,
            addedAt:
                DateTime.tryParse(itemData['addedAt'] ?? '') ?? DateTime.now(),
          );
          _items.add(cartItem);
        }

        notifyListeners();
      }
    } catch (e) {}
  }

  /// Check if cache is valid (not older than 24 hours)
  bool _isCacheValid(String cachedData) {
    try {
      final cartData = json.decode(cachedData);
      final lastUpdated = DateTime.tryParse(cartData['lastUpdated'] ?? '');
      if (lastUpdated == null) return false;

      final now = DateTime.now();
      final difference = now.difference(lastUpdated);
      return difference.inHours < 24; // Cache valid for 24 hours
    } catch (e) {
      return false;
    }
  }

  /// Load cart from database with caching
  Future<void> loadCart() async {
    try {
      await initialize();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return;
      }

      _currentUserId = userId;

      // First try to load from cache
      if (_isInitialized) {
        final cacheKey = _getCacheKey(userId);
        final cachedData = _prefs!.getString(cacheKey);

        if (cachedData != null && _isCacheValid(cachedData)) {
          await _loadFromCache();
          return;
        } else if (cachedData != null) {}
      }

      // Load from database

      // First check if there are multiple rows and clean them up
      final allRows = await _supabase
          .from('cart')
          .select('*')
          .eq('user_id', userId);

      if (allRows.length > 1) {
        await cleanupDuplicateCartRows();
        return; // This will call loadCart() again after cleanup
      }

      final response = await _supabase
          .from('cart')
          .select('items')
          .eq('user_id', userId)
          .maybeSingle();

      _items.clear();

      if (response != null && response['items'] != null) {
        final List<dynamic> itemsJson = response['items'];

        for (final itemData in itemsJson) {
          final cartItem = CartItem(
            id: itemData['id'] ?? '',
            itemId: itemData['id'] ?? '',
            nameEn: itemData['name'] ?? '',
            nameHi:
                itemData['name'] ?? '', // Using same name for both languages
            price: (itemData['price'] ?? 0.0).toDouble(),
            imageUrl: itemData['image'],
            quantity: itemData['quantity'] ?? 1,
            addedAt: DateTime.now(),
          );
          _items.add(cartItem);
        }
      }

      // Save to cache after loading from database
      await _saveToCache();

      notifyListeners();
    } catch (e) {
      // Try to load from cache as fallback
      if (_isInitialized && _currentUserId != null) {
        await _loadFromCache();
      }
    }
  }

  /// Add item to cart
  Future<void> addToCart({
    required String itemId,
    required String nameEn,
    required String nameHi,
    required double price,
    String? imageUrl,
    int quantity = 1,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Get current cart or create new one
      final cartResponse = await _supabase
          .from('cart')
          .select('items')
          .eq('user_id', userId)
          .maybeSingle();

      List<dynamic> items = [];
      if (cartResponse != null && cartResponse['items'] != null) {
        items = List<dynamic>.from(cartResponse['items']);
      } else {
        // Initialize with empty array if no cart exists
        items = [];
      }

      // Check if item already exists in cart
      bool itemExists = false;
      for (int i = 0; i < items.length; i++) {
        if (items[i]['id'] == itemId) {
          // Update existing item quantity
          items[i]['quantity'] = (items[i]['quantity'] ?? 1) + quantity;
          itemExists = true;

          break;
        }
      }

      if (!itemExists) {
        // Add new item
        final newItem = {
          'id': itemId,
          'name': nameEn,
          'image': imageUrl,
          'quantity': quantity,
          'price': price,
        };
        items.add(newItem);
      }

      // Upsert cart (this will create or update the single row for this user)
      await _supabase.from('cart').upsert({
        'user_id': userId,
        'items': items,
      }, onConflict: 'user_id');

      // Update local items and save to cache
      _items.clear();
      for (final itemData in items) {
        final cartItem = CartItem(
          id: itemData['id'] ?? '',
          itemId: itemData['id'] ?? '',
          nameEn: itemData['name'] ?? '',
          nameHi: itemData['name'] ?? '',
          price: (itemData['price'] ?? 0.0).toDouble(),
          imageUrl: itemData['image'],
          quantity: itemData['quantity'] ?? 1,
          addedAt: DateTime.now(),
        );
        _items.add(cartItem);
      }

      // Save to cache and notify listeners
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String itemId, int newQuantity) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      if (newQuantity <= 0) {
        await removeFromCart(itemId);
        return;
      }

      final cartResponse = await _supabase
          .from('cart')
          .select('items')
          .eq('user_id', userId)
          .single();

      final List<dynamic> items = List<dynamic>.from(cartResponse['items']);

      bool itemFound = false;
      for (int i = 0; i < items.length; i++) {
        if (items[i]['id'] == itemId) {
          items[i]['quantity'] = newQuantity;
          itemFound = true;

          break;
        }
      }

      if (itemFound) {
        await _supabase
            .from('cart')
            .update({'items': items})
            .eq('user_id', userId);

        // Update local items and save to cache
        _items.clear();
        for (final itemData in items) {
          final cartItem = CartItem(
            id: itemData['id'] ?? '',
            itemId: itemData['id'] ?? '',
            nameEn: itemData['name'] ?? '',
            nameHi: itemData['name'] ?? '',
            price: (itemData['price'] ?? 0.0).toDouble(),
            imageUrl: itemData['image'],
            quantity: itemData['quantity'] ?? 1,
            addedAt: DateTime.now(),
          );
          _items.add(cartItem);
        }

        // Save to cache and notify listeners
        await _saveToCache();
        notifyListeners();
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final cartResponse = await _supabase
          .from('cart')
          .select('items')
          .eq('user_id', userId)
          .single();

      final List<dynamic> items = List<dynamic>.from(cartResponse['items']);
      final initialLength = items.length;

      items.removeWhere((item) => item['id'] == itemId);

      if (items.length < initialLength) {
        await _supabase
            .from('cart')
            .update({'items': items})
            .eq('user_id', userId);

        // Update local items and save to cache
        _items.clear();
        for (final itemData in items) {
          final cartItem = CartItem(
            id: itemData['id'] ?? '',
            itemId: itemData['id'] ?? '',
            nameEn: itemData['name'] ?? '',
            nameHi: itemData['name'] ?? '',
            price: (itemData['price'] ?? 0.0).toDouble(),
            imageUrl: itemData['image'],
            quantity: itemData['quantity'] ?? 1,
            addedAt: DateTime.now(),
          );
          _items.add(cartItem);
        }

        // Save to cache and notify listeners
        await _saveToCache();
        notifyListeners();
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      await _supabase.from('cart').update({'items': []}).eq('user_id', userId);

      _items.clear();
      await _saveToCache();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if item is in cart
  bool isInCart(String itemId) {
    return _items.any((item) => item.id == itemId);
  }

  /// Get item quantity in cart
  int getItemQuantity(String itemId) {
    final item = _items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => CartItem(
        id: '',
        itemId: '',
        nameEn: '',
        nameHi: '',
        price: 0,
        quantity: 0,
        addedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }

  /// Debug method to add sample items to cart for testing
  Future<void> addSampleItems() async {
    try {
      // Get first few items from store
      final storeItems = await _supabase
          .from('store')
          .select('id, name_en, name_hi, price, image_url')
          .limit(2);

      for (final item in storeItems) {
        await addToCart(
          itemId: item['id'],
          nameEn: item['name_en'],
          nameHi: item['name_hi'],
          price: (item['price'] ?? 0.0).toDouble(),
          imageUrl: item['image_url'],
          quantity: 1,
        );
      }
    } catch (e) {}
  }

  /// Debug method to clear all cart items
  Future<void> debugClearAll() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('cart').delete().eq('user_id', userId);
      _items.clear();
      notifyListeners();
    } catch (e) {}
  }

  /// Debug method to clean up duplicate cart rows
  Future<void> cleanupDuplicateCartRows() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get all cart rows for this user
      final allCartRows = await _supabase
          .from('cart')
          .select('*')
          .eq('user_id', userId);

      if (allCartRows.length <= 1) {
        return;
      }

      // Merge all items from all rows
      List<dynamic> allItems = [];
      for (final row in allCartRows) {
        if (row['items'] != null) {
          allItems.addAll(List<dynamic>.from(row['items']));
        }
      }

      // Remove duplicates (same item_id)
      Map<String, dynamic> uniqueItems = {};
      for (final item in allItems) {
        final itemId = item['id'];
        if (uniqueItems.containsKey(itemId)) {
          // Merge quantities
          uniqueItems[itemId]['quantity'] =
              (uniqueItems[itemId]['quantity'] ?? 1) + (item['quantity'] ?? 1);
        } else {
          uniqueItems[itemId] = Map<String, dynamic>.from(item);
        }
      }

      final mergedItems = uniqueItems.values.toList();

      // Delete all existing rows
      await _supabase.from('cart').delete().eq('user_id', userId);

      // Create single row with merged items
      if (mergedItems.isNotEmpty) {
        await _supabase.from('cart').insert({
          'user_id': userId,
          'items': mergedItems,
        });
      }

      // Reload cart
      await loadCart();
    } catch (e) {}
  }
}
