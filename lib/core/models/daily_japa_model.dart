class DailyJapaModel {
  final String id;
  final String userId;
  final String mantraId;
  final int count;
  final DateTime date;
  final DateTime createdAt;

  DailyJapaModel({
    required this.id,
    required this.userId,
    required this.mantraId,
    required this.count,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mantra_id': mantraId,
      'count': count,
      'date': date.toIso8601String().split('T')[0], // Store only date part
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyJapaModel.fromJson(Map<String, dynamic> json) {
    return DailyJapaModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mantraId: json['mantra_id'] as String,
      count: json['count'] as int,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
