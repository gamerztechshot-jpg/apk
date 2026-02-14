// core/models/course_banner_model.dart
class CourseBanner {
  final String? id;
  final String bannerUrl;
  final String bannerType; // 'upload' or 'link'
  final int priority;
  final bool isActive;

  CourseBanner({
    this.id,
    required this.bannerUrl,
    this.bannerType = 'upload',
    this.priority = 0,
    this.isActive = true,
  });

  factory CourseBanner.fromJson(Map<String, dynamic> json) {
    return CourseBanner(
      id: json['id']?.toString(),
      bannerUrl: json['banner_url'] ?? '',
      bannerType: json['banner_type'] ?? 'upload',
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'banner_url': bannerUrl,
      'banner_type': bannerType,
      'priority': priority,
      'is_active': isActive,
    };
  }

  CourseBanner copyWith({
    String? id,
    String? bannerUrl,
    String? bannerType,
    int? priority,
    bool? isActive,
  }) {
    return CourseBanner(
      id: id ?? this.id,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bannerType: bannerType ?? this.bannerType,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'CourseBanner(id: $id, bannerUrl: $bannerUrl, bannerType: $bannerType, priority: $priority, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseBanner &&
        other.id == id &&
        other.bannerUrl == bannerUrl &&
        other.bannerType == bannerType &&
        other.priority == priority &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        bannerUrl.hashCode ^
        bannerType.hashCode ^
        priority.hashCode ^
        isActive.hashCode;
  }
}

