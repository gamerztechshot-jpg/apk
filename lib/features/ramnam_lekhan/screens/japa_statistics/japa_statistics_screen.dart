import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/daily_targets_service.dart';
import '../../../../core/services/auth_service.dart';

class JapaStatisticsScreen extends StatefulWidget {
  final DateTime? userRegistrationDate;

  const JapaStatisticsScreen({super.key, this.userRegistrationDate});

  @override
  State<JapaStatisticsScreen> createState() => _JapaStatisticsScreenState();
}

class _JapaStatisticsScreenState extends State<JapaStatisticsScreen> {
  int _totalJapaCount = 0;
  int _todayJapaCount = 0;
  int _yesterdayJapaCount = 0;
  int _weekJapaCount = 0;
  int _monthJapaCount = 0;
  int _yearJapaCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJapaStatistics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    _loadJapaStatistics();
  }

  Future<void> _loadJapaStatistics() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.getCurrentUser();

    if (currentUser != null) {
      // Load all japa statistics
      final totalCount = await _getTotalJapaCount(currentUser.id);
      final todayCount = await _getTodayJapaCount(currentUser.id);
      final yesterdayCount = await _getYesterdayJapaCount(currentUser.id);
      final weekCount = await _getWeekJapaCount(currentUser.id);
      final monthCount = await _getMonthJapaCount(currentUser.id);
      final yearCount = await _getYearJapaCount(currentUser.id);

      setState(() {
        _totalJapaCount = totalCount;
        _todayJapaCount = todayCount;
        _yesterdayJapaCount = yesterdayCount;
        _weekJapaCount = weekCount;
        _monthJapaCount = monthCount;
        _yearJapaCount = yearCount;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<int> _getTotalJapaCount(String userId) async {
    final dailyTargetsService = Provider.of<DailyTargetsService>(
      context,
      listen: false,
    );
    try {
      // Try to get from optimized statistics first
      final stats = await dailyTargetsService.getUserStatistics();
      if (stats.isNotEmpty && stats['total_japa_count'] != null) {
        return stats['total_japa_count'] as int;
      }
    } catch (e) {}

    // Fallback to direct calculation
    return await dailyTargetsService.getTotalJapaCount();
  }

  Future<int> _getTodayJapaCount(String userId) async {
    final dailyTargetsService = Provider.of<DailyTargetsService>(
      context,
      listen: false,
    );
    return await dailyTargetsService.getTodayJapaCount();
  }

  Future<int> _getYesterdayJapaCount(String userId) async {
    final dailyTargetsService = Provider.of<DailyTargetsService>(
      context,
      listen: false,
    );
    return await dailyTargetsService.getYesterdayJapaCount();
  }

  Future<int> _getWeekJapaCount(String userId) async {
    final dailyTargetsService = Provider.of<DailyTargetsService>(
      context,
      listen: false,
    );
    return await dailyTargetsService.getJapaCountForLastDays(7);
  }

  Future<int> _getMonthJapaCount(String userId) async {
    final dailyTargetsService = Provider.of<DailyTargetsService>(
      context,
      listen: false,
    );
    return await dailyTargetsService.getJapaCountForLastDays(30);
  }

  Future<int> _getYearJapaCount(String userId) async {
    final dailyTargetsService = Provider.of<DailyTargetsService>(
      context,
      listen: false,
    );
    return await dailyTargetsService.getJapaCountForLastDays(365);
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? 'जाप आंकड़े' : 'Japa Statistics',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFFFB366),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadJapaStatistics,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isHindi ? 'रिफ्रेश करें' : 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              isHindi
                                  ? 'आपके जाप आंकड़े'
                                  : 'Your Japa Statistics',
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isHindi
                                  ? 'सभी समय का कुल जाप: $_totalJapaCount'
                                  : 'Total Japa of All Time: $_totalJapaCount',
                              style: const TextStyle(
                                color: Color(0xFF6C757D),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Statistics cards
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Today's Japa
                        _buildStatCard(
                          isHindi ? 'आज का जाप' : 'Today\'s Japa',
                          '$_todayJapaCount',
                          Icons.today_rounded,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),

                        // Yesterday's Japa
                        _buildStatCard(
                          isHindi ? 'कल का जाप' : 'Yesterday\'s Japa',
                          '$_yesterdayJapaCount',
                          Icons.history_rounded,
                          Colors.indigo,
                        ),
                        const SizedBox(height: 12),

                        // Week
                        _buildStatCard(
                          isHindi ? 'पिछले 7 दिन' : 'Last 7 Days',
                          '$_weekJapaCount',
                          Icons.date_range_rounded,
                          Colors.green,
                        ),
                        const SizedBox(height: 12),

                        // Month
                        _buildStatCard(
                          isHindi ? 'पिछले 30 दिन' : 'Last 30 Days',
                          '$_monthJapaCount',
                          Icons.calendar_month_rounded,
                          Colors.orange,
                        ),
                        const SizedBox(height: 12),

                        // Year
                        _buildStatCard(
                          isHindi ? 'पिछले 365 दिन' : 'Last 365 Days',
                          '$_yearJapaCount',
                          Icons.calendar_today_rounded,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C3E50).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
