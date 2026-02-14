import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/leaderboard_service.dart';
import '../../../core/models/leaderboard_model.dart';

class LeaderboardSection extends StatefulWidget {
  const LeaderboardSection({super.key});

  @override
  State<LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends State<LeaderboardSection> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leaderboardService = Provider.of<LeaderboardService>(context, listen: false);
      leaderboardService.startRealTimeUpdates();
    });
  }

  @override
  void dispose() {
    final leaderboardService = Provider.of<LeaderboardService>(context, listen: false);
    leaderboardService.stopRealTimeUpdates();
    super.dispose();
  }


  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return const Color(0xFF6C757D);
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events_rounded;
      case 2:
        return Icons.emoji_events_rounded;
      case 3:
        return Icons.emoji_events_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context);
    final leaderboardService = Provider.of<LeaderboardService>(context);
    final isHindi = languageService.isHindi;
    final currentLeaderboard = leaderboardService.currentLeaderboard;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.leaderboard_rounded,
                color: const Color(0xFFFFB366),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.leaderboard,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Time period selector
          _buildPeriodSelector(leaderboardService, isHindi),
          const SizedBox(height: 16),
          
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.participants,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C757D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${leaderboardService.totalParticipants}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFE9ECEF),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _getRankingLabel(leaderboardService.currentPeriod, isHindi),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C757D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCurrentUserRankDisplay(leaderboardService, isHindi),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Leaderboard list
          if (currentLeaderboard.isEmpty)
            _buildEmptyState(isHindi)
          else
            _buildLeaderboardList(currentLeaderboard, isHindi),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: const Color(0xFFADB5BD),
          ),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'कोई डेटा नहीं मिला' : 'No data available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi 
                ? 'अभी तक कोई जाप दर्ज नहीं किया गया है'
                : 'No japa has been recorded yet',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(LeaderboardService leaderboardService, bool isHindi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['daily', 'weekly', 'monthly', 'yearly', 'alltime'].map((period) {
          final isSelected = leaderboardService.currentPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => leaderboardService.setCurrentPeriod(period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFF2C3E50).withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  _getPeriodDisplayName(period, isHindi),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF2C3E50) : const Color(0xFF6C757D),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodDisplayName(String period, bool isHindi) {
    if (isHindi) {
      switch (period) {
        case 'daily':
          return 'दैनिक';
        case 'weekly':
          return 'साप्ताहिक';
        case 'monthly':
          return 'मासिक';
        case 'yearly':
          return 'वार्षिक';
        case 'alltime':
          return 'सभी समय';
        default:
          return 'दैनिक';
      }
    } else {
      switch (period) {
        case 'daily':
          return 'Daily';
        case 'weekly':
          return 'Weekly';
        case 'monthly':
          return 'Monthly';
        case 'yearly':
          return 'Yearly';
        case 'alltime':
          return 'All Time';
        default:
          return 'Daily';
      }
    }
  }

  String _getRankingLabel(String period, bool isHindi) {
    if (isHindi) {
      switch (period) {
        case 'daily':
          return 'दैनिक रैंकिंग';
        case 'weekly':
          return 'साप्ताहिक रैंकिंग';
        case 'monthly':
          return 'मासिक रैंकिंग';
        case 'yearly':
          return 'वार्षिक रैंकिंग';
        case 'alltime':
          return 'सभी समय रैंकिंग';
        default:
          return 'दैनिक रैंकिंग';
      }
    } else {
      switch (period) {
        case 'daily':
          return 'Daily Ranking';
        case 'weekly':
          return 'Weekly Ranking';
        case 'monthly':
          return 'Monthly Ranking';
        case 'yearly':
          return 'Yearly Ranking';
        case 'alltime':
          return 'All Time Ranking';
        default:
          return 'Daily Ranking';
      }
    }
  }

  String _getCurrentUserRankDisplay(LeaderboardService leaderboardService, bool isHindi) {
    final currentUserRank = leaderboardService.getCurrentUserRank();
    
    if (currentUserRank != null) {
      return '#${currentUserRank.rank}';
    } else {
      // Check if user has any japa count for this period
      final currentLeaderboard = leaderboardService.currentLeaderboard;
      final hasAnyJapa = currentLeaderboard.any((entry) => entry.isCurrentUser && entry.totalJapaCount > 0);
      
      if (hasAnyJapa) {
        return isHindi ? 'गणना...' : 'Calculating...';
      } else {
        return isHindi ? 'शुरू करें' : 'Start';
      }
    }
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> leaderboard, bool isHindi) {
    // Separate top 10 and current user if not in top 10
    final top10 = leaderboard.where((entry) => entry.rank <= 10).toList();
    final currentUserEntry = leaderboard.where((entry) => entry.isCurrentUser && entry.rank > 10).toList();
    
    return Column(
      children: [
        // Top 10 users
        ...top10.map((entry) => _buildLeaderboardItem(entry, isHindi)),
        
        // Current user if not in top 10
        if (currentUserEntry.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: const Color(0xFFE9ECEF),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const SizedBox(height: 8),
          ...currentUserEntry.map((entry) => _buildLeaderboardItem(entry, isHindi)),
        ],
      ],
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, bool isHindi) {
    final rankColor = _getRankColor(entry.rank);
    final rankIcon = _getRankIcon(entry.rank);
    final isCurrentUser = entry.isCurrentUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? const Color(0xFFFFB366).withOpacity(0.1)
            : entry.rank <= 3 
                ? rankColor.withOpacity(0.1)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFFFFB366).withOpacity(0.5)
              : entry.rank <= 3 
                  ? rankColor.withOpacity(0.3)
                  : const Color(0xFFE9ECEF),
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? const Color(0xFFFFB366)
                  : entry.rank <= 3 
                      ? rankColor 
                      : const Color(0xFFF8F9FA),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCurrentUser
                  ? const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : entry.rank <= 3
                      ? Icon(
                          rankIcon,
                          color: Colors.white,
                          size: 20,
                        )
                      : Text(
                          '${entry.rank}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser ? const Color(0xFFFFB366) : const Color(0xFF2C3E50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB366),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isHindi ? 'आप' : 'You',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Rank #${entry.rank}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C757D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Japa count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalJapaCount}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFB366),
                ),
              ),
              Text(
                isHindi ? 'जाप' : 'Japa',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
