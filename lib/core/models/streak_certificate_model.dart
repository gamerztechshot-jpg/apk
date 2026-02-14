// core/models/streak_certificate_model.dart
class StreakCertificateModel {
  final String id;
  final String name;
  final String nameHindi;
  final String description;
  final String descriptionHindi;
  final int requiredStreakDays;
  final String imagePath;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  StreakCertificateModel({
    required this.id,
    required this.name,
    required this.nameHindi,
    required this.description,
    required this.descriptionHindi,
    required this.requiredStreakDays,
    required this.imagePath,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory StreakCertificateModel.fromJson(Map<String, dynamic> json) {
    return StreakCertificateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameHindi: json['name_hindi'] as String,
      description: json['description'] as String,
      descriptionHindi: json['description_hindi'] as String,
      requiredStreakDays: json['required_streak_days'] as int,
      imagePath: json['image_path'] as String,
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_hindi': nameHindi,
      'description': description,
      'description_hindi': descriptionHindi,
      'required_streak_days': requiredStreakDays,
      'image_path': imagePath,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  StreakCertificateModel copyWith({
    String? id,
    String? name,
    String? nameHindi,
    String? description,
    String? descriptionHindi,
    int? requiredStreakDays,
    String? imagePath,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return StreakCertificateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameHindi: nameHindi ?? this.nameHindi,
      description: description ?? this.description,
      descriptionHindi: descriptionHindi ?? this.descriptionHindi,
      requiredStreakDays: requiredStreakDays ?? this.requiredStreakDays,
      imagePath: imagePath ?? this.imagePath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  // Static list of all available streak certificates
  static List<StreakCertificateModel> get allCertificates => [
        StreakCertificateModel(
          id: 'streak_7',
          name: 'Sapt-din Sadhak',
          nameHindi: 'सप्त-दिन साधक',
          description: 'Complete 7 days of continuous Japa practice',
          descriptionHindi: '7 दिनों तक लगातार जप अभ्यास पूरा करें',
          requiredStreakDays: 7,
          imagePath: 'assets/images/certificates/streak_7.png',
          isUnlocked: false,
        ),
        StreakCertificateModel(
          id: 'streak_21',
          name: 'Anushthan Sadhak',
          nameHindi: 'अनुष्ठान साधक',
          description: 'Achieve 21 days of continuous Japa practice',
          descriptionHindi: '21 दिनों तक लगातार जप अभ्यास हासिल करें',
          requiredStreakDays: 21,
          imagePath: 'assets/images/certificates/streak_21.png',
          isUnlocked: false,
        ),
        StreakCertificateModel(
          id: 'streak_108',
          name: 'Akhand Japa Sadhak',
          nameHindi: 'अखंड जप साधक',
          description: 'Reach the milestone of 108 days continuous Japa practice',
          descriptionHindi: '108 दिनों तक लगातार जप अभ्यास का मील का पत्थर प्राप्त करें',
          requiredStreakDays: 108,
          imagePath: 'assets/images/certificates/streak_108.png',
          isUnlocked: false,
        ),
      ];

  // Helper method to format streak days
  String get formattedStreakDays {
    return '$requiredStreakDays days';
  }

  // Helper method to get certificate level
  int get level {
    switch (requiredStreakDays) {
      case 7:
        return 1;
      case 21:
        return 2;
      case 108:
        return 3;
      default:
        return 0;
    }
  }

  // Helper method to get certificate color based on level
  String get colorHex {
    switch (level) {
      case 1:
        return '#4CAF50'; // Green
      case 2:
        return '#2196F3'; // Blue
      case 3:
        return '#9C27B0'; // Purple
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Helper method to get name based on language
  String getName({bool isHindi = false}) {
    return isHindi ? nameHindi : name;
  }

  // Helper method to get description based on language
  String getDescription({bool isHindi = false}) {
    return isHindi ? descriptionHindi : description;
  }
}
