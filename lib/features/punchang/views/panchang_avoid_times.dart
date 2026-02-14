// features/punchang/views/panchang_avoid_times.dart
import 'package:flutter/material.dart';
import '../../../core/models/panchang_model.dart';

class PanchangAvoidTimes extends StatelessWidget {
  final PanchangModel panchang;
  final bool isHindi;

  const PanchangAvoidTimes({
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
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isHindi ? 'अशुभ समय' : 'Inauspicious Times',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAvoidCard(
                isHindi ? 'राहु काल' : 'Rahu Kaal',
                panchang.rahuKaal,
                Colors.red,
                Icons.block,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAvoidCard(
                isHindi ? 'यमगण्ड काल' : 'Yamaganda Kaal',
                panchang.yamagandaKaal,
                Colors.deepOrange,
                Icons.dangerous,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvoidCard(
    String title,
    String time,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
