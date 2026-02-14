// features/home/widgets/home_bottom_banner.dart
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../ramnam_lekhan/screens/ramnam_lekhan/ramnam_lekhan_screen.dart';

class HomeBottomBanner extends StatelessWidget {
  final AppLocalizations l10n;

  const HomeBottomBanner({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final margin = isTablet ? 40.0 : 20.0;
    final padding = isTablet ? 32.0 : 24.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NaamJapaScreen()),
        );
      },
      child: Container(
        margin: EdgeInsets.all(margin),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.startYourDayWith,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.naamJapa,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 32 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.bannerSubtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: isTablet ? 28 : 24,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward,
                color: Colors.orange,
                size: isTablet ? 24 : 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
