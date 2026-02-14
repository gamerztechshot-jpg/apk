class MantraModel {
  final String id;
  final String mantra;
  final String hindiMantra;
  final String meaning;
  final String hindiMeaning;
  final String benefits;
  final String hindiBenefits;
  final String? deityId;
  final String category;
  final DifficultyLevel difficultyLevel;
  final bool isFavorite;
  final bool isActive;
  final bool isCustom;
  final int displayOrder;

  MantraModel({
    required this.id,
    required this.mantra,
    required this.hindiMantra,
    required this.meaning,
    required this.hindiMeaning,
    required this.benefits,
    required this.hindiBenefits,
    this.deityId,
    required this.category,
    required this.difficultyLevel,
    this.isFavorite = false,
    this.isActive = true,
    this.isCustom = false,
    this.displayOrder = 0,
  });

  /// Create MantraModel from JSON (Supabase response)
  factory MantraModel.fromJson(Map<String, dynamic> json) {
    return MantraModel(
      id: json['id'] as String,
      mantra: json['mantra_en'] as String,
      hindiMantra: json['mantra_hi'] as String? ?? '',
      meaning: json['meaning_en'] as String? ?? '',
      hindiMeaning: json['meaning_hi'] as String? ?? '',
      benefits: json['benefits_en'] as String? ?? '',
      hindiBenefits: json['benefits_hi'] as String? ?? '',
      deityId: json['deity_id'] as String?,
      category: json['category'] as String? ?? 'General',
      difficultyLevel: _parseDifficultyLevel(json['difficulty_level'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      isCustom: json['is_custom'] as bool? ?? false,
      displayOrder: json['display_order'] as int? ?? 0,
      isFavorite: false, // Will be set by FavoritesService
    );
  }

  /// Parse difficulty level from string
  static DifficultyLevel _parseDifficultyLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'medium':
        return DifficultyLevel.medium;
      case 'difficult':
        return DifficultyLevel.difficult;
      default:
        return DifficultyLevel.easy;
    }
  }

  /// Convert MantraModel to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mantra_en': mantra,
      'mantra_hi': hindiMantra,
      'meaning_en': meaning,
      'meaning_hi': hindiMeaning,
      'benefits_en': benefits,
      'benefits_hi': hindiBenefits,
      'deity_id': deityId,
      'category': category,
      'difficulty_level': difficultyLevel.name,
      'is_active': isActive,
      'is_custom': isCustom,
      'display_order': displayOrder,
    };
  }

  MantraModel copyWith({
    String? id,
    String? mantra,
    String? hindiMantra,
    String? meaning,
    String? hindiMeaning,
    String? benefits,
    String? hindiBenefits,
    String? deityId,
    String? category,
    DifficultyLevel? difficultyLevel,
    bool? isFavorite,
    bool? isActive,
    bool? isCustom,
    int? displayOrder,
  }) {
    return MantraModel(
      id: id ?? this.id,
      mantra: mantra ?? this.mantra,
      hindiMantra: hindiMantra ?? this.hindiMantra,
      meaning: meaning ?? this.meaning,
      hindiMeaning: hindiMeaning ?? this.hindiMeaning,
      benefits: benefits ?? this.benefits,
      hindiBenefits: hindiBenefits ?? this.hindiBenefits,
      deityId: deityId ?? this.deityId,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
      isCustom: isCustom ?? this.isCustom,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  /// ⚠️ ALL HARDCODED DATA REMOVED
  /// 
  /// This static list is EMPTY and DEPRECATED.
  /// All mantras are now fetched from Supabase database.
  /// 
  /// Use MantraService.getAllMantras() instead.
  @Deprecated('Use MantraService.getAllMantras() instead')
  static List<MantraModel> allMantras = [];

  // ==========================================
  // DEPRECATED CATEGORY GETTERS
  // Use MantraService.getMantrasByCategory() instead
  // ==========================================

  @Deprecated('Use MantraService.getMantrasByCategory("Durga") instead')
  static List<MantraModel> get durgaMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Ganesha") instead')
  static List<MantraModel> get ganeshaMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Hanuman") instead')
  static List<MantraModel> get hanumanMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Krishna") instead')
  static List<MantraModel> get krishnaMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Lakshmi") instead')
  static List<MantraModel> get lakshmiMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Narasimha") instead')
  static List<MantraModel> get narasimhaMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Parvati") instead')
  static List<MantraModel> get parvatiMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Radha") instead')
  static List<MantraModel> get radhaMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Ram") instead')
  static List<MantraModel> get ramMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Saraswati") instead')
  static List<MantraModel> get saraswatiMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Shani") instead')
  static List<MantraModel> get shaniMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Shiv") instead')
  static List<MantraModel> get shivaMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Sita") instead')
  static List<MantraModel> get sitaMantras => [];
  
  @Deprecated('Use MantraService.getMantrasByCategory("Vishnu") instead')
  static List<MantraModel> get vishnuMantras => [];
}

enum DifficultyLevel {
  easy,
  medium,
  difficult,
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.difficult:
        return 'Difficult';
    }
  }

  String get hindiDisplayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'आसान';
      case DifficultyLevel.medium:
        return 'मध्यम';
      case DifficultyLevel.difficult:
        return 'कठिन';
    }
  }

  String get color {
    switch (this) {
      case DifficultyLevel.easy:
        return '#4CAF50'; // Green
      case DifficultyLevel.medium:
        return '#FF9800'; // Orange
      case DifficultyLevel.difficult:
        return '#F44336'; // Red
    }
  }
}

class MantraRating {
  final String mantraId;
  final String userId;
  final DifficultyLevel userRating;
  final DateTime timestamp;

  MantraRating({
    required this.mantraId,
    required this.userId,
    required this.userRating,
    required this.timestamp,
  });
}

class MantraStats {
  final String mantraId;
  final int easyCount;
  final int mediumCount;
  final int difficultCount;
  final DifficultyLevel majorityRating;

  MantraStats({
    required this.mantraId,
    required this.easyCount,
    required this.mediumCount,
    required this.difficultCount,
    required this.majorityRating,
  });

  int get totalRatings => easyCount + mediumCount + difficultCount;
}
