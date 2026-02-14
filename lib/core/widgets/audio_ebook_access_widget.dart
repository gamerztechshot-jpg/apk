// core/widgets/audio_ebook_access_widget.dart
import 'package:flutter/material.dart';
import '../models/audio_ebook_model.dart';
import '../services/audio_ebook_access_service.dart';
import '../../features/audio_ebook/audio_ebook_payment.dart';

class AudioEbookAccessWidget extends StatefulWidget {
  final AudioEbookModel item;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final VoidCallback? onAccessGranted;
  final VoidCallback? onPurchaseRequired;

  const AudioEbookAccessWidget({
    super.key,
    required this.item,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.onAccessGranted,
    this.onPurchaseRequired,
  });

  @override
  State<AudioEbookAccessWidget> createState() => _AudioEbookAccessWidgetState();
}

class _AudioEbookAccessWidgetState extends State<AudioEbookAccessWidget> {
  final AudioEbookAccessService _accessService = AudioEbookAccessService();
  Map<String, dynamic>? _accessInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccessInfo();
  }

  Future<void> _loadAccessInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final accessInfo = await _accessService.getAccessInfo(
        userId: widget.userId,
        item: widget.item,
      );

      setState(() {
        _accessInfo = accessInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePurchase() async {
    try {
      // Navigate to payment screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioEbookPaymentScreen(
            item: widget.item,
            userId: widget.userId,
            customerName: widget.customerName,
            customerEmail: widget.customerEmail,
            customerPhone: widget.customerPhone,
          ),
        ),
      );

      // Refresh access info after payment
      if (result == true) {
        await _loadAccessInfo();
        widget.onAccessGranted?.call();
      }
    } catch (e) {
      _showErrorDialog('Failed to process purchase: $e');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_accessInfo == null) {
      return _buildErrorWidget();
    }

    final hasAccess = _accessInfo!['hasAccess'] as bool;
    final isFree = _accessInfo!['isFree'] as bool;
    final isPurchased = _accessInfo!['isPurchased'] as bool;
    final requiresPurchase = _accessInfo!['requiresPurchase'] as bool;

    return _buildAccessWidget(
      hasAccess: hasAccess,
      isFree: isFree,
      isPurchased: isPurchased,
      requiresPurchase: requiresPurchase,
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking access...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Unable to check access',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please try again later',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAccessInfo,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessWidget({
    required bool hasAccess,
    required bool isFree,
    required bool isPurchased,
    required bool requiresPurchase,
  }) {
    if (hasAccess) {
      return _buildAccessGrantedWidget(
        isFree: isFree,
        isPurchased: isPurchased,
      );
    } else if (requiresPurchase) {
      return _buildPurchaseRequiredWidget();
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildAccessGrantedWidget({
    required bool isFree,
    required bool isPurchased,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isFree ? 'Free Content' : 'Purchased Content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isFree
                ? 'This content is available for free'
                : 'You have lifetime access to this content',
            style: TextStyle(fontSize: 14, color: Colors.green.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onAccessGranted?.call();
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                widget.item.type == 'Audio' ? 'Play Audio' : 'Read Ebook',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseRequiredWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Premium Content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Purchase this ${widget.item.type.toLowerCase()} for lifetime access',
            style: TextStyle(fontSize: 14, color: Colors.orange.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Price: ',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                widget.item.priceText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handlePurchase,
              icon: const Icon(Icons.shopping_cart),
              label: Text('Purchase ${widget.item.type}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple access check widget for displaying purchase status
class AudioEbookPurchaseStatusWidget extends StatelessWidget {
  final AudioEbookModel item;
  final String userId;
  final bool showPurchaseButton;
  final VoidCallback? onPurchasePressed;

  const AudioEbookPurchaseStatusWidget({
    super.key,
    required this.item,
    required this.userId,
    this.showPurchaseButton = true,
    this.onPurchasePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!item.paid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'FREE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      );
    }

    return FutureBuilder<bool>(
      future: _checkPurchaseStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final isPurchased = snapshot.data ?? false;

        if (isPurchased) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  'PURCHASED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.priceText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              if (showPurchaseButton) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onPurchasePressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BUY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        }
      },
    );
  }

  Future<bool> _checkPurchaseStatus() async {
    try {
      final accessService = AudioEbookAccessService();
      return await accessService.hasAccess(userId: userId, item: item);
    } catch (e) {
      return false;
    }
  }
}
