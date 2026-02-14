// features/astro/views/astrologer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/language_service.dart';
import '../models/astrologer_model.dart';

class AstrologerDetailScreen extends StatefulWidget {
  final AstrologerModel astrologer;

  const AstrologerDetailScreen({super.key, required this.astrologer});

  @override
  State<AstrologerDetailScreen> createState() => _AstrologerDetailScreenState();
}

class _AstrologerDetailScreenState extends State<AstrologerDetailScreen> {
  late PaymentService _paymentService;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _orderId;

  // Controllers for per-minute booking
  final TextEditingController _minutesController = TextEditingController();
  String _selectedCommunicationMode = 'chat'; // Default to chat

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _setupPaymentCallbacks();
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  void _setupPaymentCallbacks() {
    _paymentService.onPaymentSuccess = (response) async {
      final l10n = AppLocalizations.of(context)!;

      try {
        // Get payment details from response - response is a PaymentSuccessResponse object
        final paymentId = response.paymentId ?? '';
        final orderId = response.orderId ?? _orderId ?? '';

        // Get current user
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.getCurrentUser();

        if (user != null && paymentId.isNotEmpty && orderId.isNotEmpty) {
          // Prepare customer info
          final customerInfo = {
            'name': user.userMetadata?['name'] ?? 'Guest',
            'email': user.email ?? 'guest@example.com',
            'phone': user.userMetadata?['phone'] ?? '',
          };

          // Determine booking type and amount based on which payment was made
          String bookingType;
          double totalAmount;
          int? minutesBooked;
          String? communicationMode;

          // Check if this was a per-minute booking (minutes controller has value)
          if (_minutesController.text.isNotEmpty) {
            bookingType = 'per_minute';
            minutesBooked = int.tryParse(_minutesController.text);
            totalAmount =
                (minutesBooked ?? 0) * widget.astrologer.perMinuteCharge;
            communicationMode = _selectedCommunicationMode;
          } else {
            // This was a per-month booking
            bookingType = 'per_month';
            totalAmount = widget.astrologer.perMonthCharge;
          }

          // Save booking to database
          final bookingSaved = await _saveAstrologerBooking(
            paymentId: paymentId,
            orderId: orderId,
            userId: user.id,
            astrologerId: widget.astrologer.id,
            bookingType: bookingType,
            totalAmount: totalAmount,
            customerInfo: customerInfo,
            minutesBooked: minutesBooked,
            communicationMode: communicationMode,
          );

          if (bookingSaved) {
            _setLoading(false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.paymentSuccessful),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else {
            _setLoading(false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.paymentSuccessfulButFailedToSave),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          _setLoading(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.paymentSuccessfulButMissingData),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        _setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentSuccessfulButErrorOccurred),
            backgroundColor: Colors.orange,
          ),
        );
      }
    };

    _paymentService.onPaymentError = (response) async {
      final l10n = AppLocalizations.of(context)!;

      try {
        // Get current user
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.getCurrentUser();

        if (user != null && _orderId != null) {
          // Save failed payment record
          await _saveFailedPaymentRecord(
            userId: user.id,
            astrologerId: widget.astrologer.id,
            orderId: _orderId!,
            errorDescription: response['description'] ?? 'Payment failed',
          );
        }
      } catch (e) {}

      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.paymentFailed(response['description'] ?? 'Unknown error'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    };

    _paymentService.onExternalWallet = (response) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.redirectingToExternalWallet(
              response['wallet_name'] ?? 'external wallet',
            ),
          ),
          backgroundColor: Colors.blue,
        ),
      );
    };
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  // Save astrologer booking to database after successful payment
  Future<bool> _saveAstrologerBooking({
    required String paymentId,
    required String orderId,
    required String userId,
    required String astrologerId,
    required String bookingType,
    required double totalAmount,
    required Map<String, dynamic> customerInfo,
    int? minutesBooked,
    String? communicationMode,
  }) async {
    try {
      final paymentInfo = {
        'razorpay_payment_id': paymentId,
        'order_id': orderId,
        'payment_status': 'paid',
        'created_at': DateTime.now().toIso8601String(),
      };

      final bookingData = {
        'user_id': userId,
        'astrologer_id': astrologerId,
        'booking_type': bookingType,
        'total_amount': totalAmount,
        'payment_status': 'paid',
        'booking_status': 'confirmed',
        'payment_info': paymentInfo,
        'customer_info': customerInfo,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add optional fields based on booking type
      if (minutesBooked != null) {
        bookingData['minutes_booked'] = minutesBooked;
      }
      if (communicationMode != null) {
        bookingData['communication_mode'] = communicationMode;
      }

      // Insert into astrologer_bookings table
      await _supabase.from('astrologer_bookings').insert(bookingData);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Save failed payment record to database
  Future<void> _saveFailedPaymentRecord({
    required String userId,
    required String astrologerId,
    required String orderId,
    required String errorDescription,
  }) async {
    try {
      // Prepare customer info
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      final customerInfo = {
        'name': user?.userMetadata?['name'] ?? 'Guest',
        'email': user?.email ?? 'guest@example.com',
        'phone': user?.userMetadata?['phone'] ?? '',
      };

      final paymentInfo = {
        'order_id': orderId,
        'payment_status': 'failed',
        'error_description': errorDescription,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Determine booking type and amount
      String bookingType;
      double totalAmount;
      int? minutesBooked;
      String? communicationMode;

      if (_minutesController.text.isNotEmpty) {
        bookingType = 'per_minute';
        minutesBooked = int.tryParse(_minutesController.text);
        totalAmount = (minutesBooked ?? 0) * widget.astrologer.perMinuteCharge;
        communicationMode = _selectedCommunicationMode;
      } else {
        bookingType = 'per_month';
        totalAmount = widget.astrologer.perMonthCharge;
      }

      final bookingData = {
        'user_id': userId,
        'astrologer_id': astrologerId,
        'booking_type': bookingType,
        'total_amount': totalAmount,
        'payment_status': 'failed',
        'booking_status': 'cancelled',
        'payment_info': paymentInfo,
        'customer_info': customerInfo,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add optional fields based on booking type
      if (minutesBooked != null) {
        bookingData['minutes_booked'] = minutesBooked;
      }
      if (communicationMode != null) {
        bookingData['communication_mode'] = communicationMode;
      }


      // Insert into astrologer_bookings table
      await _supabase.from('astrologer_bookings').insert(bookingData);
    } catch (e) {}
  }

  Future<void> _processPerMinutePayment() async {
    final l10n = AppLocalizations.of(context)!;

    if (_minutesController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterNumberOfMinutes)));
      return;
    }

    final int minutes = int.tryParse(_minutesController.text) ?? 0;
    if (minutes <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.minutesMustBePositive)));
      return;
    }

    final double totalAmount = minutes * widget.astrologer.perMinuteCharge;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.calculatedAmountIsZero)));
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;
    final user = authService.getCurrentUser();

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseLoginToContinue)));
      return;
    }

    _setLoading(true);
    try {
      final userDisplayName = user.userMetadata?['name'] ?? 'Guest';
      final userEmail = user.email ?? 'guest@example.com';
      final userPhone = user.userMetadata?['phone'] ?? '';

      final order = await _paymentService.createRazorpayOrder(
        amount: (totalAmount * 100).toInt(), // Convert to paise
        currency: 'INR',
        receipt:
            'astro_min_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        notes: {
          'user_id': user.id,
          'user_name': userDisplayName,
          'user_email': userEmail,
          'user_phone': userPhone,
          'astrologer_id': widget.astrologer.id,
          'astrologer_name': widget.astrologer.getName(isHindi),
          'booking_type': 'per_minute',
          'minutes_booked': minutes,
          'communication_mode': _selectedCommunicationMode,
        },
      );

      _orderId = order['id'];

      await _paymentService.startPayment(
        orderId: _orderId!,
        amount: totalAmount.toInt(),
        pujaName: '${widget.astrologer.getName(isHindi)} - Per Minute Booking',
        customerName: userDisplayName,
        customerEmail: userEmail,
        customerPhone: userPhone,
      );
    } catch (e) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorProcessingPayment(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processPerMonthPayment() async {
    final l10n = AppLocalizations.of(context)!;
    final double totalAmount = widget.astrologer.perMonthCharge;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.monthlyChargeNotAvailable)));
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;
    final user = authService.getCurrentUser();

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseLoginToContinue)));
      return;
    }

    _setLoading(true);
    try {
      final userDisplayName = user.userMetadata?['name'] ?? 'Guest';
      final userEmail = user.email ?? 'guest@example.com';
      final userPhone = user.userMetadata?['phone'] ?? '';

      final order = await _paymentService.createRazorpayOrder(
        amount: (totalAmount * 100).toInt(), // Convert to paise
        currency: 'INR',
        receipt:
            'astro_month_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        notes: {
          'user_id': user.id,
          'user_name': userDisplayName,
          'user_email': userEmail,
          'user_phone': userPhone,
          'astrologer_id': widget.astrologer.id,
          'astrologer_name': widget.astrologer.getName(isHindi),
          'booking_type': 'per_month',
        },
      );

      _orderId = order['id'];

      await _paymentService.startPayment(
        orderId: _orderId!,
        amount: totalAmount.toInt(),
        pujaName: '${widget.astrologer.getName(isHindi)} - Per Month Booking',
        customerName: userDisplayName,
        customerEmail: userEmail,
        customerPhone: userPhone,
      );
    } catch (e) {
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorProcessingPayment(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final astrologer = widget.astrologer;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Text(astrologer.getName(isHindi)),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Astrologer Profile Card
                  _buildAstrologerProfileCard(astrologer, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),

                  // About Astrologer
                  _buildSectionTitle(
                    l10n.aboutAstrologer(astrologer.getName(isHindi)),
                    isTablet,
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  _buildAboutSection(astrologer, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),

                  // Booking Options
                  _buildSectionTitle(l10n.bookASession, isTablet),
                  SizedBox(height: isTablet ? 12 : 8),
                  _buildBookingOptions(isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                ],
              ),
            ),
    );
  }

  Widget _buildAstrologerProfileCard(
    AstrologerModel astrologer,
    bool isTablet,
  ) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          Container(
            width: isTablet ? 80 : 70,
            height: isTablet ? 80 : 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange.shade200, width: 2),
            ),
            child: ClipOval(
              child:
                  astrologer.getPhotoUrl(isHindi) != null &&
                      astrologer.getPhotoUrl(isHindi)!.isNotEmpty
                  ? Image.network(
                      astrologer.getPhotoUrl(isHindi)!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(isTablet),
                    )
                  : _buildDefaultAvatar(isTablet),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),

          // Astrologer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  astrologer.getName(isHindi),
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  astrologer.getQualificationDisplay(isHindi),
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: isTablet ? 20 : 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      astrologer.getRatingDisplay(),
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      astrologer.getReviewCountDisplay(),
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  astrologer.getExperienceDisplay(isHindi),
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.grey.shade600,
                      size: isTablet ? 16 : 14,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        astrologer.getAddress(isHindi),
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isTablet) {
    return Container(
      color: Colors.orange.shade50,
      child: Icon(
        Icons.person,
        color: Colors.orange.shade600,
        size: isTablet ? 40 : 35,
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isTablet) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isTablet ? 20 : 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAboutSection(AstrologerModel astrologer, bool isTablet) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        astrologer.getAboutYou(isHindi),
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBookingOptions(bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final bool hasPerMinute = widget.astrologer.perMinuteCharge > 0;
    final bool hasPerMonth = widget.astrologer.perMonthCharge > 0;

    // If neither option is available, don't show booking options
    if (!hasPerMinute && !hasPerMonth) {
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
        child: Center(
          child: Text(
            l10n.bookingOptionsNotAvailable,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

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
            l10n.chooseBookingType,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          // Show both buttons if both options are available
          if (hasPerMinute && hasPerMonth)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showPerMinuteBookingDialog(isTablet),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: isTablet ? 24 : 20),
                        SizedBox(height: isTablet ? 8 : 6),
                        Text(
                          l10n.perMinute,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isTablet ? 4 : 2),
                        Text(
                          '₹${widget.astrologer.perMinuteCharge.toStringAsFixed(0)}${l10n.perMin}',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processPerMonthPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 16 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month, size: isTablet ? 24 : 20),
                        SizedBox(height: isTablet ? 8 : 6),
                        Text(
                          l10n.perMonth,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isTablet ? 4 : 2),
                        Text(
                          '₹${widget.astrologer.perMonthCharge.toStringAsFixed(0)}${l10n.perMonth}',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          // Show only per minute button if only per minute is available
          else if (hasPerMinute)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPerMinuteBookingDialog(isTablet),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: isTablet ? 24 : 20),
                    SizedBox(height: isTablet ? 8 : 6),
                    Text(
                      l10n.bookPerMinute,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isTablet ? 4 : 2),
                    Text(
                      '₹${widget.astrologer.perMinuteCharge.toStringAsFixed(0)}${l10n.perMin}',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Show only per month button if only per month is available
          else if (hasPerMonth)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processPerMonthPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_month, size: isTablet ? 24 : 20),
                    SizedBox(height: isTablet ? 8 : 6),
                    Text(
                      l10n.bookPerMonth,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isTablet ? 4 : 2),
                    Text(
                      '₹${widget.astrologer.perMonthCharge.toStringAsFixed(0)}${l10n.perMonth}',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPerMinuteBookingDialog(bool isTablet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;
            final minutes = int.tryParse(_minutesController.text) ?? 0;
            final totalAmount = minutes * widget.astrologer.perMinuteCharge;

            return AlertDialog(
              title: Text(l10n.bookPerMinuteSession),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.enterNumberOfMinutes,
                      style: TextStyle(fontSize: isTablet ? 16 : 14),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    TextFormField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.numberOfMinutes,
                        hintText: l10n.minutesExample,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.timer),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    Text(
                      l10n.communicationMode,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(l10n.chat),
                            value: 'chat',
                            groupValue: _selectedCommunicationMode,
                            onChanged: (value) {
                              setState(() {
                                _selectedCommunicationMode = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(l10n.call),
                            value: 'call',
                            groupValue: _selectedCommunicationMode,
                            onChanged: (value) {
                              setState(() {
                                _selectedCommunicationMode = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.totalAmount,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: minutes > 0
                      ? () {
                          Navigator.of(context).pop();
                          _processPerMinutePayment();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.payNow),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
