import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StreakService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Streak data
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _currentTarget = 108;
  bool _todayAchieved = false;
  int _todayProgress = 0;
  int _daysUntilTarget = 108;
  String? _currentUserId;
  bool _isLoading = false;
  bool _hasLoadedOnce = false; // Track if data has been loaded once

  // Statistics data for profile section
  int _totalJapaCount = 0;
  int _daysActive = 0;

  // Getters
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get currentTarget => _currentTarget;
  bool get todayAchieved => _todayAchieved;
  int get todayProgress => _todayProgress;
  int get daysUntilTarget => _daysUntilTarget;
  bool get isLoading => _isLoading;

  // Statistics getters for profile section
  int get totalJapaCount => _totalJapaCount;
  int get daysActive => _daysActive;

  StreakService() {
    _initializeService();
  }

  void _initializeService() {
    _currentUserId = _supabase.auth.currentUser?.id;
    if (_currentUserId != null) {
      _loadStreakDataFast();
    }

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _currentUserId = data.session?.user.id;
        _loadStreakDataFast();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUserId = null;
        _resetStreakData();
      }
    });
  }

  void _resetStreakData() {
    _currentStreak = 0;
    _longestStreak = 0;
    _currentTarget = 108;
    _todayAchieved = false;
    _todayProgress = 0;
    _daysUntilTarget = 108;
    _totalJapaCount = 0;
    _daysActive = 0;
    _hasLoadedOnce = false;
    notifyListeners();
  }

  /// Fast loading - get comprehensive data in one call
  Future<void> _loadStreakDataFast() async {
    if (_currentUserId == null) return;

    // Don't show loading if we already have data
    if (!_hasLoadedOnce) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Get comprehensive statistics in one call (fast)
      final statsResponse = await _supabase.rpc(
        'get_user_japa_statistics',
        params: {'p_user_id': _currentUserId!},
      );

      if (statsResponse.isNotEmpty) {
        final stats = statsResponse.first;

        // Set statistics data
        _totalJapaCount = (stats['total_japa_count'] as int?) ?? 0;
        _daysActive = (stats['total_active_days'] as int?) ?? 0;
        _todayProgress = (stats['today_japa_count'] as int?) ?? 0;

        _todayAchieved = _todayProgress >= _currentTarget;
        _daysUntilTarget = _currentTarget - _todayProgress;
      } else {
        // Set default values if no data
        _totalJapaCount = 0;
        _daysActive = 0;
        _todayProgress = 0;
        _todayAchieved = false;
        _daysUntilTarget = _currentTarget;
      }

      // Load streak data in background (non-blocking)
      if (!_hasLoadedOnce) {
        _loadStreakDataInBackground();
      }

      _hasLoadedOnce = true;
    } catch (e) {
      // Set default values if loading fails
      _currentTarget = 108;
      _todayAchieved = false;
      _todayProgress = 0;
      _daysUntilTarget = 108;
      _totalJapaCount = 0;
      _daysActive = 0;
      _hasLoadedOnce = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load streak calculation in background
  Future<void> _loadStreakDataInBackground() async {
    try {
      // Get last 7 days of japa data for faster calculation (instead of 30)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final response = await _supabase
          .from('user_daily_japa')
          .select('date, total_japa_count')
          .eq('user_id', _currentUserId!)
          .gte('date', sevenDaysAgo.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      // Calculate current streak (limited to 7 days for speed)
      _currentStreak = _calculateCurrentStreak(response);

      // Calculate longest streak (limited to 7 days for speed)
      _longestStreak = _calculateLongestStreak(response);

      notifyListeners();
    } catch (e) {}
  }

  /// Calculate current streak from japa data (optimized for 7 days)
  int _calculateCurrentStreak(List<dynamic> japaData) {
    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      // Reduced from 30 to 7 days
      final checkDate = today.subtract(Duration(days: i));
      final dateString = checkDate.toIso8601String().split('T')[0];

      final dayData = japaData
          .where((item) => item['date'] == dateString)
          .toList();

      if (dayData.isNotEmpty) {
        final japaCount = (dayData.first['total_japa_count'] as int?) ?? 0;
        if (japaCount >= _currentTarget) {
          streak++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate longest streak from japa data (optimized for 7 days)
  int _calculateLongestStreak(List<dynamic> japaData) {
    int longestStreak = 0;
    int currentStreak = 0;

    // Sort data by date (oldest first)
    final sortedData = List<Map<String, dynamic>>.from(japaData)
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    for (final item in sortedData) {
      final japaCount = (item['total_japa_count'] as int?) ?? 0;
      if (japaCount >= _currentTarget) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    return longestStreak;
  }

  /// Set a new daily target (local only - no database changes)
  Future<Map<String, dynamic>?> setDailyTarget(int newTarget) async {
    if (_currentUserId == null) return null;

    if (newTarget <= 0) {
      return {'success': false, 'message': 'Target must be greater than 0'};
    }

    try {
      // Update local target
      final oldTarget = _currentTarget;
      _currentTarget = newTarget;
      _todayAchieved = _todayProgress >= _currentTarget;
      _daysUntilTarget = _currentTarget - _todayProgress;

      // Recalculate streaks with new target (fast)
      _loadStreakDataInBackground();

      notifyListeners();

      return {
        'success': true,
        'message': 'Target updated successfully',
        'old_target': oldTarget,
        'new_target': newTarget,
        'target_met_today': _todayAchieved,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to set target: $e'};
    }
  }

  /// Check and update streak after japa counting (fast)
  Future<void> checkStreakUpdate() async {
    if (_currentUserId == null) return;

    try {
      // Just reload today's data and recalculate streaks
      await _loadStreakDataFast();
    } catch (e) {}
  }

  /// Get detailed streak information
  Future<Map<String, dynamic>?> getStreakInfo() async {
    if (_currentUserId == null) return null;

    try {
      // Return local data
      return {
        'current_streak': _currentStreak,
        'longest_streak': _longestStreak,
        'current_target': _currentTarget,
        'today_achieved': _todayAchieved,
      };
    } catch (e) {
      return null;
    }
  }

  /// Refresh streak data (fast)
  Future<void> refreshStreakData() async {
    await _loadStreakDataFast();
  }

  /// Get streak progress percentage
  double getProgressPercentage() {
    if (_currentTarget == 0) return 0.0;
    return (_todayProgress / _currentTarget).clamp(0.0, 1.0);
  }

  /// Check if user is close to target (within 10%)
  bool get isCloseToTarget {
    if (_currentTarget == 0) return false;
    final percentage = getProgressPercentage();
    return percentage >= 0.9 && percentage < 1.0;
  }

  /// Get motivational message based on progress
  String getMotivationalMessage() {
    if (_todayAchieved) {
      return "🎉 Target achieved! Keep up the great work!";
    } else if (isCloseToTarget) {
      return "🔥 Almost there! Just ${_daysUntilTarget} more japas!";
    } else if (_todayProgress == 0) {
      return "🌟 Start your spiritual journey today!";
    } else if (getProgressPercentage() >= 0.5) {
      return "💪 You're halfway there! Keep going!";
    } else {
      return "🙏 Every japa counts. Keep practicing!";
    }
  }
}
