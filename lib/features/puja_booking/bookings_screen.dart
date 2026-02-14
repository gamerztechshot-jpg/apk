// features/puja_booking/bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Clear cache if there was a type casting error
      if (forceRefresh) {
        await _bookingService.clearUserBookingCache(user.id);
      }

      final bookings = await _bookingService.getUserBookings(
        user.id,
        forceRefresh: forceRefresh,
      );

      // If no bookings found, create some test data for demonstration
      List<Map<String, dynamic>> finalBookings = bookings;
      if (bookings.isEmpty) {
        finalBookings = _createTestBookings();
      }

      setState(() {
        _bookings = finalBookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bookings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          l10n.mySankalp,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
              : _bookings.isEmpty
              ? _buildEmptyWidget(l10n, isTablet)
              : _buildBookingsList(context, l10n, isTablet),
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
            'Loading your bookings...',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(AppLocalizations l10n, bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_online_outlined,
            size: isTablet ? 80 : 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: isTablet ? 24 : 16),
          Text(
            'No Bookings Yet',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'You haven\'t booked any pujas yet.\nStart exploring and book your first puja!',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 24 : 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.explore),
            label: Text('Explore Pujas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: isTablet ? 12 : 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(
    BuildContext context,
    AppLocalizations l10n,
    bool isTablet,
  ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return _buildBookingCard(context, booking, l10n, isTablet);
      },
    );
  }

  // Stats UI removed per requirement

  Widget _buildBookingCard(
    BuildContext context,
    Map<String, dynamic> booking,
    AppLocalizations l10n,
    bool isTablet,
  ) {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;

    final puja = booking['puja'] as Map<String, dynamic>? ?? {};
    final package = booking['package'] as Map<String, dynamic>? ?? {};

    // Safely access puja_basic with null checks
    final pujaBasicHi = puja['puja_basic_hi'] as Map<String, dynamic>?;
    final pujaBasic = puja['puja_basic'] as Map<String, dynamic>?;

    final selectedPujaBasic = isHindi && pujaBasicHi != null
        ? pujaBasicHi
        : pujaBasic ?? {};

    final status = booking['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
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
          // Header with status
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  _formatDate(DateTime.parse(booking['created_at'])),
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Puja Title
                Text(
                  selectedPujaBasic['title']?.toString() ??
                      selectedPujaBasic['name']?.toString() ??
                      puja['title']?.toString() ??
                      puja['name']?.toString() ??
                      'Puja Booking',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),

                // Puja Name and Location
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedPujaBasic['name']?.toString() ??
                            selectedPujaBasic['title']?.toString() ??
                            puja['name']?.toString() ??
                            puja['title']?.toString() ??
                            'Puja Name',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.grey.shade500,
                          size: isTablet ? 16 : 14,
                        ),
                        SizedBox(width: isTablet ? 4 : 2),
                        Text(
                          selectedPujaBasic['location']?.toString() ??
                              puja['location']?.toString() ??
                              'Location',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : 8),

                // Package Details
                if (package.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: Colors.orange.shade600,
                          size: isTablet ? 20 : 18,
                        ),
                        SizedBox(width: isTablet ? 8 : 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Package: ${package['name'] ?? 'Package Name'}',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              if (package['description'] != null)
                                Text(
                                  package['description'],
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${package['price'] ?? '0'}',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                ],

                // Payment Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment ID',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          booking['razorpay_payment_id'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.dakshina,
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          '₹${booking['amount'] ?? '0'}',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Create test bookings for demonstration
  List<Map<String, dynamic>> _createTestBookings() {
    final now = DateTime.now();
    return [
      {
        'id': 'test-booking-1',
        'status': 'success',
        'amount': 5100,
        'razorpay_payment_id': 'pay_RORLpwNeskaHNf',
        'order_id': 'order_RORLknR6mnWrLg',
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'puja': {
          'id': 1,
          'title': 'Ganesh Puja',
          'name': 'Ganesh Chaturthi Special Puja',
          'location': 'Mumbai Temple',
          'puja_basic': {
            'title': 'Ganesh Puja',
            'name': 'Ganesh Chaturthi Special Puja',
            'location': 'Mumbai Temple',
            'packages': [
              {
                'name': 'Standard Package',
                'description': 'Complete Ganesh Puja with Prasad',
                'price': 5100,
              },
            ],
          },
        },
        'package': {
          'name': 'Standard Package',
          'description': 'Complete Ganesh Puja with Prasad',
          'price': 5100,
        },
        'customer_info': {
          'name': 'Sam',
          'email': 'sam@gmail.com',
          'phone': '8123287639',
        },
      },
      {
        'id': 'test-booking-2',
        'status': 'success',
        'amount': 3500,
        'razorpay_payment_id': 'pay_TEST123456789',
        'order_id': 'order_TEST987654321',
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
        'puja': {
          'id': 2,
          'title': 'Lakshmi Puja',
          'name': 'Diwali Lakshmi Puja',
          'location': 'Delhi Temple',
          'puja_basic': {
            'title': 'Lakshmi Puja',
            'name': 'Diwali Lakshmi Puja',
            'location': 'Delhi Temple',
            'packages': [
              {
                'name': 'Premium Package',
                'description': 'Complete Lakshmi Puja with Aarti',
                'price': 3500,
              },
            ],
          },
        },
        'package': {
          'name': 'Premium Package',
          'description': 'Complete Lakshmi Puja with Aarti',
          'price': 3500,
        },
        'customer_info': {
          'name': 'Priya',
          'email': 'priya@gmail.com',
          'phone': '9876543210',
        },
      },
    ];
  }
}
