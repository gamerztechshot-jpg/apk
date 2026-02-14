// features/pandit/screens/pandit_packages_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/pandit_package_model.dart';
import '../../../core/widgets/cached_network_image_widget.dart';
import 'package:provider/provider.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/pandit_package_order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PanditPackageDetailScreen extends StatelessWidget {
  final PanditPackageModel package;
  const PanditPackageDetailScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    final ordersService = PanditPackageOrderService();
    final currentUser = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pandit Package'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            CachedNetworkImageWidget(
              imageUrl: package.photoUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.currency_rupee,
                              color: Colors.deepPurple.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              package.price.toString(),
                              style: TextStyle(
                                color: Colors.deepPurple.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Available',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            package.description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please login first')),
                          );
                          return;
                        }
                        try {
                          final order = await paymentService
                              .createRazorpayOrder(
                                amount: (package.price * 100).toInt(),
                                currency: 'INR',
                                receipt: 'pkg_${package.id}',
                                notes: {
                                  'package_id': package.id,
                                  'user_id': currentUser.id,
                                  'package_name': package.name,
                                },
                              );
                          await ordersService.createPendingOrder(
                            userId: currentUser.id,
                            packageId: package.id,
                            amount: package.price.toInt(),
                            razorpayOrderId: order['id'],
                          );
                          paymentService.onPaymentSuccess = (resp) async {
                            await ordersService.markOrderSuccess(
                              razorpayOrderId: order['id'],
                              razorpayPaymentId: resp.paymentId,
                              razorpaySignature: resp.signature,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment successful'),
                                ),
                              );
                            }
                          };
                          paymentService.onPaymentError = (resp) async {
                            await ordersService.markOrderFailed(
                              razorpayOrderId: order['id'],
                              reason: resp.message ?? 'Unknown',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Payment failed: ${resp.message}',
                                  ),
                                ),
                              );
                            }
                          };
                          await paymentService.startPayment(
                            orderId: order['id'],
                            amount: package.price.toInt(),
                            pujaName: package.name,
                            customerName:
                                currentUser.userMetadata?['name'] ?? 'User',
                            customerEmail: currentUser.email ?? '',
                            customerPhone:
                                currentUser.userMetadata?['phone'] ?? '',
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error starting payment: $e'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: const Text(
                        'Book & Pay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
