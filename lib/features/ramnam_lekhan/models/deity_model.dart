class DeityModel {
  final String id;
  final String englishName;
  final String hindiName;
  final String icon;
  final String description;
  final String hindiDescription;
  final List<String> colors;
  final String? imageUrl;
  final bool isActive;
  final bool isCustom;
  final int displayOrder;

  const DeityModel({
    required this.id,
    required this.englishName,
    required this.hindiName,
    required this.icon,
    required this.description,
    required this.hindiDescription,
    required this.colors,
    this.imageUrl,
    this.isActive = true,
    this.isCustom = false,
    this.displayOrder = 0,
  });

  /// Create DeityModel from JSON (Supabase response)
  factory DeityModel.fromJson(Map<String, dynamic> json) {
    return DeityModel(
      id: json['id'] as String,
      englishName: json['english_name'] as String,
      hindiName: json['hindi_name'] as String,
      icon: json['icon'] as String,
      description: json['description_en'] as String,
      hindiDescription: json['description_hi'] as String,
      colors: (json['colors'] as List<dynamic>?)?.cast<String>() ?? [],
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isCustom: json['is_custom'] as bool? ?? false,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  /// Convert DeityModel to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'english_name': englishName,
      'hindi_name': hindiName,
      'icon': icon,
      'description_en': description,
      'description_hi': hindiDescription,
      'colors': colors,
      'image_url': imageUrl,
      'is_active': isActive,
      'is_custom': isCustom,
      'display_order': displayOrder,
    };
  }

  /// Static list of deities loaded from Supabase at app startup
  /// 
  /// This list is populated by DeityService.initializeDeities() in main.dart
  /// Screens can safely use DeityModel.deities.firstWhere() after initialization
  static List<DeityModel> deities = [];
}
