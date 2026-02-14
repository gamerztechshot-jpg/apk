// features/punchang/views/panchang_guidance.dart
import 'package:flutter/material.dart';
import '../../../core/models/panchang_model.dart';

class PanchangGuidance extends StatelessWidget {
  final PanchangModel panchang;
  final bool isHindi;

  const PanchangGuidance({
    super.key,
    required this.panchang,
    required this.isHindi,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.explore, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              isHindi ? 'दिशा और निवास' : 'Direction & Residence',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            children: [
              _buildGuidanceRow(
                isHindi ? 'दिशाशूल' : 'Disha Shool',
                panchang.dishaShool,
                Icons.near_me_disabled,
                Colors.red,
              ),
              const Divider(height: 24),
              _buildGuidanceRow(
                isHindi ? 'चंद्र निवास' : 'Chandra Nivas',
                panchang.chandraNivas,
                Icons.home,
                Colors.blue,
              ),
              const Divider(height: 24),
              _buildGuidanceRow(
                isHindi ? 'अयन' : 'Ayan',
                panchang.ayan,
                Icons.public,
                Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceRow(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
