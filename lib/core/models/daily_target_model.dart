class DailyTargetModel {
  final String id;
  final String userId;
  final int targetCount;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastUpdated;
  final DateTime createdAt;

  DailyTargetModel({
    required this.id,
    required this.userId,
    required this.targetCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastUpdated,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'target_count': targetCount,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_updated': lastUpdated.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyTargetModel.fromJson(Map<String, dynamic> json) {
    return DailyTargetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      targetCount: json['target_count'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  DailyTargetModel copyWith({
    String? id,
    String? userId,
    int? targetCount,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return DailyTargetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetCount: targetCount ?? this.targetCount,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
