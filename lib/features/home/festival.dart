// features/home/festival.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/festival_provider.dart';
import '../../core/models/festival_model.dart';
import '../../core/widgets/cached_network_image_widget.dart';

class FestivalCard extends StatefulWidget {
  const FestivalCard({super.key});

  @override
  State<FestivalCard> createState() => _FestivalCardState();
}

class _FestivalCardState extends State<FestivalCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);
      final languageCode = l10n?.localeName ?? 'en';
      Provider.of<FestivalProvider>(
        context,
        listen: false,
      ).fetchFestivals(languageCode);
    });
  }

  // Responsive helper methods
  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    if (_isSmallScreen(context)) {
      return baseSize * 0.85;
    } else if (_isLargeScreen(context)) {
      return baseSize * 1.1;
    }
    return baseSize;
  }

  double _getResponsivePadding(BuildContext context, double basePadding) {
    if (_isSmallScreen(context)) {
      return basePadding * 0.8;
    }
    return basePadding;
  }

  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (_isSmallScreen(context)) {
      return baseSpacing * 0.7;
    }
    return baseSpacing;
  }

  // Helper method for building image widgets with better error handling
  Widget _buildImageWidget(Festival festival, BuildContext context) {
    if (festival.imageUrl == null || festival.imageUrl!.isEmpty) {
      return Icon(
        Icons.celebration,
        color: Colors.orange.shade600,
        size: _getResponsiveFontSize(context, 24),
      );
    }

    return CachedNetworkImageWidget(
      imageUrl: festival.imageUrl!,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(11),
      placeholder: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
          ),
        ),
      ),
      errorWidget: Icon(
        Icons.celebration,
        color: Colors.orange.shade600,
        size: _getResponsiveFontSize(context, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isHindi = l10n?.localeName == 'hi';

    return Consumer<FestivalProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasLoaded) {
          return _buildSmoothLoadingCard();
        }

        if (provider.error != null && !provider.hasLoaded) {
          return _buildErrorCard(provider);
        }

        if (provider.festivals.isEmpty && provider.hasLoaded) {
          return _buildEmptyCard();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildFestivalList(isHindi, provider.festivals),
              _buildViewMoreButton(provider.festivals),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmoothLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  strokeWidth: 2,
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading festivals...',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(FestivalProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load festivals',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Unknown error',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final l10n = AppLocalizations.of(context);
                final languageCode = l10n?.localeName ?? 'en';
                provider.fetchFestivals(languageCode, forceRefresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No upcoming festivals found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeaderLine(),
          const SizedBox(width: 12),
          Text(
            'UPCOMING FESTIVALS & VRAT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          _buildHeaderLine(),
        ],
      ),
    );
  }

  Widget _buildHeaderLine() {
    return Row(
      children: [
        Container(width: 20, height: 2, color: Colors.orange.shade300),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.orange.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.orange.shade300,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildFestivalList(bool isHindi, List<Festival> festivals) {
    // Show loading shimmer if no festivals yet
    if (festivals.isEmpty) {
      return _buildShimmerList();
    }

    final displayFestivals = festivals.take(3).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayFestivals.length,
      itemBuilder: (context, index) {
        final festival = displayFestivals[index];
        return _buildFestivalItem(festival, isHindi);
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildShimmerItem();
      },
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Shimmer date box
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            // Shimmer text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Shimmer image box
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFestivalItem(Festival festival, bool isHindi) {
    final dayOfWeek = DateFormat('EEE').format(festival.parsedDate);
    final day = festival.parsedDate.day.toString();
    final month = DateFormat('MMM').format(festival.parsedDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = _isSmallScreen(context);
        final isLarge = _isLargeScreen(context);

        // Responsive dimensions
        final dateBoxSize = isSmall ? 50.0 : (isLarge ? 70.0 : 60.0);
        final cardPadding = _getResponsivePadding(context, 16.0);
        final horizontalMargin = _getResponsivePadding(context, 20.0);
        final spacing = _getResponsiveSpacing(context, 16.0);
        final smallSpacing = _getResponsiveSpacing(context, 12.0);

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                // Date box - responsive size
                Container(
                  width: dateBoxSize,
                  height: dateBoxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      // Top section with orange background
                      Container(
                        width: double.infinity,
                        height: dateBoxSize * 0.33, // Responsive height
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            topRight: Radius.circular(11),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            dayOfWeek.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _getResponsiveFontSize(context, 10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Bottom section with white background
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: _getResponsiveFontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                month,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: _getResponsiveFontSize(context, 8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing),
                // Festival details - responsive with AutoSizeText
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        festival.festivalName,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(height: _getResponsiveSpacing(context, 4)),
                      Text(
                        festival.month,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 12),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: smallSpacing),
                // Image box - responsive size
                Container(
                  width: dateBoxSize,
                  height: dateBoxSize,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: _buildImageWidget(festival, context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewMoreButton(List<Festival> festivals) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FestivalListScreen(festivals: festivals),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'VIEW MORE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.orange.shade600, size: 16),
          ],
        ),
      ),
    );
  }
}

class FestivalListScreen extends StatelessWidget {
  final List<Festival> festivals;

  const FestivalListScreen({super.key, required this.festivals});

  // Responsive helper methods
  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    if (_isSmallScreen(context)) {
      return baseSize * 0.85;
    } else if (_isLargeScreen(context)) {
      return baseSize * 1.1;
    }
    return baseSize;
  }

  double _getResponsivePadding(BuildContext context, double basePadding) {
    if (_isSmallScreen(context)) {
      return basePadding * 0.8;
    }
    return basePadding;
  }

  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (_isSmallScreen(context)) {
      return baseSpacing * 0.7;
    }
    return baseSpacing;
  }

  // Helper method for building image widgets with better error handling
  Widget _buildImageWidget(Festival festival, BuildContext context) {
    if (festival.imageUrl == null || festival.imageUrl!.isEmpty) {
      return Icon(
        Icons.celebration,
        color: Colors.orange.shade600,
        size: _getResponsiveFontSize(context, 24),
      );
    }

    return CachedNetworkImageWidget(
      imageUrl: festival.imageUrl!,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(11),
      placeholder: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
          ),
        ),
      ),
      errorWidget: Icon(
        Icons.celebration,
        color: Colors.orange.shade600,
        size: _getResponsiveFontSize(context, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isHindi = l10n?.localeName == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isHindi ? 'आगामी त्योहार और व्रत' : 'Upcoming Festivals & Vrat',
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: festivals.length,
          itemBuilder: (context, index) {
            final festival = festivals[index];
            return _buildFestivalCard(festival, isHindi);
          },
        ),
      ),
    );
  }

  Widget _buildFestivalCard(Festival festival, bool isHindi) {
    final dayOfWeek = DateFormat('EEE').format(festival.parsedDate);
    final day = festival.parsedDate.day.toString();
    final month = DateFormat('MMM').format(festival.parsedDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = _isSmallScreen(context);
        final isLarge = _isLargeScreen(context);

        // Responsive dimensions
        final dateBoxSize = isSmall ? 50.0 : (isLarge ? 70.0 : 60.0);
        final cardPadding = _getResponsivePadding(context, 16.0);
        final spacing = _getResponsiveSpacing(context, 16.0);
        final smallSpacing = _getResponsiveSpacing(context, 12.0);

        return Container(
          margin: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 8)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                // Date box - responsive size
                Container(
                  width: dateBoxSize,
                  height: dateBoxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      // Top section with orange background
                      Container(
                        width: double.infinity,
                        height: dateBoxSize * 0.33, // Responsive height
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            topRight: Radius.circular(11),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            dayOfWeek.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _getResponsiveFontSize(context, 10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Bottom section with white background
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: _getResponsiveFontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                month,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: _getResponsiveFontSize(context, 8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing),
                // Festival details - responsive with AutoSizeText
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        festival.festivalName,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                      SizedBox(height: _getResponsiveSpacing(context, 4)),
                      Text(
                        festival.month,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 12),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: smallSpacing),
                // Image box - responsive size
                Container(
                  width: dateBoxSize,
                  height: dateBoxSize,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: _buildImageWidget(festival, context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
