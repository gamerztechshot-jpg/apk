// features/festival_kit/models/festival_config_model.dart

/// Main festival configuration model
class FestivalConfig {
  final String? id;
  final String festivalName;
  final DateTime startDate;
  final DateTime endDate;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final List<FestivalContentItem> contentItems;

  FestivalConfig({
    this.id,
    required this.festivalName,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.contentItems,
  });

  factory FestivalConfig.fromJson(Map<String, dynamic> json) {
    return FestivalConfig(
      id: json['id']?.toString(),
      festivalName: json['festival_name'] ?? 'Festival',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      imageUrl: json['image_url'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      contentItems:
          (json['content_items'] as List<dynamic>?)
              ?.map((item) => FestivalContentItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'festival_name': festivalName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'content_items': contentItems.map((item) => item.toJson()).toList(),
    };
  }

  /// Check if festival is currently active (admin controlled via is_active flag)
  bool get isCurrentlyActive => isActive;
}

/// Individual content item in the festival
class FestivalContentItem {
  final String id;
  final String type; // audio, ebook, store_item, puja
  final String title;
  final String description;
  final String image;
  final String refId;
  final Map<String, dynamic>? itemDetails;
  final DateTime addedAt;

  FestivalContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.image,
    required this.refId,
    this.itemDetails,
    required this.addedAt,
  });

  factory FestivalContentItem.fromJson(Map<String, dynamic> json) {
    return FestivalContentItem(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      refId: json['ref_id']?.toString() ?? '',
      itemDetails: json['item_details'] as Map<String, dynamic>?,
      addedAt: DateTime.parse(json['added_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'image': image,
      'ref_id': refId,
      'item_details': itemDetails,
      'added_at': addedAt.toIso8601String(),
    };
  }

  /// Get the first image URL from comma-separated images
  String get primaryImageUrl {
    if (image.isEmpty) return '';
    return image.split(',').first.trim();
  }

  /// Get all image URLs from comma-separated images
  List<String> get allImageUrls {
    if (image.isEmpty) return [];
    return image.split(',').map((url) => url.trim()).toList();
  }
}
