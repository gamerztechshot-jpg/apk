import 'package:flutter/material.dart';
import 'package:karmasu/features/teacher/model/course.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../features/teacher/service/enrollment_service.dart';

class CoursePaymentScreen extends StatefulWidget {
  final Course course;

  const CoursePaymentScreen({super.key, required this.course});

  @override
  State<CoursePaymentScreen> createState() => _CoursePaymentScreenState();
}

class _CoursePaymentScreenState extends State<CoursePaymentScreen> {
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
    _paymentService.onExternalWallet = (_) {};
  }

  Future<void> _handlePaymentSuccess(dynamic response) async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      await _enrollmentService.saveCourseEnrollment(
        userId: user.id,
        courseId: widget.course.id,
        paymentId: response.paymentId,
        orderId: response.orderId,
        amount: widget.course.priceInt,
        customerInfo: {
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'course_title': widget.course.title,
          'teacher_id': widget.course.teacherId,
        },
      );

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(dynamic response) {
    setState(() => _isLoading = false);
    _showErrorDialog('Payment cancelled or failed');
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.getCurrentUser();
      if (user == null) throw Exception('Login required');

      final order = await _paymentService.createCourseOrder(
        amount: widget.course.priceInt,
        currency: 'INR',
        receipt:
            'c_${widget.course.id.substring(0, widget.course.id.length > 8 ? 8 : widget.course.id.length)}_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        userDisplayName: _nameCtrl.text.trim(),
        userEmail: _emailCtrl.text.trim(),
        userPhone: _phoneCtrl.text.trim(),
        courseId: widget.course.id,
        courseTitle: widget.course.title,
      );

      _orderId = order['id'];

      await _paymentService.startCoursePayment(
        orderId: _orderId!,
        amount: widget.course.priceInt,
        courseTitle: widget.course.title,
        customerName: _nameCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enroll in Course')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _courseDetails(),
                  _paymentSummary(),
                  _customerForm(),
                  const SizedBox(height: 20),
                  _payButton(),
                ],
              ),
            ),
    );
  }

  Widget _courseDetails() => Card(
    child: ListTile(
      title: Text(widget.course.title),
      subtitle: Text(widget.course.description),
    ),
  );

  Widget _paymentSummary() => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          if (widget.course.price > widget.course.actualPrice)
            ListTile(
              title: const Text('Original Price'),
              trailing: Text(
                '₹${widget.course.price}',
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
            ),
          ListTile(
            title: const Text('Payable Amount'),
            trailing: Text(
              '₹${widget.course.actualPrice}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
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

  Widget _payButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _processPayment,
      child: Text('Pay ₹${widget.course.actualPrice}'),
    ),
  );

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Enrollment Successful'),
        content: const Text('You are now enrolled in this course.'),
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

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }
}
