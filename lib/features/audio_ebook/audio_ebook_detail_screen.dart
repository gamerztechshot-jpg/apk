// features/audio_ebook/audio_ebook_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/audio_ebook_model.dart';
import '../../core/services/auth_service.dart';
import 'audio_ebook_payment.dart';
import 'pdf_viewer_screen.dart';
import 'audio_player_screen.dart';

class AudioEbookDetailScreen extends StatefulWidget {
  final AudioEbookModel item;

  const AudioEbookDetailScreen({super.key, required this.item});

  @override
  State<AudioEbookDetailScreen> createState() => _AudioEbookDetailScreenState();
}

class _AudioEbookDetailScreenState extends State<AudioEbookDetailScreen> {
  final AudioEbookPaymentService _paymentService = AudioEbookPaymentService();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isPurchased = false;
  bool _isCheckingPurchase = true;

  @override
  void initState() {
    super.initState();
    _initializePaymentService();
    _checkPurchaseStatus();
  }

  void _initializePaymentService() {
    _paymentService.onPaymentSuccess = _handlePaymentSuccess;
    _paymentService.onPaymentError = _handlePaymentError;
  }

  Future<void> _checkPurchaseStatus() async {
    try {
      // Get real user data from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      if (user == null) {
        setState(() {
          _isPurchased = false;
          _isCheckingPurchase = false;
        });
        return;
      }

      final isPurchased = await _paymentService.isItemPurchased(
        userId: user.id,
        itemId: widget.item.id,
        itemType: widget.item.type,
      );

      setState(() {
        _isPurchased = isPurchased;
        _isCheckingPurchase = false;
      });
    } catch (e) {
      setState(() {
        _isPurchased = false;
        _isCheckingPurchase = false;
      });
    }
  }

  void _handlePaymentSuccess(dynamic response) async {
    setState(() {
      _isPurchased = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment successful! You can now access ${widget.item.title}',
        ),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  void _handlePaymentError(dynamic response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  void _initiatePayment() async {
    if (widget.item.amount == null) return;

    try {
      // Get real user data from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.getCurrentUser();

      if (user == null) {
        _showErrorDialog('Please login to make a purchase');
        return;
      }

      // Get user profile data
      final userProfile = await _getUserProfile(user.id);

      final customerName =
          userProfile?['display_name'] ?? user.userMetadata?['name'] ?? 'User';
      final customerEmail = userProfile?['email'] ?? user.email!;
      final customerPhone =
          userProfile?['phone'] ?? user.userMetadata?['phone'] ?? '';

      // Navigate to payment screen with real user data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioEbookPaymentScreen(
            item: widget.item,
            userId: user.id,
            customerName: customerName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Error getting user data: $e');
    }
  }

  void _openContent() {
    if (widget.item.type == 'Audio') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(
            audioUrl: widget.item.url,
            title: widget.item.title,
            coverImage: widget.item.displayImage,
            author: 'Unknown', // You can get this from item data
            language: 'Hindi', // You can get this from item data
            rating: 4.5, // You can get this from item data
            duration: '2 hours', // You can get this from item data
            category: widget.item.category,
            audioId: widget.item.id,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(
            pdfUrl: widget.item.url,
            title: widget.item.title,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.item.displayImage.isNotEmpty
                      ? Image.network(
                          widget.item.displayImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                widget.item.type == 'Audio'
                                    ? Icons.headphones
                                    : Icons.menu_book,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            widget.item.type == 'Audio'
                                ? Icons.headphones
                                : Icons.menu_book,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Type Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.item.type == 'Audio'
                          ? Colors.blue.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.item.type == 'Audio'
                            ? Colors.blue.shade300
                            : Colors.green.shade300,
                      ),
                    ),
                    child: Text(
                      widget.item.type,
                      style: TextStyle(
                        color: widget.item.type == 'Audio'
                            ? Colors.blue.shade700
                            : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category and Language
              Row(
                children: [
                  _buildInfoChip(
                    'Category',
                    widget.item.category,
                    Icons.category,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    'Language',
                    widget.item.language,
                    Icons.language,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Read/Play Buttons
              _buildReadPlayButtons(),
              const SizedBox(height: 16),

              // Price and Stats
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            widget.item.paid
                                ? Icons.paid
                                : Icons.free_breakfast,
                            color: widget.item.paid
                                ? Colors.orange.shade600
                                : Colors.green.shade600,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.item.paid ? 'Premium' : 'Free',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.item.paid
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            widget.item.type == 'Audio'
                                ? Icons.headset
                                : Icons.visibility,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.item.countText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.item.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.orange.shade600),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadPlayButtons() {
    if (_isCheckingPurchase) {
      return const Center(child: CircularProgressIndicator());
    }

    // Check if user can access content
    final canAccess = !widget.item.paid || _isPurchased;

    return Row(
      children: [
        // Read Ebook Button (for ebooks)
        if (widget.item.type == 'Ebook') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canAccess ? _openContent : _initiatePayment,
              icon: const Icon(Icons.menu_book),
              label: Text(canAccess ? 'Read Ebook' : 'Purchase to Read'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ] else ...[
          // Play Audio Button (for audiobooks)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canAccess ? _openContent : _initiatePayment,
              icon: const Icon(Icons.play_arrow),
              label: Text(canAccess ? 'Play Audio' : 'Purchase to Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isCheckingPurchase) {
      return const Center(child: CircularProgressIndicator());
    }

    // Check if user can access content
    final canAccess = !widget.item.paid || _isPurchased;

    return Column(
      children: [
        // Purchase button (only show if not purchased and is paid)
        if (!canAccess && widget.item.paid) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _initiatePayment,
              icon: const Icon(Icons.payment),
              label: Text('Purchase for ₹${widget.item.amount}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Share button (always available)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Share ${widget.item.title}'),
                  backgroundColor: Colors.blue.shade600,
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade600,
              side: BorderSide(color: Colors.orange.shade600),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Get user profile data from Supabase
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      // Try different possible column names for user ID
      final response = await _supabase
          .from('profiles')
          .select('display_name, email, phone')
          .eq('user_id', userId) // Try user_id instead of id
          .single();

      return response;
    } catch (e) {
      // If user_id doesn't work, try id
      try {
        final response = await _supabase
            .from('profiles')
            .select('display_name, email, phone')
            .eq('id', userId)
            .single();

        return response;
      } catch (e2) {
        return null;
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
