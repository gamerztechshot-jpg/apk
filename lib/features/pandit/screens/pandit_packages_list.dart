// features/pandit/screens/pandit_packages_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/pandit_package_model.dart';
import '../../../core/services/pandit_package_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/pandit_package_order_service.dart';
import '../../../core/services/auth_service.dart';

class PanditPackagesList extends StatefulWidget {
  const PanditPackagesList({super.key});

  @override
  State<PanditPackagesList> createState() => _PanditPackagesListState();
}

class _PanditPackagesListState extends State<PanditPackagesList> {
  bool _isLoading = true;
  List<PanditPackageModel> _packages = [];
  PanditPackageModel? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages({bool force = false}) async {
    try {
      setState(() => _isLoading = true);
      final service = Provider.of<PanditPackageService>(context, listen: false);
      final items = await service.getPackages(forceRefresh: force);

      setState(() {
        _packages = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading packages: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _packages.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadPackages(force: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _packages.length,
                      itemBuilder: (context, index) {
                        final item = _packages[index];
                        return _SelectablePackageCard(
                          item: item,
                          isSelected: _selectedPackage?.id == item.id,
                          onTap: () => _selectPackage(item),
                        );
                      },
                    ),
                  ),
                ),
                if (_selectedPackage != null) _buildBottomBar(),
              ],
            ),
    );
  }

  void _selectPackage(PanditPackageModel package) {
    setState(() {
      _selectedPackage = package;
    });
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selected Package',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${_selectedPackage!.price}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _handlePayment,
            icon: const Icon(Icons.payment),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            label: const Text(
              'Pay Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_selectedPackage == null) return;

    final auth = context.read<AuthService>();
    final currentUser = auth.getCurrentUser();

    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    try {
      final paymentService = Provider.of<PaymentService>(
        context,
        listen: false,
      );
      final orderService = Provider.of<PanditPackageOrderService>(
        context,
        listen: false,
      );

      // Create Razorpay order
      final order = await paymentService.createRazorpayOrder(
        amount: (_selectedPackage!.price * 100).toInt(),
        currency: 'INR',
        receipt: 'pkg_${_selectedPackage!.id}',
        notes: {
          'package_id': _selectedPackage!.id,
          'user_id': currentUser.id,
          'package_name': _selectedPackage!.name,
        },
      );

      // Create pending order in database
      await orderService.createPendingOrder(
        userId: currentUser.id,
        packageId: _selectedPackage!.id,
        amount: _selectedPackage!.price.toInt(),
        razorpayOrderId: order['id'],
      );

      // Set payment callbacks
      paymentService.onPaymentSuccess = (resp) async {
        try {
          await orderService.markOrderSuccess(
            razorpayOrderId: order['id'],
            razorpayPaymentId: resp.paymentId,
            razorpaySignature: resp.signature,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Payment successful')));
            // Reset selection after successful payment
            setState(() {
              _selectedPackage = null;
            });
          }
        } catch (e) {}
      };

      paymentService.onPaymentError = (resp) async {
        try {
          await orderService.markOrderFailed(
            razorpayOrderId: order['id'],
            reason: resp['error']['description'] ?? 'Payment failed',
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment failed: ${resp['error']['description']}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {}
      };

      // Start payment
      await paymentService.startPayment(
        orderId: order['id'],
        amount: _selectedPackage!.price.toInt(),
        pujaName: _selectedPackage!.name,
        customerName: currentUser.userMetadata?['name'] ?? 'User',
        customerEmail: currentUser.email ?? '',
        customerPhone: currentUser.userMetadata?['phone'] ?? '',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No packages available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check back later',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _SelectablePackageCard extends StatelessWidget {
  final PanditPackageModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectablePackageCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.orange.shade600
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Package Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: Colors.orange.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Package Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Price and Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.price}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
