import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_model.dart';
import 'cache_service.dart';

class LeaderboardService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Current state
  String _currentPeriod = 'daily';
  List<LeaderboardEntry> _currentLeaderboard = [];
  int _totalParticipants = 0;
  UserRank? _currentUserRank;
  bool _isLoading = false;

  // Getters
  String get currentPeriod => _currentPeriod;
  List<LeaderboardEntry> get currentLeaderboard => _currentLeaderboard;
  int get totalParticipants => _totalParticipants;
  UserRank? get currentUserRank => _currentUserRank;
  bool get isLoading => _isLoading;

  /// Get daily leaderboard with caching
  Future<List<LeaderboardEntry>> getDailyLeaderboard({
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateString = targetDate.toIso8601String().split('T')[0];
      final cacheKey = 'daily_$dateString';

      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedLeaderboard(cacheKey);
        if (cachedData != null) {
          return _parseLeaderboardResponse(cachedData);
        }
      }

      final response = await _supabase.rpc(
        'get_daily_leaderboard',
        params: {'p_date': dateString},
      );

      final leaderboardData = _parseLeaderboardResponse(response);

      // Cache the data for future use
      await CacheService.cacheLeaderboard(cacheKey, response);

      return leaderboardData;
    } catch (e) {
      return [];
    }
  }

  /// Get weekly leaderboard with caching
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard({
    DateTime? startDate,
    bool forceRefresh = false,
  }) async {
    try {
      final targetStartDate =
          startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final startDateString = targetStartDate.toIso8601String().split('T')[0];
      final cacheKey = 'weekly_$startDateString';

      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedLeaderboard(cacheKey);
        if (cachedData != null) {
          return _parseLeaderboardResponse(cachedData);
        }
      }

      final response = await _supabase.rpc(
        'get_weekly_leaderboard',
        params: {'p_start_date': startDateString},
      );

      final leaderboardData = _parseLeaderboardResponse(response);

      // Cache the data for future use
      await CacheService.cacheLeaderboard(cacheKey, response);

      return leaderboardData;
    } catch (e) {
      return [];
    }
  }

  /// Get monthly leaderboard with caching
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard({
    DateTime? startDate,
    bool forceRefresh = false,
  }) async {
    try {
      final targetStartDate =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final startDateString = targetStartDate.toIso8601String().split('T')[0];
      final cacheKey = 'monthly_$startDateString';

      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedLeaderboard(cacheKey);
        if (cachedData != null) {
          return _parseLeaderboardResponse(cachedData);
        }
      }

      final response = await _supabase.rpc(
        'get_monthly_leaderboard',
        params: {'p_start_date': startDateString},
      );

      final leaderboardData = _parseLeaderboardResponse(response);

      // Cache the data for future use
      await CacheService.cacheLeaderboard(cacheKey, response);

      return leaderboardData;
    } catch (e) {
      return [];
    }
  }

  /// Get yearly leaderboard with caching
  Future<List<LeaderboardEntry>> getYearlyLeaderboard({
    DateTime? startDate,
    bool forceRefresh = false,
  }) async {
    try {
      final targetStartDate =
          startDate ?? DateTime.now().subtract(const Duration(days: 365));
      final startDateString = targetStartDate.toIso8601String().split('T')[0];
      final cacheKey = 'yearly_$startDateString';

      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedLeaderboard(cacheKey);
        if (cachedData != null) {
          return _parseLeaderboardResponse(cachedData);
        }
      }

      final response = await _supabase.rpc(
        'get_yearly_leaderboard',
        params: {'p_start_date': startDateString},
      );

      final leaderboardData = _parseLeaderboardResponse(response);

      // Cache the data for future use
      await CacheService.cacheLeaderboard(cacheKey, response);

      return leaderboardData;
    } catch (e) {
      return [];
    }
  }

  /// Get all-time leaderboard with caching
  Future<List<LeaderboardEntry>> getAllTimeLeaderboard({
    bool forceRefresh = false,
  }) async {
    try {
      const cacheKey = 'alltime';

      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedLeaderboard(cacheKey);
        if (cachedData != null) {
          return _parseLeaderboardResponse(cachedData);
        }
      }

      final response = await _supabase.rpc('get_alltime_leaderboard');

      final leaderboardData = _parseLeaderboardResponse(response);

      // Cache the data for future use
      await CacheService.cacheLeaderboard(cacheKey, response);

      return leaderboardData;
    } catch (e) {
      return [];
    }
  }

  /// Get participant count for a leaderboard type
  Future<int> getParticipantCount(
    String leaderboardType, {
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateString = targetDate.toIso8601String().split('T')[0];

      final response = await _supabase.rpc(
        'get_leaderboard_participant_count',
        params: {'p_leaderboard_type': leaderboardType, 'p_date': dateString},
      );

      return response as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get user's rank in a leaderboard
  Future<UserRank?> getUserRank(
    String leaderboardType, {
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateString = targetDate.toIso8601String().split('T')[0];

      final response = await _supabase.rpc(
        'get_user_leaderboard_rank',
        params: {'p_leaderboard_type': leaderboardType, 'p_date': dateString},
      );

      if (response.isNotEmpty) {
        final data = response.first;
        return UserRank(
          rank: (data['rank'] as int?) ?? 0,
          japaCount: (data['japa_count'] as int?) ?? 0,
          totalParticipants: (data['total_participants'] as int?) ?? 0,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse leaderboard response
  List<LeaderboardEntry> _parseLeaderboardResponse(dynamic response) {
    if (response == null) return [];

    final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
      response,
    );

    return data.map((item) {
      return LeaderboardEntry(
        rank: (item['rank'] as int?) ?? 0,
        userId: item['user_id'] as String? ?? '',
        username: item['username'] as String? ?? 'Unknown User',
        japaCount: (item['japa_count'] as int?) ?? 0,
        isCurrentUser: (item['is_current_user'] as bool?) ?? false,
      );
    }).toList();
  }

  /// Set current period and load leaderboard
  Future<void> setCurrentPeriod(String period) async {
    if (_currentPeriod == period) return;

    _currentPeriod = period;
    await refreshLeaderboard();
  }

  /// Refresh current leaderboard
  Future<void> refreshLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<LeaderboardEntry> leaderboard;
      int participants;
      UserRank? userRank;

      switch (_currentPeriod) {
        case 'daily':
          leaderboard = await getDailyLeaderboard();
          participants = await getParticipantCount('daily');
          userRank = await getUserRank('daily');
          break;
        case 'weekly':
          leaderboard = await getWeeklyLeaderboard();
          participants = await getParticipantCount('weekly');
          userRank = await getUserRank('weekly');
          break;
        case 'monthly':
          leaderboard = await getMonthlyLeaderboard();
          participants = await getParticipantCount('monthly');
          userRank = await getUserRank('monthly');
          break;
        case 'yearly':
          leaderboard = await getYearlyLeaderboard();
          participants = await getParticipantCount('yearly');
          userRank = await getUserRank('yearly');
          break;
        case 'alltime':
          leaderboard = await getAllTimeLeaderboard();
          participants = await getParticipantCount('alltime');
          userRank = await getUserRank('alltime');
          break;
        default:
          leaderboard = await getDailyLeaderboard();
          participants = await getParticipantCount('daily');
          userRank = await getUserRank('daily');
      }

      _currentLeaderboard = leaderboard;
      _totalParticipants = participants;
      _currentUserRank = userRank;
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get current user rank
  UserRank? getCurrentUserRank() {
    return _currentUserRank;
  }

  /// Start real-time updates (placeholder for future implementation)
  void startRealTimeUpdates() {
    // TODO: Implement real-time updates if needed
  }

  /// Stop real-time updates (placeholder for future implementation)
  void stopRealTimeUpdates() {
    // TODO: Implement real-time updates if needed
  }

  /// Force refresh leaderboard data (clears cache and fetches fresh data)
  Future<void> refreshLeaderboardData() async {
    await CacheService.clearDataTypeCache('leaderboard');

    await refreshLeaderboard();
  }

  /// Clear leaderboard cache
  Future<void> clearLeaderboardCache() async {
    await CacheService.clearDataTypeCache('leaderboard');
  }
}
