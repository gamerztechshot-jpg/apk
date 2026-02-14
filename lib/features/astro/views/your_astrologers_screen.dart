// features/astro/views/your_astrologers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';

class YourAstrologersScreen extends StatefulWidget {
  const YourAstrologersScreen({super.key});

  @override
  State<YourAstrologersScreen> createState() => _YourAstrologersScreenState();
}

class _YourAstrologersScreenState extends State<YourAstrologersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _bookedAstrologers = [];
  bool _isLoading = true;

  String _getLocalizedField(
    Map<String, dynamic> record,
    String key, {
    required bool isHindi,
  }) {
    final dynamic hiValue = record['${key}_hi'];
    final dynamic enValue = record[key];

    final String? hi = hiValue?.toString().trim();
    final String? en = enValue?.toString().trim();

    if (isHindi) {
      return (hi != null && hi.isNotEmpty) ? hi : (en ?? '');
    }
    return (en != null && en.isNotEmpty) ? en : (hi ?? '');
  }

  String? _getLocalizedPhotoUrl(
    Map<String, dynamic> record, {
    required bool isHindi,
  }) {
    final dynamic hiValue = record['photo_url_hi'];
    final dynamic enValue = record['photo_url'];

    final String? hi = hiValue?.toString().trim();
    final String? en = enValue?.toString().trim();

    if (isHindi) return (hi != null && hi.isNotEmpty) ? hi : en;
    return (en != null && en.isNotEmpty) ? en : hi;
  }

  @override
  void initState() {
    super.initState();
    _loadBookedAstrologers();
  }

  Future<void> _loadBookedAstrologers() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch booked astrologers for the current user
      dynamic response;
      try {
        response = await _supabase
            .from('astrologer_bookings')
            .select('''
            *,
            astrologers:astrologer_id (
              id,
              name,
              name_hi,
              photo_url,
              photo_url_hi,
              qualification,
              qualification_hi,
              rating,
              experience,
              address,
              address_hi,
              phone_number,
              phone_number_hi,
              priority
            )
          ''')
            .eq('user_id', user.id)
            .eq('booking_status', 'confirmed')
            .order('astrologers.priority', ascending: true);
      } catch (_) {
        response = await _supabase
            .from('astrologer_bookings')
            .select('''
            *,
            astrologers:astrologer_id (
              id,
              name,
              photo_url,
              qualification,
              rating,
              experience,
              address,
              phone_number,
              priority
            )
          ''')
            .eq('user_id', user.id)
            .eq('booking_status', 'confirmed')
            .order('astrologers.priority', ascending: true);
      }

      setState(() {
        _bookedAstrologers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      for (int i = 0; i < _bookedAstrologers.length; i++) {
        final booking = _bookedAstrologers[i];
        final astrologer = booking['astrologers'];
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final whatsappUrl = 'https://wa.me/9129388891';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not installed on your device'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchPhoneCall(String phoneNumber) async {
    final phoneUrl = 'tel:9129388891';

    try {
      final uri = Uri.parse(phoneUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make phone calls on this device'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Astrologers'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bookedAstrologers.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _bookedAstrologers.length,
                itemBuilder: (context, index) {
                  final booking = _bookedAstrologers[index];
                  final astrologer = booking['astrologers'];

                  return _buildBookedAstrologerCard(booking, astrologer);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: Icon(
                Icons.person_search,
                size: 60,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Booked Astrologers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t booked any astrologers yet.\nBook an astrologer to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore),
              label: const Text('Browse Astrologers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookedAstrologerCard(
    Map<String, dynamic> booking,
    Map<String, dynamic> astrologer,
  ) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;

    // Always use the fixed phone number: 9129388891
    final phoneNumber = '9129388891';
    final whatsappNumber = '9129388891';

    final photoUrl = _getLocalizedPhotoUrl(astrologer, isHindi: isHindi);
    final name = _getLocalizedField(astrologer, 'name', isHindi: isHindi);
    final qualification =
        _getLocalizedField(astrologer, 'qualification', isHindi: isHindi);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Astrologer Info
                Row(
                  children: [
                    // Profile Photo
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: photoUrl != null
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(),
                              )
                            : _buildDefaultAvatar(),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Astrologer Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            qualification.isNotEmpty
                                ? qualification
                                : 'Astrologer',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${astrologer['rating'] ?? 5.0}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.work,
                                color: Colors.grey.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getExperienceInYears(
                                  astrologer['experience'] ?? 1,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Booking Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Booking Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Type',
                              booking['booking_type']
                                      ?.toString()
                                      .replaceAll('_', ' ')
                                      .toUpperCase() ??
                                  'N/A',
                              Icons.category,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Amount',
                              '₹${booking['total_amount']?.toStringAsFixed(0) ?? '0'}',
                              Icons.currency_rupee,
                            ),
                          ),
                        ],
                      ),
                      if (booking['minutes_booked'] != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          'Duration',
                          '${booking['minutes_booked']} minutes',
                          Icons.timer,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contact Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchWhatsApp(whatsappNumber),
                        icon: const Icon(Icons.chat, size: 20),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchPhoneCall(phoneNumber),
                        icon: const Icon(Icons.phone, size: 20),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.orange.shade50,
      child: Icon(Icons.person, color: Colors.orange.shade600, size: 35),
    );
  }

  String _getExperienceInYears(int months) {
    if (months < 12) {
      return '$months months exp';
    } else {
      final years = (months / 12).floor();
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years year${years > 1 ? 's' : ''} exp';
      } else {
        return '$years year${years > 1 ? 's' : ''} $remainingMonths months exp';
      }
    }
  }
}
