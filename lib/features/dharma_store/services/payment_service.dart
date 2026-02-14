// features/dharma_store/services/payment_service.dart
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../services/order_service.dart';
import '../../../core/config/razorpay_keys.dart';

class PaymentService {
  late Razorpay _razorpay;
  final SupabaseClient _supabase = Supabase.instance.client;
  final OrderService _orderService = OrderService();

  // Payment result callbacks
  Function(dynamic)? onPaymentSuccess;
  Function(dynamic)? onPaymentError;
  Function(dynamic)? onExternalWallet;

  PaymentService() {
    try {
      _razorpay = Razorpay();
      _setupEventHandlers();
    } catch (e) {
      rethrow;
    }
  }

  void _setupEventHandlers() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(dynamic response) {
    if (onPaymentSuccess != null) {
      onPaymentSuccess!(response);
    }
  }

  void _handlePaymentError(dynamic response) {
    if (onPaymentError != null) {
      onPaymentError!(response);
    }
  }

  void _handleExternalWallet(dynamic response) {
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  /// Create payment options for Dharma Store
  Map<String, dynamic> _createPaymentOptions({
    required String orderId,
    required int amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) {
    return {
      'key': api_key, // Use actual Razorpay key from config
      'amount': amount * 100, // Convert to paise
      'name': 'Dharma Store',
      'description': 'Payment for Dharma Store Order',
      'order_id': orderId,
      'currency': 'INR',
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
      },
      'theme': {
        'color': '#FF6B35', // Orange color matching app theme
      },
      'method': {
        'netbanking': true,
        'card': true,
        'wallet': true,
        'upi': true,
        'emi': true,
        'paylater': true,
      },
      'external': {
        'wallets': [
          'paytm',
          'mobikwik',
          'freecharge',
          'olamoney',
          'jio_money',
          'airtel_money',
        ],
      },
      'upi': {
        'apps': [
          'google_pay',
          'phonepe',
          'paytm',
          'bhim',
          'amazon_pay',
          'mobikwik',
        ],
      },
      'retry': {'enabled': true, 'max_count': 3},
      'timeout': 300, // 5 minutes
    };
  }

  /// Start payment process
  Future<void> startPayment({
    required String orderId,
    required int amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      // Validate required fields
      if (orderId.isEmpty) {
        throw Exception('Order ID cannot be empty');
      }
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }
      if (customerName.isEmpty) {
        throw Exception('Customer name cannot be empty');
      }

      final options = _createPaymentOptions(
        orderId: orderId,
        amount: amount,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
      );

      _razorpay.open(options);
    } catch (e) {
      if (onPaymentError != null) {
        onPaymentError!({'code': 0, 'message': 'Failed to start payment: $e'});
      }
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
      return await _orderService.createOrder(
        amount: amount,
        currency: currency,
        receipt: receipt,
        userId: userId,
        userDisplayName: userDisplayName,
        userEmail: userEmail,
        userPhone: userPhone,
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
      );
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Save order after successful payment
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
      return await _orderService.saveOrderRecord(
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
        userId: userId,
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        totalAmount: totalAmount,
        userDisplayName: userDisplayName,
        userEmail: userEmail,
        userPhone: userPhone,
      );
    } catch (e) {
      return false;
    }
  }

  /// Get user profile data from profiles table
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Verify payment signature (should be done on backend)
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    // This should call your backend API to verify the payment
    // For now, returning true for demo purposes
    // In production, make an HTTP request to your backend

    return true;
  }

  /// Dispose resources
  void dispose() {
    _razorpay.clear();
  }
}
