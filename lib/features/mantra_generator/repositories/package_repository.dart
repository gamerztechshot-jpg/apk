// lib/features/mantra_generator/repositories/package_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chatbot_package_model.dart';
import '../models/chatbot_payment_model.dart';

class PackageRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all active chatbot packages
  Future<List<ChatbotPackage>> getPackages() async {
    try {
      final response = await _supabase
          .from('chatbot_packages')
          .select()
          .eq('is_active', true)
          .order('final_amount', ascending: true);

      return (response as List)
          .map((json) => ChatbotPackage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch packages: $e');
    }
  }

  /// Fetch all active chatbot packages (Alias for getPackages)
  Future<List<ChatbotPackage>> getActivePackages() => getPackages();

  /// Fetch a single package by ID
  Future<ChatbotPackage?> getPackageById(String packageId) async {
    try {
      final response = await _supabase
          .from('chatbot_packages')
          .select()
          .eq('id', packageId)
          .maybeSingle();

      if (response == null) return null;
      return ChatbotPackage.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch package by ID: $e');
    }
  }

  /// Get user's most recent successful payment/package
  Future<ChatbotPayment?> getUserActivePackage(String userId) async {
    try {
      final response = await _supabase
          .from('user_payments')
          .select()
          .eq('user_id', userId)
          .eq('payment_status', 'success')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return ChatbotPayment.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get user's active package with full package details
  Future<Map<String, dynamic>?> getUserActivePackageWithDetails(
    String userId,
  ) async {
    try {
      final payment = await getUserActivePackage(userId);
      if (payment == null) return null;

      final package = await getPackageById(payment.packageId);
      if (package == null) return null;

      return {'payment': payment, 'package': package};
    } catch (e) {
      return null;
    }
  }

  /// Create a payment entry (pending status)
  Future<Map<String, dynamic>> createPaymentEntry({
    required String userId,
    required String packageId,
    required Map<String, dynamic> userInfo,
    required Map<String, dynamic> planDetails,
  }) async {
    try {
      final response = await _supabase
          .from('user_payments')
          .insert({
            'user_id': userId,
            'package_id': packageId,
            'user_info': userInfo,
            'plan_details': planDetails,
            'payment_status': 'pending',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create payment entry: $e');
    }
  }

  /// Update payment status after Razorpay response
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String paymentStatus,
    required Map<String, dynamic> paymentResponse,
  }) async {
    try {
      await _supabase
          .from('user_payments')
          .update({
            'payment_status': paymentStatus,
            'payment_response': paymentResponse,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }
}
