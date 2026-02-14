import 'package:flutter/material.dart';
import '../../../model/webinar.dart';

class WebinarBottomBar extends StatelessWidget {
  final Webinar webinar;
  final bool isEnrolled;
  final VoidCallback onAction;

  const WebinarBottomBar({
    super.key,
    required this.webinar,
    required this.isEnrolled,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: _buildPriceSection()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildActionButton()),
          ],
        ),
      ),
    );
  }

  // ---------------- PRICE SECTION ----------------
  Widget _buildPriceSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (webinar.price > webinar.actualPrice)
          Row(
            children: [
              Text(
                '₹${webinar.price}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_calculateDiscount(webinar.price, webinar.actualPrice)}% OFF',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        Text(
          webinar.price == 0 ? 'Free' : '₹${webinar.actualPrice}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // ---------------- ACTION BUTTON ----------------
  Widget _buildActionButton() {
    if (isEnrolled) {
      final state = webinar.webinarState.toLowerCase();
      String label = 'Join Now';
      IconData icon = Icons.videocam;
      Color color = Colors.red.shade600;

      if (state == 'completed') {
        label = 'Watch Recording';
        icon = Icons.play_circle_fill;
        color = Colors.blue.shade600;
      }

      return ElevatedButton(
        onPressed: onAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 20),
          SizedBox(width: 8),
          Text(
            'Register Now',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ---------------- DISCOUNT ----------------
  static int _calculateDiscount(double original, double current) {
    if (original <= 0) return 0;
    return ((original - current) / original * 100).round();
  }
}
