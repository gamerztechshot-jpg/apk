import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_target_model.dart';
import 'certificate_service.dart';
import 'streak_service.dart';
import 'cache_service.dart';

class DailyTargetsService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  DailyTargetModel? _currentTarget;
  int _todayJapaCount = 0;
  int _daysActive = 0;
  int _totalJapaCount = 0;
  String? _currentUserId;

  DailyTargetModel? get currentTarget => _currentTarget;
  int get todayJapaCount => _todayJapaCount;
  int get daysActive => _daysActive;
  int get totalJapaCount => _totalJapaCount;

  DailyTargetsService() {
    _initializeService();
  }

  void _initializeService() {
    _currentUserId = _supabase.auth.currentUser?.id;
    if (_currentUserId != null) {
      _loadDailyTarget();
      getTodayJapaCount();
      getDaysActive();
      getTotalJapaCount();
    }

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _currentUserId = data.session?.user.id;
        _loadDailyTarget();
        getTodayJapaCount();
        getDaysActive();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUserId = null;
        _currentTarget = null;
        _todayJapaCount = 0;
        _daysActive = 0;
        notifyListeners();
      }
    });
  }

  Future<void> _loadDailyTarget() async {
    if (_currentUserId == null) return;

    try {
      // For now, create a default target since we're working with existing structure
      // This can be enhanced later to store user preferences
      _currentTarget = DailyTargetModel(
        id: 'default_${_currentUserId}',
        userId: _currentUserId!,
        targetCount: 108, // Default target
        currentStreak: 0, // Will be calculated from activity data
        longestStreak: 0, // Will be calculated from activity data
        lastUpdated: DateTime.now(),
        createdAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      // Create default target as fallback
      _currentTarget = DailyTargetModel(
        id: 'fallback_${_currentUserId}',
        userId: _currentUserId!,
        targetCount: 108,
        currentStreak: 0,
        longestStreak: 0,
        lastUpdated: DateTime.now(),
        createdAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> setDailyTarget(int targetCount) async {
    if (_currentUserId == null) return;

    try {
      // Update the current target in memory
      if (_currentTarget != null) {
        _currentTarget = DailyTargetModel(
          id: _currentTarget!.id,
          userId: _currentTarget!.userId,
          targetCount: targetCount,
          currentStreak: _currentTarget!.currentStreak,
          longestStreak: _currentTarget!.longestStreak,
          lastUpdated: DateTime.now(),
          createdAt: _currentTarget!.createdAt,
        );
      } else {
        _currentTarget = DailyTargetModel(
          id: 'target_${_currentUserId}',
          userId: _currentUserId!,
          targetCount: targetCount,
          currentStreak: 0,
          longestStreak: 0,
          lastUpdated: DateTime.now(),
          createdAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {}
  }

  // Force refresh the daily target data
  Future<void> refreshDailyTarget() async {
    await _loadDailyTarget();
  }

  /// Record Japa count for a specific mantra
  /// Returns the updated total count and whether this is a new active day
  Future<Map<String, dynamic>?> recordJapaCount(
    String mantraId,
    int count, {
    CertificateService? certificateService,
    StreakService? streakService,
  }) async {
    if (_currentUserId == null) return null;

    try {
      // Use the existing database function to record japa activity
      final response = await _supabase.rpc(
        'record_japa_activity',
        params: {
          'p_user_id': _currentUserId!,
          'p_mantra_id': mantraId,
          'p_count': count,
        },
      );

      // Parse the response
      final result = response as Map<String, dynamic>;
      final totalCount = result['total_count'] as int;
      final isNewActiveDay = result['is_new_active_day'] as bool;

      // Update local state
      _todayJapaCount = totalCount;

      // If this is a new active day, increment days active
      if (isNewActiveDay) {
        _daysActive++;
      }

      // Update total japa count
      _totalJapaCount = await getTotalJapaCount();

      notifyListeners();

      // CRITICAL: Refresh the daily target to get updated streak info
      await _loadDailyTarget();

      // Check and update streak if streak service is provided
      if (streakService != null) {
        await streakService.checkStreakUpdate();
      }

      // Check for certificates if certificate service is provided
      if (certificateService != null) {
        final currentStreak = _currentTarget?.currentStreak ?? 0;

        await certificateService.checkAndGenerateCertificates(
          _totalJapaCount,
          currentStreak,
        );
      }

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Get today's Japa count using existing database function with caching
  Future<int> getTodayJapaCount({bool forceRefresh = false}) async {
    if (_currentUserId == null) return 0;

    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedStats = await CacheService.getCachedUserStats(
          _currentUserId!,
        );
        if (cachedStats != null &&
            cachedStats.containsKey('today_japa_count')) {
          _todayJapaCount = cachedStats['today_japa_count'] as int? ?? 0;

          notifyListeners();
          return _todayJapaCount;
        }
      }

      // Use the existing database function
      final response = await _supabase.rpc(
        'get_today_japa_count',
        params: {'p_user_id': _currentUserId!},
      );

      _todayJapaCount = (response as int?) ?? 0;

      // Update cache with current stats
      final currentStats = await getUserStatistics();
      await CacheService.cacheUserStats(_currentUserId!, currentStats);

      notifyListeners();

      return _todayJapaCount;
    } catch (e) {
      return 0;
    }
  }

  /// Get total Japa count using existing database function
  Future<int> getTotalJapaCount() async {
    if (_currentUserId == null) return 0;

    try {
      // Use the existing database function to get comprehensive statistics
      final response = await _supabase.rpc(
        'get_user_japa_statistics',
        params: {'p_user_id': _currentUserId!},
      );

      if (response.isNotEmpty) {
        final stats = response.first;
        _totalJapaCount = (stats['total_japa_count'] as int?) ?? 0;
        return _totalJapaCount;
      }

      _totalJapaCount = 0;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get Japa count for a specific date range from user_daily_japa table
  Future<int> getJapaCountForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_currentUserId == null) return 0;

    try {
      final startDateString = startDate.toIso8601String().split('T')[0];
      final endDateString = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('user_daily_japa')
          .select('total_japa_count')
          .eq('user_id', _currentUserId!)
          .gte('date', startDateString)
          .lte('date', endDateString);

      int total = 0;
      for (var item in response) {
        total += (item['total_japa_count'] as int?) ?? 0;
      }

      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Get Japa count for the last N days using existing database function
  Future<int> getJapaCountForLastDays(int days) async {
    if (_currentUserId == null) return 0;

    try {
      // Use the existing database function
      final response = await _supabase.rpc(
        'get_japa_count_last_days',
        params: {'p_user_id': _currentUserId!, 'p_days': days},
      );

      return (response as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get yesterday's Japa count using existing database function
  Future<int> getYesterdayJapaCount() async {
    if (_currentUserId == null) return 0;

    try {
      // Use the existing database function
      final response = await _supabase.rpc(
        'get_yesterday_japa_count',
        params: {'p_user_id': _currentUserId!},
      );

      return (response as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get total active days count using existing database function
  Future<int> getDaysActive() async {
    if (_currentUserId == null) return 0;

    try {
      // Use the existing database function
      final response = await _supabase.rpc(
        'get_user_active_days_count',
        params: {'p_user_id': _currentUserId!},
      );

      _daysActive = (response as int?) ?? 0;
      notifyListeners();

      return _daysActive;
    } catch (e) {
      return 0;
    }
  }

  /// Get daily Japa data for a date range using existing database function
  Future<List<Map<String, dynamic>>> getDailyJapaData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_currentUserId == null) return [];

    try {
      final startDateString = startDate.toIso8601String().split('T')[0];
      final endDateString = endDate.toIso8601String().split('T')[0];

      // Try the database function first
      final response = await _supabase.rpc(
        'get_daily_japa_data',
        params: {
          'p_user_id': _currentUserId!,
          'p_start_date': startDateString,
          'p_end_date': endDateString,
        },
      );

      // Ensure all values are properly typed and handle nulls
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response,
      );

      // Process each item to ensure proper types
      return data.map((item) {
        return {
          'date': item['date']?.toString() ?? '',
          'japa_count': (item['japa_count'] as int?) ?? 0,
          'is_active': (item['is_active'] as bool?) ?? false,
        };
      }).toList();
    } catch (e) {
      // Fallback: Query the table directly
      try {
        final fallbackStartDateString = startDate.toIso8601String().split(
          'T',
        )[0];
        final fallbackEndDateString = endDate.toIso8601String().split('T')[0];

        final response = await _supabase
            .from('user_daily_japa')
            .select('date, total_japa_count, is_active_day')
            .eq('user_id', _currentUserId!)
            .gte('date', fallbackStartDateString)
            .lte('date', fallbackEndDateString)
            .order('date');

        // Generate date series manually
        final List<Map<String, dynamic>> result = [];
        final days = endDate.difference(startDate).inDays + 1;

        for (int i = 0; i < days; i++) {
          final currentDate = startDate.add(Duration(days: i));
          final dateString = currentDate.toIso8601String().split('T')[0];

          // Find matching record
          final matchingRecord =
              response
                  .where((record) => record['date'] == dateString)
                  .isNotEmpty
              ? response.where((record) => record['date'] == dateString).first
              : null;

          result.add({
            'date': dateString,
            'japa_count': matchingRecord != null
                ? (matchingRecord['total_japa_count'] as int?) ?? 0
                : 0,
            'is_active': matchingRecord != null
                ? (matchingRecord['is_active_day'] as bool?) ?? false
                : false,
          });
        }

        return result;
      } catch (fallbackError) {
        return [];
      }
    }
  }

  // New optimized methods using database functions

  /// Get comprehensive user statistics using existing database function with caching
  Future<Map<String, dynamic>> getUserStatistics({
    bool forceRefresh = false,
  }) async {
    if (_currentUserId == null) return {};

    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedStats = await CacheService.getCachedUserStats(
          _currentUserId!,
        );
        if (cachedStats != null && cachedStats.isNotEmpty) {
          return cachedStats;
        }
      }

      // Use the existing database function
      final response = await _supabase.rpc(
        'get_user_japa_statistics',
        params: {'p_user_id': _currentUserId!},
      );

      Map<String, dynamic> stats = {};
      if (response.isNotEmpty) {
        stats = response.first;
        // Cache the statistics
        await CacheService.cacheUserStats(_currentUserId!, stats);
      }

      return stats;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getStreakHistory(int days) async {
    if (_currentUserId == null) return [];

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      return getDailyJapaData(startDate, endDate);
    } catch (e) {
      return [];
    }
  }

  Future<bool> isTargetMetToday() async {
    if (_currentUserId == null || _currentTarget == null) return false;

    try {
      // Check if today's japa count meets the target
      return _todayJapaCount >= _currentTarget!.targetCount;
    } catch (e) {
      return _todayJapaCount >= _currentTarget!.targetCount;
    }
  }

  Future<bool> isStreakLockedToday() async {
    if (_currentUserId == null) return false;

    try {
      // For now, return false - streak locking can be implemented later if needed
      return false;
    } catch (e) {
      return false;
    }
  }

  // =====================================================
  // ADDITIONAL UTILITY METHODS FOR STATISTICS
  // =====================================================

  /// Get Japa count for last 7 days
  Future<int> getLast7DaysJapaCount() async {
    return getJapaCountForLastDays(7);
  }

  /// Get Japa count for last 30 days
  Future<int> getLast30DaysJapaCount() async {
    return getJapaCountForLastDays(30);
  }

  /// Get Japa count for last 365 days
  Future<int> getLast365DaysJapaCount() async {
    return getJapaCountForLastDays(365);
  }

  /// Get all Japa statistics in one call
  Future<Map<String, int>> getAllJapaStatistics() async {
    if (_currentUserId == null) return {};

    try {
      final stats = await getUserStatistics();
      return {
        'today': stats['today_japa_count'] as int? ?? 0,
        'yesterday': stats['yesterday_japa_count'] as int? ?? 0,
        'last_7_days': stats['last_7_days_count'] as int? ?? 0,
        'last_30_days': stats['last_30_days_count'] as int? ?? 0,
        'last_365_days': stats['last_365_days_count'] as int? ?? 0,
        'total': stats['total_japa_count'] as int? ?? 0,
        'active_days': stats['total_active_days'] as int? ?? 0,
      };
    } catch (e) {
      return {};
    }
  }

  /// Check if user was active on a specific date
  Future<bool> wasActiveOnDate(DateTime date) async {
    if (_currentUserId == null) return false;

    try {
      final dateString = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('user_daily_japa')
          .select('is_active_day')
          .eq('user_id', _currentUserId!)
          .eq('date', dateString)
          .eq('is_active_day', true)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get Japa count for a specific date
  Future<int> getJapaCountForDate(DateTime date) async {
    if (_currentUserId == null) return 0;

    try {
      final dateString = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('user_daily_japa')
          .select('total_japa_count')
          .eq('user_id', _currentUserId!)
          .eq('date', dateString)
          .maybeSingle();

      return (response?['total_japa_count'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Refresh all statistics
  Future<void> refreshAllStatistics() async {
    await Future.wait([
      getTodayJapaCount(forceRefresh: true),
      getDaysActive(),
      _loadDailyTarget(),
    ]);
  }

  /// Clear user statistics cache
  Future<void> clearUserStatsCache() async {
    if (_currentUserId != null) {
      await CacheService.clearUserCache(_currentUserId!);
    }
  }
}
