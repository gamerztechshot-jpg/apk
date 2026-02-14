// core/models/certificate_model.dart
class CertificateModel {
  final String id;
  final String userId;
  final String
  type; // 'japa_completion', 'daily_streak', 'event_based', 'points_threshold'
  final String title;
  final String description;
  final int japaCount;
  final int streakDays;
  final int points;
  final DateTime achievedAt;
  final String? eventName;
  final String? mantraName;
  final Map<String, dynamic> metadata;
  final String colorHex;
  final int level;
  final int requiredJapaCount;

  static final List<CertificateModel> allCertificates = [
    CertificateModel(
      id: '1',
      userId: '',
      type: 'japa_completion',
      title: '108 Japa Certificate',
      description: 'Complete 108 japa',
      japaCount: 108,
      streakDays: 0,
      points: 0,
      achievedAt: DateTime.now(),
      colorHex: '#FF6B35',
      level: 1,
      requiredJapaCount: 108,
    ),
    CertificateModel(
      id: '2',
      userId: '',
      type: 'japa_completion',
      title: '1008 Japa Certificate',
      description: 'Complete 1008 japa',
      japaCount: 1008,
      streakDays: 0,
      points: 0,
      achievedAt: DateTime.now(),
      colorHex: '#4ECDC4',
      level: 2,
      requiredJapaCount: 1008,
    ),
    CertificateModel(
      id: '3',
      userId: '',
      type: 'japa_completion',
      title: '11,000 Japa Certificate',
      description: 'Complete 11,000 japa',
      japaCount: 11000,
      streakDays: 0,
      points: 0,
      achievedAt: DateTime.now(),
      colorHex: '#45B7D1',
      level: 3,
      requiredJapaCount: 11000,
    ),
    CertificateModel(
      id: '4',
      userId: '',
      type: 'japa_completion',
      title: '1 Lakh Japa Certificate',
      description: 'Complete 1 Lakh japa',
      japaCount: 100000,
      streakDays: 0,
      points: 0,
      achievedAt: DateTime.now(),
      colorHex: '#96CEB4',
      level: 4,
      requiredJapaCount: 100000,
    ),
    CertificateModel(
      id: '5',
      userId: '',
      type: 'japa_completion',
      title: '10 Lakh Japa Certificate',
      description: 'Complete 10 Lakh japa',
      japaCount: 1000000,
      streakDays: 0,
      points: 0,
      achievedAt: DateTime.now(),
      colorHex: '#FFEAA7',
      level: 5,
      requiredJapaCount: 1000000,
    ),
    CertificateModel(
      id: '6',
      userId: '',
      type: 'japa_completion',
      title: '1 Crore Japa Certificate',
      description: 'Complete 1 Crore japa',
      japaCount: 10000000,
      streakDays: 0,
      points: 0,
      achievedAt: DateTime.now(),
      colorHex: '#DDA0DD',
      level: 6,
      requiredJapaCount: 10000000,
    ),
  ];

  CertificateModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.japaCount,
    required this.streakDays,
    required this.points,
    required this.achievedAt,
    this.eventName,
    this.mantraName,
    this.metadata = const {},
    this.colorHex = '#FF6B35',
    this.level = 1,
    int? requiredJapaCount,
  }) : requiredJapaCount = requiredJapaCount ?? japaCount;

  factory CertificateModel.fromMap(Map<String, dynamic> map) {
    return CertificateModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      japaCount: map['japa_count'] as int,
      streakDays: map['streak_days'] as int,
      points: map['points'] as int,
      achievedAt: DateTime.parse(map['achieved_at'] as String),
      eventName: map['event_name'] as String?,
      mantraName: map['mantra_name'] as String?,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      colorHex: map['color_hex'] as String? ?? '#FF6B35',
      level: map['level'] as int? ?? 1,
      requiredJapaCount: map['required_japa_count'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'description': description,
      'japa_count': japaCount,
      'streak_days': streakDays,
      'points': points,
      'achieved_at': achievedAt.toIso8601String(),
      'event_name': eventName,
      'mantra_name': mantraName,
      'metadata': metadata,
      'color_hex': colorHex,
      'level': level,
      'required_japa_count': requiredJapaCount,
    };
  }

  CertificateModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    int? japaCount,
    int? streakDays,
    int? points,
    DateTime? achievedAt,
    String? eventName,
    String? mantraName,
    Map<String, dynamic>? metadata,
    String? colorHex,
    int? level,
    int? requiredJapaCount,
  }) {
    return CertificateModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      japaCount: japaCount ?? this.japaCount,
      streakDays: streakDays ?? this.streakDays,
      points: points ?? this.points,
      achievedAt: achievedAt ?? this.achievedAt,
      eventName: eventName ?? this.eventName,
      mantraName: mantraName ?? this.mantraName,
      metadata: metadata ?? this.metadata,
      colorHex: colorHex ?? this.colorHex,
      level: level ?? this.level,
      requiredJapaCount: requiredJapaCount ?? this.requiredJapaCount,
    );
  }

  // Method to get certificate name based on language
  String getName({bool isHindi = false}) {
    if (isHindi) {
      switch (type) {
        case 'japa_completion':
          if (japaCount == 108) return '108 जप प्रमाणपत्र';
          if (japaCount == 1008) return '1008 जप प्रमाणपत्र';
          if (japaCount == 11000) return '11,000 जप प्रमाणपत्र';
          if (japaCount == 100000) return '1 लाख जप प्रमाणपत्र';
          if (japaCount == 1000000) return '10 लाख जप प्रमाणपत्र';
          if (japaCount == 10000000) return '1 करोड़ जप प्रमाणपत्र';
          return '$japaCount जप प्रमाणपत्र';
        case 'daily_streak':
          return '$streakDays दिन की लगातार साधना';
        default:
          return title;
      }
    } else {
      return title;
    }
  }

  // Method to get certificate description based on language
  String getDescription({bool isHindi = false}) {
    if (isHindi) {
      switch (type) {
        case 'japa_completion':
          return '$japaCount जप पूर्ण करने के लिए बधाई!';
        case 'daily_streak':
          return '$streakDays दिन लगातार साधना करने के लिए बधाई!';
        default:
          return description;
      }
    } else {
      return description;
    }
  }
}

enum CertificateType {
  japaCompletion,
  dailyStreak,
  eventBased,
  pointsThreshold,
}

enum JapaMilestone {
  hundredEight(108, '108 Japa'),
  thousandEight(1008, '1008 Japa'),
  elevenThousand(11000, '11,000 Japa'),
  oneLakh(100000, '1 Lakh Japa'),
  tenLakh(1000000, '10 Lakh Japa'),
  oneCrore(10000000, '1 Crore Japa');

  const JapaMilestone(this.count, this.displayName);
  final int count;
  final String displayName;
}

enum EventType {
  mahashivratri(
    'Mahashivratri Japa Completion',
    'Special certificate for Mahashivratri japa completion',
  ),
  janmashtami(
    'Janmashtami Japa Completion',
    'Special certificate for Janmashtami japa completion',
  ),
  diwali(
    'Diwali Japa Completion',
    'Special certificate for Diwali japa completion',
  ),
  navratri(
    'Navratri Japa Completion',
    'Special certificate for Navratri japa completion',
  ),
  guruPurnima(
    'Guru Purnima Japa Completion',
    'Special certificate for Guru Purnima japa completion',
  );

  const EventType(this.displayName, this.description);
  final String displayName;
  final String description;
}

enum StreakMilestone {
  sevenDays(7, '7 Days'),
  twentyOneDays(21, '21 Days'),
  fiftyDays(50, '50 Days'),
  hundredDays(100, '100 Days'),
  threeHundredDays(300, '300 Days'),
  oneYear(365, '1 Year');

  const StreakMilestone(this.days, this.displayName);
  final int days;
  final String displayName;
}
