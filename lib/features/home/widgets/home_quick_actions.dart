// features/home/widgets/home_quick_actions.dart
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/notifications_screen.dart';
import '../../profile/profile.dart';
import '../../teacher/views/acharya_screen.dart';

class HomeQuickActions extends StatelessWidget {
  final AppLocalizations l10n;

  const HomeQuickActions({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;
    final cardHeight = isTablet ? 120.0 : 100.0;
    final iconSize = isTablet ? 32.0 : 28.0;
    final labelSize = isTablet ? 14.0 : 12.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              height: cardHeight,
              icon: Icons.menu_book_outlined,
              label: 'Learn More',
              iconSize: iconSize,
              labelSize: labelSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AcharyaScreen()),
                );
              },
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: _QuickActionCard(
              height: cardHeight,
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              iconSize: iconSize,
              labelSize: labelSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: _QuickActionCard(
              height: cardHeight,
              icon: Icons.settings_outlined,
              label: l10n.settings,
              iconSize: iconSize,
              labelSize: labelSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final double height;
  final IconData icon;
  final String label;
  final double iconSize;
  final double labelSize;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.height,
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.labelSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.orange.shade600, size: iconSize),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
