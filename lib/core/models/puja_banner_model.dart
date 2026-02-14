// core/models/puja_banner_model.dart
class PujaBanner {
  final int id;
  final String category;
  final String imageUrl;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  PujaBanner({
    required this.id,
    required this.category,
    required this.imageUrl,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PujaBanner.fromJson(Map<String, dynamic> json) {
    return PujaBanner(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
      priority: json['priority'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'image_url': imageUrl,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PujaBanner copyWith({
    int? id,
    String? category,
    String? imageUrl,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PujaBanner(
      id: id ?? this.id,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PujaBanner(id: $id, category: $category, imageUrl: $imageUrl, priority: $priority, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PujaBanner &&
        other.id == id &&
        other.category == category &&
        other.imageUrl == imageUrl &&
        other.priority == priority &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        category.hashCode ^
        imageUrl.hashCode ^
        priority.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
