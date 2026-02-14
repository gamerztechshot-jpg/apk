// features/dharma_store/services/store_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/models/store.dart';

class StoreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Cache for products
  List<Store>? _cachedProducts;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(
    hours: 2,
  ); // Cache for 2 hours (longer for store items)
  static const String _storeCacheKey = 'dharma_store_products_cache';
  static const String _categoriesCacheKey = 'dharma_store_categories_cache';
  static const String _bannersCacheKey = 'dharma_store_banners_cache';

  /// Initialize the store service with persistent caching
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      //
    } catch (e) {}
  }

  /// Save products to persistent cache
  Future<void> _saveProductsToCache(List<Store> products) async {
    if (!_isInitialized) return;

    try {
      final cacheData = {
        'products': products.map((product) => _storeToJson(product)).toList(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'count': products.length,
      };

      await _prefs!.setString(_storeCacheKey, json.encode(cacheData));
    } catch (e) {}
  }

  /// Get store banners (URLs) with lightweight caching
  Future<List<String>> getStoreBanners() async {
    await initialize();

    // Try cache first (short TTL ~1 hour)
    try {
      final cached = _prefs?.getString(_bannersCacheKey);
      if (cached != null) {
        final data = json.decode(cached);
        final lastUpdated = DateTime.tryParse(data['lastUpdated'] ?? '');
        if (lastUpdated != null &&
            DateTime.now().difference(lastUpdated) < const Duration(hours: 1)) {
          final urls = List<String>.from(data['urls'] ?? []);
          if (urls.isNotEmpty) return urls;
        }
      }
    } catch (_) {}

    // Fetch from database
    try {
      final response = await _supabase
          .from('store_banners')
          .select('url, priority')
          .order('priority', ascending: true);

      final urls = (response as List<dynamic>)
          .map((e) => (e['url'] as String?)?.trim())
          .whereType<String>()
          .where((u) => u.isNotEmpty)
          .toList();

      // Save to cache
      try {
        await _prefs?.setString(
          _bannersCacheKey,
          json.encode({
            'urls': urls,
            'lastUpdated': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}

      return urls;
    } catch (e) {
      return [];
    }
  }

  /// Load products from persistent cache
  Future<List<Store>?> _loadProductsFromCache() async {
    if (!_isInitialized) return null;

    try {
      final cachedData = _prefs!.getString(_storeCacheKey);
      if (cachedData == null) return null;

      final cacheData = json.decode(cachedData);
      final lastUpdated = DateTime.tryParse(cacheData['lastUpdated'] ?? '');

      // Check if cache is still valid
      if (lastUpdated == null ||
          DateTime.now().difference(lastUpdated) > _cacheExpiry) {
        return null;
      }

      final productsJson = cacheData['products'] as List<dynamic>;
      final products = productsJson
          .map((json) => _storeFromJson(json))
          .toList();

      return products;
    } catch (e) {
      return null;
    }
  }

  /// Save categories to persistent cache
  Future<void> _saveCategoriesToCache(List<String> categories) async {
    if (!_isInitialized) return;

    try {
      final cacheData = {
        'categories': categories,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _prefs!.setString(_categoriesCacheKey, json.encode(cacheData));
    } catch (e) {}
  }

  /// Load categories from persistent cache
  Future<List<String>?> _loadCategoriesFromCache() async {
    if (!_isInitialized) return null;

    try {
      final cachedData = _prefs!.getString(_categoriesCacheKey);
      if (cachedData == null) return null;

      final cacheData = json.decode(cachedData);
      final lastUpdated = DateTime.tryParse(cacheData['lastUpdated'] ?? '');

      // Check if cache is still valid (categories change less frequently)
      if (lastUpdated == null ||
          DateTime.now().difference(lastUpdated) > Duration(hours: 6)) {
        return null;
      }

      final categories = List<String>.from(cacheData['categories'] ?? []);
      return categories;
    } catch (e) {
      return null;
    }
  }

  /// Convert Store to JSON for caching
  Map<String, dynamic> _storeToJson(Store store) {
    return {
      'id': store.id,
      'nameEn': store.nameEn,
      'nameHi': store.nameHi,
      'descriptionEn': store.descriptionEn,
      'descriptionHi': store.descriptionHi,
      'price': store.price,
      'originalPrice': store.originalPrice,
      'imageUrl': store.imageUrl,
      'images': store.images,
      'category': store.category,
      'sizes': store.sizes,
      'colors': store.colors,
      'reviews': store.reviews
          .map(
            (review) => {
              'id': review.id,
              'reviewerNameEn': review.reviewerNameEn,
              'reviewerNameHi': review.reviewerNameHi,
              'rating': review.rating,
              'commentEn': review.commentEn,
              'commentHi': review.commentHi,
              'createdAt': review.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'isAvailable': store.isAvailable,
      'createdAt': store.createdAt.toIso8601String(),
      'updatedAt': store.updatedAt.toIso8601String(),
    };
  }

  /// Convert JSON to Store from cache
  Store _storeFromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? '',
      nameEn: json['nameEn'] ?? '',
      nameHi: json['nameHi'] ?? '',
      descriptionEn: json['descriptionEn'] ?? '',
      descriptionHi: json['descriptionHi'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      imageUrl: json['imageUrl'],
      images: List<String>.from(json['images'] ?? []),
      category: json['category'] ?? 'General',
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.map(
                (reviewJson) => Review(
                  id: reviewJson['id'] ?? '',
                  reviewerNameEn: reviewJson['reviewerNameEn'] ?? '',
                  reviewerNameHi: reviewJson['reviewerNameHi'] ?? '',
                  rating: reviewJson['rating'] ?? 5,
                  commentEn: reviewJson['commentEn'] ?? '',
                  commentHi: reviewJson['commentHi'] ?? '',
                  createdAt:
                      DateTime.tryParse(reviewJson['createdAt'] ?? '') ??
                      DateTime.now(),
                ),
              )
              .toList() ??
          [],
      isAvailable: json['isAvailable'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Clear all caches (useful for refreshing data)
  Future<void> clearCache() async {
    _cachedProducts = null;
    _lastFetchTime = null;

    if (_isInitialized) {
      await _prefs!.remove(_storeCacheKey);
      await _prefs!.remove(_categoriesCacheKey);
    }
  }

  /// Test database connection and table structure
  Future<void> testConnection() async {
    try {
      // Test basic connection
      final testResponse = await _supabase
          .from('store')
          .select('id, created_at')
          .limit(1);

      //

      // Test table structure
      final structureResponse = await _supabase
          .from('store')
          .select('*')
          .limit(1);

      //

      // Test with RLS bypass (if possible)
      try {
        final rlsBypassResponse = await _supabase
            .from('store')
            .select('*')
            .limit(1);
      } catch (e) {}
    } catch (e) {}
  }

  /// Simple test method to check if we can fetch store data
  Future<List<Map<String, dynamic>>> testStoreAccess() async {
    try {
      final response = await _supabase
          .from('store')
          .select('id, info, pricing, images')
          .limit(3);

      //
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Fetch all products from the store table with persistent caching
  Future<List<Store>> getProducts({bool isHindi = false}) async {
    await initialize();

    // First try to load from persistent cache
    final cachedProducts = await _loadProductsFromCache();
    if (cachedProducts != null) {
      _cachedProducts = cachedProducts;
      _lastFetchTime = DateTime.now();
      return cachedProducts;
    }

    // Return in-memory cached data if available and not expired
    if (_cachedProducts != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry) {
      return _cachedProducts!;
    }

    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;

      // Try different approaches to fetch data
      List<dynamic> response = [];

      try {
        // First try: Simple select without filters
        response = await _supabase
            .from('store')
            .select('*')
            .order('created_at', ascending: false);

        //

        // Debug first few rows to understand category field shape
        for (var i = 0; i < (response.length < 5 ? response.length : 5); i++) {
          final r = response[i] as Map<String, dynamic>;
          final info = r['info'];
        }
      } catch (e) {
        try {
          // Second try: Select with specific columns
          response = await _supabase
              .from('store')
              .select(
                'id, info, images, reviews, pricing, is_active, created_at',
              )
              .order('created_at', ascending: false);

          //
        } catch (e2) {
          try {
            // Third try: Select with limit
            response = await _supabase.from('store').select('*').limit(5);
          } catch (e3) {
            throw e3;
          }
        }
      }

      if (response.isEmpty) {
        return [];
      }

      final products = response
          .map((data) => _mapStoreData(data, isHindi: isHindi))
          .toList();

      // Debug resolved categories for first few products
      for (var i = 0; i < (products.length < 5 ? products.length : 5); i++) {
        final p = products[i];
      }

      // Cache the results in memory and persistent storage
      _cachedProducts = products;
      _lastFetchTime = DateTime.now();
      await _saveProductsToCache(products);

      return products;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch product by ID
  Future<Store> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('store')
          .select('*')
          .eq('id', id)
          .eq('is_active', true)
          .single();

      final product = _mapStoreData(response);

      return product;
    } catch (e) {
      rethrow;
    }
  }

  /// Map database data to Store model
  Store _mapStoreData(Map<String, dynamic> data, {bool isHindi = false}) {
    final info = data['info'] as Map<String, dynamic>? ?? {};
    final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
    final reviews = data['reviews'] as List<dynamic>? ?? [];
    final images = data['images'] as List<dynamic>? ?? [];

    // Prefer localized category jsonb if present
    String resolvedCategory = 'General';
    final catRaw = data['category'];
    Map<String, dynamic>? catJson;
    if (catRaw is Map) {
      catJson = Map<String, dynamic>.from(catRaw as Map);
    } else if (catRaw is String) {
      try {
        final decoded = json.decode(catRaw);
        if (decoded is Map) {
          catJson = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    if (catJson != null) {
      final key = isHindi ? 'category_hi' : 'category_en';
      resolvedCategory = (catJson[key] as String?)?.trim() ?? 'General';
    } else {
      resolvedCategory = (info['category'] as String?)?.trim() ?? 'General';
    }

    final store = Store(
      id: data['id'] ?? '',
      nameEn: info['title_en'] ?? '',
      nameHi: info['title_hi'] ?? '',
      descriptionEn: info['description_en'] ?? '',
      descriptionHi: info['description_hi'] ?? '',
      price: (pricing['current_price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (pricing['original_price'] as num?)?.toDouble(),
      imageUrl: images.isNotEmpty ? images.first.toString() : null,
      images: images.map((e) => e.toString()).toList(),
      category: resolvedCategory,
      sizes:
          (info['sizes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      colors:
          (info['colors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reviews: reviews.map((review) => _mapReviewData(review)).toList(),
      isAvailable: data['is_active'] ?? true,
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
    );

    return store;
  }

  /// Map review data to Review model
  Review _mapReviewData(Map<String, dynamic> reviewData) {
    // Handle the actual review structure from your database
    return Review(
      id: reviewData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      reviewerNameEn: reviewData['name_en'] ?? 'Anonymous',
      reviewerNameHi: reviewData['name_hi'] ?? 'अज्ञात',
      rating: reviewData['rating'] ?? 5, // Use actual rating from database
      commentEn: reviewData['comment_en'] ?? '',
      commentHi: reviewData['comment_hi'] ?? '',
      createdAt:
          DateTime.tryParse(reviewData['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Get unique categories from products with caching
  Future<List<String>> getCategories() async {
    await initialize();

    // First try to load from persistent cache
    final cachedCategories = await _loadCategoriesFromCache();
    if (cachedCategories != null) {
      return cachedCategories;
    }

    try {
      final response = await _supabase
          .from('store')
          .select('info')
          .eq('is_active', true);

      final categories = <String>{};
      for (final data in response) {
        final info = data['info'] as Map<String, dynamic>? ?? {};
        final category = info['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      final categoryList = categories.toList()..sort();

      // Save to persistent cache
      await _saveCategoriesToCache(categoryList);

      return categoryList;
    } catch (e) {
      return [];
    }
  }

  /// Get localized categories from `category` jsonb (category_en/category_hi)
  Future<List<String>> getLocalizedCategories({required bool isHindi}) async {
    try {
      final response = await _supabase
          .from('store')
          .select('category')
          .eq('is_active', true);

      final categories = <String>{};
      for (final data in response as List<dynamic>) {
        final cat = data['category'] as Map<String, dynamic>?;
        if (cat != null) {
          final value =
              (isHindi ? cat['category_hi'] : cat['category_en']) as String?;
          if (value != null && value.trim().isNotEmpty) {
            categories.add(value.trim());
          }
        }
      }

      final list = categories.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return list;
    } catch (e) {
      return [];
    }
  }

  /// Search products by query
  Future<List<Store>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('store')
          .select('*')
          .eq('is_active', true)
          .or(
            'info->title_en.ilike.%$query%,info->title_hi.ilike.%$query%,info->description_en.ilike.%$query%,info->description_hi.ilike.%$query%',
          )
          .order('created_at', ascending: false);

      final products = response.map((data) => _mapStoreData(data)).toList();

      return products;
    } catch (e) {
      rethrow;
    }
  }

  /// Get products by category
  Future<List<Store>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('store')
          .select('*')
          .eq('is_active', true)
          .eq('info->category', category)
          .order('created_at', ascending: false);

      final products = response.map((data) => _mapStoreData(data)).toList();

      return products;
    } catch (e) {
      rethrow;
    }
  }
}
