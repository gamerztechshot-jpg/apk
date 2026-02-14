// lib/features/mantra_generator/models/chatbot_package_model.dart

class ChatbotPackage {
  final String id;
  final String packageName;
  final String packageType;
  final double amount;
  final double? discountAmount;
  final double? discountPercent;
  final double finalAmount;
  final String? description;
  final int aiQuestionLimit;
  final dynamic contentAccess;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatbotPackage({
    required this.id,
    required this.packageName,
    required this.packageType,
    required this.amount,
    this.discountAmount,
    this.discountPercent,
    required this.finalAmount,
    this.description,
    required this.aiQuestionLimit,
    this.contentAccess,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatbotPackage.fromJson(Map<String, dynamic> json) {
    return ChatbotPackage(
      id: json['id'] as String,
      packageName: json['package_name'] as String,
      packageType: json['package_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      discountAmount: json['discount_amount'] != null
          ? (json['discount_amount'] as num).toDouble()
          : null,
      discountPercent: json['discount_percent'] != null
          ? (json['discount_percent'] as num).toDouble()
          : null,
      finalAmount: (json['final_amount'] as num).toDouble(),
      description: json['description'] as String?,
      aiQuestionLimit: json['ai_question_limit'] as int,
      contentAccess: json['content_access'],
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
      'package_name': packageName,
      'package_type': packageType,
      'amount': amount,
      'discount_amount': discountAmount,
      'discount_percent': discountPercent,
      'final_amount': finalAmount,
      'description': description,
      'ai_question_limit': aiQuestionLimit,
      'content_access': contentAccess,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // --- Helper Methods to fix UI errors ---

  String getFormattedPrice() {
    return '₹${finalAmount.toStringAsFixed(0)}';
  }

  String? getDiscountDisplay() {
    if (discountPercent != null && discountPercent! > 0) {
      return '${discountPercent!.toStringAsFixed(0)}% OFF';
    }
    if (discountAmount != null && discountAmount! > 0) {
      return '₹${discountAmount!.toStringAsFixed(0)} OFF';
    }
    return null;
  }

  bool get hasUnlimitedAccess {
    if (contentAccess == null) return false;
    if (contentAccess is Map) {
      return contentAccess['unlimited'] == true;
    }
    if (contentAccess is List) {
      return contentAccess.contains('*') || contentAccess.contains('unlimited');
    }
    return false;
  }

  int get accessibleProblemsCount {
    if (hasUnlimitedAccess) return 0;
    if (contentAccess is List) {
      return contentAccess.length;
    }
    if (contentAccess is Map) {
      final List? ids = contentAccess['problem_ids'] as List?;
      return ids?.length ?? 0;
    }
    return 0;
  }

  bool hasAccessToProblem(String problemId) {
    if (hasUnlimitedAccess) return true;
    if (contentAccess is List) {
      return contentAccess.contains(problemId);
    }
    if (contentAccess is Map) {
      final List? ids = contentAccess['problem_ids'] as List?;
      return ids?.contains(problemId) ?? false;
    }
    return false;
  }
}
