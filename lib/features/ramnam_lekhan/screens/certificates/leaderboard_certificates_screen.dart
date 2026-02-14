// features/ramnam_lekhan/screens/certificates/leaderboard_certificates_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/leaderboard_certificate_model.dart';
import '../../../../core/services/leaderboard_certificate_service.dart';
import '../../../../core/services/language_service.dart';

class LeaderboardCertificatesScreen extends StatefulWidget {
  const LeaderboardCertificatesScreen({super.key});

  @override
  State<LeaderboardCertificatesScreen> createState() =>
      _LeaderboardCertificatesScreenState();
}

class _LeaderboardCertificatesScreenState
    extends State<LeaderboardCertificatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ActiveLeaderboardCertificate> _userCertificates = [];
  bool _userCertificatesLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_userCertificatesLoaded) {
      // Load user certificates when "My Certificates" tab is selected
      _loadUserCertificates();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final service = Provider.of<LeaderboardCertificateService>(
      context,
      listen: false,
    );
    await Future.wait([
      service.loadCertificateTypes(),
      service.loadCurrentCertificateHolders(),
      service.loadUserCertificateHistory(),
    ]);

    // Load user certificates separately
    await _loadUserCertificates();

    // Manually trigger notifications after all data is loaded
    service.notifyStateChanged();
  }

  Future<void> _loadUserCertificates() async {
    final service = Provider.of<LeaderboardCertificateService>(
      context,
      listen: false,
    );
    try {
      final certificates = await service.loadUserCurrentCertificates();

      if (mounted) {
        setState(() {
          _userCertificates = certificates;
          _userCertificatesLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userCertificates = [];
          _userCertificatesLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? 'लीडरबोर्ड प्रमाणपत्र' : 'Leaderboard Certificates',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: isHindi ? 'प्रमाणपत्र जानकारी' : 'Certificate Info',
              icon: Icon(Icons.info_outline, size: 20),
            ),
            Tab(
              text: isHindi ? 'मेरे प्रमाणपत्र' : 'My Certificates',
              icon: Icon(Icons.person, size: 20),
            ),
            Tab(
              text: isHindi ? 'इतिहास' : 'History',
              icon: Icon(Icons.history, size: 20),
            ),
          ],
        ),
      ),
      body: Consumer<LeaderboardCertificateService>(
        builder: (context, service, child) {
          if (service.isLoading &&
              service.activeCertificates.isEmpty &&
              service.certificateTypes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    service.error!,
                    style: TextStyle(color: Colors.red.shade600, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCertificateInfoTab(service, isHindi),
              _buildMyCertificatesTab(service, isHindi),
              _buildHistoryTab(service, isHindi),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCertificateInfoTab(
    LeaderboardCertificateService service,
    bool isHindi,
  ) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Professional Header
          _buildProfessionalHeader(isHindi),

          const SizedBox(height: 24),

          // Certificate Information Cards
          if (service.certificateTypes.isEmpty)
            _buildEmptyState(
              icon: Icons.info_outline,
              title: isHindi ? 'कोई जानकारी नहीं' : 'No Information',
              subtitle: isHindi
                  ? 'प्रमाणपत्र प्रकार लोड हो रहे हैं'
                  : 'Certificate types are loading',
            )
          else
            ...service.certificateTypes.map((certificateType) {
              return _buildProfessionalCertificateCard(
                certificateType,
                isHindi,
              );
            }).toList(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader(bool isHindi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.purple.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade500, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.emoji_events, color: Colors.white, size: 40),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            isHindi ? 'लीडरबोर्ड प्रमाणपत्र' : 'Leaderboard Certificates',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              isHindi
                  ? 'अपनी साधना में उत्कृष्टता के लिए प्रमाणपत्र प्राप्त करें'
                  : 'Earn certificates for excellence in your spiritual practice',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            isHindi
                ? 'नीचे दिए गए प्रमाणपत्रों के बारे में जानें और अपने लक्ष्य निर्धारित करें'
                : 'Learn about the certificates below and set your goals',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalCertificateCard(
    LeaderboardCertificateModel certificateType,
    bool isHindi,
  ) {
    // Get professional color scheme for each certificate type
    Color primaryColor;
    Color backgroundColor;
    IconData cardIcon;
    String category;

    switch (certificateType.typeCode) {
      case 'daily':
        primaryColor = Colors.orange.shade600;
        backgroundColor = Colors.orange.shade50;
        cardIcon = Icons.wb_sunny;
        category = isHindi ? 'दैनिक' : 'Daily';
        break;
      case 'weekly':
        primaryColor = Colors.grey.shade700;
        backgroundColor = Colors.grey.shade50;
        cardIcon = Icons.calendar_view_week;
        category = isHindi ? 'साप्ताहिक' : 'Weekly';
        break;
      case 'monthly':
        primaryColor = Colors.grey.shade600;
        backgroundColor = Colors.grey.shade50;
        cardIcon = Icons.calendar_view_month;
        category = isHindi ? 'मासिक' : 'Monthly';
        break;
      case 'yearly':
        primaryColor = Colors.orange.shade500;
        backgroundColor = Colors.orange.shade50;
        cardIcon = Icons.calendar_today;
        category = isHindi ? 'वार्षिक' : 'Yearly';
        break;
      case 'alltime':
        primaryColor = Colors.orange.shade700;
        backgroundColor = Colors.orange.shade50;
        cardIcon = Icons.emoji_events;
        category = isHindi ? 'सभी समय' : 'All-Time';
        break;
      default:
        primaryColor = Colors.grey.shade600;
        backgroundColor = Colors.grey.shade50;
        cardIcon = Icons.help_outline;
        category = isHindi ? 'अन्य' : 'Other';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(cardIcon, color: Colors.white, size: 32),
                ),

                const SizedBox(width: 20),

                // Title and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi
                            ? certificateType.certificateNameHi
                            : certificateType.certificateNameEn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Certificate Details
                _buildProfessionalInfoRow(
                  icon: Icons.schedule,
                  label: isHindi ? 'गणना समय' : 'Calculation Time',
                  value: certificateType.calculationTime,
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 20),

                _buildProfessionalInfoRow(
                  icon: Icons.timer,
                  label: isHindi ? 'वैधता अवधि' : 'Validity Period',
                  value: certificateType.validityPeriod,
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 20),

                _buildProfessionalInfoRow(
                  icon: Icons.emoji_events,
                  label: isHindi ? 'पुरस्कार मानदंड' : 'Award Criteria',
                  value: _getCertificateCriteria(
                    certificateType.typeCode,
                    isHindi,
                  ),
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 20),

                _buildProfessionalInfoRow(
                  icon: Icons.info_outline,
                  label: isHindi ? 'विवरण' : 'Description',
                  value: _getCertificateDescription(
                    certificateType.typeCode,
                    isHindi,
                  ),
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCertificateCriteria(String typeCode, bool isHindi) {
    switch (typeCode) {
      case 'daily':
        return isHindi
            ? 'दिन के अंत में सबसे अधिक जप करने वाला व्यक्ति'
            : 'Person with highest japa count at end of day';
      case 'weekly':
        return isHindi
            ? 'सप्ताह के अंत में सबसे अधिक जप करने वाला व्यक्ति'
            : 'Person with highest japa count at end of week';
      case 'monthly':
        return isHindi
            ? 'महीने के अंत में सबसे अधिक जप करने वाला व्यक्ति'
            : 'Person with highest japa count at end of month';
      case 'yearly':
        return isHindi
            ? 'वर्ष के अंत में सबसे अधिक जप करने वाला व्यक्ति'
            : 'Person with highest japa count at end of year';
      case 'alltime':
        return isHindi
            ? 'सभी समय में सबसे अधिक जप करने वाला व्यक्ति'
            : 'Person with highest japa count of all time';
      default:
        return isHindi
            ? 'लीडरबोर्ड में #1 स्थान'
            : '#1 position in leaderboard';
    }
  }

  String _getCertificateDescription(String typeCode, bool isHindi) {
    switch (typeCode) {
      case 'daily':
        return isHindi
            ? 'दैनिक लीडरबोर्ड में #1 स्थान प्राप्त करने वाले को दिया जाता है'
            : 'Awarded to the #1 position in daily leaderboard';
      case 'weekly':
        return isHindi
            ? 'साप्ताहिक लीडरबोर्ड में #1 स्थान प्राप्त करने वाले को दिया जाता है'
            : 'Awarded to the #1 position in weekly leaderboard';
      case 'monthly':
        return isHindi
            ? 'मासिक लीडरबोर्ड में #1 स्थान प्राप्त करने वाले को दिया जाता है'
            : 'Awarded to the #1 position in monthly leaderboard';
      case 'yearly':
        return isHindi
            ? 'वार्षिक लीडरबोर्ड में #1 स्थान प्राप्त करने वाले को दिया जाता है'
            : 'Awarded to the #1 position in yearly leaderboard';
      case 'alltime':
        return isHindi
            ? 'सभी समय के लीडरबोर्ड में #1 स्थान प्राप्त करने वाले को दिया जाता है'
            : 'Awarded to the #1 position in all-time leaderboard';
      default:
        return isHindi ? 'लीडरबोर्ड प्रमाणपत्र' : 'Leaderboard certificate';
    }
  }

  Widget _buildMyCertificatesHeader(bool isHindi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.purple.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            isHindi ? 'मेरे प्रमाणपत्र' : 'My Certificates',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              isHindi
                  ? 'आपके द्वारा प्राप्त किए गए प्रमाणपत्र'
                  : 'Certificates you have earned',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            isHindi
                ? 'आपके वर्तमान प्रमाणपत्रों को देखें और उनकी जानकारी प्राप्त करें'
                : 'View your current certificates and their details',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalMyCertificateCard(
    ActiveLeaderboardCertificate certificate,
    LeaderboardCertificateModel certificateType,
    bool isHindi,
  ) {
    // Get professional color scheme for each certificate type
    Color primaryColor;
    Color backgroundColor;
    IconData cardIcon;
    String category;

    switch (certificateType.typeCode) {
      case 'daily':
        primaryColor = Colors.orange.shade600;
        backgroundColor = Colors.orange.shade50;
        cardIcon = Icons.wb_sunny;
        category = isHindi ? 'दैनिक' : 'Daily';
        break;
      case 'weekly':
        primaryColor = Colors.grey.shade700;
        backgroundColor = Colors.grey.shade50;
        cardIcon = Icons.calendar_view_week;
        category = isHindi ? 'साप्ताहिक' : 'Weekly';
        break;
      case 'monthly':
        primaryColor = Colors.grey.shade600;
        backgroundColor = Colors.grey.shade50;
        cardIcon = Icons.calendar_view_month;
        category = isHindi ? 'मासिक' : 'Monthly';
        break;
      case 'yearly':
        primaryColor = Colors.orange.shade500;
        backgroundColor = Colors.orange.shade50;
        cardIcon = Icons.calendar_today;
        category = isHindi ? 'वार्षिक' : 'Yearly';
        break;
      case 'alltime':
        primaryColor = Colors.orange.shade700;
        backgroundColor = Colors.orange.shade50;
        cardIcon = Icons.emoji_events;
        category = isHindi ? 'सभी समय' : 'All-Time';
        break;
      default:
        primaryColor = Colors.grey.shade600;
        backgroundColor = Colors.grey.shade50;
        cardIcon = Icons.help_outline;
        category = isHindi ? 'अन्य' : 'Other';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(cardIcon, color: Colors.white, size: 32),
                ),

                const SizedBox(width: 20),

                // Title and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi
                            ? certificateType.certificateNameHi
                            : certificateType.certificateNameEn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isHindi ? 'सक्रिय' : 'Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Certificate Details
                _buildProfessionalInfoRow(
                  icon: Icons.emoji_events,
                  label: isHindi ? 'रैंक' : 'Rank',
                  value: '#${certificate.rankPosition}',
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 20),

                _buildProfessionalInfoRow(
                  icon: Icons.favorite,
                  label: isHindi ? 'जप संख्या' : 'Japa Count',
                  value:
                      '${certificate.formattedJapaCount} ${isHindi ? 'जप' : 'Japas'}',
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 20),

                _buildProfessionalInfoRow(
                  icon: Icons.calendar_today,
                  label: isHindi ? 'अवधि' : 'Period',
                  value: certificate.formattedPeriod,
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 20),

                _buildProfessionalInfoRow(
                  icon: Icons.schedule,
                  label: isHindi ? 'प्राप्ति तिथि' : 'Awarded Date',
                  value: _formatDate(certificate.awardedAt),
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 24),

                // Download Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          _downloadCertificate(certificate, certificateType),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isHindi
                                ? 'प्रमाणपत्र डाउनलोड करें'
                                : 'Download Certificate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(bool isHindi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.purple.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.purple.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.history, color: Colors.white, size: 40),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            isHindi ? 'प्रमाणपत्र इतिहास' : 'Certificate History',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              isHindi
                  ? 'सभी प्रमाणपत्रों का इतिहास'
                  : 'History of all certificates',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            isHindi
                ? 'पिछले सभी प्रमाणपत्रों और उनके विवरणों को देखें'
                : 'View all previous certificates and their details',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalHistoryCard(
    LeaderboardCertificateHistory history,
    LeaderboardCertificateModel certificateType,
    bool isHindi,
  ) {
    // Get professional color scheme for each certificate type
    Color primaryColor;
    Color backgroundColor;
    IconData cardIcon;
    String category;

    switch (certificateType.typeCode) {
      case 'daily':
        primaryColor = Colors.orange.shade600;
        backgroundColor = Colors.orange.shade50;
        cardIcon = Icons.wb_sunny;
        category = isHindi ? 'दैनिक' : 'Daily';
        break;
      case 'weekly':
        primaryColor = Colors.grey.shade700;
        backgroundColor = Colors.grey.shade50;
        cardIcon = Icons.calendar_view_week;
        category = isHindi ? 'साप्ताहिक' : 'Weekly';
        break;
      case 'monthly':
        primaryColor = Colors.grey.shade600;
        backgroundColor = Colors.grey.shade50;
        cardIcon = Icons.calendar_view_month;
        category = isHindi ? 'मासिक' : 'Monthly';
        break;
      case 'yearly':
        primaryColor = Colors.orange.shade500;
        backgroundColor = Colors.orange.shade50;
        cardIcon = Icons.calendar_today;
        category = isHindi ? 'वार्षिक' : 'Yearly';
        break;
      case 'alltime':
        primaryColor = Colors.orange.shade700;
        backgroundColor = Colors.orange.shade50;
        cardIcon = Icons.emoji_events;
        category = isHindi ? 'सभी समय' : 'All-Time';
        break;
      default:
        primaryColor = Colors.grey.shade600;
        backgroundColor = Colors.grey.shade50;
        cardIcon = Icons.help_outline;
        category = isHindi ? 'अन्य' : 'Other';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(cardIcon, color: Colors.white, size: 32),
                ),

                const SizedBox(width: 20),

                // Title and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi
                            ? certificateType.certificateNameHi
                            : certificateType.certificateNameEn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    history.isTransferred
                        ? (isHindi ? 'स्थानांतरित' : 'Transferred')
                        : (isHindi ? 'पूर्ण' : 'Completed'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Certificate Details
                _buildProfessionalInfoRow(
                  icon: Icons.emoji_events,
                  label: isHindi ? 'रैंक' : 'Rank',
                  value: '#${history.rankPosition}',
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 20),

                _buildProfessionalInfoRow(
                  icon: Icons.favorite,
                  label: isHindi ? 'जप संख्या' : 'Japa Count',
                  value: '${history.japaCount} ${isHindi ? 'जप' : 'Japas'}',
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 20),

                _buildProfessionalInfoRow(
                  icon: Icons.calendar_today,
                  label: isHindi ? 'अवधि' : 'Period',
                  value: _formatDate(history.periodStartDate),
                  primaryColor: primaryColor,
                ),

                const SizedBox(height: 20),

                _buildProfessionalInfoRow(
                  icon: Icons.schedule,
                  label: isHindi ? 'प्राप्ति तिथि' : 'Awarded Date',
                  value: _formatDate(history.awardedAt),
                  primaryColor: primaryColor,
                ),

                if (history.isTransferred) ...[
                  const SizedBox(height: 20),
                  _buildProfessionalInfoRow(
                    icon: Icons.swap_horiz,
                    label: isHindi ? 'स्थानांतरित' : 'Transferred',
                    value:
                        history.transferredToUsername ??
                        (isHindi ? 'अज्ञात' : 'Unknown'),
                    primaryColor: primaryColor,
                  ),
                ],

                const SizedBox(height: 24),

                // Download Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          _downloadHistoryCertificate(history, certificateType),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isHindi
                                ? 'प्रमाणपत्र डाउनलोड करें'
                                : 'Download Certificate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCertificatesTab(
    LeaderboardCertificateService service,
    bool isHindi,
  ) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Professional Header
          _buildMyCertificatesHeader(isHindi),

          const SizedBox(height: 20),

          // Loading state
          if (!_userCertificatesLoaded)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      isHindi
                          ? 'प्रमाणपत्र लोड हो रहे हैं...'
                          : 'Loading certificates...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Empty state
          else if (_userCertificates.isEmpty)
            Column(
              children: [
                _buildEmptyState(
                  icon: Icons.person_outline,
                  title: isHindi ? 'कोई प्रमाणपत्र नहीं' : 'No Certificates',
                  subtitle: isHindi
                      ? 'आपके पास अभी कोई प्रमाणपत्र नहीं है'
                      : 'You don\'t have any certificates yet',
                ),
                const SizedBox(height: 20),
                // Debug button to manually load certificates
                ElevatedButton(
                  onPressed: () {
                    _loadUserCertificates();
                  },
                  child: Text(isHindi ? 'पुनः लोड करें' : 'Reload'),
                ),
              ],
            )
          // User certificates list
          else
            ..._userCertificates.map((certificate) {
              if (service.certificateTypes.isEmpty) {
                return _buildLoadingCard();
              }

              // Try to find certificate type by ID first, then by type code
              LeaderboardCertificateModel? certificateType;
              try {
                certificateType = service.certificateTypes.firstWhere(
                  (type) => type.id == certificate.certificateTypeId,
                );
              } catch (e) {
                // If not found by ID, try to find by type code from the certificate data
                if (certificate.typeCode != null) {
                  try {
                    certificateType = service.certificateTypes.firstWhere(
                      (type) => type.typeCode == certificate.typeCode,
                    );
                  } catch (e2) {
                    certificateType = _createFallbackCertificateType(
                      certificate,
                    );
                  }
                } else {
                  certificateType = _createFallbackCertificateType(certificate);
                }
              }

              return _buildProfessionalMyCertificateCard(
                certificate,
                certificateType,
                isHindi,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(LeaderboardCertificateService service, bool isHindi) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Professional Header
          _buildHistoryHeader(isHindi),

          const SizedBox(height: 20),

          // History list
          if (service.certificateHistory.isEmpty)
            _buildEmptyState(
              icon: Icons.history_outlined,
              title: isHindi ? 'कोई इतिहास नहीं' : 'No History',
              subtitle: isHindi
                  ? 'अभी तक कोई प्रमाणपत्र इतिहास नहीं है'
                  : 'No certificate history available yet',
            )
          else
            ...service.certificateHistory.map((history) {
              if (service.certificateTypes.isEmpty) {
                return _buildLoadingCard();
              }

              // Try to find certificate type by ID first, then by type code
              LeaderboardCertificateModel? certificateType;
              try {
                certificateType = service.certificateTypes.firstWhere(
                  (type) => type.id == history.certificateTypeId,
                );
              } catch (e) {
                // If not found by ID, try to find by type code from the certificate data
                if (history.typeCode != null) {
                  try {
                    certificateType = service.certificateTypes.firstWhere(
                      (type) => type.typeCode == history.typeCode,
                    );
                  } catch (e2) {
                    certificateType = _createFallbackCertificateTypeFromHistory(
                      history,
                    );
                  }
                } else {
                  certificateType = _createFallbackCertificateTypeFromHistory(
                    history,
                  );
                }
              }

              return _buildProfessionalHistoryCard(
                history,
                certificateType,
                isHindi,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Download certificate as PDF
  Future<void> _downloadCertificate(
    ActiveLeaderboardCertificate certificate,
    LeaderboardCertificateModel certificateType,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get current user info
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user profile for name
      String displayName = 'User';
      try {
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('display_name')
            .eq('user_id', currentUser.id)
            .single();

        displayName = profileResponse['display_name'] as String? ?? 'User';
      } catch (e) {
        // Use email as fallback if profile not found
        displayName = currentUser.email?.split('@').first ?? 'User';
      }

      // Generate PDF

      // Ensure we have a valid user name
      final finalDisplayName = displayName.isNotEmpty
          ? displayName
          : 'Certificate Holder';

      final pdfBytes =
          await LeaderboardCertificateService.generateLeaderboardCertificatePdf(
            certificate: certificate,
            certificateType: certificateType,
            userName: finalDisplayName,
            logoAssetPath: 'assets/images/logo.jpg',
            isHindi:
                false, // You can make this dynamic based on language preference
          );

      // Close loading dialog
      Navigator.of(context).pop();

      // Share/Download the PDF
      await LeaderboardCertificateService.shareLeaderboardCertificate(
        pdfBytes: pdfBytes,
        fileName:
            '${certificateType.getName(isHindi: false)}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
      );

      // Show success message
      if (mounted) {
        final isHindi = Provider.of<LanguageService>(
          context,
          listen: false,
        ).isHindi;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'प्रमाणपत्र सफलतापूर्वक डाउनलोड हो गया!'
                  : 'Certificate downloaded successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        final isHindi = Provider.of<LanguageService>(
          context,
          listen: false,
        ).isHindi;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'प्रमाणपत्र डाउनलोड करने में त्रुटि: $e'
                  : 'Error downloading certificate: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Download history certificate as PDF
  Future<void> _downloadHistoryCertificate(
    LeaderboardCertificateHistory history,
    LeaderboardCertificateModel certificateType,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get current user info
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user profile for name
      String displayName = 'User';
      try {
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('display_name')
            .eq('user_id', currentUser.id)
            .single();

        displayName = profileResponse['display_name'] as String? ?? 'User';
      } catch (e) {
        // Use email as fallback if profile not found
        displayName = currentUser.email?.split('@').first ?? 'User';
      }

      // Convert history to active certificate for PDF generation
      final activeCertificate = ActiveLeaderboardCertificate(
        id: history.id,
        certificateTypeId: history.certificateTypeId,
        userId: history.userId,
        username: history.username,
        periodStartDate: history.periodStartDate,
        periodEndDate: history.periodEndDate,
        japaCount: history.japaCount,
        rankPosition: history.rankPosition,
        awardedAt: history.awardedAt,
        expiresAt: null,
        isCurrent: false,
        createdAt: null,
        updatedAt: null,
        typeCode: history.typeCode,
      );

      // Generate PDF

      // Ensure we have a valid user name
      final finalDisplayName = displayName.isNotEmpty
          ? displayName
          : 'Certificate Holder';

      final pdfBytes =
          await LeaderboardCertificateService.generateLeaderboardCertificatePdf(
            certificate: activeCertificate,
            certificateType: certificateType,
            userName: finalDisplayName,
            logoAssetPath: 'assets/images/logo.jpg',
            isHindi:
                false, // You can make this dynamic based on language preference
          );

      // Close loading dialog
      Navigator.of(context).pop();

      // Share/Download the PDF
      await LeaderboardCertificateService.shareLeaderboardCertificate(
        pdfBytes: pdfBytes,
        fileName:
            '${certificateType.getName(isHindi: false)}_History_${DateFormat('yyyy-MM-dd').format(history.awardedAt)}.pdf',
      );

      // Show success message
      if (mounted) {
        final isHindi = Provider.of<LanguageService>(
          context,
          listen: false,
        ).isHindi;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'प्रमाणपत्र सफलतापूर्वक डाउनलोड हो गया!'
                  : 'Certificate downloaded successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        final isHindi = Provider.of<LanguageService>(
          context,
          listen: false,
        ).isHindi;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'प्रमाणपत्र डाउनलोड करने में त्रुटि: $e'
                  : 'Error downloading certificate: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Create a fallback certificate type when the proper one can't be found
  LeaderboardCertificateModel _createFallbackCertificateType(
    ActiveLeaderboardCertificate certificate,
  ) {
    // Determine the type based on the period or type code
    String typeCode = certificate.typeCode ?? 'unknown';

    // If type code is not available, try to determine from period
    if (typeCode == 'unknown') {
      if (certificate.periodEndDate == null) {
        typeCode = 'alltime';
      } else {
        final duration = certificate.periodEndDate!.difference(
          certificate.periodStartDate,
        );
        if (duration.inDays == 0) {
          typeCode = 'daily';
        } else if (duration.inDays <= 7) {
          typeCode = 'weekly';
        } else if (duration.inDays <= 31) {
          typeCode = 'monthly';
        } else if (duration.inDays <= 365) {
          typeCode = 'yearly';
        } else {
          typeCode = 'alltime';
        }
      }
    }

    // Create a fallback certificate type
    return LeaderboardCertificateModel(
      id: certificate.certificateTypeId,
      typeCode: typeCode,
      typeNameEn: _getTypeNameEn(typeCode),
      typeNameHi: _getTypeNameHi(typeCode),
      certificateNameEn: _getCertificateNameEn(typeCode),
      certificateNameHi: _getCertificateNameHi(typeCode),
      calculationTime: 'Real-time',
      validityPeriod: 'Permanent',
      isActive: true,
    );
  }

  String _getTypeNameEn(String typeCode) {
    switch (typeCode) {
      case 'daily':
        return 'Daily Topper';
      case 'weekly':
        return 'Weekly Topper';
      case 'monthly':
        return 'Monthly Topper';
      case 'yearly':
        return 'Yearly Topper';
      case 'alltime':
        return 'All-Time Topper';
      default:
        return 'Unknown Topper';
    }
  }

  String _getTypeNameHi(String typeCode) {
    switch (typeCode) {
      case 'daily':
        return 'दैनिक टॉपर';
      case 'weekly':
        return 'साप्ताहिक टॉपर';
      case 'monthly':
        return 'मासिक टॉपर';
      case 'yearly':
        return 'वार्षिक टॉपर';
      case 'alltime':
        return 'सर्वकालिक टॉपर';
      default:
        return 'अज्ञात टॉपर';
    }
  }

  String _getCertificateNameEn(String typeCode) {
    switch (typeCode) {
      case 'daily':
        return 'Aaj ka Tapasvi';
      case 'weekly':
        return 'Saptah ka Yogi';
      case 'monthly':
        return 'Masik Sadhak Ratna';
      case 'yearly':
        return 'Varshik Sadhak Ratna';
      case 'alltime':
        return 'Mahajapa Yogi';
      default:
        return 'Unknown Certificate';
    }
  }

  String _getCertificateNameHi(String typeCode) {
    switch (typeCode) {
      case 'daily':
        return 'आज का तपस्वी';
      case 'weekly':
        return 'सप्ताह का योगी';
      case 'monthly':
        return 'मासिक साधक रत्न';
      case 'yearly':
        return 'वार्षिक साधक रत्न';
      case 'alltime':
        return 'महाजप योगी';
      default:
        return 'अज्ञात प्रमाणपत्र';
    }
  }

  /// Create a fallback certificate type for history when the proper one can't be found
  LeaderboardCertificateModel _createFallbackCertificateTypeFromHistory(
    LeaderboardCertificateHistory history,
  ) {
    // Determine the type based on the period or type code
    String typeCode = history.typeCode ?? 'unknown';

    // If type code is not available, try to determine from period
    if (typeCode == 'unknown') {
      if (history.periodEndDate == null) {
        typeCode = 'alltime';
      } else {
        final duration = history.periodEndDate!.difference(
          history.periodStartDate,
        );
        if (duration.inDays == 0) {
          typeCode = 'daily';
        } else if (duration.inDays <= 7) {
          typeCode = 'weekly';
        } else if (duration.inDays <= 31) {
          typeCode = 'monthly';
        } else if (duration.inDays <= 365) {
          typeCode = 'yearly';
        } else {
          typeCode = 'alltime';
        }
      }
    }

    // Create a fallback certificate type
    return LeaderboardCertificateModel(
      id: history.certificateTypeId,
      typeCode: typeCode,
      typeNameEn: _getTypeNameEn(typeCode),
      typeNameHi: _getTypeNameHi(typeCode),
      certificateNameEn: _getCertificateNameEn(typeCode),
      certificateNameHi: _getCertificateNameHi(typeCode),
      calculationTime: 'Real-time',
      validityPeriod: 'Permanent',
      isActive: true,
    );
  }
}
