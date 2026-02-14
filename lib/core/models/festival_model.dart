// core/models/festival_model.dart
class FestivalBanner {
  final String id;
  final String bannerUrl;
  final String? title;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FestivalBanner({
    required this.id,
    required this.bannerUrl,
    this.title,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory FestivalBanner.fromJson(Map<String, dynamic> json) {
    return FestivalBanner(
      id: json['id'] ?? '',
      bannerUrl: json['image_url'] ?? '',
      title: json['festival_name'],
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': bannerUrl,
      'festival_name': title,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class Festival {
  final String date;
  final String festivalName;
  final String month;
  final String? imageUrl;
  final DateTime parsedDate;

  Festival({
    required this.date,
    required this.festivalName,
    required this.month,
    this.imageUrl,
    required this.parsedDate,
  });
}
