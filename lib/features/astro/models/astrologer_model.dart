// features/astro/models/astrologer_model.dart
class AstrologerModel {
  final String id;
  final String name;
  final String? nameHi;
  final String email;
  final String phoneNumber;
  final String qualification;
  final String? qualificationHi;
  final int experience;
  final String aboutYou;
  final String? aboutYouHi;
  final String address;
  final String? addressHi;
  final String? photoUrl;
  final double perMinuteCharge;
  final double perMonthCharge;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? priority;
  final double? rating;

  AstrologerModel({
    required this.id,
    required this.name,
    this.nameHi,
    required this.email,
    required this.phoneNumber,
    required this.qualification,
    this.qualificationHi,
    required this.experience,
    required this.aboutYou,
    this.aboutYouHi,
    required this.address,
    this.addressHi,
    this.photoUrl,
    required this.perMinuteCharge,
    required this.perMonthCharge,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.priority,
    this.rating,
  });

  factory AstrologerModel.fromJson(Map<String, dynamic> json) {
    // Helper to get value
    String getValue(String key) {
      return json[key]?.toString() ?? '';
    }

    String? getValueHi(String key) {
      final val = json['${key}_hi']?.toString() ?? json['${key}Hi']?.toString();
      final hiString = val?.trim();
      if (hiString == null || hiString.isEmpty) return null;
      return hiString;
    }

    // Get experience - handle both string and int
    int parseExperience(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
        final match = RegExp(r'\d+').firstMatch(value);
        if (match != null) return int.parse(match.group(0)!);
      }
      return 0;
    }

    final experienceValue = parseExperience(json['experience']);

    return AstrologerModel(
      id: json['id']?.toString() ?? '',
      name: getValue('name').isEmpty
          ? (json['name']?.toString() ?? '')
          : getValue('name'),
      nameHi: getValueHi('name'),
      email: getValue('email').isEmpty
          ? (json['email']?.toString() ?? '')
          : getValue('email'),
      phoneNumber: getValue('phone_number').isEmpty
          ? (json['phone']?.toString() ?? '')
          : getValue('phone_number'),
      qualification: getValue('qualification').isEmpty
          ? (json['qualification']?.toString() ?? '')
          : getValue('qualification'),
      qualificationHi: getValueHi('qualification'),
      experience: experienceValue,
      aboutYou: getValue('about_you').isEmpty
          ? (json['about_you']?.toString() ?? '')
          : getValue('about_you'),
      aboutYouHi: getValueHi('about_you'),
      address: getValue('address').isEmpty
          ? (json['address']?.toString() ?? '')
          : getValue('address'),
      addressHi: getValueHi('address'),
      photoUrl: json['photo_url']?.toString(),
      perMinuteCharge: (json['per_minute_charge'] as num?)?.toDouble() ?? 0.0,
      perMonthCharge: (json['per_month_charge'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      priority: json['priority'] != null
          ? (json['priority'] as num).toDouble()
          : null,
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
    );
  }

  // Factory method for data with calculated ratings (from views)
  factory AstrologerModel.fromJsonWithRating(Map<String, dynamic> json) {
    final model = AstrologerModel.fromJson(json);
    return AstrologerModel(
      id: model.id,
      name: model.name,
      nameHi: model.nameHi,
      email: model.email,
      phoneNumber: model.phoneNumber,
      qualification: model.qualification,
      qualificationHi: model.qualificationHi,
      experience: model.experience,
      aboutYou: model.aboutYou,
      aboutYouHi: model.aboutYouHi,
      address: model.address,
      addressHi: model.addressHi,
      photoUrl: model.photoUrl,
      perMinuteCharge: model.perMinuteCharge,
      perMonthCharge: model.perMonthCharge,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      priority: model.priority,
      rating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : model.rating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (nameHi != null) 'name_hi': nameHi,
      'email': email,
      'phone_number': phoneNumber,
      'qualification': qualification,
      if (qualificationHi != null) 'qualification_hi': qualificationHi,
      'experience': experience,
      'about_you': aboutYou,
      if (aboutYouHi != null) 'about_you_hi': aboutYouHi,
      'address': address,
      if (addressHi != null) 'address_hi': addressHi,
      'photo_url': photoUrl,
      'per_minute_charge': perMinuteCharge,
      'per_month_charge': perMonthCharge,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'priority': priority,
      'rating': rating,
    };
  }

  // Helper method to get display price
  String getDisplayPrice() {
    if (perMinuteCharge > 0) {
      return '₹${perMinuteCharge.toStringAsFixed(0)}/min';
    } else if (perMonthCharge > 0) {
      return '₹${perMonthCharge.toStringAsFixed(0)}/month';
    }
    return 'Contact for price';
  }

  // Helper method for backward compatibility
  @Deprecated('Use getExperienceDisplay(bool isHindi) instead')
  String getExperienceDisplayLegacy() => getExperienceDisplay(false);

  @Deprecated('Use getQualificationDisplay(bool isHindi) instead')
  String getQualificationDisplayLegacy() => getQualificationDisplay(false);

  // Helper method to get rating from database
  double getRating() => rating ?? 4.5;

  // Helper method to get formatted rating display
  String getRatingDisplay() => getRating().toStringAsFixed(1);

  // Helper method to get review count display
  String getReviewCountDisplay() => 'Reviews available';

  // Language-aware getters
  String getName(bool isHindi) =>
      isHindi && nameHi != null && nameHi!.isNotEmpty ? nameHi! : name;

  String getQualification(bool isHindi) =>
      isHindi && qualificationHi != null && qualificationHi!.isNotEmpty
      ? qualificationHi!
      : qualification;

  String getAboutYou(bool isHindi) =>
      isHindi && aboutYouHi != null && aboutYouHi!.isNotEmpty
      ? aboutYouHi!
      : aboutYou;

  String getAddress(bool isHindi) =>
      isHindi && addressHi != null && addressHi!.isNotEmpty
      ? addressHi!
      : address;

  String? getPhotoUrl(bool isHindi) => photoUrl;

  // Language-aware display methods
  String getQualificationDisplay(bool isHindi) {
    final qual = getQualification(isHindi);
    return isHindi ? '$qual में विशेषज्ञ' : 'Expert in $qual';
  }

  String getExperienceDisplay(bool isHindi) {
    if (experience < 12) {
      return isHindi
          ? '$experience महीने का अनुभव'
          : '$experience months experience';
    } else {
      final years = (experience / 12).floor();
      final months = experience % 12;
      if (months == 0) {
        return isHindi ? '$years वर्ष का अनुभव' : '$years years experience';
      } else {
        return isHindi
            ? '$years वर्ष $months महीने का अनुभव'
            : '$years years $months months experience';
      }
    }
  }
}
