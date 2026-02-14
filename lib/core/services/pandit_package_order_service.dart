// core/services/pandit_package_order_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PanditPackageOrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createPendingOrder({
    required String userId,
    required String packageId,
    required int amount,
    required String razorpayOrderId,
  }) async {
    final record = {
      'user_id': userId,
      'package_id': packageId,
      'amount': amount,
      'currency': 'INR',
      'status': 'created',
      'razorpay_order_id': razorpayOrderId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final inserted = await _supabase
        .from('pandit_package_orders')
        .insert(record)
        .select()
        .single();
    return inserted;
  }

  Future<void> markOrderSuccess({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    await _supabase
        .from('pandit_package_orders')
        .update({
          'status': 'success',
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('razorpay_order_id', razorpayOrderId);
  }

  Future<void> markOrderFailed({
    required String razorpayOrderId,
    required String reason,
  }) async {
    await _supabase
        .from('pandit_package_orders')
        .update({
          'status': 'failed',
          'failure_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('razorpay_order_id', razorpayOrderId);
  }
}
