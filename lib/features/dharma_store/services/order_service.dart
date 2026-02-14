// features/dharma_store/services/order_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../../../core/config/razorpay_keys.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create Razorpay order (similar to existing payment service)
  Future<Map<String, dynamic>> createRazorpayOrder({
    required int amount,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    try {
      // Prepare order data
      final orderData = {
        'amount': amount * 100, // Convert rupees to paise
        'currency': currency,
        'receipt': receipt,
      };

      // Add notes if provided
      if (notes != null) {
        orderData['notes'] = notes;
      }

      // Create Basic Auth header
      final credentials = '$api_key:$api_secret';
      final bytes = utf8.encode(credentials);
      final base64Str = base64.encode(bytes);

      // Make HTTP request to Razorpay API
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $base64Str',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 200) {
        final orderResponse = json.decode(response.body);

        return orderResponse;
      } else {
        final errorResponse = json.decode(response.body);

        // Handle specific error cases
        if (response.statusCode == 400) {
          throw Exception(
            'Bad Request: ${errorResponse['error']['description'] ?? 'Invalid request parameters'}',
          );
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Invalid Razorpay credentials');
        } else if (response.statusCode == 403) {
          throw Exception('Forbidden: Insufficient permissions');
        } else {
          throw Exception(
            'Failed to create order: ${errorResponse['error']['description'] ?? 'Unknown error (Status: ${response.statusCode})'}',
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Create order with Razorpay integration
  Future<Map<String, dynamic>> createOrder({
    required int amount,
    required String currency,
    required String receipt,
    required String userId,
    required String userDisplayName,
    required String userEmail,
    required String userPhone,
    required List<CartItem> cartItems,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    try {
      // First create order with Razorpay API
      final razorpayOrder = await createRazorpayOrder(
        amount:
            amount, // Amount is already in rupees, will be converted to paise in createRazorpayOrder
        currency: currency,
        receipt: receipt,
        notes: {
          'user_id': userId,
          'user_name': userDisplayName,
          'user_email': userEmail,
          'user_phone': userPhone,
          'store_type': 'dharma_store',
        },
      );

      return {
        'id': razorpayOrder['id'],
        'amount': razorpayOrder['amount'],
        'currency': razorpayOrder['currency'],
        'receipt': razorpayOrder['receipt'],
        'status': razorpayOrder['status'],
        'created_at': razorpayOrder['created_at'],
        'user_id': userId,
        'razorpay_order': razorpayOrder,
      };
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Save order to database after successful payment
  Future<bool> saveOrderRecord({
    required String paymentId,
    required String orderId,
    required String signature,
    required String userId,
    required List<CartItem> cartItems,
    required Map<String, dynamic> deliveryAddress,
    required double totalAmount,
    required String userDisplayName,
    required String userEmail,
    required String userPhone,
  }) async {
    try {
      // Generate order number
      final orderNumber = _generateOrderNumber();

      // Prepare items array
      final itemsArray = cartItems
          .map(
            (item) => {
              'item_id': item.itemId,
              'name_en': item.nameEn,
              'name_hi': item.nameHi,
              'price': item.price,
              'quantity': item.quantity,
              'image_url': item.imageUrl,
            },
          )
          .toList();

      // Prepare payment info
      final paymentInfo = {
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'payment_status': 'paid',
        'payment_method': 'razorpay',
        'signature': signature,
      };

      final orderData = {
        'user_id': userId,
        'order_number': orderNumber,
        'status': 'pending',
        'total_amount': totalAmount,
        'payment_info': paymentInfo,
        'address': deliveryAddress,
        'items': itemsArray,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Validate critical fields
      if (orderData['user_id'] == null ||
          orderData['user_id'].toString().isEmpty) {
        throw Exception('CRITICAL ERROR: user_id is null or empty!');
      }
      if (orderData['total_amount'] == null ||
          (orderData['total_amount'] as double) <= 0) {
        throw Exception('CRITICAL ERROR: total_amount is null or invalid!');
      }


      // Test Supabase connection first
      try {
        final testResult = await _supabase
            .from('orders')
            .select('count')
            .limit(1);
      } catch (e) {
        throw Exception('Database connection failed: $e');
      }

      final result = await _supabase.from('orders').insert(orderData).select();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get orders for current user
  Future<List<Order>> getUserOrders() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final orders = response.map((order) => Order.fromJson(order)).toList();

      return orders;
    } catch (e) {
      rethrow;
    }
  }

  /// Get order by ID
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

      final order = Order.fromJson(response);

      return order;
    } catch (e) {
      rethrow;
    }
  }

  /// Update order status (for admin use)
  Future<Order> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select()
          .single();

      final order = Order.fromJson(response);

      return order;
    } catch (e) {
      rethrow;
    }
  }

  /// Generate unique order number
  String _generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'DS$timestamp$random'; // DS = Dharma Store
  }
}
