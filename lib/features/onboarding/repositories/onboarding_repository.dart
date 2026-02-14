// features/onboarding/repositories/onboarding_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_item.dart';

class OnboardingRepository {
  static const _cacheKey = 'karmasu_onboarding_items';
  static const _cacheExpiryHours = 24;
  static const _urls = [
    'https://fwhblztexcyxjrfhrrsb.supabase.co/storage/v1/object/public/profiles/onboarding/onboarding1',
    'https://fwhblztexcyxjrfhrrsb.supabase.co/storage/v1/object/public/profiles/onboarding/onboarding2',
    'https://fwhblztexcyxjrfhrrsb.supabase.co/storage/v1/object/public/profiles/onboarding/onboarding3',
  ];

  static List<OnboardingItem>? _memoryCache;

  /// Returns default onboarding items instantly (no network). Use for fast first paint.
  static List<OnboardingItem> getDefaultItems() {
    return [
      for (var i = 0; i < _urls.length; i++)
        OnboardingItem(
          order: i + 1,
          url: _urls[i],
          type: OnboardingMediaType.image,
        ),
    ];
  }

  Future<List<OnboardingItem>> fetchItems() async {
    // In-memory cache: instant return on subsequent loads in same session
    if (_memoryCache != null && _memoryCache!.isNotEmpty) {
      return _memoryCache!;
    }

    // Persistent cache: skip network if recently cached
    final cached = await _getCachedItems();
    if (cached != null && cached.isNotEmpty) {
      _memoryCache = cached;
      return cached;
    }

    final items = await _fetchFromNetwork();
    if (items.isNotEmpty) {
      _memoryCache = items;
      unawaited(_saveToCache(items));
    }
    return items;
  }

  Future<List<OnboardingItem>?> _getCachedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      final ts = prefs.getInt('${_cacheKey}_ts');
      if (json == null || ts == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _cacheExpiryHours * 3600 * 1000) return null;
      final list = jsonDecode(json) as List;
      return list
          .map((e) => OnboardingItem(
                order: e['order'] as int,
                url: e['url'] as String,
                type: (e['type'] as String) == 'video'
                    ? OnboardingMediaType.video
                    : OnboardingMediaType.image,
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(List<OnboardingItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(items
          .map((e) => {
                'order': e.order,
                'url': e.url,
                'type': e.type == OnboardingMediaType.video ? 'video' : 'image',
              })
          .toList());
      await prefs.setString(_cacheKey, json);
      await prefs.setInt(
          '${_cacheKey}_ts', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<List<OnboardingItem>> _fetchFromNetwork() async {
    // Single HEAD per URL: get availability + content-type in one request
    final futures = <Future<OnboardingItem?>>[];
    for (var i = 0; i < _urls.length; i++) {
      futures.add(_buildItemWithSingleRequest(i + 1, _urls[i]));
    }
    List<OnboardingItem> available;
    try {
      final items = await Future.wait(futures)
          .timeout(const Duration(seconds: 8));
      available = items.whereType<OnboardingItem>().toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (_) {
      available = [];
    }
    // Fallback: always show onboarding with default items if fetch fails/empty
    if (available.isEmpty) {
      available = [
        for (var i = 0; i < _urls.length; i++)
          OnboardingItem(order: i + 1, url: _urls[i], type: OnboardingMediaType.image),
      ];
    }
    return available;
  }

  Future<OnboardingItem?> _buildItemWithSingleRequest(int order, String url) async {
    try {
      final response = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      String contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (response.statusCode < 200 || response.statusCode >= 400) {
        if (response.statusCode != 405 && response.statusCode != 403) {
          return null;
        }
        // HEAD not allowed: try minimal GET
        final get = await http
            .get(Uri.parse(url), headers: const {'Range': 'bytes=0-0'})
            .timeout(const Duration(seconds: 3));
        if (get.statusCode < 200 || get.statusCode >= 400) return null;
        contentType = get.headers['content-type']?.toLowerCase() ?? '';
      }
      final type = _typeFromExtension(url) ?? _typeFromContentType(contentType);
      return OnboardingItem(order: order, url: url, type: type);
    } catch (_) {
      return null;
    }
  }

  OnboardingMediaType? _typeFromExtension(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm')) return OnboardingMediaType.video;
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) return OnboardingMediaType.image;
    return null;
  }

  OnboardingMediaType _typeFromContentType(String contentType) {
    if (contentType.contains('video')) return OnboardingMediaType.video;
    return OnboardingMediaType.image;
  }
}
