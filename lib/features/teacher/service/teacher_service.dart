import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/course.dart';
import '../model/webinar.dart';
import '../model/quiz.dart';
import '../model/teacher_model.dart';
import '../../../core/services/cache_service.dart';

class TeacherService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Retry helper with exponential backoff
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        // Check if it's a network error that should be retried
        final errorString = e.toString().toLowerCase();
        final isNetworkError = errorString.contains('connection') ||
            errorString.contains('socket') ||
            errorString.contains('handshake') ||
            errorString.contains('timeout') ||
            errorString.contains('closed before full header');
        
        if (!isNetworkError) {
          rethrow; // Don't retry non-network errors
        }
        
        // Exponential backoff: 1s, 2s, 4s
        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
        );
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retries exceeded');
  }

  Future<List<Course>> getCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('status', 'approved')
          .eq('active', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Course.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Webinar>> getWebinars({bool forceRefresh = false}) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedWebinars();
        if (cachedData != null && cachedData.isNotEmpty) {
          return cachedData.map((json) => Webinar.fromJson(json)).toList();
        }
      }

      // Retry with exponential backoff for network errors
      final response = await _retryWithBackoff(() async {
        return await _supabase
            .from('webinars')
            .select()
            .eq('status', 'approved')
            .eq('active', true)
            .order('start_time', ascending: true);
      });

      final webinars = (response as List)
          .map((json) => Webinar.fromJson(json))
          .toList();

      // Cache the results
      if (webinars.isNotEmpty) {
        await CacheService.cacheWebinars(response);
      }

      return webinars;
    } catch (e) {
      // Try to return cached data as fallback
      try {
        final cachedData = await CacheService.getCachedWebinars();
        if (cachedData != null && cachedData.isNotEmpty) {
          return cachedData.map((json) => Webinar.fromJson(json)).toList();
        }
      } catch (_) {
        // Ignore cache errors
      }
      return [];
    }
  }

  Future<List<Quiz>> getQuizzes() async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select()
          .eq('status', 'active')
          .eq(
            'is_admin',
            true,
          ) // Only fetch admin quizzes for the outer section
          .order('created_at', ascending: false);

      return (response as List).map((json) => Quiz.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Quiz>> getAllQuizzes() async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Quiz.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TeacherModel>> getTeachers({bool forceRefresh = false}) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedTeachers();
        if (cachedData != null && cachedData.isNotEmpty) {
          return cachedData
              .map((json) => TeacherModel.fromJson(json))
              .toList();
        }
      }

      // Retry with exponential backoff for network errors
      final response = await _retryWithBackoff(() async {
        return await _supabase.from('pat').select('id, basic_info');
      });

      final teachers = (response as List)
          .map((json) => TeacherModel.fromJson(json))
          .toList();

      // Cache the results
      if (teachers.isNotEmpty) {
        await CacheService.cacheTeachers(response);
      }

      return teachers;
    } catch (e) {
      // Try to return cached data as fallback
      try {
        final cachedData = await CacheService.getCachedTeachers();
        if (cachedData != null && cachedData.isNotEmpty) {
          return cachedData
              .map((json) => TeacherModel.fromJson(json))
              .toList();
        }
      } catch (_) {
        // Ignore cache errors
      }
      return [];
    }
  }

  Future<TeacherModel?> getTeacherById(String id) async {
    try {
      final response = await _supabase
          .from('pat')
          .select('id, basic_info')
          .eq('user_id', id)
          .single();

      return TeacherModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Quiz?> getQuizById(String id) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select()
          .eq('quiz_id', id)
          .single();

      return Quiz.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPdfById(String id) async {
    try {
      final response = await _supabase
          .from('pdfs')
          .select()
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get courses by list of IDs
  Future<List<Course>> getCoursesByIds(List<String> courseIds) async {
    if (courseIds.isEmpty) return [];

    try {
      final response = await _supabase
          .from('courses')
          .select()
          .inFilter('course_id', courseIds);

      return (response as List).map((json) => Course.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get webinars by list of IDs
  Future<List<Webinar>> getWebinarsByIds(List<String> webinarIds) async {
    if (webinarIds.isEmpty) return [];

    try {
      final response = await _supabase
          .from('webinars')
          .select()
          .inFilter('webinar_id', webinarIds);

      return (response as List).map((json) => Webinar.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
