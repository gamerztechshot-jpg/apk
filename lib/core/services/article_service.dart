// core/services/article_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article_model.dart';
import 'cache_service.dart';

class ArticleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ArticleModel>> fetchArticles({bool forceRefresh = false}) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedArticlesData();
        if (cachedData != null) {
          return cachedData.map((item) => ArticleModel.fromMap(item)).toList();
        }
      }
      final response = await _supabase
          .from('articles')
          .select()
          .order(
            'priority',
            ascending: false,
          ) // Order by priority (highest first)
          .order('created_at', ascending: false); // Then by creation date

      final articles = (response as List)
          .map((item) => ArticleModel.fromMap(item))
          .toList();

      await CacheService.cacheArticlesData(response);

      return articles;
    } catch (e) {
      return [];
    }
  }

  Future<List<ArticleModel>> fetchArticlesByCategory(
    String category, {
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _supabase
          .from('articles')
          .select()
          .eq('category', category)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      final articles = (response as List)
          .map((item) => ArticleModel.fromMap(item))
          .toList();

      return articles;
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> fetchCategories({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedCategories =
            await CacheService.getCachedArticleCategories();
        if (cachedCategories != null && cachedCategories.isNotEmpty) {
          return cachedCategories.map((item) => item.toString()).toList();
        }
      }
      final response = await _supabase
          .from('articles')
          .select('category, priority')
          .order('priority', ascending: false);

      final categoryMap = <String, int>{};
      for (var item in response) {
        final category = item['category'] as String;
        final priority = item['priority'] as int;
        if (!categoryMap.containsKey(category) ||
            categoryMap[category]! < priority) {
          categoryMap[category] = priority;
        }
      }

      final sortedCategories = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final categories = ['All', ...sortedCategories.map((e) => e.key)];

      await CacheService.cacheArticleCategories(categories);

      return categories;
    } catch (e) {
      return ['All'];
    }
  }

  Future<List<ArticleModel>> searchArticles(
    String query, {
    String category = 'All',
  }) async {
    try {
      var queryBuilder = _supabase
          .from('articles')
          .select()
          .or('title_en.ilike.%$query%,title_hi.ilike.%$query%');

      if (category != 'All') {
        queryBuilder = queryBuilder.eq('category', category);
      }

      final response = await queryBuilder
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      final articles = (response as List)
          .map((item) => ArticleModel.fromMap(item))
          .toList();

      return articles;
    } catch (e) {
      return [];
    }
  }

  Future<ArticleModel?> fetchArticleById(int id) async {
    try {
      final response = await _supabase
          .from('articles')
          .select()
          .eq('id', id)
          .single();

      final article = ArticleModel.fromMap(response);
      return article;
    } catch (e) {
      return null;
    }
  }

  Future<List<ArticleModel>> getRelatedArticles({
    required String currentArticleCategory,
    required int currentArticleId,
    int limit = 5,
  }) async {
    try {
      final response = await _supabase
          .from('articles')
          .select()
          .eq('category', currentArticleCategory)
          .neq('id', currentArticleId)
          .order('priority', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      final articles = (response as List)
          .map((item) => ArticleModel.fromMap(item))
          .toList();

      return articles;
    } catch (e) {
      return [];
    }
  }

  Future<List<ArticleModel>> refreshArticles() async {
    return await fetchArticles(forceRefresh: true);
  }

  Future<void> clearArticlesCache() async {
    await CacheService.clearDataTypeCache('articles');
    await CacheService.clearDataTypeCache('article_categories');
  }
}
