// features/dharma_store/widgets/review_display_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/store.dart';
import '../../../core/services/language_service.dart';

class ReviewDisplayWidget extends StatelessWidget {
  final List<Review> reviews;

  const ReviewDisplayWidget({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          isHindi ? 'अभी तक कोई समीक्षा नहीं है' : 'No reviews yet',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Average Rating
        _buildAverageRating(),
        const SizedBox(height: 16),

        // Individual Reviews
        ...reviews.take(3).map((review) => _buildReviewCard(review, isHindi)),

        // Show More Button (if there are more than 3 reviews)
        if (reviews.length > 3) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Navigate to full reviews page
              _showAllReviews(context, reviews, isHindi);
            },
            child: Text(
              isHindi
                  ? 'सभी समीक्षाएं देखें (${reviews.length})'
                  : 'View all reviews (${reviews.length})',
              style: TextStyle(
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAverageRating() {
    final averageRating =
        reviews.fold<double>(0, (sum, review) => sum + review.rating) /
        reviews.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          // Star Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < averageRating.floor()
                    ? Icons.star
                    : index < averageRating
                    ? Icons.star_half
                    : Icons.star_border,
                color: Colors.amber.shade600,
                size: 20,
              );
            }),
          ),
          const SizedBox(width: 8),

          // Rating Number
          Text(
            averageRating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),

          // Review Count
          Text(
            '(${reviews.length} reviews)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review, bool isHindi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer Name and Rating
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade600,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Review Date
          Text(
            _formatDate(review.createdAt),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 8),

          // Review Comment
          if (review.comment.isNotEmpty) ...[
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllReviews(
    BuildContext context,
    List<Review> reviews,
    bool isHindi,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    isHindi ? 'सभी समीक्षाएं' : 'All Reviews',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Reviews List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  return _buildReviewCard(reviews[index], isHindi);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
