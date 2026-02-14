// core/models/leaderboard_certificate_model.dart
class LeaderboardCertificateModel {
  final String id;
  final String typeCode;
  final String typeNameEn;
  final String typeNameHi;
  final String certificateNameEn;
  final String certificateNameHi;
  final String calculationTime;
  final String validityPeriod;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LeaderboardCertificateModel({
    required this.id,
    required this.typeCode,
    required this.typeNameEn,
    required this.typeNameHi,
    required this.certificateNameEn,
    required this.certificateNameHi,
    required this.calculationTime,
    required this.validityPeriod,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory LeaderboardCertificateModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardCertificateModel(
      id: json['id'] as String,
      typeCode: json['type_code'] as String,
      typeNameEn: json['type_name_en'] as String,
      typeNameHi: json['type_name_hi'] as String,
      certificateNameEn: json['certificate_name_en'] as String,
      certificateNameHi: json['certificate_name_hi'] as String,
      calculationTime: json['calculation_time'] as String,
      validityPeriod: json['validity_period'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type_code': typeCode,
      'type_name_en': typeNameEn,
      'type_name_hi': typeNameHi,
      'certificate_name_en': certificateNameEn,
      'certificate_name_hi': certificateNameHi,
      'calculation_time': calculationTime,
      'validity_period': validityPeriod,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  LeaderboardCertificateModel copyWith({
    String? id,
    String? typeCode,
    String? typeNameEn,
    String? typeNameHi,
    String? certificateNameEn,
    String? certificateNameHi,
    String? calculationTime,
    String? validityPeriod,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaderboardCertificateModel(
      id: id ?? this.id,
      typeCode: typeCode ?? this.typeCode,
      typeNameEn: typeNameEn ?? this.typeNameEn,
      typeNameHi: typeNameHi ?? this.typeNameHi,
      certificateNameEn: certificateNameEn ?? this.certificateNameEn,
      certificateNameHi: certificateNameHi ?? this.certificateNameHi,
      calculationTime: calculationTime ?? this.calculationTime,
      validityPeriod: validityPeriod ?? this.validityPeriod,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get name based on language
  String getName({bool isHindi = false}) {
    return isHindi ? certificateNameHi : certificateNameEn;
  }

  // Helper method to get type name based on language
  String getTypeName({bool isHindi = false}) {
    return isHindi ? typeNameHi : typeNameEn;
  }

  // Helper method to get certificate color based on type
  String get colorHex {
    switch (typeCode) {
      case 'daily':
        return '#FF6B6B'; // Red
      case 'weekly':
        return '#4ECDC4'; // Teal
      case 'monthly':
        return '#45B7D1'; // Blue
      case 'yearly':
        return '#96CEB4'; // Green
      case 'alltime':
        return '#FFEAA7'; // Yellow
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Helper method to get certificate icon
  String get iconName {
    switch (typeCode) {
      case 'daily':
        return 'sunrise';
      case 'weekly':
        return 'calendar-week';
      case 'monthly':
        return 'calendar-month';
      case 'yearly':
        return 'calendar-year';
      case 'alltime':
        return 'crown';
      default:
        return 'trophy';
    }
  }

  // Helper method to get certificate level
  int get level {
    switch (typeCode) {
      case 'daily':
        return 1;
      case 'weekly':
        return 2;
      case 'monthly':
        return 3;
      case 'yearly':
        return 4;
      case 'alltime':
        return 5;
      default:
        return 0;
    }
  }
}

// Model for active leaderboard certificates (current holders)
class ActiveLeaderboardCertificate {
  final String id;
  final String certificateTypeId;
  final String userId;
  final String username;
  final DateTime periodStartDate;
  final DateTime? periodEndDate;
  final int japaCount;
  final int rankPosition;
  final DateTime awardedAt;
  final DateTime? expiresAt;
  final bool isCurrent;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? typeCode; // Add type code from database response

  ActiveLeaderboardCertificate({
    required this.id,
    required this.certificateTypeId,
    required this.userId,
    required this.username,
    required this.periodStartDate,
    this.periodEndDate,
    required this.japaCount,
    required this.rankPosition,
    required this.awardedAt,
    this.expiresAt,
    required this.isCurrent,
    this.createdAt,
    this.updatedAt,
    this.typeCode,
  });

  factory ActiveLeaderboardCertificate.fromJson(Map<String, dynamic> json) {
    return ActiveLeaderboardCertificate(
      id: json['certificate_id'] as String? ?? json['id'] as String? ?? '',
      certificateTypeId: json['certificate_type_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown User',
      periodStartDate: json['period_start_date'] != null
          ? DateTime.parse(json['period_start_date'] as String)
          : DateTime.now(),
      periodEndDate: json['period_end_date'] != null
          ? DateTime.parse(json['period_end_date'] as String)
          : null,
      japaCount: json['japa_count'] as int? ?? 0,
      rankPosition: json['rank_position'] as int? ?? 1,
      awardedAt: json['awarded_at'] != null
          ? DateTime.parse(json['awarded_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isCurrent: json['is_current'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      typeCode: json['type_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'certificate_type_id': certificateTypeId,
      'user_id': userId,
      'username': username,
      'period_start_date': periodStartDate.toIso8601String(),
      'period_end_date': periodEndDate?.toIso8601String(),
      'japa_count': japaCount,
      'rank_position': rankPosition,
      'awarded_at': awardedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_current': isCurrent,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'type_code': typeCode,
    };
  }

  // Helper method to format japa count with commas
  String get formattedJapaCount {
    return japaCount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Helper method to format period dates
  String get formattedPeriod {
    if (periodEndDate == null) {
      return 'All-Time';
    }
    
    final start = periodStartDate;
    final end = periodEndDate!;
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${start.day}/${start.month}/${start.year}';
    }
    
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  // Helper method to check if certificate is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Helper method to get time remaining until expiration
  Duration? get timeUntilExpiration {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }
}

// Model for leaderboard certificate history
class LeaderboardCertificateHistory {
  final String id;
  final String certificateTypeId;
  final String userId;
  final String username;
  final DateTime periodStartDate;
  final DateTime? periodEndDate;
  final int japaCount;
  final int rankPosition;
  final DateTime awardedAt;
  final bool isTransferred;
  final String? transferredToUserId;
  final String? transferredToUsername;
  final DateTime? transferredAt;
  final DateTime? createdAt;
  final String? typeCode; // Add type code from database response

  LeaderboardCertificateHistory({
    required this.id,
    required this.certificateTypeId,
    required this.userId,
    required this.username,
    required this.periodStartDate,
    this.periodEndDate,
    required this.japaCount,
    required this.rankPosition,
    required this.awardedAt,
    required this.isTransferred,
    this.transferredToUserId,
    this.transferredToUsername,
    this.transferredAt,
    this.createdAt,
    this.typeCode,
  });

  factory LeaderboardCertificateHistory.fromJson(Map<String, dynamic> json) {
    return LeaderboardCertificateHistory(
      id: json['certificate_id'] as String? ?? json['id'] as String? ?? '',
      certificateTypeId: json['certificate_type_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown User',
      periodStartDate: json['period_start_date'] != null
          ? DateTime.parse(json['period_start_date'] as String)
          : DateTime.now(),
      periodEndDate: json['period_end_date'] != null
          ? DateTime.parse(json['period_end_date'] as String)
          : null,
      japaCount: json['japa_count'] as int? ?? 0,
      rankPosition: json['rank_position'] as int? ?? 1,
      awardedAt: json['awarded_at'] != null
          ? DateTime.parse(json['awarded_at'] as String)
          : DateTime.now(),
      isTransferred: json['is_transferred'] as bool? ?? false,
      transferredToUserId: json['transferred_to_user_id'] as String?,
      transferredToUsername: json['transferred_to_username'] as String?,
      transferredAt: json['transferred_at'] != null
          ? DateTime.parse(json['transferred_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      typeCode: json['type_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'certificate_type_id': certificateTypeId,
      'user_id': userId,
      'username': username,
      'period_start_date': periodStartDate.toIso8601String(),
      'period_end_date': periodEndDate?.toIso8601String(),
      'japa_count': japaCount,
      'rank_position': rankPosition,
      'awarded_at': awardedAt.toIso8601String(),
      'is_transferred': isTransferred,
      'transferred_to_user_id': transferredToUserId,
      'transferred_to_username': transferredToUsername,
      'transferred_at': transferredAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'type_code': typeCode,
    };
  }

  // Helper method to format japa count with commas
  String get formattedJapaCount {
    return japaCount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Helper method to format period dates
  String get formattedPeriod {
    if (periodEndDate == null) {
      return 'All-Time';
    }
    
    final start = periodStartDate;
    final end = periodEndDate!;
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${start.day}/${start.month}/${start.year}';
    }
    
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }
}
