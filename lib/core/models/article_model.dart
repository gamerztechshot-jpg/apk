// core/models/article_model.dart
class ArticleModel {
  final int id;
  final String titleEn;
  final String titleHi;
  final String descriptionEn;
  final String descriptionHi;
  final String category;
  final String image;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  ArticleModel({
    required this.id,
    required this.titleEn,
    required this.titleHi,
    required this.descriptionEn,
    required this.descriptionHi,
    required this.category,
    required this.image,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArticleModel.fromMap(Map<String, dynamic> map) {
    return ArticleModel(
      id: map['id'] as int,
      titleEn: map['title_en'] as String? ?? '',
      titleHi: map['title_hi'] as String? ?? '',
      descriptionEn: map['description_en'] as String? ?? '',
      descriptionHi: map['description_hi'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      image: map['image'] as String? ?? '',
      priority: map['priority'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title_en': titleEn,
      'title_hi': titleHi,
      'description_en': descriptionEn,
      'description_hi': descriptionHi,
      'category': category,
      'image': image,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get title based on language preference
  String getTitle({bool isHindi = false}) {
    return isHindi ? titleHi : titleEn;
  }

  // Get description based on language preference
  String getDescription({bool isHindi = false}) {
    return isHindi ? descriptionHi : descriptionEn;
  }

  // Get display title (English by default for current app language)
  String get displayTitle {
    return titleEn.isNotEmpty ? titleEn : titleHi;
  }

  // Get display description (English by default for current app language)
  String get displayDescription {
    return descriptionEn.isNotEmpty ? descriptionEn : descriptionHi;
  }

  // Check if article has image
  bool get hasImage => image.isNotEmpty;

  // Get category icon based on category name
  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'mantras':
        return '🕉️';
      case 'ayurveda':
        return '🌿';
      case 'yoga':
        return '🧘';
      case 'bhagavad gita':
        return '📖';
      case 'spirituality':
        return '✨';
      case 'meditation':
        return '🧘‍♀️';
      case 'hinduism':
        return '🕉️';
      case 'philosophy':
        return '💭';
      default:
        return '📄';
    }
  }
}
