// features/mantra_generator/repositories/payment_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create payment record
  Future<Map<String, dynamic>> createPaymentRecord({
    required String userId,
    required String packageId,
    required Map<String, dynamic> planDetails,
    required Map<String, dynamic> userInfo,
    required String paymentStatus,
    Map<String, dynamic>? paymentResponse,
  }) async {
    try {
      final response = await _supabase
          .from('user_payments')
          .insert({
            'user_id': userId,
            'package_id': packageId,
            'plan_details': planDetails,
            'user_info': userInfo,
            'payment_status': paymentStatus,
            'payment_response': paymentResponse ?? {},
          })
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to create payment record: $e');
    }
  }

  /// Get user's payment history
  Future<List<Map<String, dynamic>>> getUserPayments(String userId) async {
    try {
      final response = await _supabase
          .from('user_payments')
          .select('''
            *,
            chatbot_packages:package_id (
              id,
              package_name,
              package_type,
              ai_question_limit,
              content_access
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch user payments: $e');
    }
  }

  /// Get user's successful payments only
  Future<List<Map<String, dynamic>>> getUserSuccessfulPayments(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('user_payments')
          .select('''
            *,
            chatbot_packages:package_id (
              id,
              package_name,
              package_type,
              ai_question_limit,
              content_access
            )
          ''')
          .eq('user_id', userId)
          .eq('payment_status', 'success')
          .order('created_at', ascending: false);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch successful payments: $e');
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String paymentStatus,
    Map<String, dynamic>? paymentResponse,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'payment_status': paymentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (paymentResponse != null) {
        updateData['payment_response'] = paymentResponse;
      }

      await _supabase
          .from('user_payments')
          .update(updateData)
          .eq('id', paymentId);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Get payment by ID
  Future<Map<String, dynamic>?> getPaymentById(String paymentId) async {
    try {
      final response = await _supabase
          .from('user_payments')
          .select('''
            *,
            chatbot_packages:package_id (
              id,
              package_name,
              package_type,
              ai_question_limit,
              content_access
            )
          ''')
          .eq('id', paymentId)
          .maybeSingle();

      return response as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}
