// features/pandit/widgets/pandit_dashboard.dart
import 'package:flutter/material.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../screens/my_family_pandit_screen.dart';
import '../screens/pandit_list_screen.dart';
import '../screens/spiritual_diary_screen.dart';
import '../screens/todays_puja_screen.dart';

class PanditDashboard extends StatelessWidget {
  const PanditDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.temple_hindu, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.spiritualServices,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ),
        // Dashboard Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // First Row
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      context,
                      l10n.bookPanditJi,
                      l10n.connectWithSpiritualGuide,
                      Icons.person,
                      Colors.orange.shade600,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PanditListScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDashboardCard(
                      context,
                      l10n.spiritualDiary,
                      l10n.trackSpiritualJourney,
                      Icons.book,
                      Colors.orange.shade600,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SpiritualDiaryScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second Row
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      context,
                      l10n.todaysPujaSuggestion,
                      l10n.discoverTodaysAuspiciousPujas,
                      Icons.temple_hindu,
                      Colors.orange.shade600,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TodaysPujaScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDashboardCard(
                      context,
                      l10n.myFamilyPandit,
                      l10n.viewAssignedPanditDetails,
                      Icons.group,
                      Colors.orange.shade600,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyFamilyPanditScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Bounded height required because Column uses Spacer; set larger height to avoid overflow
        height: 150,
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Arrow
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
