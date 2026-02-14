// core/services/puja_story_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/puja_story_model.dart';

class PujaStoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PujaStoryModel>> getAllStories() async {
    try {
      final response = await _supabase
          .from('puja_stories')
          .select('*')
          .order('priority', ascending: true);

      final stories = response
          .map((story) => PujaStoryModel.fromJson(story))
          .toList();

      return stories;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PujaStoryModel>> getStoriesByCategory(String category) async {
    try {
      final response = await _supabase
          .from('puja_stories')
          .select('*')
          .eq('category', category)
          .order('priority', ascending: true);

      final stories = response
          .map((story) => PujaStoryModel.fromJson(story))
          .toList();

      return stories;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getUniqueCategories() async {
    try {
      final response = await _supabase.from('puja_stories').select('category');

      final categories = response
          .map((item) => item['category'] as String)
          .toSet()
          .toList();

      return categories;
    } catch (e) {
      rethrow;
    }
  }

  Future<PujaStoryModel> createStory(PujaStoryModel story) async {
    try {
      final response = await _supabase
          .from('puja_stories')
          .insert(story.toJson())
          .select()
          .single();

      final createdStory = PujaStoryModel.fromJson(response);

      return createdStory;
    } catch (e) {
      rethrow;
    }
  }

  Future<PujaStoryModel> updateStory(PujaStoryModel story) async {
    try {
      final response = await _supabase
          .from('puja_stories')
          .update(story.toJson())
          .eq('id', story.id)
          .select()
          .single();

      final updatedStory = PujaStoryModel.fromJson(response);

      return updatedStory;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteStory(int storyId) async {
    try {
      await _supabase.from('puja_stories').delete().eq('id', storyId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PujaStoryModel>> getStoriesWithPagination({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final from = page * limit;
      final to = from + limit - 1;

      final response = await _supabase
          .from('puja_stories')
          .select('*')
          .order('priority', ascending: true)
          .range(from, to);

      final stories = response
          .map((story) => PujaStoryModel.fromJson(story))
          .toList();

      return stories;
    } catch (e) {
      rethrow;
    }
  }
}
