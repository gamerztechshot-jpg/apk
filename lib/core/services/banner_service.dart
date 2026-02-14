// core/services/banner_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/festival_model.dart';
import '../models/puja_banner_model.dart';
import '../models/course_banner_model.dart';
import 'cache_service.dart';

class BannerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch festival banners from Supabase with caching (for home screen)
  Future<List<FestivalBanner>> getFestivalBanners({
    bool forceRefresh = false,
  }) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedFestivalBannerData();
        if (cachedData != null) {
          return cachedData
              .map((json) => FestivalBanner.fromJson(json))
              .toList();
        }
      }

      final response = await _supabase
          .from('festival_banners')
          .select('*')
          .order('created_at', ascending: false);

      final banners = (response as List).map((json) {
        return FestivalBanner.fromJson(json);
      }).toList();

      // Cache the data for future use
      await CacheService.cacheFestivalBannerData(response);

      return banners;
    } catch (e) {
      return [];
    }
  }

  // Fetch puja banners from Supabase with caching (for puja screen)
  Future<List<PujaBanner>> getPujaBanners({bool forceRefresh = false}) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedPujaBannerData();
        if (cachedData != null) {
          return cachedData.map((json) => PujaBanner.fromJson(json)).toList();
        }
      }

      final response = await _supabase
          .from('puja_banners')
          .select('*')
          .order('priority', ascending: true)
          .order('created_at', ascending: false);

      final banners = (response as List).map((json) {
        return PujaBanner.fromJson(json);
      }).toList();

      // Cache the data for future use
      await CacheService.cachePujaBannerData(response);

      return banners;
    } catch (e) {
      return [];
    }
  }

  // Get default banner URLs
  List<String> getDefaultBanners() {
    return [
      'https://fwhblztexcyxjrfhrrsb.supabase.co/storage/v1/object/public/images/banner1.jpg',
      'https://fwhblztexcyxjrfhrrsb.supabase.co/storage/v1/object/public/images/banner2.jpg',
      'https://fwhblztexcyxjrfhrrsb.supabase.co/storage/v1/object/public/images/banner3.jpg',
    ];
  }

  // Get festival banner URLs (for home screen)
  Future<List<String>> getFestivalBannerUrls({
    bool forceRefresh = false,
  }) async {
    try {
      final festivalBanners = await getFestivalBanners(
        forceRefresh: forceRefresh,
      );

      if (festivalBanners.isNotEmpty) {
        // Return festival banner URLs if available
        final urls = festivalBanners
            .map(
              (banner) =>
                  _withCacheBuster(banner.bannerUrl, banner.updatedAt),
            )
            .toList();

        return urls;
      } else {
        // Return default banners if no festival banners
        final defaultUrls = getDefaultBanners();

        return defaultUrls;
      }
    } catch (e) {
      // Fallback to default banners on error
      final defaultUrls = getDefaultBanners();

      return defaultUrls;
    }
  }

  // Get puja banner URLs (for puja screen)
  Future<List<String>> getPujaBannerUrls({bool forceRefresh = false}) async {
    try {
      final pujaBanners = await getPujaBanners(forceRefresh: forceRefresh);

      if (pujaBanners.isNotEmpty) {
        // Return puja banner URLs if available
        final urls = pujaBanners
            .map((banner) => _withCacheBuster(banner.imageUrl, banner.updatedAt))
            .toList();

        return urls;
      } else {
        // Return default banners if no puja banners
        final defaultUrls = getDefaultBanners();

        return defaultUrls;
      }
    } catch (e) {
      // Fallback to default banners on error
      final defaultUrls = getDefaultBanners();

      return defaultUrls;
    }
  }

  /// Force refresh festival banner data (clears cache and fetches fresh data)
  Future<List<FestivalBanner>> refreshFestivalBannerData() async {
    return await getFestivalBanners(forceRefresh: true);
  }

  /// Force refresh puja banner data (clears cache and fetches fresh data)
  Future<List<PujaBanner>> refreshPujaBannerData() async {
    return await getPujaBanners(forceRefresh: true);
  }

  /// Clear banner cache
  Future<void> clearBannerCache() async {
    await CacheService.clearDataTypeCache('banner');
    await CacheService.clearDataTypeCache('festival_banner');
    await CacheService.clearDataTypeCache('puja_banner');
    await CacheService.clearDataTypeCache('course_banner');
  }

  /// Get puja banners with full details (for advanced usage)
  Future<List<PujaBanner>> getPujaBannersWithDetails({
    bool forceRefresh = false,
  }) async {
    return await getPujaBanners(forceRefresh: forceRefresh);
  }

  // Fetch course banners from Supabase with caching (for acharya/course screen)
  Future<List<CourseBanner>> getActiveCourseBanners({
    bool forceRefresh = false,
  }) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedCourseBannerData();
        if (cachedData != null) {
          return cachedData
              .map((json) => CourseBanner.fromJson(json))
              .toList();
        }
      }

      final response = await _supabase
          .from('course_banners')
          .select('*')
          .eq('is_active', true)
          .order('priority', ascending: true); // Priority 1 first, then 2, 3, etc.

      final banners = (response as List)
          .map((json) => CourseBanner.fromJson(json))
          .toList();

      // Cache the data for future use
      await CacheService.cacheCourseBannerData(response);

      return banners;
    } catch (e) {
      return [];
    }
  }

  /// Force refresh course banner data (clears cache and fetches fresh data)
  Future<List<CourseBanner>> refreshCourseBannerData() async {
    return await getActiveCourseBanners(forceRefresh: true);
  }

  String _withCacheBuster(String url, DateTime? updatedAt) {
    if (url.isEmpty || updatedAt == null) return url;
    try {
      final uri = Uri.parse(url);
      final params = Map<String, String>.from(uri.queryParameters);
      params['v'] = updatedAt.millisecondsSinceEpoch.toString();
      return uri.replace(queryParameters: params).toString();
    } catch (_) {
      return url;
    }
  }
}
