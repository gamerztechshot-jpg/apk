// features/pandit/models/pandit_model.dart
class PanditModel {
  final String id;
  final String name;
  final String? nameHi;
  final String email;
  final String? emailHi;
  final String phone;
  final String? phoneHi;
  final String? profileImage;
  final String? profileImageHi;
  final String? bio;
  final String? bioHi;
  final int experienceYears;
  final String? experienceHi;
  final List<String> specializations;
  final List<String> specializationsHi;
  final String location;
  final String? locationHi;
  final double rating;
  final int totalBookings;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  PanditModel({
    required this.id,
    required this.name,
    this.nameHi,
    required this.email,
    this.emailHi,
    required this.phone,
    this.phoneHi,
    this.profileImage,
    this.profileImageHi,
    this.bio,
    this.bioHi,
    required this.experienceYears,
    this.experienceHi,
    required this.specializations,
    this.specializationsHi = const [],
    required this.location,
    this.locationHi,
    required this.rating,
    required this.totalBookings,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PanditModel.fromJson(Map<String, dynamic> json) {
    try {
      // Debug logging to understand the data structure

      // Extract basic_info if it exists, otherwise use root level fields
      final basicInfo = json['basic_info'] as Map<String, dynamic>? ?? {};
      final roles = json['roles'] as Map<String, dynamic>? ?? {};

      // Helper to get value with fallback
      String getValue(String key) {
        return basicInfo[key]?.toString() ?? json[key]?.toString() ?? '';
      }

      String? getValueHi(String key) {
        final hiValue = basicInfo['${key}_hi']?.toString();
        if (hiValue == null || hiValue.isEmpty) return null;
        return hiValue;
      }

      // Get name from basic_info first, then fallback to root level
      final name = getValue('name').isEmpty
          ? (json['name']?.toString() ?? 'Unknown Pandit')
          : getValue('name');
      final nameHi = getValueHi('name');

      // Get location from address in basic_info, then fallback to location field
      final location =
          (basicInfo['address']?.toString().trim() ??
          json['location']?.toString() ??
          'Location not specified');
      final locationHi = getValueHi('address');

      // Get email from basic_info first, then fallback to root level
      final email = getValue('email').isEmpty
          ? (json['email']?.toString() ?? '')
          : getValue('email');
      final emailHi = getValueHi('email');

      // Get phone from basic_info first, then fallback to root level
      final phone = getValue('phone').isEmpty
          ? (json['phone']?.toString() ?? '')
          : getValue('phone');
      final phoneHi = getValueHi('phone');

      // Get profile image from basic_info first, then fallback to root level
      final profileImage =
          basicInfo['photo_url']?.toString() ??
          json['profile_image']?.toString();
      final profileImageHi = basicInfo['photo_url_hi']?.toString();

      // Get bio from basic_info first, then fallback to root level
      final bio = basicInfo['about_you']?.toString() ?? json['bio']?.toString();
      final bioHi = getValueHi('about_you');

      // Get experience from basic_info first, then fallback to root level
      final experienceYears =
          _parseInt(basicInfo['experience']) ??
          _parseInt(json['experience_years']) ??
          0;
      final experienceHi = getValueHi('experience');

      // Get qualification as specializations
      final qualification = basicInfo['qualification']?.toString();
      final qualificationHi = basicInfo['qualification_hi']?.toString();
      final specializations = <String>[];
      final specializationsHi = <String>[];
      if (qualification != null && qualification.isNotEmpty) {
        specializations.add(qualification);
      }
      if (qualificationHi != null && qualificationHi.isNotEmpty) {
        specializationsHi.add(qualificationHi);
      }

      // Check if pandit is approved in roles
      final isPanditApproved = roles['pandit'] == 'approved';


      return PanditModel(
        id: json['id']?.toString() ?? '',
        name: name,
        nameHi: nameHi,
        email: email,
        emailHi: emailHi,
        phone: phone,
        phoneHi: phoneHi,
        profileImage: profileImage,
        profileImageHi: profileImageHi,
        bio: bio,
        bioHi: bioHi,
        experienceYears: experienceYears,
        experienceHi: experienceHi,
        specializations: specializations,
        specializationsHi: specializationsHi,
        location: location,
        locationHi: locationHi,
        rating: _parseDouble(json['rating']) ?? 0.0,
        totalBookings: _parseInt(json['total_bookings']) ?? 0,
        isAvailable: json['is_active'] == true && isPanditApproved,
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper methods for safe parsing
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'bio': bio,
      'experience_years': experienceYears,
      'specializations': specializations,
      'location': location,
      'rating': rating,
      'total_bookings': totalBookings,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get experienceText => '$experienceYears years of experience';
  String get ratingText => '${rating.toStringAsFixed(1)} ★';
  String get bookingsText => '$totalBookings bookings';

  // Language-aware getters
  String getName(bool isHindi) =>
      isHindi && nameHi != null && nameHi!.isNotEmpty ? nameHi! : name;
  String getLocation(bool isHindi) =>
      isHindi && locationHi != null && locationHi!.isNotEmpty
      ? locationHi!
      : location;
  String? getBio(bool isHindi) =>
      isHindi && bioHi != null && bioHi!.isNotEmpty ? bioHi : bio;
  String? getProfileImage(bool isHindi) {
    // Photo URL is synced, so use either one
    return profileImageHi ?? profileImage;
  }

  List<String> getSpecializations(bool isHindi) {
    if (isHindi && specializationsHi.isNotEmpty) {
      return specializationsHi;
    }
    return specializations;
  }

  // Language-aware display methods
  String getExperienceText(bool isHindi) {
    if (isHindi) {
      return '$experienceYears वर्ष का अनुभव';
    }
    return '$experienceYears years of experience';
  }
}
