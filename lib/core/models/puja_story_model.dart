// core/models/puja_story_model.dart
class PujaStoryModel {
  final int id;
  final String nameEn;
  final String nameHi;
  final String category;
  final String? url;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  PujaStoryModel({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.category,
    this.url,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PujaStoryModel.fromJson(Map<String, dynamic> json) {
    return PujaStoryModel(
      id: json['id'] ?? 0,
      nameEn: json['name_en'] ?? '',
      nameHi: json['name_hi'] ?? '',
      category: json['category'] ?? '',
      url: json['url'],
      priority: json['priority'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_hi': nameHi,
      'category': category,
      'url': url,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PujaStoryModel copyWith({
    int? id,
    String? nameEn,
    String? nameHi,
    String? category,
    String? url,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PujaStoryModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameHi: nameHi ?? this.nameHi,
      category: category ?? this.category,
      url: url ?? this.url,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PujaStoryModel(id: $id, nameEn: $nameEn, nameHi: $nameHi, category: $category, url: $url, priority: $priority, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PujaStoryModel &&
        other.id == id &&
        other.nameEn == nameEn &&
        other.nameHi == nameHi &&
        other.category == category &&
        other.url == url &&
        other.priority == priority &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nameEn.hashCode ^
        nameHi.hashCode ^
        category.hashCode ^
        url.hashCode ^
        priority.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
