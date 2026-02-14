enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  yearly,
  allTime,
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final int japaCount;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.japaCount,
    required this.isCurrentUser,
  });

  // Alias for compatibility
  int get totalJapaCount => japaCount;

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, username: $username, japaCount: $japaCount, isCurrentUser: $isCurrentUser)';
  }
}

// Alias for compatibility
typedef LeaderboardModel = LeaderboardEntry;

class UserRank {
  final int rank;
  final int japaCount;
  final int totalParticipants;

  UserRank({
    required this.rank,
    required this.japaCount,
    required this.totalParticipants,
  });

  @override
  String toString() {
    return 'UserRank(rank: $rank, japaCount: $japaCount, totalParticipants: $totalParticipants)';
  }
}