// core/widgets/puja_story_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/puja_story_model.dart';
import '../services/language_service.dart';
import 'cached_network_image_widget.dart';

class PujaStoryWidget extends StatelessWidget {
  final List<PujaStoryModel> stories;
  final Function(String category)? onStoryTap;

  const PujaStoryWidget({super.key, required this.stories, this.onStoryTap});

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final storySize = isTablet ? 80.0 : 70.0;
    final storySpacing = isTablet ? 16.0 : 12.0;

    return Container(
      height: storySize + 40, // Height for story circle + text
      margin: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return _buildStoryItem(
            context,
            story,
            storySize,
            storySpacing,
            isTablet,
          );
        },
      ),
    );
  }

  Widget _buildStoryItem(
    BuildContext context,
    PujaStoryModel story,
    double storySize,
    double spacing,
    bool isTablet,
  ) {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;
    final rawStoryName = isHindi ? story.nameHi : story.nameEn;
    // Remove "Story" from the end of the name if it exists
    final storyName = rawStoryName.replaceAll(
      RegExp(r'\s*Story\s*$', caseSensitive: false),
      '',
    );

    // Debug: Print story information
    final isValidUrl = _isValidImageUrl(story.url);

    return GestureDetector(
      onTap: () => onStoryTap?.call(story.category),
      child: Container(
        width: storySize + spacing,
        child: Column(
          children: [
            // Story Circle
            Container(
              width: storySize,
              height: storySize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade400,
                    Colors.orange.shade600,
                    Colors.orange.shade800,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(3), // Border width
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: _isValidImageUrl(story.url)
                      ? Container(
                          width: storySize - 6,
                          height: storySize - 6,
                          child: CachedNetworkImageWidget(
                            imageUrl: story.url!,
                            width: storySize - 6,
                            height: storySize - 6,
                            fit: BoxFit.cover,
                            cacheDuration: const Duration(
                              hours: 24,
                            ), // Longer cache for story images
                            placeholder: Container(
                              width: storySize - 6,
                              height: storySize - 6,
                              color: Colors.grey.shade200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.temple_hindu,
                                    color: Colors.grey.shade400,
                                    size: (storySize - 6) * 0.3,
                                  ),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            errorWidget: Container(
                              width: storySize - 6,
                              height: storySize - 6,
                              color: Colors.red.shade50,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.red.shade400,
                                    size: (storySize - 6) * 0.3,
                                  ),
                                  Text(
                                    'Error',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: storySize - 6,
                          height: storySize - 6,
                          color: Colors.orange.shade50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.temple_hindu,
                                color: Colors.orange.shade400,
                                size: (storySize - 6) * 0.4,
                              ),
                              Text(
                                'No Image',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Story Name
            Container(
              width: storySize,
              child: Text(
                storyName,
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Check if the URL is a valid image URL
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
