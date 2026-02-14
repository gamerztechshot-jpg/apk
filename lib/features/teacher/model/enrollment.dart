class CourseEnrollment {
  final String id;
  final String orderId;
  final String courseId;
  final String courseTitle;
  final double amountPaid;
  final String paymentId;
  final String paymentStatus;
  final DateTime enrolledAt;

  CourseEnrollment({
    required this.id,
    required this.orderId,
    required this.courseId,
    required this.courseTitle,
    required this.amountPaid,
    required this.paymentId,
    required this.paymentStatus,
    required this.enrolledAt,
  });

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) {
    final paymentInfo = json['payment_info'] ?? {};
    final enrollmentInfo = json['enrollment_info'] ?? {};

    return CourseEnrollment(
      id: json['id'],
      orderId: paymentInfo['order_id'] ?? '',
      courseId: json['course_id'],
      courseTitle: enrollmentInfo['title'] ?? '',
      amountPaid: (paymentInfo['amount'] ?? 0).toDouble(),
      paymentId: paymentInfo['razorpay_payment_id'] ?? '',
      paymentStatus: paymentInfo['status'] ?? '',
      enrolledAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'enrollment_info': {'title': courseTitle},
      'payment_info': {
        'order_id': orderId,
        'razorpay_payment_id': paymentId,
        'amount': amountPaid,
        'status': paymentStatus,
      },
      'created_at': enrolledAt.toIso8601String(),
    };
  }
}

class WebinarEnrollment {
  final String id;
  final String userId;
  final String webinarId;
  final String webinarTitle;
  final double amountPaid;
  final String paymentId;
  final String paymentStatus;
  final DateTime enrolledAt;

  WebinarEnrollment({
    required this.id,
    required this.userId,
    required this.webinarId,
    required this.webinarTitle,
    required this.amountPaid,
    required this.paymentId,
    required this.paymentStatus,
    required this.enrolledAt,
  });

  factory WebinarEnrollment.fromJson(Map<String, dynamic> json) {
    final paymentInfo = json['payment_info'] ?? {};
    final enrollmentInfo = json['enrollment_info'] ?? {};

    return WebinarEnrollment(
      id: json['id'],
      userId: json['user_id'],
      webinarId: json['webinar_id'],
      webinarTitle: enrollmentInfo['title'] ?? '',
      amountPaid: (paymentInfo['amount'] ?? 0).toDouble(),
      paymentId: paymentInfo['razorpay_payment_id'] ?? '',
      paymentStatus: paymentInfo['status'] ?? '',
      enrolledAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'webinar_id': webinarId,
      'enrollment_info': {'title': webinarTitle},
      'payment_info': {
        'razorpay_payment_id': paymentId,
        'amount': amountPaid,
        'status': paymentStatus,
      },
      'created_at': enrolledAt.toIso8601String(),
    };
  }
}
