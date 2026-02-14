// features/punchang/views/panchang_sacred_timings.dart
import 'package:flutter/material.dart';
import '../../../core/models/panchang_model.dart';

class PanchangSacredTimings extends StatelessWidget {
  final PanchangModel panchang;
  final bool isHindi;

  const PanchangSacredTimings({
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
            Icon(Icons.star, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              isHindi ? 'पवित्र समय' : 'Sacred Timings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMuhuratCard(
                isHindi ? 'ब्रह्म मुहूर्त' : 'Brahma Muhurat',
                panchang.brahmaMuhurat,
                isHindi
                    ? 'ध्यान और अध्ययन के लिए सर्वोत्तम'
                    : 'Best for meditation & study',
                Colors.purple,
                Icons.star,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMuhuratCard(
                isHindi ? 'अभिजित मुहूर्त' : 'Abhijit Muhurat',
                panchang.abhijitMuhurat,
                isHindi ? 'विजय और सफलता का समय' : 'Victory & success timing',
                Colors.amber,
                Icons.wb_sunny,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMuhuratCard(
                isHindi ? 'गोधूलि' : 'Godhuli',
                panchang.godhuliMuhurat,
                isHindi ? 'पवित्र शाम का समय' : 'Sacred evening time',
                Colors.orange,
                Icons.wb_twilight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMuhuratCard(
                isHindi ? 'अमृत काल' : 'Amrit Kalam',
                panchang.amritKalam,
                isHindi
                    ? 'अमृत समय - अत्यधिक शुभ'
                    : 'Nectar time - highly auspicious',
                Colors.green,
                Icons.favorite,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMuhuratCard(
    String title,
    String time,
    String description,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
