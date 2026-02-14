// features/dharma_store/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/language_service.dart';
import '../services/cart_service.dart';
import '../widgets/cart_item_widget.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final cartService = Provider.of<CartService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isHindi ? 'कार्ट' : 'Cart',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (cartService.itemCount > 0)
            TextButton(
              onPressed: () {
                cartService.clearCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isHindi ? 'कार्ट साफ़ किया गया' : 'Cart cleared',
                    ),
                  ),
                );
              },
              child: Text(
                isHindi ? 'साफ़ करें' : 'Clear',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: cartService.itemCount == 0
          ? _buildEmptyCart(isHindi)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartService.items.length,
                    itemBuilder: (context, index) {
                      final item = cartService.items[index];
                      return CartItemWidget(
                        item: item,
                        onQuantityChanged: (newQuantity) {
                          cartService.updateQuantity(item.id, newQuantity);
                        },
                        onRemove: () {
                          cartService.removeFromCart(item.id);
                        },
                      );
                    },
                  ),
                ),
                _buildCartSummary(cartService, isHindi),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(bool isHindi) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'आपका कार्ट खाली है' : 'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? 'कुछ उत्पाद जोड़कर शुरू करें'
                : 'Add some products to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isHindi ? 'खरीदारी शुरू करें' : 'Start Shopping',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(CartService cartService, bool isHindi) {
    final subtotal = cartService.totalAmount;
    final shipping = subtotal > 500 ? 0.0 : 50.0; // Free shipping above ₹500
    final total = subtotal + shipping;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'ऑर्डर सारांश' : 'Order Summary',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'सबटोटल:' : 'Subtotal:',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '₹${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'शिपिंग:' : 'Shipping:',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                shipping == 0
                    ? (isHindi ? 'मुफ्त' : 'Free')
                    : '₹${shipping.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: shipping == 0 ? Colors.green : null,
                ),
              ),
            ],
          ),
          if (subtotal < 500) ...[
            const SizedBox(height: 4),
            Text(
              isHindi
                  ? '₹500 से अधिक खरीदारी पर मुफ्त शिपिंग'
                  : 'Free shipping on orders above ₹500',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
            ),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'कुल:' : 'Total:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckoutScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                isHindi ? 'चेकआउट' : 'Checkout',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
