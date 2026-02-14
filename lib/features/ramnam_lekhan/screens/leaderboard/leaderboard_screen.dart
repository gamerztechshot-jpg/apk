import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/leaderboard_service.dart';
import 'package:karmasu/core/services/language_service.dart';
import 'package:karmasu/core/models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final LeaderboardService _leaderboardService = LeaderboardService();

  // Data for each tab
  List<LeaderboardEntry> _dailyLeaderboard = [];
  List<LeaderboardEntry> _weeklyLeaderboard = [];
  List<LeaderboardEntry> _monthlyLeaderboard = [];
  List<LeaderboardEntry> _yearlyLeaderboard = [];
  List<LeaderboardEntry> _allTimeLeaderboard = [];

  // Participant counts
  int _dailyParticipants = 0;
  int _weeklyParticipants = 0;
  int _monthlyParticipants = 0;
  int _yearlyParticipants = 0;
  int _allTimeParticipants = 0;

  // User ranks
  UserRank? _dailyUserRank;
  UserRank? _weeklyUserRank;
  UserRank? _monthlyUserRank;
  UserRank? _yearlyUserRank;
  UserRank? _allTimeUserRank;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllLeaderboards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all leaderboards in parallel
      final results = await Future.wait([
        _leaderboardService.getDailyLeaderboard(),
        _leaderboardService.getWeeklyLeaderboard(),
        _leaderboardService.getMonthlyLeaderboard(),
        _leaderboardService.getYearlyLeaderboard(),
        _leaderboardService.getAllTimeLeaderboard(),
        _leaderboardService.getParticipantCount('daily'),
        _leaderboardService.getParticipantCount('weekly'),
        _leaderboardService.getParticipantCount('monthly'),
        _leaderboardService.getParticipantCount('yearly'),
        _leaderboardService.getParticipantCount('alltime'),
        _leaderboardService.getUserRank('daily'),
        _leaderboardService.getUserRank('weekly'),
        _leaderboardService.getUserRank('monthly'),
        _leaderboardService.getUserRank('yearly'),
        _leaderboardService.getUserRank('alltime'),
      ]);

      if (mounted) {
        setState(() {
          _dailyLeaderboard = results[0] as List<LeaderboardEntry>;
          _weeklyLeaderboard = results[1] as List<LeaderboardEntry>;
          _monthlyLeaderboard = results[2] as List<LeaderboardEntry>;
          _yearlyLeaderboard = results[3] as List<LeaderboardEntry>;
          _allTimeLeaderboard = results[4] as List<LeaderboardEntry>;
          _dailyParticipants = results[5] as int;
          _weeklyParticipants = results[6] as int;
          _monthlyParticipants = results[7] as int;
          _yearlyParticipants = results[8] as int;
          _allTimeParticipants = results[9] as int;
          _dailyUserRank = results[10] as UserRank?;
          _weeklyUserRank = results[11] as UserRank?;
          _monthlyUserRank = results[12] as UserRank?;
          _yearlyUserRank = results[13] as UserRank?;
          _allTimeUserRank = results[14] as UserRank?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isHindi ? 'लीडरबोर्ड' : 'Leaderboard',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          tabs: [
            Tab(text: isHindi ? 'दैनिक' : 'Daily'),
            Tab(text: isHindi ? 'साप्ताहिक' : 'Weekly'),
            Tab(text: isHindi ? 'मासिक' : 'Monthly'),
            Tab(text: isHindi ? 'वार्षिक' : 'Yearly'),
            Tab(text: isHindi ? 'सभी समय' : 'All Time'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardTab(
                  _dailyLeaderboard,
                  _dailyParticipants,
                  _dailyUserRank,
                  isHindi,
                  'daily',
                ),
                _buildLeaderboardTab(
                  _weeklyLeaderboard,
                  _weeklyParticipants,
                  _weeklyUserRank,
                  isHindi,
                  'weekly',
                ),
                _buildLeaderboardTab(
                  _monthlyLeaderboard,
                  _monthlyParticipants,
                  _monthlyUserRank,
                  isHindi,
                  'monthly',
                ),
                _buildLeaderboardTab(
                  _yearlyLeaderboard,
                  _yearlyParticipants,
                  _yearlyUserRank,
                  isHindi,
                  'yearly',
                ),
                _buildLeaderboardTab(
                  _allTimeLeaderboard,
                  _allTimeParticipants,
                  _allTimeUserRank,
                  isHindi,
                  'alltime',
                ),
              ],
            ),
    );
  }

  Widget _buildLeaderboardTab(
    List<LeaderboardEntry> leaderboard,
    int participants,
    UserRank? userRank,
    bool isHindi,
    String type,
  ) {
    return RefreshIndicator(
      onRefresh: _loadAllLeaderboards,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Participant count
            _buildParticipantCount(participants, isHindi),
            const SizedBox(height: 16),

            // Leaderboard entries
            if (leaderboard.isEmpty)
              _buildEmptyState(isHindi)
            else
              _buildLeaderboardList(leaderboard, userRank, isHindi),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCount(int participants, bool isHindi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.people_rounded, color: Colors.orange.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isHindi
                  ? '$participants सक्रिय प्रतिभागी'
                  : '$participants Active Participants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'अभी तक कोई डेटा नहीं है' : 'No data available yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? 'जाप शुरू करें और लीडरबोर्ड में अपना स्थान बनाएं!'
                : 'Start counting Japa and make your mark on the leaderboard!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(
    List<LeaderboardEntry> leaderboard,
    UserRank? userRank,
    bool isHindi,
  ) {
    return Column(
      children: [
        // Top 10 leaderboard
        ...leaderboard.map((entry) => _buildLeaderboardEntry(entry, isHindi)),

        // User's rank if not in top 10
        if (userRank != null && userRank.rank > 10)
          _buildUserRankEntry(userRank, isHindi),
      ],
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, bool isHindi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isCurrentUser
              ? Colors.orange.shade300
              : Colors.grey.shade200,
          width: entry.isCurrentUser ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(entry.rank),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.isCurrentUser
                          ? (isHindi ? 'आप' : 'You')
                          : entry.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: entry.isCurrentUser
                            ? Colors.orange.shade700
                            : Colors.black87,
                      ),
                    ),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star_rounded,
                        color: Colors.orange.shade600,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.japaCount} ${isHindi ? 'जाप' : 'Japa'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Trophy icon for top 3
          if (entry.rank <= 3)
            Icon(
              Icons.emoji_events_rounded,
              color: _getRankColor(entry.rank),
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildUserRankEntry(UserRank userRank, bool isHindi) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${userRank.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isHindi ? 'आप' : 'You',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.person_rounded,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${userRank.japaCount} ${isHindi ? 'जाप' : 'Japa'} • ${isHindi ? 'कुल' : 'Total'} ${userRank.totalParticipants}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600; // Gold
      case 2:
        return Colors.grey.shade500; // Silver
      case 3:
        return Colors.orange.shade700; // Bronze
      default:
        return Colors.blue.shade600;
    }
  }
}
