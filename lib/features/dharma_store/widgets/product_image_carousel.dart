// features/dharma_store/widgets/product_image_carousel.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/cached_network_image_widget.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> images;
  final String? mainImage;

  const ProductImageCarousel({super.key, required this.images, this.mainImage});

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _allImages {
    final images = <String>[];
    if (widget.mainImage != null && widget.mainImage!.isNotEmpty) {
      images.add(widget.mainImage!);
    }
    images.addAll(widget.images);
    return images;
  }

  @override
  Widget build(BuildContext context) {
    final allImages = _allImages;

    if (allImages.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Main Image Carousel
        Container(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: allImages.length,
            itemBuilder: (context, index) {
              return CachedNetworkImageWidget(
                imageUrl: allImages[index],
                fit: BoxFit.cover,
                placeholder: Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Page Indicators
        if (allImages.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              allImages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? Colors.orange.shade600
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
