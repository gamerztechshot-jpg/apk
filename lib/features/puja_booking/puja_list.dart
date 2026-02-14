// features/puja_booking/puja_list.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../../core/models/puja_model.dart';
import '../../core/models/puja_story_model.dart';
import '../../core/services/puja_service.dart';
import '../../core/services/puja_story_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/database_test_service.dart';
import '../../core/widgets/cached_network_image_widget.dart';
import '../../core/widgets/puja_story_widget.dart';
import '../../features/home/banner.dart';
import 'package:provider/provider.dart';
import 'puja_detail_screen.dart';
import 'bookings_screen.dart';

class PujaListScreen extends StatefulWidget {
  final bool hideBackButton;
  
  const PujaListScreen({super.key, this.hideBackButton = false});

  @override
  State<PujaListScreen> createState() => _PujaListScreenState();
}

class _PujaListScreenState extends State<PujaListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<BannerCarouselState> _bannerKey =
      GlobalKey<BannerCarouselState>();
  List<PujaModel> _pujas = [];
  List<PujaModel> _filteredPujas = [];
  List<PujaStoryModel> _stories = [];
  bool _isLoading = true;
  bool _isStoriesLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadPujas();
    _loadStories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPujas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pujaService = Provider.of<PujaService>(context, listen: false);
      final pujas = await pujaService.getAllPujas();

      setState(() {
        _pujas = pujas;
        _filteredPujas = pujas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pujas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStories() async {
    setState(() {
      _isStoriesLoading = true;
    });

    try {
      final storyService = PujaStoryService();
      final stories = await storyService.getAllStories();


      setState(() {
        _stories = stories;
        _isStoriesLoading = false;
      });

    } catch (e) {
      setState(() {
        _stories = [];
        _isStoriesLoading = false;
      });
    }
  }

  void _filterPujas(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<PujaModel> filtered = _pujas;

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((puja) {
        final pujaCategory = puja.category.toLowerCase().trim();
        final selectedCategory = _selectedCategory!.toLowerCase().trim();
        final matches = pujaCategory == selectedCategory;
        if (matches) {
        } else {
        }
        return matches;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final languageService = Provider.of<LanguageService>(
        context,
        listen: false,
      );
      final isHindi = languageService.isHindi;

      filtered = filtered.where((puja) {
        final basic = isHindi ? puja.pujaBasicHi : puja.pujaBasic;
        final searchQuery = _searchQuery.toLowerCase().trim();
        return basic.name.toLowerCase().trim().contains(searchQuery) ||
            basic.title.toLowerCase().trim().contains(searchQuery) ||
            basic.location.toLowerCase().trim().contains(searchQuery);
      }).toList();
    }

    _filteredPujas = filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.pujaPaathTitle,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.hideBackButton,
        leading: widget.hideBackButton
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.book_online, size: isTablet ? 28 : 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookingsScreen()),
              );
            },
            tooltip: l10n.mySankalp,
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade50, Colors.white],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadPujas();
              await _loadStories();
              // Refresh banners
              if (_bannerKey.currentState != null) {
                await _bannerKey.currentState!.refreshBanners();
              }
            },
            color: Colors.orange.shade600,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Search Bar
                  _buildSearchBar(context, l10n, isTablet),

                  // Banner Carousel
                  BannerCarousel(key: _bannerKey, bannerType: BannerType.puja),

                  // Stories Row
                  if (!_isStoriesLoading && _stories.isNotEmpty)
                    PujaStoryWidget(
                      stories: _stories,
                      onStoryTap: _filterByCategory,
                    ),

                  // Content
                  _isLoading
                      ? _buildLoadingWidget(isTablet)
                      : _filteredPujas.isEmpty
                      ? _buildEmptyWidget(l10n, isTablet)
                      : _buildPujaList(context, l10n, isTablet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    AppLocalizations l10n,
    bool isTablet,
  ) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.searchPlaceholder,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade400,
            size: isTablet ? 24 : 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade400,
                    size: isTablet ? 24 : 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterPujas('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 18 : 15,
          ),
        ),
        onChanged: _filterPujas,
      ),
    );
  }

  Widget _buildLoadingWidget(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            strokeWidth: 3,
          ),
          SizedBox(height: isTablet ? 24 : 16),
          Text(
            'Loading Pujas...',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(AppLocalizations l10n, bool isTablet) {
    String title;
    String message;
    IconData icon;

    if (_selectedCategory != null) {
      title = 'No Pujas in $_selectedCategory Category';
      message =
          'No pujas found for the selected category. Try selecting a different category or clear the filter.';
      icon = Icons.category;
    } else if (_searchQuery.isNotEmpty) {
      title = 'No Pujas Found';
      message = 'Try searching with different keywords';
      icon = Icons.search_off;
    } else {
      title = 'No Pujas Available';
      message =
          'No pujas found in database. Please add some pujas to get started.';
      icon = Icons.temple_hindu;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isTablet ? 80 : 64, color: Colors.grey.shade400),
          SizedBox(height: isTablet ? 24 : 16),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            message,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedCategory != null) ...[
            SizedBox(height: isTablet ? 24 : 16),
            ElevatedButton.icon(
              onPressed: () => _filterByCategory(null),
              icon: Icon(Icons.clear),
              label: Text('Clear Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 20,
                  vertical: isTablet ? 12 : 10,
                ),
              ),
            ),
          ] else if (_searchQuery.isEmpty) ...[
            SizedBox(height: isTablet ? 24 : 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadPujas,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 20,
                      vertical: isTablet ? 12 : 10,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                ElevatedButton.icon(
                  onPressed: _testDatabase,
                  icon: Icon(Icons.bug_report),
                  label: Text('Test DB'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 20,
                      vertical: isTablet ? 12 : 10,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                ElevatedButton.icon(
                  onPressed: _loadStories,
                  icon: Icon(Icons.collections),
                  label: Text('Load Stories'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 20,
                      vertical: isTablet ? 12 : 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPujaList(
    BuildContext context,
    AppLocalizations l10n,
    bool isTablet,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      child: Column(
        children: _filteredPujas.map((puja) {
          return _buildPujaCard(context, puja, l10n, isTablet);
        }).toList(),
      ),
    );
  }

  Widget _buildPujaCard(
    BuildContext context,
    PujaModel puja,
    AppLocalizations l10n,
    bool isTablet,
  ) {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;
    final basic = isHindi ? puja.pujaBasicHi : puja.pujaBasic;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PujaDetailScreen(puja: puja)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.orange.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              height: isTablet ? 200 : 160,
              width: double.infinity,
              child: Stack(
                children: [
                  // Main Image
                  CachedNetworkImageWidget(
                    imageUrl: puja.pujaImages.isNotEmpty
                        ? puja.pujaImages.first
                        : 'https://picsum.photos/400/300?random=99',
                    width: double.infinity,
                    height: isTablet ? 200 : 160,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    placeholder: Container(
                      height: isTablet ? 200 : 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange.shade600,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      height: isTablet ? 200 : 160,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.temple_hindu,
                            color: Colors.orange.shade400,
                            size: isTablet ? 48 : 40,
                          ),
                          SizedBox(height: isTablet ? 8 : 6),
                          Text(
                            'Puja Image',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Gradient overlay
                  Container(
                    height: isTablet ? 200 : 160,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                  // Devotee count badge
                  Positioned(
                    top: isTablet ? 16 : 12,
                    right: isTablet ? 16 : 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12 : 8,
                        vertical: isTablet ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.white,
                            size: isTablet ? 16 : 14,
                          ),
                          SizedBox(width: isTablet ? 6 : 4),
                          Text(
                            '${puja.devoteeCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (orange, bigger)
                  Text(
                    basic.title,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isTablet ? 8 : 6),

                  // Puja Name and Location Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Puja Name (black, small)
                      Expanded(
                        child: Text(
                          basic.name,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.grey.shade500,
                            size: isTablet ? 16 : 14,
                          ),
                          SizedBox(width: isTablet ? 4 : 2),
                          Text(
                            basic.location,
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 12 : 8),

                  // Description and Date Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description on the left
                      Expanded(
                        child: Text(
                          basic.shortDescription,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(width: isTablet ? 16 : 12),

                      // Date on the right
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey.shade500,
                            size: isTablet ? 16 : 14,
                          ),
                          SizedBox(width: isTablet ? 4 : 2),
                          Text(
                            _formatDate(puja.eventDate),
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 16 : 12),

                  // Starting from and Book now Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Starting from
                      Text(
                        '${l10n.startingFrom} ₹${puja.packages.isNotEmpty ? puja.packages.map((p) => p.price).reduce((a, b) => a < b ? a : b) : '0'}',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade600,
                        ),
                      ),

                      // Book Now Button
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                          vertical: isTablet ? 12 : 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade600,
                              Colors.orange.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.shade300,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.sankalpNow,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: isTablet ? 6 : 4),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: isTablet ? 16 : 14,
                            ),
                          ],
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date TBD';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _testDatabase() async {
    try {
      final testService = DatabaseTestService();

      // Test connection
      final connectionResult = await testService.testConnection();

      // Get table info
      final tableInfo = await testService.getTableInfo();

      // Show results
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Database Test Results'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection: ${connectionResult ? "âœ… Success" : "âŒ Failed"}',
                ),
                SizedBox(height: 8),
                Text(
                  'Table Info: ${tableInfo['success'] ? "âœ… Success" : "âŒ Failed"}',
                ),
                if (tableInfo['success'])
                  Text('Records found: ${tableInfo['count']}'),
                if (!tableInfo['success']) Text('Error: ${tableInfo['error']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              if (!tableInfo['success'] || tableInfo['count'] == 0)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _insertTestData();
                  },
                  child: Text('Insert Test Data'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _insertTestData() async {
    try {
      final testService = DatabaseTestService();
      final result = await testService.insertTestPuja();

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Test puja inserted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload pujas
          _loadPujas();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to insert test puja: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inserting test data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
