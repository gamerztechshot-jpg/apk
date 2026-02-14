class FavoriteModel {
  final String id;
  final String userId;
  final String mantraId;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.mantraId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mantra_id': mantraId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mantraId: json['mantra_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
