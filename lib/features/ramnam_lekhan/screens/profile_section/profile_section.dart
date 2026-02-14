// features/ramnam_lekhan/screens/profile_section/profile_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/leaderboard_service.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/certificate_service.dart';
import '../../../../core/services/streak_service.dart';
import '../../widgets/leaderboard_section.dart';
import '../../widgets/streak_section.dart';
import '../favorite_mantras/favorite_mantras_screen.dart';
import '../japa_statistics/japa_statistics_screen.dart';
import '../activity_graph/activity_graph_screen.dart';
import '../certificates/certificates_screen.dart';

class NaamJapaProfileSection extends StatefulWidget {
  const NaamJapaProfileSection({super.key});

  @override
  State<NaamJapaProfileSection> createState() => _NaamJapaProfileSectionState();
}

class _NaamJapaProfileSectionState extends State<NaamJapaProfileSection> {
  DateTime? _userRegistrationDate;

  @override
  void initState() {
    super.initState();
    // Initialize services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leaderboardService = Provider.of<LeaderboardService>(
        context,
        listen: false,
      );
      final streakService = Provider.of<StreakService>(
        context,
        listen: false,
      );

      // Load initial data
      leaderboardService.refreshLeaderboard();
      streakService.refreshStreakData();
      
      // Set user registration date
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.getCurrentUser();
      if (currentUser != null) {
        _userRegistrationDate = DateTime.parse(currentUser.createdAt);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final favoritesService = Provider.of<FavoritesService>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.getCurrentUser();
    final isHindi = languageService.isHindi;

    // Get user name from user metadata or email
    String userName = 'User';
    if (currentUser != null) {
      userName =
          currentUser.userMetadata?['name'] ??
          currentUser.email?.split('@')[0] ??
          'User';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? 'प्रोफाइल' : 'Profile',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFFFB366),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Profile icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFB366),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB366).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFFFFB366),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isHindi ? 'नमस्ते, $userName' : 'Hello, $userName',
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isHindi
                            ? 'अपनी आध्यात्मिक यात्रा को ट्रैक करें'
                            : 'Track your spiritual journey',
                        style: const TextStyle(
                          color: Color(0xFF6C757D),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Streak Section
            const StreakSection(),

            // Leaderboard Section
            const LeaderboardSection(),

            // Additional stats section
            _buildStatsSection(isHindi, favoritesService),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isHindi, FavoritesService favoritesService) {
    final certificateService = Provider.of<CertificateService>(
      context,
      listen: false,
    );
    final streakService = Provider.of<StreakService>(
      context,
      listen: true,
    );
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: const Color(0xFFFFB366),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'आंकड़े' : 'Statistics',
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  isHindi ? 'कुल जाप' : 'Total Japa',
                  '${streakService.totalJapaCount}',
                  Icons.self_improvement_rounded,
                  Colors.blue,
                  onTap: () => _showJapaStatistics(context, isHindi),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  isHindi ? 'दिन सक्रिय' : 'Days Active',
                  '${streakService.daysActive}',
                  Icons.calendar_today_rounded,
                  Colors.green,
                  onTap: () => _showActivityGraph(context, isHindi),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  isHindi ? 'पसंदीदा मंत्र' : 'Favorite Mantras',
                  '${favoritesService.favoritesCount}',
                  Icons.favorite_rounded,
                  Colors.red,
                  onTap: () => _showFavoriteMantras(context, isHindi),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  isHindi ? 'प्रमाणपत्र' : 'Certificates',
                  '${certificateService.certificates.length + certificateService.streakCertificates.length + 5}',
                  Icons.emoji_events_rounded,
                  Colors.amber,
                  onTap: () => _showCertificates(context, isHindi),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavoriteMantras(BuildContext context, bool isHindi) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoriteMantrasScreen()),
    );
  }

  void _showJapaStatistics(BuildContext context, bool isHindi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            JapaStatisticsScreen(userRegistrationDate: _userRegistrationDate),
      ),
    );
  }

  void _showActivityGraph(BuildContext context, bool isHindi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityGraphScreen(userRegistrationDate: _userRegistrationDate),
      ),
    );
  }

  void _showCertificates(BuildContext context, bool isHindi) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CertificatesScreen()),
    );
  }
}
