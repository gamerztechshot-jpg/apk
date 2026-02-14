// core/widgets/simple_content_box_widget.dart
import 'package:flutter/material.dart';
import '../models/user_home_config.dart';
import 'cached_network_image_widget.dart';

class SimpleContentBoxWidget extends StatelessWidget {
  final ContentBox contentBox;
  final VoidCallback onTap;

  const SimpleContentBoxWidget({
    super.key,
    required this.contentBox,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isTablet ? 200 : 160,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image/Icon - takes most of the space
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                child: CachedNetworkImageWidget(
                  imageUrl: contentBox.imageUrl ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                  errorWidget: Container(
                    decoration: BoxDecoration(
                      color: contentBox.contentType.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      contentBox.contentType.icon,
                      color: contentBox.contentType.color,
                      size: isTablet ? 40 : 32,
                    ),
                  ),
                ),
              ),
            ),
            // Name - compact at bottom
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
                child: Center(
                  child: Text(
                    contentBox.title ?? 'Content',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
