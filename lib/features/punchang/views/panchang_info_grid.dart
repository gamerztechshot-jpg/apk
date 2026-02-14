// features/punchang/views/panchang_info_grid.dart
import 'package:flutter/material.dart';
import '../../../core/models/panchang_model.dart';
import '../viewmodels/panchang_viewmodel.dart';

class PanchangInfoGrid extends StatelessWidget {
  final PanchangModel panchang;
  final bool isHindi;
  final PanchangViewModel viewModel;

  const PanchangInfoGrid({
    super.key,
    required this.panchang,
    required this.isHindi,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildInfoCard(
          isHindi ? 'नक्षत्र' : 'Nakshatra',
          panchang.nakshatra,
          Icons.star_outline,
          Colors.purple,
          isHindi ? 'शासक नक्षत्र' : 'Ruling Constellation',
        ),
        _buildInfoCard(
          isHindi ? 'सूर्य राशि' : 'Sun Sign',
          panchang.suryaRashi,
          Icons.wb_sunny_outlined,
          Colors.orange,
          isHindi ? 'सूर्य की राशि' : 'Sun Sign',
        ),
        _buildInfoCard(
          isHindi ? 'चंद्र राशि' : 'Moon Sign',
          panchang.chandraRashi,
          Icons.nightlight_outlined,
          Colors.blue,
          isHindi ? 'चंद्र की राशि' : 'Moon Sign',
        ),
        _buildInfoCard(
          isHindi ? 'पक्ष' : 'Paksha',
          viewModel.getPaksha(panchang.tithi, isHindi),
          Icons.brightness_6_outlined,
          Colors.teal,
          isHindi ? 'चंद्र पक्ष' : 'Lunar Fortnight',
        ),
      ],
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
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 6),
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
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
