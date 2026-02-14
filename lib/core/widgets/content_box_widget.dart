// core/widgets/content_box_widget.dart
import 'package:flutter/material.dart';
import '../models/user_home_config.dart';
import 'cached_network_image_widget.dart';

class ContentBoxWidget extends StatelessWidget {
  final ContentBox contentBox;
  final VoidCallback onTap;

  const ContentBoxWidget({
    super.key,
    required this.contentBox,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardHeight = isTablet ? 120.0 : 100.0; // Reduced height for mobile

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 8 : 6,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background gradient based on content type
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      contentBox.contentType.color.withOpacity(0.1),
                      contentBox.contentType.color.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(
                isTablet ? 12 : 8,
              ), // Reduced padding for mobile
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with type badge and image
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 6 : 4, // Reduced padding
                          vertical: isTablet ? 3 : 2, // Reduced padding
                        ),
                        decoration: BoxDecoration(
                          color: contentBox.contentType.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              contentBox.contentType.icon,
                              color: Colors.white,
                              size: isTablet ? 12 : 10, // Smaller icon
                            ),
                            SizedBox(
                              width: isTablet ? 3 : 2,
                            ), // Reduced spacing
                            Text(
                              contentBox.contentType.displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 9 : 8, // Smaller text
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Content image
                      Container(
                        width: isTablet ? 50 : 40, // Smaller image
                        height: isTablet ? 50 : 40, // Smaller image
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child:
                            contentBox.imageUrl != null &&
                                contentBox.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImageWidget(
                                  imageUrl: contentBox.imageUrl!,
                                  width: isTablet ? 50 : 40, // Smaller image
                                  height: isTablet ? 50 : 40, // Smaller image
                                  fit: BoxFit.cover,
                                  placeholder: Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      contentBox.contentType.icon,
                                      color: Colors.grey.shade400,
                                      size: isTablet ? 20 : 16, // Smaller icon
                                    ),
                                  ),
                                  errorWidget: Icon(
                                    contentBox.contentType.icon,
                                    color: contentBox.contentType.color,
                                    size: isTablet ? 20 : 16, // Smaller icon
                                  ),
                                ),
                              )
                            : Icon(
                                contentBox.contentType.icon,
                                color: contentBox.contentType.color,
                                size: isTablet ? 20 : 16, // Smaller icon
                              ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 8 : 6), // Reduced spacing
                  // Title
                  Text(
                    contentBox.title ?? 'Content',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12, // Smaller text
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1, // Single line for mobile
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isTablet ? 3 : 2), // Reduced spacing
                  // Description
                  Expanded(
                    child: Text(
                      contentBox.description ?? 'Tap to explore',
                      style: TextStyle(
                        fontSize: isTablet ? 10 : 8, // Smaller text
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2, // Reduced lines for mobile
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: isTablet ? 6 : 4), // Reduced spacing
                  // Arrow indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          isTablet ? 4 : 3,
                        ), // Smaller padding
                        decoration: BoxDecoration(
                          color: contentBox.contentType.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: isTablet ? 14 : 12, // Smaller icon
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
