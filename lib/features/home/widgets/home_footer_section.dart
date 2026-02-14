// features/home/widgets/home_footer_section.dart
import 'package:flutter/material.dart';

class HomeFooterSection extends StatelessWidget {
  final VoidCallback onBackToTop;

  const HomeFooterSection({super.key, required this.onBackToTop});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;

    return Container(
      margin: EdgeInsets.fromLTRB(horizontalMargin, 16, horizontalMargin, 24),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28 : 22,
        vertical: isTablet ? 28 : 22,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade100.withOpacity(0.6),
            Colors.orange.shade50,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FooterHighlight(
                  icon: Icons.star_border,
                  text:
                      'Trusted by lakhs\nof devotees\nworldwide',
                ),
              ),
              Expanded(
                child: _FooterHighlight(
                  icon: Icons.verified_outlined,
                  text:
                      '100+ Verified\nPandits from\nRenowned\nTemples',
                ),
              ),
              Expanded(
                child: _FooterHighlight(
                  icon: Icons.translate_outlined,
                  text:
                      'Personalised to\nyour region,\nlanguage, and\ntradition',
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Eternal Dharma, modern tech - A Bhagiratha Effort',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          OutlinedButton.icon(
            onPressed: onBackToTop,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
              side: BorderSide(color: Colors.orange.shade200),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 22 : 18,
                vertical: isTablet ? 14 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.arrow_upward, size: 18),
            label: const Text(
              'BACK TO TOP',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterHighlight extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FooterHighlight({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.amber.shade600,
          size: isTablet ? 32 : 28,
        ),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
