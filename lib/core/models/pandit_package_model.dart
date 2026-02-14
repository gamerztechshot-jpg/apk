// core/models/pandit_package_model.dart

class PanditPackageModel {
  final String id; // UUID
  final String name;
  final String description;
  final String photoUrl;
  final num price;
  final DateTime? createdAt;

  PanditPackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.photoUrl,
    required this.price,
    this.createdAt,
  });

  factory PanditPackageModel.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return PanditPackageModel(
      id: (json['id'] ?? '').toString(),
      name: (json['package_name'] ?? json['name'] ?? '').toString(),
      description: (json['package_description'] ?? json['description'] ?? '')
          .toString(),
      photoUrl: (json['photo_url'] ?? json['photo'] ?? '').toString(),
      price: (json['price'] ?? 0),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_name': name,
      'package_description': description,
      'photo_url': photoUrl,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
