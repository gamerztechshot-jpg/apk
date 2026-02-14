// core/widgets/dynamic_content_boxes.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_home_config.dart';
import '../services/user_home_service.dart';
import '../../features/audio_ebook/audio_ebook_screen.dart';
import '../../features/dharma_store/screens/store_home_screen.dart';
import '../../features/puja_booking/puja_list.dart';
import 'cached_network_image_widget.dart';

class DynamicContentBoxes extends StatefulWidget {
  const DynamicContentBoxes({super.key});

  @override
  State<DynamicContentBoxes> createState() {
    return _DynamicContentBoxesState();
  }
}

class _DynamicContentBoxesState extends State<DynamicContentBoxes> {
  List<ContentBox> _contentBoxes = [];
  bool _isLoading = true;
  String? _error;
  String? _backgroundUrl;

  @override
  void initState() {
    super.initState();
    _loadContentBoxes();
  }

  Future<void> _loadContentBoxes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userHomeService = Provider.of<UserHomeService>(
        context,
        listen: false,
      );
      final config = await userHomeService.getUserHomeConfig();

      if (config != null) {
        // Get background URL
        _backgroundUrl = userHomeService.getBackgroundUrl(config);

        final boxes = await userHomeService.getContentBoxesWithRealData(config);

        for (int i = 0; i < boxes.length; i++) {}

        setState(() {
          _contentBoxes = boxes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No content configuration found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load content: $e';
      });
    }
  }

  void _onContentBoxTap(ContentBox contentBox) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // If refId is available, fetch content details
      Map<String, dynamic>? contentDetails;
      if (contentBox.refId != null && contentBox.refId!.isNotEmpty) {
        final userHomeService = Provider.of<UserHomeService>(
          context,
          listen: false,
        );
        contentDetails = await userHomeService.getContentDetails(
          contentBox.type,
          contentBox.refId!,
        );
      }

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to content screen (with or without details)
      _navigateToContentScreen(contentBox, contentDetails);
    } catch (e) {
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showErrorSnackBar('Failed to load content: $e');
    }
  }

  void _navigateToContentScreen(
    ContentBox contentBox,
    Map<String, dynamic>? contentDetails,
  ) {
    switch (contentBox.contentType) {
      case ContentBoxType.ebook:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AudioEbookScreen()),
        );
        break;
      case ContentBoxType.audio:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AudioEbookScreen()),
        );
        break;
      case ContentBoxType.store:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StoreHomeScreen()),
        );
        break;
      case ContentBoxType.puja:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PujaListScreen()),
        );
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;

    if (_isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        height: isTablet ? 160 : 140,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        height: isTablet ? 160 : 140,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey.shade400,
                size: isTablet ? 48 : 40,
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: isTablet ? 14 : 12,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 8 : 6),
              TextButton(
                onPressed: _loadContentBoxes,
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_contentBoxes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Featured Content',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          // Background Image with Cards Inside (like your reference image)
          Container(
            height: 250, // Fixed height as requested
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: _buildBackgroundImage(),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 135, // More space from top to show background image
                left: 8,
                right: 8,
                bottom: 8,
              ),
              child: Row(
                children: _getThreeCards().map((contentBox) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildCompactCard(contentBox),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build background image with error handling
  ImageProvider _buildBackgroundImage() {
    if (_backgroundUrl != null && _backgroundUrl!.isNotEmpty) {
      return NetworkImage(_backgroundUrl!);
    }

    // Fallback to default background
    const defaultUrl =
        'https://zwnugtwpzeaswwyofjzs.supabase.co/storage/v1/object/public/images/banner1.jpg';
    return const NetworkImage(defaultUrl);
  }

  // Get exactly 3 cards (show real data only)
  List<ContentBox> _getThreeCards() {
    List<ContentBox> threeCards = [];

    // Add actual content boxes (max 3)
    for (int i = 0; i < 3 && i < _contentBoxes.length; i++) {
      threeCards.add(_contentBoxes[i]);
    }

    return threeCards;
  }

  // Build compact card for background overlay (smaller size)
  Widget _buildCompactCard(ContentBox contentBox) {
    return GestureDetector(
      onTap: () => _onContentBoxTap(contentBox),
      child: Container(
        height: 120, // Taller cards for 250px container with 35px top padding
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image section (takes most space)
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: _buildCardImage(contentBox, false),
                ),
              ),
            ),
            // Name section (compact)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Center(
                  child: Text(
                    contentBox.title ?? 'Content',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
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

  // Build card image with caching and fallback
  Widget _buildCardImage(ContentBox contentBox, bool isTablet) {
    return CachedNetworkImageWidget(
      imageUrl: contentBox.imageUrl ?? '',
      width: double.infinity,
      fit: BoxFit.cover,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      errorWidget: _buildFallbackImage(contentBox, isTablet),
    );
  }

  // Build fallback image when main image fails
  Widget _buildFallbackImage(ContentBox contentBox, bool isTablet) {
    return Container(
      color: contentBox.contentType.color.withOpacity(0.1),
      child: Center(
        child: Icon(
          contentBox.contentType.icon,
          color: contentBox.contentType.color,
          size: isTablet ? 40 : 32,
        ),
      ),
    );
  }
}
