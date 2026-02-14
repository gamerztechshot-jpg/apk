// features/audio_ebook/audio_ebook_payment.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/models/audio_ebook_model.dart';
import '../../core/services/audio_ebook_purchase_service.dart';
import '../../core/config/razorpay_keys.dart';

class AudioEbookPaymentService {
  late Razorpay _razorpay;
  final AudioEbookPurchaseService _purchaseService =
      AudioEbookPurchaseService();

  // Payment result callbacks
  Function(dynamic)? onPaymentSuccess;
  Function(dynamic)? onPaymentError;
  Function(dynamic)? onExternalWallet;

  AudioEbookPaymentService() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    try {
      _razorpay = Razorpay();
      _setupEventHandlers();
    } catch (e) {
      // Try to reinitialize after a delay
      Future.delayed(const Duration(seconds: 1), () {
        try {
          _razorpay = Razorpay();
          _setupEventHandlers();
        } catch (retryError) {}
      });
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
    // Handle specific error cases
    if (response.code == 'NETWORK_ERROR') {
    } else if (response.code == 'INVALID_OPTIONS') {
    } else if (response.message?.toString().contains('Canvas2D') == true) {
      // Could implement retry logic here
    }

    if (onPaymentError != null) {
      onPaymentError!(response);
    }
  }

  void _handleExternalWallet(dynamic response) {
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  // Create payment options for audio/ebook purchase
  Map<String, dynamic> _createPaymentOptions({
    required String orderId,
    required double amount,
    required String itemTitle,
    required String itemType,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) {
    return {
      'key': api_key, // Use actual Razorpay key from config
      'amount': (amount * 100).toInt(), // Convert to paise
      'name': 'Karmasu',
      'description': 'Purchase: $itemTitle ($itemType)',
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

  // Start payment process for audio/ebook
  Future<void> startPayment({
    required String orderId,
    required double amount,
    required String itemTitle,
    required String itemType,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      // Validate Razorpay key
      if (api_key.isEmpty || api_key == 'YOUR_RAZORPAY_KEY_ID') {
        throw Exception('Razorpay API key not configured properly');
      }

      final options = _createPaymentOptions(
        orderId: orderId,
        amount: amount,
        itemTitle: itemTitle,
        itemType: itemType,
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

  // Create order for audio/ebook purchase
  Future<Map<String, dynamic>> createOrder({
    required AudioEbookModel item,
    required String userId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      // === Create Razorpay order via API (same approach as Puja booking) ===
      final int amountPaise = ((item.amount ?? 0) * 100).toInt();

      final orderPayload = {
        'amount': amountPaise, // paise
        'currency': 'INR',
        'receipt': 'ae_${item.id}_${DateTime.now().millisecondsSinceEpoch}',
        'notes': {
          'user_id': userId,
          'user_name': customerName,
          'user_email': customerEmail,
          'user_phone': customerPhone,
          'item_id': item.id.toString(),
          'item_type': item.type,
          'item_title': item.title,
        },
      };

      // Basic auth header
      final credentials = '$api_key:$api_secret';
      final base64Str = base64.encode(utf8.encode(credentials));

      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $base64Str',
        },
        body: json.encode(orderPayload),
      );

      if (response.statusCode != 200) {
        final body = json.decode(response.body);
        throw Exception(
          'Failed to create Razorpay order: ${body['error']?['description'] ?? 'Unknown error'}',
        );
      }

      final rpOrder = json.decode(response.body) as Map<String, dynamic>;

      // Return a normalized order map similar to Puja flow
      return {
        'id': rpOrder['id'],
        'amount': rpOrder['amount'],
        'currency': rpOrder['currency'],
        'receipt': rpOrder['receipt'],
        'status': rpOrder['status'],
        'created_at': rpOrder['created_at'],
        'item_id': item.id,
        'item_type': item.type,
        'item_title': item.title,
        'user_id': userId,
        'razorpay_order': rpOrder,
      };
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Save payment record after successful payment using new purchase service
  Future<bool> savePaymentRecord({
    required String paymentId,
    required String orderId,
    required String signature,
    required String userId,
    required int itemId,
    required String itemType,
    required double amount,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      // Prepare payment info JSON
      final paymentInfo = {
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
        'amount': amount,
        'currency': 'INR',
        'customer_email': customerEmail,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'payment_method': 'razorpay',
        'purchase_date': DateTime.now().toIso8601String(),
      };

      // Use the new purchase service to save the record
      final success = await _purchaseService.savePurchaseRecord(
        userId: userId,
        itemId: itemId,
        itemType: itemType.toLowerCase(), // Convert to lowercase
        paymentInfo: paymentInfo,
        status: 'success',
      );

      if (success) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Verify payment signature
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    // This should call your backend API to verify the payment
    // For now, returning true for demo purposes

    return true;
  }

  // Check if user has already purchased this item using new purchase service
  Future<bool> isItemPurchased({
    required String userId,
    required int itemId,
    required String itemType,
  }) async {
    try {
      // Use the new purchase service to check access
      final hasAccess = await _purchaseService.hasItemAccess(
        userId: userId,
        itemId: itemId,
        itemType: itemType.toLowerCase(), // Convert to lowercase
      );

      return hasAccess;
    } catch (e) {
      return false;
    }
  }

  // Get user's purchased items using new purchase service
  Future<List<Map<String, dynamic>>> getUserPurchases(String userId) async {
    try {
      // Use the new purchase service to get all purchased items
      final purchases = await _purchaseService.getUserPurchasedItems(userId);

      return purchases;
    } catch (e) {
      return [];
    }
  }

  // Method to handle WebView issues and provide fallback
  Future<void> handleWebViewIssues() async {
    // Clear any existing Razorpay instance
    try {
      _razorpay.clear();
    } catch (e) {}

    // Wait a moment
    await Future.delayed(const Duration(milliseconds: 1000));

    // Reinitialize Razorpay
    _initializeRazorpay();
  }

  // Method to check if Razorpay is properly initialized
  bool isRazorpayInitialized() {
    try {
      // Try to access a property to check if initialized
      _razorpay.toString();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    try {
      _razorpay.clear();
    } catch (e) {}
  }
}

// Audio/Ebook Payment Screen Widget
class AudioEbookPaymentScreen extends StatefulWidget {
  final AudioEbookModel item;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  const AudioEbookPaymentScreen({
    super.key,
    required this.item,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  @override
  State<AudioEbookPaymentScreen> createState() =>
      _AudioEbookPaymentScreenState();
}

class _AudioEbookPaymentScreenState extends State<AudioEbookPaymentScreen> {
  late AudioEbookPaymentService _paymentService;
  bool _isLoading = false;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _paymentService = AudioEbookPaymentService();
    _setupPaymentCallbacks();
  }

  void _setupPaymentCallbacks() {
    _paymentService.onPaymentSuccess = (response) {
      _handlePaymentSuccess(response);
    };

    _paymentService.onPaymentError = (response) {
      _handlePaymentError(response);
    };

    _paymentService.onExternalWallet = (response) {
      _handleExternalWallet(response);
    };
  }

  Future<void> _handlePaymentSuccess(dynamic response) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verify payment
      final isVerified = await _paymentService.verifyPayment(
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        signature: response.signature!,
      );

      if (isVerified) {
        // Save payment record
        final success = await _paymentService.savePaymentRecord(
          paymentId: response.paymentId!,
          orderId: response.orderId!,
          signature: response.signature!,
          userId: widget.userId,
          itemId: widget.item.id,
          itemType: widget.item.type,
          amount: widget.item.amount!.toDouble(),
          customerEmail: widget.customerEmail,
          customerName: widget.customerName,
          customerPhone: widget.customerPhone,
        );

        if (success) {
          if (mounted) {
            _showPaymentSuccessDialog();
          }
        } else {
          throw Exception('Failed to save payment record');
        }
      } else {
        throw Exception('Payment verification failed');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Payment verification failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePaymentError(dynamic response) {
    setState(() {
      _isLoading = false;
    });
    _showErrorDialog('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(dynamic response) {
    setState(() {
      _isLoading = false;
    });
    _showSuccessDialog('Redirected to ${response.walletName}');
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add timeout to prevent getting stuck
      await Future.delayed(const Duration(seconds: 2));

      // Check if Razorpay is properly initialized
      if (!_paymentService.isRazorpayInitialized()) {
        await _paymentService.handleWebViewIssues();

        // Wait a bit more for initialization
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      // Create order with timeout
      final order = await _paymentService
          .createOrder(
            item: widget.item,
            userId: widget.userId,
            customerName: widget.customerName,
            customerEmail: widget.customerEmail,
            customerPhone: widget.customerPhone,
          )
          .timeout(const Duration(seconds: 10));

      _orderId = order['id'];

      // Start payment with timeout
      await _paymentService
          .startPayment(
            orderId: _orderId!,
            amount: widget.item.amount!.toDouble(),
            itemTitle: widget.item.title,
            itemType: widget.item.type,
            customerName: widget.customerName,
            customerEmail: widget.customerEmail,
            customerPhone: widget.customerPhone,
          )
          .timeout(const Duration(seconds: 15));

      // Set a timeout to stop loading if payment doesn't complete
      Timer(const Duration(seconds: 30), () {
        if (_isLoading && mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog('Payment timeout. Please try again.');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Provide more specific error messages
      String errorMessage = 'Payment initialization failed';
      if (e.toString().contains('TimeoutException')) {
        errorMessage =
            'Payment request timed out. Please check your internet connection and try again.';
      } else if (e.toString().contains('Canvas2D')) {
        errorMessage =
            'WebView rendering issue. Please try again or restart the app.';
      } else if (e.toString().contains('NETWORK')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('API key')) {
        errorMessage = 'Payment configuration error. Please contact support.';
      } else {
        errorMessage = 'Payment initialization failed: $e';
      }

      _showErrorDialog(errorMessage);
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Payment Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your purchase has been confirmed.'),
              SizedBox(height: 12),
              Text('Item: ${widget.item.title}'),
              Text('Type: ${widget.item.type}'),
              Text('Amount: ₹${widget.item.amount}'),
              SizedBox(height: 12),
              Text('You can now access this content.'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to detail screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Purchase ${widget.item.type}'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade50, Colors.white],
            ),
          ),
          child: _isLoading ? _buildLoadingWidget() : _buildPaymentContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Processing Payment...',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 32),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = false;
              });
              Navigator.pop(context);
            },
            child: Text(
              'Cancel Payment',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Details Card
          _buildItemDetailsCard(),

          SizedBox(height: 24),

          // Payment Summary Card
          _buildPaymentSummaryCard(),

          SizedBox(height: 32),

          // Pay Now Button
          _buildPayNowButton(),

          SizedBox(height: 16),

          // Security Notice
          _buildSecurityNotice(),
        ],
      ),
    );
  }

  Widget _buildItemDetailsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.item.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.item.description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.item.type == 'Audio'
                      ? Colors.blue.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.item.type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.item.type == 'Audio'
                        ? Colors.blue.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Category: ${widget.item.category}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.item.title}:',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              Text(
                '₹${widget.item.amount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Taxes & Fees:',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              Text(
                '₹0',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          Divider(color: Colors.orange.shade300),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '₹${widget.item.amount}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 24),
            SizedBox(width: 12),
            Text(
              'Pay ₹${widget.item.amount}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.green.shade600, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment is secured by Razorpay with 256-bit SSL encryption.',
              style: TextStyle(fontSize: 14, color: Colors.green.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
