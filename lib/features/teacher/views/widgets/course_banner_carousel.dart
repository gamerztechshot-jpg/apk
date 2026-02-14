// features/teacher/views/widgets/course_banner_carousel.dart
import 'package:flutter/material.dart';
import '../../../../core/services/banner_service.dart';
import '../../../../core/models/course_banner_model.dart';
import '../../../../core/widgets/cached_network_image_widget.dart';

class CourseBannerCarousel extends StatefulWidget {
  const CourseBannerCarousel({super.key});

  @override
  State<CourseBannerCarousel> createState() => _CourseBannerCarouselState();
}

class _CourseBannerCarouselState extends State<CourseBannerCarousel> {
  final BannerService _bannerService = BannerService();
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);

  List<CourseBanner> _banners = [];
  bool _isLoading = true;

  // Public method to refresh banners
  Future<void> refreshBanners() async {
    await _loadBanners();
  }

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await _bannerService.getActiveCourseBanners();

      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _banners = [];
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted &&
          _banners.isNotEmpty &&
          _pageController.hasClients &&
          _banners.length > 1) {
        final nextIndex = (_currentIndex.value + 1) % _banners.length;
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
    final bannerHeight = isTablet ? 200.0 : 180.0;

    if (_isLoading) {
      return Container(
        height: bannerHeight,
        margin: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: bannerHeight,
      margin: const EdgeInsets.only(top: 10, bottom: 16),
      width: double.infinity,
      child: Stack(
        children: [
          // Banner Carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentIndex.value = index;
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImageWidget(
                    imageUrl: banner.bannerUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(12),
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
                              Icons.broken_image,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load banner',
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

          // Page Indicators (only show when multiple banners)
          if (_banners.length > 1)
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
                      _banners.length,
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
}

