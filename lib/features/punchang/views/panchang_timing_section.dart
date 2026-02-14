// features/punchang/views/panchang_timing_section.dart
import 'package:flutter/material.dart';
import '../../../core/models/panchang_model.dart';

class PanchangTimingSection extends StatelessWidget {
  final PanchangModel panchang;
  final bool isHindi;

  const PanchangTimingSection({
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
            Icon(Icons.wb_twilight, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              isHindi ? 'सूर्य  और चंद्रमा' : 'Sun & Moon',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSunMoonCard(
                isHindi ? 'सूर्योदय' : 'Sunrise',
                panchang.sunrise,
                Icons.wb_sunny,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSunMoonCard(
                isHindi ? 'सूर्यास्त' : 'Sunset',
                panchang.sunset,
                Icons.wb_twilight,
                Colors.deepOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSunMoonCard(
                isHindi ? 'चन्द्रोदय' : 'Moonrise',
                panchang.moonrise,
                Icons.nightlight_round,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSunMoonCard(
                isHindi ? 'चन्द्रास्त' : 'Moonset',
                panchang.moonset,
                Icons.mode_night,
                Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Karan and Yoga
        Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              isHindi ? 'करण और योग' : 'Karan & Yoga',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                isHindi ? 'करण' : 'Karan',
                panchang.karan,
                Icons.grain,
                Colors.purple,
                isHindi ? 'आधा तिथि' : 'Half Tithi',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                isHindi ? 'योग' : 'Yoga',
                panchang.yoga,
                Icons.spa,
                Colors.teal,
                isHindi ? 'शुभ संयोग' : 'Auspicious Union',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSunMoonCard(
    String title,
    String time,
    IconData icon,
    Color color,
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color color,
    String subtitle,
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
