// lib/features/mantra_generator/models/chatbot_payment_model.dart

class ChatbotPayment {
  final String id;
  final String userId;
  final String packageId;
  final Map<String, dynamic>? planDetails;
  final Map<String, dynamic>? userInfo;
  final String paymentStatus;
  final Map<String, dynamic>? paymentResponse;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatbotPayment({
    required this.id,
    required this.userId,
    required this.packageId,
    this.planDetails,
    this.userInfo,
    required this.paymentStatus,
    this.paymentResponse,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatbotPayment.fromJson(Map<String, dynamic> json) {
    return ChatbotPayment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      packageId: json['package_id'] as String,
      planDetails: json['plan_details'] as Map<String, dynamic>?,
      userInfo: json['user_info'] as Map<String, dynamic>?,
      paymentStatus: json['payment_status'] as String,
      paymentResponse: json['payment_response'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'package_id': packageId,
      'plan_details': planDetails,
      'user_info': userInfo,
      'payment_status': paymentStatus,
      'payment_response': paymentResponse,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
