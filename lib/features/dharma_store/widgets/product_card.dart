// features/dharma_store/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/store.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/cached_network_image_widget.dart';

class ProductCard extends StatelessWidget {
  final Store product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        // Responsive font sizes based on card width
        final titleFontSize = cardWidth < 150 ? 13.0 : 14.0;
        final priceFontSize = cardWidth < 150 ? 12.0 : 13.0;
        final ratingFontSize = cardWidth < 150 ? 10.0 : 11.0;
        final buttonFontSize = cardWidth < 150 ? 10.0 : 11.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 0,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image - Top section with rounded corners
                Expanded(
                  flex: 48, // slightly less to give more space to content
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: Colors.grey.shade50,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child:
                          product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? CachedNetworkImageWidget(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orange,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 28,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                // Product Content - Bottom section
                Expanded(
                  flex: 52, // slightly more to avoid overflow
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      8,
                    ), // Reduced bottom padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name - One line only for consistency
                        Text(
                          isHindi ? product.nameHi : product.nameEn,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // Price and Rating Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Price (left side)
                            Expanded(
                              flex: 2,
                              child: _buildPriceWidget(priceFontSize),
                            ),

                            const SizedBox(width: 8),

                            // Rating (right side)
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: ratingFontSize,
                                    color: Colors.amber.shade600,
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      '${_calculateAverageRating().toStringAsFixed(1)}',
                                      style: TextStyle(
                                        fontSize: ratingFontSize - 1,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Description (2 lines, based on language)
                        Text(
                          isHindi
                              ? (product.descriptionHi.trim().isEmpty
                                    ? product.nameHi
                                    : product.descriptionHi)
                              : (product.descriptionEn.trim().isEmpty
                                    ? product.nameEn
                                    : product.descriptionEn),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: cardWidth < 150 ? 10 : 11,
                            color: Colors.grey.shade700,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Add to Cart Button - Full width, rounded corners, bright orange
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: onAddToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              isHindi ? 'कार्ट में जोड़ें' : 'Add to Cart',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceWidget(double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.originalPrice != null &&
            product.originalPrice! > product.price) ...[
          Text(
            '₹${product.originalPrice!.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: fontSize - 2,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          '₹${product.price.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade600,
          ),
        ),
      ],
    );
  }

  double _calculateAverageRating() {
    if (product.reviews.isEmpty) return 0.0;

    final totalRating = product.reviews.fold<double>(
      0.0,
      (sum, review) => sum + review.rating,
    );
    return totalRating / product.reviews.length;
  }
}
