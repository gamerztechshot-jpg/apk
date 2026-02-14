// features/home/widgets/home_feature_cards.dart
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../audio_ebook/audio_ebook_screen.dart';
import '../../dharma_store/screens/store_home_screen.dart';
import '../../puja_booking/puja_list.dart';
import '../../punchang/punnchang.dart';
import '../../sadhna/sadhna.dart';

class HomeFeatureCards extends StatelessWidget {
  final AppLocalizations l10n;

  const HomeFeatureCards({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: Column(
        children: [
          // First row - Sadhna and Puja/Paath
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  context,
                  l10n.sadhnaTitle,
                  l10n.sadhnaSubtitle,
                  'assets/images/sadhna.png',
                  Colors.orange,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _buildFeatureCard(
                  context,
                  l10n.pujaPaathTitle,
                  l10n.pujaPaathSubtitle,
                  'assets/images/puja.png',
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          // Second row - Vedalay (left) and Panchang+Samagri (right)
          Row(
            children: [
              // Vedalay card - same size as Sadhna
              Expanded(
                child: _buildFeatureCard(
                  context,
                  l10n.vedalayTitle,
                  l10n.vedalaySubtitle,
                  'assets/images/vedalay.png',
                  Colors.orange,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              // Right side - Panchang and Samagri stacked vertically
              Expanded(
                child: Column(
                  children: [
                    _buildSmallFeatureCard(
                      context,
                      l10n.panchangTitle,
                      l10n.panchangSubtitle,
                      'assets/images/punchang.png',
                      Colors.orange,
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    _buildSmallFeatureCard(
                      context,
                      l10n.samagriTitle,
                      l10n.samagriSubtitle,
                      'assets/images/samagri.png',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    String imagePath,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardHeight = isTablet ? 180.0 : 160.0;

    return GestureDetector(
      onTap: () {
        if (title == l10n.pujaPaathTitle) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PujaListScreen()),
          );
        } else if (title == l10n.sadhnaTitle) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SadhnaScreen()),
          );
        } else if (title == l10n.vedalayTitle) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AudioEbookScreen()),
          );
        } else {
          _showSnackBar(context, '$title feature will be implemented soon!');
        }
      },
      child: Container(
        height: cardHeight,
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.orange.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow at left end, image at right end
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 8 : 6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: isTablet ? 18 : 16,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      imagePath,
                      width: isTablet ? 32 : 28,
                      height: isTablet ? 32 : 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    String imagePath,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardHeight = isTablet ? 80.0 : 70.0;

    return GestureDetector(
      onTap: () {
        if (title == l10n.panchangTitle) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PanchangScreen()),
          );
        } else if (title == l10n.samagriTitle) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StoreHomeScreen()),
          );
        } else {
          _showSnackBar(context, '$title feature will be implemented soon!');
        }
      },
      child: Container(
        height: cardHeight,
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image on the left
            Container(
              padding: EdgeInsets.all(isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                imagePath,
                width: isTablet ? 24 : 20,
                height: isTablet ? 24 : 20,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 10),
            // Title and subtitle in the middle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow on the right
            Container(
              padding: EdgeInsets.all(isTablet ? 6 : 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: isTablet ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
