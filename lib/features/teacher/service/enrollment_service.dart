import 'package:supabase_flutter/supabase_flutter.dart';

class EnrollmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===============================
  // COURSE ENROLLMENT
  // ===============================

  /// Check if user is enrolled in a course
  Future<bool> isUserEnrolledInCourse(String userId, String courseId) async {
    try {
      final result = await _supabase
          .from('course_enrollments')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Get list of course IDs user is enrolled in
  Future<List<String>> getUserEnrolledCourseIds(String userId) async {
    try {
      final result = await _supabase
          .from('course_enrollments')
          .select('course_id')
          .eq('user_id', userId);

      return (result as List).map((e) => e['course_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save course enrollment after payment
  Future<void> saveCourseEnrollment({
    required String userId,
    required String courseId,
    required String paymentId,
    required String orderId,
    required int amount,
    required Map<String, dynamic> customerInfo,
  }) async {
    // Check if already enrolled (avoid duplicate payment enrollments)
    final existing = await _supabase
        .from('course_enrollments')
        .select('id')
        .eq('user_id', userId)
        .eq('course_id', courseId)
        .maybeSingle();

    if (existing != null) {
      // Already enrolled → do nothing
      return;
    }

    // Insert enrollment record
    await _supabase.from('course_enrollments').insert({
      'user_id': userId,
      'course_id': courseId,
      'enrollment_info': customerInfo['course_title'] != null
          ? {
              'title': customerInfo['course_title'],
              'price': amount,
              'teacher_id': customerInfo['teacher_id'],
            }
          : null,
      'payment_info': {
        'razorpay_payment_id': paymentId,
        'order_id': orderId,
        'amount': amount,
        'status': 'success',
      },
      'customer_info': {
        'name': customerInfo['name'],
        'email': customerInfo['email'],
        'phone': customerInfo['phone'],
      },
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ===============================
  // WEBINAR ENROLLMENT
  // ===============================

  /// Check if user is enrolled in a webinar
  Future<bool> isUserEnrolledInWebinar(String userId, String webinarId) async {
    try {
      final result = await _supabase
          .from('webinar_enrollments')
          .select('id')
          .eq('user_id', userId)
          .eq('webinar_id', webinarId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Get list of webinar IDs user is enrolled in
  Future<List<String>> getUserEnrolledWebinarIds(String userId) async {
    try {
      final result = await _supabase
          .from('webinar_enrollments')
          .select('webinar_id')
          .eq('user_id', userId);

      return (result as List).map((e) => e['webinar_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save webinar enrollment after payment
  Future<void> saveWebinarEnrollment({
    required String userId,
    required String webinarId,
    required String paymentId,
    required String orderId,
    required int amount,
    required Map<String, dynamic> customerInfo,
  }) async {
    // Check if already registered
    final existing = await _supabase
        .from('webinar_enrollments')
        .select('id')
        .eq('user_id', userId)
        .eq('webinar_id', webinarId)
        .maybeSingle();

    if (existing != null) {
      return;
    }

    // Insert webinar enrollment
    await _supabase.from('webinar_enrollments').insert({
      'user_id': userId,
      'webinar_id': webinarId,
      'enrollment_info': customerInfo['webinar_title'] != null
          ? {
              'title': customerInfo['webinar_title'],
              'price': amount,
              'teacher_id': customerInfo['teacher_id'],
            }
          : null,
      'payment_info': {
        'razorpay_payment_id': paymentId,
        'order_id': orderId,
        'amount': amount,
        'status': 'success',
      },
      'customer_info': {
        'name': customerInfo['name'],
        'email': customerInfo['email'],
        'phone': customerInfo['phone'],
      },
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
