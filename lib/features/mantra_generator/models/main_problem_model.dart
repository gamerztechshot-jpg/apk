// features/mantra_generator/models/main_problem_model.dart

class MainProblem {
  final String id;
  final String titleEn;
  final String titleHi;
  final String? descriptionEn;
  final String? descriptionHi;
  final String? mantraEn;
  final String? mantraHi;
  final bool isPaid;
  final int creditCost;
  final String? audioId;
  final String? ebookId;
  final String? mantraId;
  final String? dharmaStoreId;
  final String? pujaId;
  final String? astrologerId;
  final List<String> audioIds;
  final List<String> ebookIds;
  final List<String> dharmaStoreIds;
  final List<String> pujaIds;
  final List<String> astrologerIds;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MainProblem({
    required this.id,
    required this.titleEn,
    required this.titleHi,
    this.descriptionEn,
    this.descriptionHi,
    this.mantraEn,
    this.mantraHi,
    this.isPaid = false,
    this.creditCost = 0,
    this.audioId,
    this.ebookId,
    this.mantraId,
    this.dharmaStoreId,
    this.pujaId,
    this.astrologerId,
    this.audioIds = const [],
    this.ebookIds = const [],
    this.dharmaStoreIds = const [],
    this.pujaIds = const [],
    this.astrologerIds = const [],
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory MainProblem.fromJson(Map<String, dynamic> json) {
    return MainProblem(
      id: json['id'] as String,
      titleEn:
          json['problem_heading_en'] as String? ??
          json['title'] as String? ??
          '',
      titleHi: json['problem_heading_hi'] as String? ?? '',
      descriptionEn:
          json['description_en']?.toString() ?? json['description']?.toString(),
      descriptionHi: json['description_hi']?.toString(),
      mantraEn: json['mantra_en']?.toString(),
      mantraHi: json['mantra_hi']?.toString(),
      isPaid: json['is_paid'] as bool? ?? false,
      creditCost: (json['credit_cost'] as int?) ?? 0,
      audioId: json['audio_id']?.toString(),
      ebookId: json['ebook_id']?.toString(),
      mantraId: json['mantra_id']?.toString(),
      dharmaStoreId: json['dharma_store_id']?.toString(),
      pujaId: json['puja_id']?.toString(),
      astrologerId: json['astrologer_id']?.toString(),
      audioIds:
          (json['audio_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      ebookIds:
          (json['ebook_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      dharmaStoreIds:
          (json['dharma_store_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pujaIds:
          (json['puja_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      astrologerIds:
          (json['astrologer_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      displayOrder: (json['display_order'] as int?) ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'problem_heading_en': titleEn,
      'problem_heading_hi': titleHi,
      'description_en': descriptionEn,
      'description_hi': descriptionHi,
      'mantra_en': mantraEn,
      'mantra_hi': mantraHi,
      'is_paid': isPaid,
      'credit_cost': creditCost,
      'audio_id': audioId,
      'ebook_id': ebookId,
      'mantra_id': mantraId,
      'dharma_store_id': dharmaStoreId,
      'puja_id': pujaId,
      'astrologer_id': astrologerId,
      'audio_ids': audioIds,
      'ebook_ids': ebookIds,
      'dharma_store_ids': dharmaStoreIds,
      'puja_ids': pujaIds,
      'astrologer_ids': astrologerIds,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get count of linked content items
  int get linkedContentCount {
    int count = 0;

    // Helper to get unique IDs from both array and legacy field
    List<String> getContentIds(List<String> ids, String? legacyId) {
      final allIds = <String>{...ids};
      if (legacyId != null && legacyId.isNotEmpty) {
        allIds.add(legacyId);
      }
      return allIds.toList();
    }

    count += getContentIds(audioIds, audioId).length;
    count += getContentIds(ebookIds, ebookId).length;
    count += getContentIds(dharmaStoreIds, dharmaStoreId).length;
    count += getContentIds(pujaIds, pujaId).length;
    count += getContentIds(astrologerIds, astrologerId).length;

    if (mantraId != null && mantraId!.isNotEmpty) count++;
    if ((mantraEn?.isNotEmpty ?? false) || (mantraHi?.isNotEmpty ?? false)) {
      count++;
    }

    return count;
  }

  /// Get credit cost display text
  String getCreditCostDisplay() {
    if (creditCost <= 0) return 'Free';
    return '$creditCost credit${creditCost > 1 ? 's' : ''}';
  }

  /// Check if problem requires credits
  bool get requiresCredits => creditCost > 0;

  // Helper method to get localized title
  String getTitle(String languageCode) {
    if (languageCode == 'hi' && titleHi.isNotEmpty) return titleHi;
    return titleEn; // Fallback to English
  }

  // Helper method to get localized description
  String? getDescription(String languageCode) {
    if (languageCode == 'hi' && (descriptionHi?.isNotEmpty ?? false)) {
      return descriptionHi;
    }
    return descriptionEn; // Fallback to English
  }

  // Helper method to get localized mantra
  String? getMantra(String languageCode) {
    if (languageCode == 'hi' && (mantraHi?.isNotEmpty ?? false)) {
      return mantraHi;
    }
    return mantraEn; // Fallback to English
  }
}
