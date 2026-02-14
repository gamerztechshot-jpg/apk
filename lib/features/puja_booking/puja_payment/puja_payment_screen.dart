// features/puja_booking/puja_payment/puja_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/puja_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/language_service.dart';
import '../../../l10n/app_localizations.dart';

class PujaPaymentScreen extends StatefulWidget {
  final PujaModel puja;
  final PujaPackage selectedPackage;

  const PujaPaymentScreen({
    super.key,
    required this.puja,
    required this.selectedPackage,
  });

  @override
  State<PujaPaymentScreen> createState() => _PujaPaymentScreenState();
}

class _PujaPaymentScreenState extends State<PujaPaymentScreen> {
  late PaymentService _paymentService;
  bool _isLoading = false;
  String? _orderId;
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _gotraCtrl = TextEditingController();
  final TextEditingController _partnerNameCtrl = TextEditingController();
  final TextEditingController _partnerGotraCtrl = TextEditingController();
  final TextEditingController _familyNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
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
      // Get user data from auth (only for user_id)
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      if (user == null) {
        throw Exception('User not found');
      }

      // Build customer info from form inputs (no prefilling)
      final customerInfo = _buildCustomerInfo();
      final userDisplayName = _nameCtrl.text.trim();
      final userEmail = _emailCtrl.text.trim();
      final userPhone = _phoneCtrl.text.trim();

      // Test data integrity before saving
      await _paymentService.testDataIntegrity(
        userId: user.id,
        pujaId: widget.puja.id,
        packageId: widget.selectedPackage.name.hashCode,
        amount: widget.selectedPackage.price,
        customerEmail: userEmail,
        customerName: userDisplayName,
        customerPhone: userPhone,
      );

      // Save payment record to database with new JSON structure
      final success = await _paymentService.savePaymentRecord(
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        userId: user.id,
        pujaId: widget.puja.id,
        packageId: widget.selectedPackage.name.hashCode,
        amount: widget.selectedPackage.price,
        customerInfo: customerInfo,
        panditId:
            widget.puja.pujaBasic.panditId, // Include pandit_id from puja data
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
      final order = await _paymentService.createOrder(
        amount: widget
            .selectedPackage
            .price, // Flexible amount based on selected package
        currency: 'INR',
        receipt:
            'puja_${widget.puja.id}_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        userDisplayName: userDisplayName,
        userEmail: userEmail,
        userPhone: userPhone,
        pujaId: widget.puja.id,
        pujaName: widget.puja.pujaBasic.name,
      );

      _orderId = order['id'];

      // Start payment with user profile data
      await _paymentService.startPayment(
        orderId: _orderId!,
        amount: widget
            .selectedPackage
            .price, // Flexible amount based on selected package
        pujaName: widget.puja.pujaBasic.name,
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
        final l10n = AppLocalizations.of(context)!;
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
                Text('Thank you for booking the puja!'),
                SizedBox(height: 12),
                _kv('Puja', widget.puja.pujaBasic.name),
                _kv('Package', widget.selectedPackage.name),
                _kv(l10n.dakshina, '₹${widget.selectedPackage.price}'),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;

    final basic = isHindi
        ? (widget.puja.pujaBasicHi.name.isNotEmpty
              ? widget.puja.pujaBasicHi
              : widget.puja.pujaBasic)
        : widget.puja.pujaBasic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Payment',
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
              : _buildPaymentContent(basic, isTablet, l10n),
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

  Widget _buildPaymentContent(
    PujaBasic basic,
    bool isTablet,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puja Details Card
          _buildPujaDetailsCard(basic, isTablet),

          SizedBox(height: isTablet ? 24 : 20),

          // Package Details Card
          _buildPackageDetailsCard(isTablet),

          SizedBox(height: isTablet ? 24 : 20),

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

  Widget _buildPujaDetailsCard(PujaBasic basic, bool isTablet) {
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
            'Puja Details',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            basic.name,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade600,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            basic.title,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.grey.shade600,
                size: isTablet ? 18 : 16,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Expanded(
                child: Text(
                  basic.location,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDetailsCard(bool isTablet) {
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
            'Selected Package',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            widget.selectedPackage.name,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade600,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            widget.selectedPackage.description,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
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
                '${widget.selectedPackage.name}:',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '₹${widget.selectedPackage.price}',
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
                '${l10n.dakshina}:',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '₹${widget.selectedPackage.price}',
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
    final packageName = widget.selectedPackage.name.toLowerCase();
    final isCouple = packageName.contains('couple');
    final isFamily = packageName.contains('family');

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
              'Customer Details',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),

            // Common fields
            TextFormField(
              controller: _nameCtrl,
              decoration: _dec(isFamily ? 'Your Name' : 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
            ),
            SizedBox(height: 12),
            if (isFamily) ...[
              TextFormField(
                controller: _familyNameCtrl,
                decoration: _dec('Family Name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter family name'
                    : null,
              ),
              SizedBox(height: 12),
            ],
            TextFormField(
              controller: _gotraCtrl,
              decoration: _dec(isFamily ? 'Family Gotra' : 'Gotra'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter gotra' : null,
            ),
            SizedBox(height: 12),

            if (isCouple) ...[
              TextFormField(
                controller: _partnerNameCtrl,
                decoration: _dec('Partner Name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter partner name'
                    : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _partnerGotraCtrl,
                decoration: _dec('Partner Gotra'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter partner gotra'
                    : null,
              ),
              SizedBox(height: 12),
            ],

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
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildCustomerInfo() {
    final package = widget.selectedPackage.name.toLowerCase();
    if (package.contains('single')) {
      return {
        'type': 'single',
        'name': _nameCtrl.text.trim(),
        'gotra': _gotraCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };
    } else if (package.contains('couple')) {
      return {
        'type': 'couple',
        'name': _nameCtrl.text.trim(),
        'gotra': _gotraCtrl.text.trim(),
        'partner_name': _partnerNameCtrl.text.trim(),
        'partner_gotra': _partnerGotraCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };
    } else {
      return {
        'type': 'family',
        'name': _nameCtrl.text.trim(),
        'family_name': _familyNameCtrl.text.trim(),
        'gotra': _gotraCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };
    }
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
              'Pay ₹${widget.selectedPackage.price}',
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
