// features/mantra_generator/views/screens/package_purchase_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:karmasu/core/services/language_service.dart';
import 'package:karmasu/core/services/auth_service.dart';
import 'package:karmasu/core/config/razorpay_keys.dart';
import '../../models/chatbot_package_model.dart';
import '../../viewmodels/package_viewmodel.dart';
import '../../services/credit_service.dart';

class PackagePurchaseScreen extends StatefulWidget {
  final ChatbotPackage package;

  const PackagePurchaseScreen({
    super.key,
    required this.package,
  });

  @override
  State<PackagePurchaseScreen> createState() => _PackagePurchaseScreenState();
}

class _PackagePurchaseScreenState extends State<PackagePurchaseScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  String? _orderId;
  String? _paymentId;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _setupPaymentCallbacks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
    if (user != null) {
      _emailCtrl.text = user.email ?? '';
      _nameCtrl.text = user.userMetadata?['name'] ?? '';
      _phoneCtrl.text = user.userMetadata?['phone'] ?? '';
    }
  }

  void _setupPaymentCallbacks() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.getCurrentUser()?.id;

      if (userId == null) {
        throw Exception('User not found');
      }

      // Update payment status via ViewModel
      final viewModel = Provider.of<PackageViewModel>(context, listen: false);
      await viewModel.updatePaymentStatus(
        paymentId: _paymentId ?? '',
        paymentStatus: 'success',
        paymentResponse: {
          'paymentId': response.paymentId,
          'orderId': response.orderId,
          'signature': response.signature,
        },
      );

      // Add topup credits (based on package)
      // Note: You may want to add credits based on package type or amount
      final creditService = CreditService();
      // For now, we'll add credits equal to AI question limit
      await creditService.addTopupCredits(
        userId,
        widget.package.aiQuestionLimit,
      );

      if (mounted) {
        _showPaymentSuccessDialog();
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

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isLoading = false;
    });

    // Update payment status
    if (mounted) {
      final viewModel = Provider.of<PackageViewModel>(context, listen: false);
      viewModel.updatePaymentStatus(
        paymentId: _paymentId ?? '',
        paymentStatus: 'failed',
        paymentResponse: {
          'code': response.code,
          'message': response.message,
        },
      );
    }

    _showPaymentCancelledDialog();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirected to ${response.walletName}'),
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.getCurrentUser()?.id;

      if (userId == null) {
        throw Exception('User not found. Please login first.');
      }

      final userDisplayName = _nameCtrl.text.trim();
      final userEmail = _emailCtrl.text.trim();
      final userPhone = _phoneCtrl.text.trim();

      // Create payment record (pending status)
      final viewModel = Provider.of<PackageViewModel>(context, listen: false);
      final paymentRecord = await viewModel.purchasePackage(
        packageId: widget.package.id,
        userInfo: {
          'name': userDisplayName,
          'email': userEmail,
          'phone': userPhone,
        },
      );

      _paymentId = paymentRecord['id'] as String?;

      // Create Razorpay order
      final order = await _createRazorpayOrder(
        amount: widget.package.finalAmount,
        userId: userId,
        userDisplayName: userDisplayName,
        userEmail: userEmail,
        userPhone: userPhone,
      );

      _orderId = order['id'];

      // Start payment
      final options = {
        'key': api_key,
        'amount': (widget.package.finalAmount * 100).toInt(), // Convert to paise
        'name': 'Karmasu',
        'description': 'Payment for ${widget.package.packageName}',
        'order_id': _orderId,
        'currency': 'INR',
        'prefill': {
          'contact': userPhone,
          'email': userEmail,
          'name': userDisplayName,
        },
        'theme': {
          'color': '#FF6B35', // Orange color
        },
        'method': {
          'netbanking': true,
          'card': true,
          'wallet': true,
          'upi': true,
          'emi': true,
          'paylater': true,
        },
        'retry': {'enabled': true, 'max_count': 3},
        'timeout': 300, // 5 minutes
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Payment initialization failed: $e');
    }
  }

  Future<Map<String, dynamic>> _createRazorpayOrder({
    required double amount,
    required String userId,
    required String userDisplayName,
    required String userEmail,
    required String userPhone,
  }) async {
    try {
      // Generate receipt with max 40 characters limit
      // Format: mg_<short_pkg_id>_<short_timestamp>
      // mg_ = 3 chars, short_pkg_id = 8 chars (first 8 of UUID), _ = 1 char, short_timestamp = 8 chars
      final packageIdShort = widget.package.id.length > 8 
          ? widget.package.id.substring(0, 8) 
          : widget.package.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final shortTimestamp = timestamp.length > 8 
          ? timestamp.substring(timestamp.length - 8) 
          : timestamp;
      final receipt = 'mg_${packageIdShort}_$shortTimestamp';
      
      // Ensure receipt doesn't exceed 40 characters
      final finalReceipt = receipt.length > 40 
          ? receipt.substring(0, 40) 
          : receipt;
      
      
      final orderData = {
        'amount': (amount * 100).toInt(), // Convert to paise
        'currency': 'INR',
        'receipt': finalReceipt,
        'notes': {
          'user_id': userId,
          'user_name': userDisplayName,
          'user_email': userEmail,
          'user_phone': userPhone,
          'package_id': widget.package.id,
          'package_name': widget.package.packageName,
        },
      };

      final credentials = '$api_key:$api_secret';
      final base64Str = base64.encode(utf8.encode(credentials));

      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $base64Str',
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['error']?['description'] ?? 'Failed to create order',
        );
      }
    } catch (e) {
      throw Exception('Order creation failed: $e');
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Payment Successful'),
          ],
        ),
        content: Text(
          'Your package "${widget.package.packageName}" has been activated successfully!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to package list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentCancelledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Payment Cancelled'),
          ],
        ),
        content: const Text('Payment was cancelled. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? 'पैकेज खरीदें' : 'Purchase Package',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.package.packageName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.package.getFormattedPrice(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade600,
                          ),
                        ),
                        if (widget.package.getDiscountDisplay() != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '₹${widget.package.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.package.getDiscountDisplay()!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isHindi
                          ? '${widget.package.aiQuestionLimit} AI प्रश्न'
                          : '${widget.package.aiQuestionLimit} AI Questions',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Form Fields
              Text(
                isHindi ? 'ग्राहक विवरण' : 'Customer Details',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: isHindi ? 'नाम' : 'Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isHindi ? 'कृपया नाम दर्ज करें' : 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: isHindi ? 'ईमेल' : 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isHindi
                        ? 'कृपया ईमेल दर्ज करें'
                        : 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return isHindi
                        ? 'कृपया वैध ईमेल दर्ज करें'
                        : 'Please enter valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: isHindi ? 'फ़ोन नंबर' : 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isHindi
                        ? 'कृपया फ़ोन नंबर दर्ज करें'
                        : 'Please enter phone number';
                  }
                  if (value.length < 10) {
                    return isHindi
                        ? 'कृपया वैध फ़ोन नंबर दर्ज करें'
                        : 'Please enter valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          isHindi
                              ? '₹${widget.package.finalAmount.toStringAsFixed(2)} का भुगतान करें'
                              : 'Pay ₹${widget.package.finalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
