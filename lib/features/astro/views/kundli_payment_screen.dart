// features/astro/views/kundli_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../l10n/app_localizations.dart';
import '../models/kundli_type_model.dart';

class KundliPaymentScreen extends StatefulWidget {
  final KundliTypeModel kundliType;

  const KundliPaymentScreen({super.key, required this.kundliType});

  @override
  State<KundliPaymentScreen> createState() => _KundliPaymentScreenState();
}

class _KundliPaymentScreenState extends State<KundliPaymentScreen> {
  late PaymentService _paymentService;
  bool _isLoading = false;
  String? _orderId;
  String _announcementMessage = "Welcome to the app!";
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _birthDateCtrl = TextEditingController();
  final TextEditingController _birthTimeCtrl = TextEditingController();
  final TextEditingController _birthPlaceCtrl = TextEditingController();
  final TextEditingController _grandFatherNameCtrl = TextEditingController();
  final TextEditingController _fatherNameCtrl = TextEditingController();
  final TextEditingController _motherNameCtrl = TextEditingController();
  final TextEditingController _gotraCtrl = TextEditingController();
  final TextEditingController _specificQuestionsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _setupPaymentCallbacks();
    _fetchAnnouncementMessage();
  }

  Future<void> _fetchAnnouncementMessage() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://fwhblztexcyxjrfhrrsb.supabase.co/storage/v1/object/public/punchang/kundli_info.json',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _announcementMessage = data['announcement'] ?? "Welcome to the app!";
        });
      }
    } catch (e) {
      // Keep default message
    }
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
      // Get user data from auth (only for user_id)
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      if (user == null) {
        throw Exception('User not found');
      }

      // Build customer info from form inputs
      final customerInfo = _buildCustomerInfo();
      final userDisplayName = _nameCtrl.text.trim();
      final userEmail = _emailCtrl.text.trim();
      final userPhone = _phoneCtrl.text.trim();

      // Save payment record to database
      final success = await _paymentService.saveKundliPaymentRecord(
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        userId: user.id,
        kundliId: widget.kundliType.id,
        amount: widget.kundliType.price,
        customerInfo: customerInfo,
      );

      if (success) {
        if (mounted) {
          // Show success dialog
          _showPaymentSuccessDialog();
        }
      } else {
        throw Exception('Failed to save payment record');
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
    _showPaymentCancelledDialog();
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
      // Validate form
      if (!_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get user data from auth
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      if (user == null) {
        throw Exception('User not found. Please login first.');
      }

      // Use details provided in form
      final userDisplayName = _nameCtrl.text.trim();
      final userEmail = _emailCtrl.text.trim();
      final userPhone = _phoneCtrl.text.trim();

      // Create order with all required data
      final order = await _paymentService.createKundliOrder(
        amount: widget.kundliType.price.toInt(),
        currency: 'INR',
        receipt:
            'kundli_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}', // Shortened receipt to fit 40 char limit
        userId: user.id,
        userDisplayName: userDisplayName,
        userEmail: userEmail,
        userPhone: userPhone,
        kundliId: widget.kundliType.id,
        kundliName: widget.kundliType.title,
      );

      _orderId = order['id'];

      // Start payment with user profile data
      await _paymentService.startKundliPayment(
        orderId: _orderId!,
        amount: widget.kundliType.price.toInt(),
        kundliName: widget.kundliType.title,
        customerName: userDisplayName,
        customerEmail: userEmail,
        customerPhone: userPhone,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog('Payment initialization failed: $e');
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Payment Successful',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text('Thank you for purchasing the kundli!'),
                SizedBox(height: 12),
                _kv('Kundli', widget.kundliType.title),
                _kv('Amount', '₹${widget.kundliType.price.toStringAsFixed(0)}'),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
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

  void _showPaymentCancelledDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/payment_cancelled.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Payment Cancelled',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your payment was not completed. You can try again anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('$key:')),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    _birthTimeCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _grandFatherNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _motherNameCtrl.dispose();
    _gotraCtrl.dispose();
    _specificQuestionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Kundli Payment',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
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
          child: _isLoading
              ? _buildLoadingWidget(isTablet)
              : _buildPaymentContent(isTablet, l10n),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            strokeWidth: 3,
          ),
          SizedBox(height: isTablet ? 24 : 16),
          Text(
            'Processing Payment...',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent(bool isTablet, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Announcement Message
          _buildAnnouncementCard(isTablet),

          SizedBox(height: isTablet ? 20 : 16),

          // Kundli Details Card
          _buildKundliDetailsCard(isTablet),

          SizedBox(height: isTablet ? 20 : 16),

          // Payment Summary Card
          _buildPaymentSummaryCard(isTablet, l10n),

          SizedBox(height: isTablet ? 32 : 24),

          // Customer details form
          _buildCustomerForm(isTablet),

          SizedBox(height: isTablet ? 24 : 20),

          // Pay Now Button
          _buildPayNowButton(isTablet),

          SizedBox(height: isTablet ? 16 : 12),

          // Security Notice
          _buildSecurityNotice(isTablet),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade600,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Text(
              _announcementMessage,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKundliDetailsCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
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
            'Kundli Details',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          _buildDetailRow('Title', widget.kundliType.title, isTablet),
          SizedBox(height: isTablet ? 8 : 6),
          _buildDetailRow(
            'Description',
            widget.kundliType.description,
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isTablet ? 100 : 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryCard(bool isTablet, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
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
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.kundliType.title}:',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '₹${widget.kundliType.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Taxes & Fees:',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '₹0',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
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
                'Total Amount:',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '₹${widget.kundliType.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
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

  Widget _buildCustomerForm(bool isTablet) {
    InputDecoration _dec(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.symmetric(
        vertical: isTablet ? 16 : 12,
        horizontal: 12,
      ),
    );

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
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
              'Kundli Information',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),

            // Personal Information
            TextFormField(
              controller: _nameCtrl,
              decoration: _dec('Full Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
            ),
            SizedBox(height: 12),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('Email'),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Please enter valid email'
                  : null,
            ),
            SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _dec('Phone Number'),
              validator: (v) => (v == null || v.trim().length < 8)
                  ? 'Please enter valid phone'
                  : null,
            ),
            SizedBox(height: 12),

            // Birth Information
            TextFormField(
              controller: _birthDateCtrl,
              decoration: _dec('Date of Birth (DD/MM/YYYY)'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter birth date'
                  : null,
            ),
            SizedBox(height: 12),

            TextFormField(
              controller: _birthTimeCtrl,
              decoration: _dec('Birth Time (HH:MM)'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter birth time'
                  : null,
            ),
            SizedBox(height: 12),

            TextFormField(
              controller: _birthPlaceCtrl,
              decoration: _dec('Birth Place'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter birth place'
                  : null,
            ),
            SizedBox(height: 12),

            // Family Information
            TextFormField(
              controller: _grandFatherNameCtrl,
              decoration: _dec('Grand Father Name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter grand father name'
                  : null,
            ),
            SizedBox(height: 12),

            TextFormField(
              controller: _fatherNameCtrl,
              decoration: _dec('Father Name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter father name'
                  : null,
            ),
            SizedBox(height: 12),

            TextFormField(
              controller: _motherNameCtrl,
              decoration: _dec('Mother Name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter mother name'
                  : null,
            ),
            SizedBox(height: 12),

            TextFormField(
              controller: _gotraCtrl,
              decoration: _dec('Gotra'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter gotra' : null,
            ),
            SizedBox(height: 12),

            // Specific Questions
            TextFormField(
              controller: _specificQuestionsCtrl,
              decoration: InputDecoration(
                labelText: 'Specific Questions (Optional)',
                hintText:
                    'Any specific questions or areas you want to focus on in your kundli',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isTablet ? 16 : 12,
                  horizontal: 12,
                ),
              ),
              maxLines: 3,
              minLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildCustomerInfo() {
    return {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'birth_date': _birthDateCtrl.text.trim(),
      'birth_time': _birthTimeCtrl.text.trim(),
      'birth_place': _birthPlaceCtrl.text.trim(),
      'grand_father_name': _grandFatherNameCtrl.text.trim(),
      'father_name': _fatherNameCtrl.text.trim(),
      'mother_name': _motherNameCtrl.text.trim(),
      'gotra': _gotraCtrl.text.trim(),
      'specific_questions': _specificQuestionsCtrl.text.trim(),
    };
  }

  Widget _buildPayNowButton(bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: isTablet ? 24 : 20),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Pay ₹${widget.kundliType.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNotice(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.green.shade600,
            size: isTablet ? 20 : 18,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Text(
              'Your payment is secured by Razorpay with 256-bit SSL encryption.',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
