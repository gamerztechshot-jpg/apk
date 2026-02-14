// features/astro/models/kundli_type_model.dart
class KundliTypeModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  KundliTypeModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.price,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KundliTypeModel.fromJson(Map<String, dynamic> json) {
    return KundliTypeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num).toDouble(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get display price
  String getDisplayPrice() {
    if (price == 0) {
      return 'Free';
    }
    return '₹${price.toStringAsFixed(0)}';
  }

  // Helper method to get download button text
  String getDownloadButtonText() {
    if (price == 0) {
      return 'Download';
    }
    return 'Purchase Now';
  }
}
