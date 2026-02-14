import 'package:flutter/material.dart';
import 'package:karmasu/features/teacher/model/webinar.dart';
import 'package:karmasu/features/teacher/service/enrollment_service.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_service.dart';

class WebinarPaymentScreen extends StatefulWidget {
  final Webinar webinar;

  const WebinarPaymentScreen({super.key, required this.webinar});

  @override
  State<WebinarPaymentScreen> createState() => _WebinarPaymentScreenState();
}

class _WebinarPaymentScreenState extends State<WebinarPaymentScreen> {
  late PaymentService _paymentService;
  late EnrollmentService _enrollmentService;

  bool _isLoading = false;
  String? _orderId;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _enrollmentService = EnrollmentService();
    _setupPaymentCallbacks();
    _prefillDetails();
  }

  void _prefillDetails() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.getCurrentUser();
    if (user != null) {
      _nameCtrl.text = user.userMetadata?['name'] ?? '';
      _emailCtrl.text = user.email ?? '';
      _phoneCtrl.text = user.userMetadata?['phone'] ?? '';
    }
  }

  void _setupPaymentCallbacks() {
    _paymentService.onPaymentSuccess = _handlePaymentSuccess;
    _paymentService.onPaymentError = _handlePaymentError;
  }

  Future<void> _handlePaymentSuccess(dynamic response) async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.getCurrentUser();

      await _enrollmentService.saveWebinarEnrollment(
        userId: user!.id,
        webinarId: widget.webinar.id,
        paymentId: response.paymentId,
        orderId: response.orderId,
        amount: widget.webinar.priceInt,
        customerInfo: {
          'name': _nameCtrl.text,
          'email': _emailCtrl.text,
          'phone': _phoneCtrl.text,
          'webinar_title': widget.webinar.title,
          'teacher_id': widget.webinar.teacherId,
        },
      );

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(dynamic _) {
    setState(() => _isLoading = false);
    _showErrorDialog('Payment failed');
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.getCurrentUser();

    final order = await _paymentService.createWebinarOrder(
      amount: widget.webinar.priceInt,
      currency: 'INR',
      receipt:
          'w_${widget.webinar.id.substring(0, widget.webinar.id.length > 8 ? 8 : widget.webinar.id.length)}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user!.id,
      userDisplayName: _nameCtrl.text,
      userEmail: _emailCtrl.text,
      userPhone: _phoneCtrl.text,
      webinarId: widget.webinar.id,
      webinarTitle: widget.webinar.title,
    );

    _orderId = order['id'];

    await _paymentService.startWebinarPayment(
      orderId: _orderId!,
      amount: widget.webinar.priceInt,
      webinarTitle: widget.webinar.title,
      customerName: _nameCtrl.text,
      customerEmail: _emailCtrl.text,
      customerPhone: _phoneCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Webinar Registration')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _webinarInfoCard(),
                  const SizedBox(height: 20),
                  _customerForm(),
                  const SizedBox(height: 24),
                  _payButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _webinarInfoCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.webinar.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.webinar.price > widget.webinar.actualPrice)
            Row(
              children: [
                const Text('Original Price: '),
                Text(
                  '₹${widget.webinar.price}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          Row(
            children: [
              const Text(
                'Registration Fee: ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '₹${widget.webinar.actualPrice}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _payButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _processPayment,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      child: Text(
        'Pay ₹${widget.webinar.actualPrice}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _customerForm() => Form(
    key: _formKey,
    child: Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        TextFormField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
        ),
        TextFormField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(labelText: 'Phone'),
          validator: (v) => v!.length < 8 ? 'Invalid phone' : null,
        ),
      ],
    ),
  );

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: const Text('You are registered for this webinar.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
