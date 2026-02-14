// core/services/audio_ebook_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/audio_ebook_model.dart';
import 'cache_service.dart';

class AudioEbookService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all audiobooks with caching
  Future<List<AudioEbookModel>> fetchAudiobooks({
    bool forceRefresh = false,
  }) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedAudioEbookData(
          'audiobooks',
        );
        if (cachedData != null) {
          return cachedData
              .map((item) => AudioEbookModel.fromMap(item, 'audio'))
              .toList();
        }
      }

      final response = await _supabase
          .from('audiobooks')
          .select()
          .order('created_at', ascending: false);

      final audiobooks = (response as List)
          .map((item) => AudioEbookModel.fromMap(item, 'audio'))
          .toList();

      // Cache the data for future use
      await CacheService.cacheAudioEbookData('audiobooks', response);

      return audiobooks;
    } catch (e) {
      return [];
    }
  }

  // Fetch all ebooks with caching
  Future<List<AudioEbookModel>> fetchEbooks({bool forceRefresh = false}) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedAudioEbookData('ebooks');
        if (cachedData != null) {
          return cachedData
              .map((item) => AudioEbookModel.fromMap(item, 'ebook'))
              .toList();
        }
      }

      final response = await _supabase
          .from('ebooks')
          .select()
          .order('created_at', ascending: false);

      final ebooks = (response as List)
          .map((item) => AudioEbookModel.fromMap(item, 'ebook'))
          .toList();

      // Cache the data for future use
      await CacheService.cacheAudioEbookData('ebooks', response);

      return ebooks;
    } catch (e) {
      return [];
    }
  }

  // Fetch both audiobooks and ebooks with caching
  Future<Map<String, List<AudioEbookModel>>> fetchAllData({
    bool forceRefresh = false,
  }) async {
    try {
      final audiobooks = await fetchAudiobooks(forceRefresh: forceRefresh);
      final ebooks = await fetchEbooks(forceRefresh: forceRefresh);

      return {'audiobooks': audiobooks, 'ebooks': ebooks};
    } catch (e) {
      return {'audiobooks': <AudioEbookModel>[], 'ebooks': <AudioEbookModel>[]};
    }
  }

  void printDataStructure(List<Map<String, dynamic>> data, String tableName) {
    if (data.isEmpty) {
      return;
    }

    for (int i = 0; i < data.length && i < 3; i++) {
      data[i].forEach((key, value) {});
    }

    if (data.length > 3) {}
  }

  /// Force refresh audio/ebook data (clears cache and fetches fresh data)
  Future<Map<String, List<AudioEbookModel>>> refreshAllData() async {
    return await fetchAllData(forceRefresh: true);
  }

  /// Clear audio/ebook cache
  Future<void> clearAudioEbookCache() async {
    await CacheService.clearDataTypeCache('audio_ebook');
  }

  // Get related audios based on category logic
  Future<List<AudioEbookModel>> getRelatedAudios({
    required String currentAudioCategory,
    required int currentAudioId,
    int limit = 5,
  }) async {
    try {
      // Get all audiobooks
      final allAudiobooks = await fetchAudiobooks();

      // Filter out the current audio
      final otherAudios = allAudiobooks
          .where((audio) => audio.id != currentAudioId)
          .toList();

      // Try to get audios from same category
      final sameCategoryAudios = otherAudios
          .where(
            (audio) =>
                audio.category.toLowerCase() ==
                currentAudioCategory.toLowerCase(),
          )
          .toList();

      if (sameCategoryAudios.isNotEmpty) {
        // If same category has audios, return up to limit
        final result = sameCategoryAudios.take(limit).toList();

        return result;
      } else {
        // If no same category audios, return top 5 from all audios
        final topAudios = otherAudios.take(limit).toList();

        return topAudios;
      }
    } catch (e) {
      return [];
    }
  }
}
