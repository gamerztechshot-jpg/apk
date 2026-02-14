// core/widgets/flexible_content_box_widget.dart
import 'package:flutter/material.dart';
import '../models/user_home_config.dart';
import 'cached_network_image_widget.dart';

class FlexibleContentBoxWidget extends StatelessWidget {
  final ContentBox contentBox;
  final VoidCallback onTap;

  const FlexibleContentBoxWidget({
    super.key,
    required this.contentBox,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardWidth = isTablet ? 200.0 : 160.0;
    final cardHeight = isTablet ? 180.0 : 160.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 12 : 8,
          vertical: isTablet ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image/Icon
            Container(
              width: isTablet ? 80 : 60,
              height: isTablet ? 80 : 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: contentBox.contentType.color.withOpacity(0.1),
              ),
              child: CachedNetworkImageWidget(
                imageUrl: contentBox.imageUrl ?? '',
                width: isTablet ? 80 : 60,
                height: isTablet ? 80 : 60,
                borderRadius: BorderRadius.circular(12),
                errorWidget: Icon(
                  contentBox.contentType.icon,
                  color: contentBox.contentType.color,
                  size: isTablet ? 40 : 30,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
              child: Text(
                contentBox.title ?? 'Content',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isTablet ? 6 : 4),
            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
              child: Text(
                contentBox.description ?? 'Tap to explore',
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            // Type badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 8 : 6,
                vertical: isTablet ? 4 : 3,
              ),
              decoration: BoxDecoration(
                color: contentBox.contentType.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                contentBox.contentType.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 10 : 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
