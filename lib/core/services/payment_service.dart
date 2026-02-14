// core/services/payment_service.dart
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/razorpay_keys.dart';

class PaymentService {
  late Razorpay _razorpay;
  final SupabaseClient _supabase = Supabase.instance.client;

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

  // Create payment options for puja booking
  Map<String, dynamic> _createPaymentOptions({
    required String orderId,
    required int amount,
    required String pujaName,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) {
    return {
      'key': api_key,
      'amount': amount * 100, // Convert to paise
      'name': 'Karmasu',
      'description': 'Payment for $pujaName',
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

  // Start payment process
  Future<void> startPayment({
    required String orderId,
    required int amount,
    required String pujaName,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final options = _createPaymentOptions(
        orderId: orderId,
        amount: amount,
        pujaName: pujaName,
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

  // Create order directly with Razorpay API
  Future<Map<String, dynamic>> createRazorpayOrder({
    required int amount,
    required String currency,
    required String receipt,
    Map<String, dynamic>? notes,
  }) async {
    try {
      // Prepare order data
      final orderData = {
        'amount': amount, // Already in paise
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final orderResponse = json.decode(response.body);
        return orderResponse;
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['description'] ??
            (errorBody['error'] != null
                ? errorBody['error']['description']
                : null) ??
            'Unknown Razorpay error';
        throw Exception(
          'Razorpay Error: $errorMessage (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Order Creation Failed: $e');
    }
  }

  // Create order on server with proper user and puja data
  Future<Map<String, dynamic>> createOrder({
    required int amount,
    required String currency,
    required String receipt,
    required String userId,
    required String userDisplayName,
    required String userEmail,
    required String userPhone,
    required int pujaId,
    required String pujaName,
  }) async {
    try {
      // First create order with Razorpay API
      final razorpayOrder = await createRazorpayOrder(
        amount: amount * 100, // Convert to paise
        currency: currency,
        receipt: receipt,
        notes: {
          'user_id': userId,
          'user_name': userDisplayName,
          'user_email': userEmail,
          'user_phone': userPhone,
          'puja_id': pujaId.toString(),
          'puja_name': pujaName,
        },
      );

      // Insert order into database (you might want to create an 'orders' table)
      // For now, we'll return the order data

      return {
        'id': razorpayOrder['id'],
        'amount': razorpayOrder['amount'],
        'currency': razorpayOrder['currency'],
        'receipt': razorpayOrder['receipt'],
        'status': razorpayOrder['status'],
        'created_at': razorpayOrder['created_at'],
        'user_id': userId,
        'puja_id': pujaId,
        'razorpay_order': razorpayOrder,
      };
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Test function to verify data integrity
  Future<void> testDataIntegrity({
    required String userId,
    required int pujaId,
    required int packageId,
    required int amount,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
  }) async {
    // Test if any values are empty or invalid
    if (userId.isEmpty) throw Exception('userId is empty!');
    if (pujaId <= 0) throw Exception('pujaId is invalid: $pujaId');
    if (packageId <= 0) throw Exception('packageId is invalid: $packageId');
    if (amount <= 0) throw Exception('amount is invalid: $amount');
    if (customerEmail.isEmpty) throw Exception('customerEmail is empty!');
    if (customerName.isEmpty) throw Exception('customerName is empty!');
    if (customerPhone.isEmpty) throw Exception('customerPhone is empty!');
  }

  // Save payment to puja_payment table after successful payment
  Future<bool> savePaymentRecord({
    required String paymentId,
    required String orderId,
    required String userId,
    required int pujaId,
    required int packageId,
    required int amount,
    required Map<String, dynamic> customerInfo,
    String? panditId,
    String paymentStatus = 'success',
  }) async {
    try {
      final pujaInfo = {
        'puja_id': pujaId,
        'package_id': packageId,
        'pandit_id': panditId,
      };

      final paymentInfo = {
        'razorpay_payment_id': paymentId,
        'order_id': orderId,
        'amount': amount,
        'payment_status': paymentStatus,
        'puja_completed': null,
        'created_at': DateTime.now().toIso8601String(),
      };

      final record = {
        'user_id': userId,
        'puja_info': pujaInfo,
        'payment_info': paymentInfo,
        'customer_info': customerInfo,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Validate that critical fields are not null or empty before saving
      if (record['user_id'] == null || record['user_id'].toString().isEmpty) {
        throw Exception(
          'CRITICAL ERROR: user_id is null or empty! Cannot save payment without user_id',
        );
      }
      if ((record['puja_info'] as Map)['puja_id'] == null ||
          ((record['puja_info'] as Map)['puja_id'] as int) <= 0) {
        throw Exception(
          'CRITICAL ERROR: puja_id is null or invalid! Cannot save payment without puja_id',
        );
      }
      if ((record['payment_info'] as Map)['amount'] == null ||
          (((record['payment_info'] as Map)['amount']) as int) <= 0) {
        throw Exception(
          'CRITICAL ERROR: amount is null or invalid! Cannot save payment without amount',
        );
      }

      await _supabase.from('puja_payment').insert(record).select();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify payment signature (should be done on backend)
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    return true;
  }

  // Get user profile data from profiles table
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

  // Create order for kundli purchase
  Future<Map<String, dynamic>> createKundliOrder({
    required int amount,
    required String currency,
    required String receipt,
    required String userId,
    required String userDisplayName,
    required String userEmail,
    required String userPhone,
    required String kundliId,
    required String kundliName,
  }) async {
    try {
      // First create order with Razorpay API
      final razorpayOrder = await createRazorpayOrder(
        amount: amount * 100, // Convert to paise
        currency: currency,
        receipt: receipt,
        notes: {
          'user_id': userId,
          'user_name': userDisplayName,
          'user_email': userEmail,
          'user_phone': userPhone,
          'kundli_id': kundliId,
          'kundli_name': kundliName,
        },
      );

      // Order data will be stored in kundli_payment table's payment_info JSON field

      return {
        'id': razorpayOrder['id'],
        'amount': razorpayOrder['amount'],
        'currency': razorpayOrder['currency'],
        'receipt': razorpayOrder['receipt'],
        'status': razorpayOrder['status'],
        'created_at': razorpayOrder['created_at'],
        'user_id': userId,
        'kundli_id': kundliId,
        'razorpay_order': razorpayOrder,
      };
    } catch (e) {
      throw Exception('Failed to create kundli order: $e');
    }
  }

  // Create payment options for kundli purchase
  Map<String, dynamic> _createKundliPaymentOptions({
    required String orderId,
    required int amount,
    required String kundliName,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) {
    return {
      'key': api_key,
      'amount': amount * 100, // Convert to paise
      'name': 'Karmasu',
      'description': 'Payment for $kundliName',
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

  // Start kundli payment process
  Future<void> startKundliPayment({
    required String orderId,
    required int amount,
    required String kundliName,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final options = _createKundliPaymentOptions(
        orderId: orderId,
        amount: amount,
        kundliName: kundliName,
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

  // Save kundli payment to database after successful payment
  Future<bool> saveKundliPaymentRecord({
    required String paymentId,
    required String orderId,
    required String userId,
    required String kundliId,
    required double amount,
    required Map<String, dynamic> customerInfo,
    String paymentStatus = 'success',
  }) async {
    try {
      final kundliInfo = {'kundli_id': kundliId};

      final paymentInfo = {
        'razorpay_payment_id': paymentId,
        'order_id': orderId,
        'amount': (amount * 100).toInt(), // Convert to paise
        'payment_status': paymentStatus,
        'currency': 'INR',
        'receipt':
            'kundli_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'created_at': DateTime.now().toIso8601String(),
      };

      final record = {
        'user_id': userId,
        'kundli_info': kundliInfo,
        'payment_info': paymentInfo,
        'customer_info': customerInfo,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Validate that critical fields are not null or empty before saving
      if (record['user_id'] == null || record['user_id'].toString().isEmpty) {
        throw Exception(
          'CRITICAL ERROR: user_id is null or empty! Cannot save payment without user_id',
        );
      }
      if ((record['kundli_info'] as Map)['kundli_id'] == null ||
          ((record['kundli_info'] as Map)['kundli_id'] as String).isEmpty) {
        throw Exception(
          'CRITICAL ERROR: kundli_id is null or invalid! Cannot save payment without kundli_id',
        );
      }
      if ((record['payment_info'] as Map)['amount'] == null ||
          (((record['payment_info'] as Map)['amount']) as int) <= 0) {
        throw Exception(
          'CRITICAL ERROR: amount is null or invalid! Cannot save payment without amount',
        );
      }

      await _supabase.from('kundli_payment').insert(record).select();

      return true;
    } catch (e) {
      return false;
    }
  }

  // ================== COURSE PAYMENT ==================

  Future<Map<String, dynamic>> createCourseOrder({
    required int amount,
    required String currency,
    required String receipt,
    required String userId,
    required String userDisplayName,
    required String userEmail,
    required String userPhone,
    required String courseId,
    required String courseTitle,
  }) async {
    try {
      final razorpayOrder = await createRazorpayOrder(
        amount: amount * 100,
        currency: currency,
        receipt: receipt,
        notes: {
          'user_id': userId,
          'user_name': userDisplayName,
          'user_email': userEmail,
          'user_phone': userPhone,
          'course_id': courseId,
          'course_title': courseTitle,
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
        'course_id': courseId,
        'razorpay_order': razorpayOrder,
      };
    } catch (e) {
      throw Exception('Failed to create course order: $e');
    }
  }

  Future<void> startCoursePayment({
    required String orderId,
    required int amount,
    required String courseTitle,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final options = {
        'key': api_key,
        'amount': amount * 100,
        'name': 'Karmasu',
        'description': 'Payment for $courseTitle',
        'order_id': orderId,
        'currency': 'INR',
        'prefill': {
          'contact': customerPhone,
          'email': customerEmail,
          'name': customerName,
        },
        'theme': {'color': '#FF6B35'},
      };

      _razorpay.open(options);
    } catch (e) {
      onPaymentError?.call({
        'code': 0,
        'message': 'Failed to start course payment: $e',
      });
    }
  }

  // ================== WEBINAR PAYMENT ==================

  Future<Map<String, dynamic>> createWebinarOrder({
    required int amount,
    required String currency,
    required String receipt,
    required String userId,
    required String userDisplayName,
    required String userEmail,
    required String userPhone,
    required String webinarId,
    required String webinarTitle,
  }) async {
    try {
      final razorpayOrder = await createRazorpayOrder(
        amount: amount * 100,
        currency: currency,
        receipt: receipt,
        notes: {
          'user_id': userId,
          'user_name': userDisplayName,
          'user_email': userEmail,
          'user_phone': userPhone,
          'webinar_id': webinarId,
          'webinar_title': webinarTitle,
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
        'webinar_id': webinarId,
        'razorpay_order': razorpayOrder,
      };
    } catch (e) {
      throw Exception('Failed to create webinar order: $e');
    }
  }

  Future<void> startWebinarPayment({
    required String orderId,
    required int amount,
    required String webinarTitle,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final options = {
        'key': api_key,
        'amount': amount * 100,
        'name': 'Karmasu',
        'description': 'Payment for $webinarTitle',
        'order_id': orderId,
        'currency': 'INR',
        'prefill': {
          'contact': customerPhone,
          'email': customerEmail,
          'name': customerName,
        },
        'theme': {'color': '#FF6B35'},
      };

      _razorpay.open(options);
    } catch (e) {
      onPaymentError?.call({
        'code': 0,
        'message': 'Failed to start webinar payment: $e',
      });
    }
  }

  // Dispose resources
  void dispose() {
    _razorpay.clear();
  }
}
