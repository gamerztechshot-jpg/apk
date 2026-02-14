// core/services/user_home_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_home_config.dart';

class UserHomeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // In-memory cache
  UserHomeConfig? _cachedConfig;
  DateTime? _cacheTimestamp;
  static const int _cacheExpiryHours = 6; // Cache for 6 hours

  // Default background URLs
  static const List<String> _defaultBackgrounds = [
    'https://zwnugtwpzeaswwyofjzs.supabase.co/storage/v1/object/public/images/banner1.jpg',
    'https://zwnugtwpzeaswwyofjzs.supabase.co/storage/v1/object/public/images/banner2.jpg',
    'https://zwnugtwpzeaswwyofjzs.supabase.co/storage/v1/object/public/images/banner3.jpg',
  ];

  UserHomeService() {}

  Future<UserHomeConfig?> getUserHomeConfig() async {
    try {
      final cachedConfig = _getCachedConfig();
      if (cachedConfig != null) {
        return cachedConfig;
      }

      final response = await _supabase
          .from('user_home')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      UserHomeConfig? config;
      if (response.isNotEmpty) {
        final rawData = response.first;

        config = UserHomeConfig.fromJson(rawData);

        // Cache the config
        _cacheConfig(config);
      } else {
        config = _createSampleConfig();
        _cacheConfig(config);
      }

      return config;
    } catch (e) {
      final fallbackConfig = _createSampleConfig();
      _cacheConfig(fallbackConfig);
      return fallbackConfig;
    }
  }

  // Create sample configuration if none exists
  UserHomeConfig _createSampleConfig() {
    final sampleConfig = UserHomeConfig(
      id: 'sample-config',
      image: _defaultBackgrounds[0],
      backgroundUrl: _defaultBackgrounds[0],
      box1: {
        'type': 'ebook',
        'ref_id': 'sample-ebook-1',
        'title': 'Bhagavad Gita',
        'description': 'The sacred Hindu scripture with 700 verses',
        'image': null, // Use fallback icon instead of invalid URL
      },
      box2: {
        'type': 'store_item',
        'ref_id': 'sample-store-1',
        'title': 'Puja Samagri',
        'description': 'Essential items for daily worship',
        'image': null, // Use fallback icon instead of invalid URL
      },
      box3: {
        'type': 'puja',
        'ref_id': 'sample-puja-1',
        'title': 'Ganesh Puja',
        'description': 'Book online Ganesh Puja for prosperity',
        'image': null, // Use fallback icon instead of invalid URL
      },
      createdAt: DateTime.now(),
    );

    return sampleConfig;
  }

  // Get content boxes from configuration
  List<ContentBox> getContentBoxes(UserHomeConfig config) {
    List<ContentBox> boxes = [];

    // Box 1
    if (config.box1 != null) {
      try {
        final box1 = ContentBox.fromJson(config.box1!);
        boxes.add(box1);
      } catch (e) {
        // Handle error silently
      }
    }

    // Box 2
    if (config.box2 != null) {
      try {
        final box2 = ContentBox.fromJson(config.box2!);
        boxes.add(box2);
      } catch (e) {
        // Handle error silently
      }
    }

    // Box 3
    if (config.box3 != null) {
      try {
        final box3 = ContentBox.fromJson(config.box3!);
        boxes.add(box3);
      } catch (e) {
        // Handle error silently
      }
    }

    // Process boxes if needed
    return boxes;
  }

  // Fetch content details based on type and ref_id
  Future<Map<String, dynamic>?> getContentDetails(
    String type,
    String refId,
  ) async {
    try {
      String tableName;
      String selectFields;
      switch (type.toLowerCase()) {
        case 'ebook':
        case 'article':
          tableName = 'articles';
          selectFields =
              'id, title_en, title_hi, description_en, description_hi, image, category';
          break;
        case 'audio':
          tableName = 'audiobooks'; // Fixed: was 'audio_books'
          selectFields = 'id, info'; // Fixed: use info JSONB column
          break;
        case 'store':
        case 'store_item':
          tableName = 'store';
          selectFields =
              'id, info, images'; // Fixed: use info and images JSONB columns
          break;
        case 'puja':
          tableName = 'puja_booking';
          selectFields =
              'id, puja_basic, puja_images'; // Fixed: removed category
          break;
        default:
          return null;
      }

      final response = await _supabase
          .from(tableName)
          .select(selectFields)
          .eq('id', refId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Fetch real content data and update content boxes
  Future<List<ContentBox>> getContentBoxesWithRealData(
    UserHomeConfig config,
  ) async {
    List<ContentBox> boxes = [];

    // Process each box
    final boxConfigs = [config.box1, config.box2, config.box3];
    for (int i = 0; i < boxConfigs.length; i++) {
      final boxConfig = boxConfigs[i];
      if (boxConfig == null) continue;

      try {
        // Parse the basic content box
        final contentBox = ContentBox.fromJson(boxConfig);

        // If ref_id exists, fetch real data
        if (contentBox.refId != null && contentBox.refId!.isNotEmpty) {
          final realData = await getContentDetails(
            contentBox.type,
            contentBox.refId!,
          );

          if (realData != null) {
            // Update content box with real data
            final updatedBox = _updateContentBoxWithRealData(
              contentBox,
              realData,
            );
            boxes.add(updatedBox);
          } else {
            // Fallback to original content box if real data not found
            boxes.add(contentBox);
          }
        } else {
          // Use original content box if no ref_id
          boxes.add(contentBox);
        }
      } catch (e) {
        // Handle error silently
      }
    }

    return boxes;
  }

  // Update content box with real data from database
  ContentBox _updateContentBoxWithRealData(
    ContentBox originalBox,
    Map<String, dynamic> realData,
  ) {
    String? title;
    String? description;
    String? imageUrl;

    switch (originalBox.type.toLowerCase()) {
      case 'ebook':
      case 'article':
        title = realData['title_en'] ?? realData['title_hi'];
        description = realData['description_en'] ?? realData['description_hi'];
        imageUrl = realData['image'];
        break;
      case 'audio':
        final info = realData['info'] as Map<String, dynamic>?;
        title = info?['title'];
        description = info?['description'];
        // Get first image from the images array in info
        final images = info?['image'] as List<dynamic>?;
        imageUrl = images?.isNotEmpty == true ? images!.first.toString() : null;
        break;
      case 'store':
      case 'store_item':
        final storeInfo = realData['info'] as Map<String, dynamic>?;
        title = storeInfo?['title_en'] ?? storeInfo?['title_hi'];
        description =
            storeInfo?['description_en'] ?? storeInfo?['description_hi'];
        // Get first image from the images array
        final storeImages = realData['images'] as List<dynamic>?;
        imageUrl = storeImages?.isNotEmpty == true
            ? storeImages!.first.toString()
            : null;
        break;
      case 'puja':
        final pujaBasic = realData['puja_basic'] as Map<String, dynamic>?;
        title = pujaBasic?['name'] ?? pujaBasic?['title'];
        description = pujaBasic?['short_description'];
        // Get first image from puja_images string (comma-separated)
        final pujaImages = realData['puja_images']?.toString();
        if (pujaImages != null && pujaImages.isNotEmpty) {
          final imageList = pujaImages.split(',');
          imageUrl = imageList.isNotEmpty ? imageList.first.trim() : null;
        }
        break;
    }

    // Create updated content box with real data
    return ContentBox(
      type: originalBox.type,
      refId: originalBox.refId,
      title: title ?? originalBox.title,
      description: description ?? originalBox.description,
      imageUrl: imageUrl,
      contentType: originalBox.contentType,
    );
  }

  // Cache management methods
  UserHomeConfig? _getCachedConfig() {
    if (_cachedConfig != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      final hoursSinceCache = cacheAge.inHours;

      if (hoursSinceCache < _cacheExpiryHours) {
        return _cachedConfig;
      } else {
        _clearCache();
      }
    }
    return null;
  }

  void _cacheConfig(UserHomeConfig config) {
    _cachedConfig = config;
    _cacheTimestamp = DateTime.now();
  }

  void _clearCache() {
    _cachedConfig = null;
    _cacheTimestamp = null;
  }

  // Get background URL with fallback
  String getBackgroundUrl(UserHomeConfig config) {
    // First try backgroundUrl field
    if (config.backgroundUrl != null && config.backgroundUrl!.isNotEmpty) {
      return config.backgroundUrl!;
    }

    // Then try image field (from your schema)
    if (config.image != null && config.image!.isNotEmpty) {
      return config.image!;
    }

    // Fallback to default backgrounds
    final defaultUrl = _defaultBackgrounds[0];
    return defaultUrl;
  }

  // Force refresh (clear cache and fetch new data)
  Future<UserHomeConfig?> forceRefresh() async {
    _clearCache();
    return await getUserHomeConfig();
  }
}
