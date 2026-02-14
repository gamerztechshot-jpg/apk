// features/festival_kit/views/festival_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/festival_viewmodel.dart';
import '../models/festival_config_model.dart';
import '../../../core/widgets/cached_network_image_widget.dart';
import '../../../l10n/app_localizations.dart';
// Detail screens imports
import '../../dharma_store/screens/product_detail_screen.dart';
import '../../audio_ebook/audio_ebook_detail_screen.dart';
import '../../puja_booking/puja_detail_screen.dart';
import '../../articles/article_detail_screen.dart';
// Services imports
import '../../dharma_store/services/store_service.dart';
import '../../../core/services/puja_service.dart';
import '../../../core/services/article_service.dart';
import '../../../core/services/audio_ebook_service.dart';

class FestivalDetailScreen extends StatefulWidget {
  const FestivalDetailScreen({super.key});

  @override
  State<FestivalDetailScreen> createState() => _FestivalDetailScreenState();
}

class _FestivalDetailScreenState extends State<FestivalDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<FestivalViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return _buildLoadingState();
          }

          if (viewModel.errorMessage != null) {
            return _buildErrorState(viewModel.errorMessage!);
          }

          if (viewModel.festivalConfig == null) {
            return _buildEmptyState();
          }

          return _buildFestivalContent(viewModel.festivalConfig!);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load festival',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No festival data available',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildFestivalContent(FestivalConfig config) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return CustomScrollView(
      slivers: [
        // App Bar with Festival Banner
        _buildSliverAppBar(config, isTablet),

        // Festival Info
        SliverToBoxAdapter(child: _buildFestivalInfo(config, l10n, isTablet)),

        // Content Sections
        SliverToBoxAdapter(
          child: _buildContentSections(config, l10n, isTablet),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(FestivalConfig config, bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 300 : 250,
      pinned: true,
      backgroundColor: Colors.orange.shade600,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner Image
            CachedNetworkImageWidget(
              imageUrl: config.imageUrl,
              fit: BoxFit.cover,
              placeholder: Container(
                color: Colors.orange.shade100,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              ),
              errorWidget: Container(
                color: Colors.orange.shade100,
                child: const Icon(
                  Icons.celebration,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            // Festival Name
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                config.festivalName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFestivalInfo(
    FestivalConfig config,
    AppLocalizations? l10n,
    bool isTablet,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final startDate = dateFormat.format(config.startDate);
    final endDate = dateFormat.format(config.endDate);

    return Container(
      margin: EdgeInsets.all(isTablet ? 24 : 16),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$startDate - $endDate',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (config.isCurrentlyActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${config.contentItems.length} Special Items',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSections(
    FestivalConfig config,
    AppLocalizations? l10n,
    bool isTablet,
  ) {
    final viewModel = Provider.of<FestivalViewModel>(context, listen: false);
    final contentTypes = viewModel.contentTypes;

    return Column(
      children: contentTypes.map((type) {
        final items = viewModel.getContentItemsByType(type);
        return _buildContentSection(type, items, isTablet);
      }).toList(),
    );
  }

  Widget _buildContentSection(
    String type,
    List<FestivalContentItem> items,
    bool isTablet,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    final sectionTitle = _getSectionTitle(type);
    final sectionIcon = _getSectionIcon(type);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(sectionIcon, color: Colors.orange.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildContentCard(items[index], type, isTablet);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(
    FestivalContentItem item,
    String type,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: () => _handleContentItemTap(item, type),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CachedNetworkImageWidget(
                  imageUrl: item.primaryImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      _getSectionIcon(type),
                      color: Colors.grey.shade400,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

            // Content Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSectionTitle(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return 'Audio';
      case 'ebook':
        return 'E-Books';
      case 'store_item':
        return 'Store Items';
      case 'puja':
        return 'Puja Services';
      default:
        return type;
    }
  }

  IconData _getSectionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return Icons.headphones;
      case 'ebook':
        return Icons.menu_book;
      case 'store_item':
        return Icons.shopping_bag;
      case 'puja':
        return Icons.temple_hindu;
      default:
        return Icons.category;
    }
  }

  void _handleContentItemTap(FestivalContentItem item, String type) {
    _navigateToDetailScreen(item, type);
  }

  Future<void> _navigateToDetailScreen(
    FestivalContentItem item,
    String type,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      ),
    );

    try {
      switch (type.toLowerCase()) {
        case 'store_item':
          await _navigateToStoreProduct(item);
          break;
        case 'audio':
          await _navigateToAudio(item);
          break;
        case 'ebook':
          await _navigateToEbook(item);
          break;
        case 'puja':
          await _navigateToPuja(item);
          break;
        case 'article':
          await _navigateToArticle(item);
          break;
        default:
          // Close loading for unknown type
          if (mounted) Navigator.pop(context);
          _showErrorSnackBar('Unknown content type: $type');
      }
    } catch (e) {
      // Close loading on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackBar('Failed to load content: ${e.toString()}');
    }
  }

  Future<void> _navigateToStoreProduct(FestivalContentItem item) async {
    final storeService = StoreService();
    final product = await storeService.getProductById(item.refId);

    if (mounted) {
      Navigator.pop(context); // Close loading
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: product),
        ),
      );
    }
  }

  Future<void> _navigateToAudio(FestivalContentItem item) async {
    final audioEbookService = AudioEbookService();
    final allAudios = await audioEbookService.fetchAudiobooks();

    // Find the audio by refId
    final audioItem = allAudios.firstWhere(
      (audio) => audio.id.toString() == item.refId,
      orElse: () => throw Exception('Audio not found'),
    );

    if (mounted) {
      Navigator.pop(context); // Close loading
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioEbookDetailScreen(item: audioItem),
        ),
      );
    }
  }

  Future<void> _navigateToEbook(FestivalContentItem item) async {
    final audioEbookService = AudioEbookService();
    final allEbooks = await audioEbookService.fetchEbooks();

    // Find the ebook by refId
    final ebookItem = allEbooks.firstWhere(
      (ebook) => ebook.id.toString() == item.refId,
      orElse: () => throw Exception('E-Book not found'),
    );

    if (mounted) {
      Navigator.pop(context); // Close loading
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioEbookDetailScreen(item: ebookItem),
        ),
      );
    }
  }

  Future<void> _navigateToPuja(FestivalContentItem item) async {
    final pujaService = PujaService();
    final puja = await pujaService.getPujaById(int.parse(item.refId));

    if (puja == null) {
      throw Exception('Puja not found');
    }

    if (mounted) {
      Navigator.pop(context); // Close loading
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PujaDetailScreen(puja: puja)),
      );
    }
  }

  Future<void> _navigateToArticle(FestivalContentItem item) async {
    final articleService = ArticleService();
    final article = await articleService.fetchArticleById(
      int.parse(item.refId),
    );

    if (article == null) {
      throw Exception('Article not found');
    }

    if (mounted) {
      Navigator.pop(context); // Close loading
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleDetailScreen(article: article),
        ),
      );
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
