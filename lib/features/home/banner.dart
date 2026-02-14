// features/home/banner.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/banner_service.dart';
import '../../core/widgets/cached_network_image_widget.dart';
import '../festival_kit/viewmodels/festival_viewmodel.dart';
import '../festival_kit/views/festival_detail_screen.dart';
import '../../l10n/app_localizations.dart';

enum BannerType { festival, puja }

class BannerCarousel extends StatefulWidget {
  final BannerType bannerType;

  const BannerCarousel({super.key, this.bannerType = BannerType.festival});

  @override
  State<BannerCarousel> createState() => BannerCarouselState();
}

class BannerCarouselState extends State<BannerCarousel> {
  final BannerService _bannerService = BannerService();
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);

  List<String> _bannerUrls = [];
  bool _isLoading = true;
  bool _isFestivalActive = false;

  // Public method to refresh banners
  Future<void> refreshBanners() async {
    await _loadBanners(forceRefresh: true);
  }

  @override
  void initState() {
    super.initState();
    // Defer loading until after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBanners(forceRefresh: true);
    });
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  Future<void> _loadBanners({bool forceRefresh = false}) async {
    try {
      List<String> urls;

      if (widget.bannerType == BannerType.puja) {
        urls = await _bannerService.getPujaBannerUrls(
          forceRefresh: forceRefresh,
        );

        _isFestivalActive = false;
      } else {
        // Check if festival is active
        final festivalViewModel = Provider.of<FestivalViewModel>(
          context,
          listen: false,
        );

        // Always force refresh to get latest is_active status from admin
        await festivalViewModel.loadFestivalConfig(
          forceRefresh: true,
        );

        if (festivalViewModel.isActive &&
            festivalViewModel.festivalConfig != null) {
          // Use festival banner
          urls = [festivalViewModel.festivalConfig!.imageUrl];
          _isFestivalActive = true;
        } else {
          // Use backend default banners (fallbacks handled inside service)
          urls = await _bannerService.getFestivalBannerUrls(
            forceRefresh: forceRefresh,
          );
          _isFestivalActive = false;
        }
      }

      if (mounted) {
        setState(() {
          _bannerUrls = urls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bannerUrls = _bannerService.getDefaultBanners();
          _isLoading = false;
          _isFestivalActive = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _bannerUrls.isNotEmpty && _pageController.hasClients) {
        final nextIndex = (_currentIndex.value + 1) % _bannerUrls.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;
    final bannerHeight = isTablet ? 200.0 : 160.0;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Container(
        height: bannerHeight,
        margin: EdgeInsets.symmetric(
          horizontal: horizontalMargin,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    if (_bannerUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: bannerHeight,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 16),
      child: Stack(
        children: [
          // Banner Carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentIndex.value = index;
            },
            itemCount: _bannerUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: _isFestivalActive
                    ? () => _navigateToFestivalDetail(context)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CachedNetworkImageWidget(
                    imageUrl: _bannerUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(16),
                    cacheDuration: const Duration(hours: 12), // 12 hours cache
                    placeholder: Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Load More Button (only for festival banner when active)
          if (_isFestivalActive)
            Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _navigateToFestivalDetail(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n?.localeName == 'hi' ? 'और देखें' : 'Load More',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Page Indicators (only show when not festival or multiple banners)
          if (_bannerUrls.length > 1 && !_isFestivalActive)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<int>(
                valueListenable: _currentIndex,
                builder: (context, currentIndex, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _bannerUrls.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToFestivalDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FestivalDetailScreen()),
    );
  }
}
