// features/puja_booking/puja_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../../core/models/puja_model.dart';
import '../../core/services/language_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/cached_network_image_widget.dart';
import '../../core/widgets/image_slider_widget.dart';
import 'package:provider/provider.dart';
import 'puja_payment/puja_payment_screen.dart';

class PujaDetailScreen extends StatefulWidget {
  final PujaModel puja;

  const PujaDetailScreen({super.key, required this.puja});

  @override
  State<PujaDetailScreen> createState() => _PujaDetailScreenState();
}

class _PujaDetailScreenState extends State<PujaDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  late ScrollController _scrollController;
  int _selectedPackageIndex = 0;
  int _currentSectionIndex = 0;
  final List<GlobalKey> _sectionKeys = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _pageController = PageController();
    _scrollController = ScrollController();

    // Initialize section keys
    for (int i = 0; i < 6; i++) {
      _sectionKeys.add(GlobalKey());
    }

    // Initialize selected package index safely
    _selectedPackageIndex = 0;

    // Listen to scroll changes to update active tab
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PujaDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure selected package index is valid when packages change
    final packages = widget.puja.packages;
    if (_selectedPackageIndex >= packages.length) {
      _selectedPackageIndex = packages.isNotEmpty ? 0 : 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Update active tab based on scroll position
    final scrollOffset = _scrollController.offset;
    final tabBarHeight = 48.0; // Height of the sticky tab bar
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;

    // Calculate which section is currently visible
    int newSectionIndex = 0;

    // Get the positions of each section
    for (int i = 0; i < _sectionKeys.length; i++) {
      final context = _sectionKeys[i].currentContext;
      if (context != null) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final sectionTop = position.dy - appBarHeight - tabBarHeight;

        if (scrollOffset >= sectionTop - 100) {
          // 100px threshold
          newSectionIndex = i;
        }
      }
    }

    if (newSectionIndex != _currentSectionIndex) {
      setState(() {
        _currentSectionIndex = newSectionIndex;
      });

      // Update tab controller without triggering scroll
      if (_tabController.index != newSectionIndex) {
        _tabController.animateTo(newSectionIndex);
      }
    }
  }

  void _scrollToSection(int index) {
    final context = _sectionKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;

    final basic = isHindi
        ? (widget.puja.pujaBasicHi.name.isNotEmpty
              ? widget.puja.pujaBasicHi
              : widget.puja.pujaBasic)
        : widget.puja.pujaBasic;
    final content = isHindi
        ? (widget.puja.contentHi.aboutPuja.isNotEmpty
              ? widget.puja.contentHi
              : widget.puja.content)
        : widget.puja.content;
    final templeDetails = isHindi
        ? (widget.puja.templeDetailsHi.heading.isNotEmpty
              ? widget.puja.templeDetailsHi
              : widget.puja.templeDetails)
        : widget.puja.templeDetails;
    final packages = isHindi
        ? (widget.puja.packagesHi.isNotEmpty
              ? widget.puja.packagesHi
              : widget.puja.packages)
        : widget.puja.packages;

    // Debug: Print package information

    final reviews = isHindi
        ? (widget.puja.reviewsHi.isNotEmpty
              ? widget.puja.reviewsHi
              : widget.puja.reviews)
        : widget.puja.reviews;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: isTablet ? 300 : 250,
            pinned: true,
            backgroundColor: Colors.orange.shade600,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Slider
                  ImageSliderWidget(
                    images: widget.puja.pujaImages.isNotEmpty
                        ? widget.puja.pujaImages
                        : ['https://picsum.photos/800/600?random=99'],
                    height: isTablet ? 300 : 250,
                    width: double.infinity,
                    showIndicators: true,
                    autoPlay: widget.puja.pujaImages.length > 1,
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Devotee count badge
                  Positioned(
                    top: isTablet ? 60 : 50,
                    right: isTablet ? 20 : 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.white,
                            size: isTablet ? 18 : 16,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            '${widget.puja.devoteeCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 16 : 14,
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
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: isTablet ? 28 : 24,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Title and Basic Info
          SliverToBoxAdapter(child: _buildTitleSection(basic, isTablet)),

          // Devotee Section
          SliverToBoxAdapter(child: _buildDevoteeSection(isTablet)),

          // Sticky Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              child: _buildTabBar(l10n, isTablet),
            ),
          ),

          // Scrollable Content Sections
          SliverToBoxAdapter(
            child: _buildScrollableContent(
              content,
              templeDetails,
              packages,
              reviews,
              isTablet,
            ),
          ),
        ],
      ),

      // Bottom Booking Bar
      bottomNavigationBar: _buildBottomBookingBar(packages, isTablet),
    );
  }

  Widget _buildTitleSection(PujaBasic basic, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Puja Title (orange, bigger) - moved above
          Text(
            basic.title,
            style: TextStyle(
              fontSize: isTablet ? 24 : 22,
              color: Colors.orange.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),

          // Puja Name (small, black)
          Text(
            basic.name,
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),

          // Location and Date
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.grey.shade600,
                size: isTablet ? 20 : 18,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Expanded(
                child: Text(
                  basic.location,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 8 : 6),

          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.grey.shade600,
                size: isTablet ? 20 : 18,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Text(
                _formatDate(widget.puja.eventDate),
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 8 : 6),

          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.grey.shade600,
                size: isTablet ? 20 : 18,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Text(
                l10n.bookingCloses(
                  _formatDateTime(widget.puja.bookingClosesAt),
                ),
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n, bool isTablet) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.orange.shade600,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.orange.shade600,
        indicatorWeight: 3,
        labelStyle: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w600,
        ),
        onTap: (index) {
          _scrollToSection(index);
        },
        tabs: [
          Tab(text: l10n.about),
          Tab(text: l10n.benefits),
          Tab(text: l10n.process),
          Tab(text: l10n.temple),
          Tab(text: l10n.packages),
          Tab(text: l10n.reviews),
        ],
      ),
    );
  }

  Widget _buildScrollableContent(
    PujaContent content,
    TempleDetails templeDetails,
    List<PujaPackage> packages,
    List<PujaReview> reviews,
    bool isTablet,
  ) {
    return Column(
      children: [
        // About Section
        _buildSectionContainer(
          key: _sectionKeys[0],
          child: _buildAboutTab(content, isTablet),
        ),

        // Benefits Section
        _buildSectionContainer(
          key: _sectionKeys[1],
          child: _buildBenefitsTab(content, isTablet),
        ),

        // Process Section
        _buildSectionContainer(
          key: _sectionKeys[2],
          child: _buildProcessTab(content, isTablet),
        ),

        // Temple Section
        _buildSectionContainer(
          key: _sectionKeys[3],
          child: _buildTempleTab(templeDetails, isTablet),
        ),

        // Packages Section
        _buildSectionContainer(
          key: _sectionKeys[4],
          child: _buildPackagesTab(packages, isTablet),
        ),

        // Reviews Section
        _buildSectionContainer(
          key: _sectionKeys[5],
          child: _buildReviewsTab(reviews, isTablet),
        ),
      ],
    );
  }

  Widget _buildSectionContainer({
    required GlobalKey key,
    required Widget child,
  }) {
    return Container(key: key, child: child);
  }

  Widget _buildAboutTab(PujaContent content, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 20,
        right: isTablet ? 24 : 20,
        top: isTablet ? 24 : 20,
        bottom: isTablet ? 24 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.aboutPuja, isTablet),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            content.aboutPuja,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsTab(PujaContent content, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 20,
        right: isTablet ? 24 : 20,
        top: isTablet ? 24 : 20,
        bottom: isTablet ? 24 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.benefits, isTablet),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            content.benefits,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessTab(PujaContent content, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: isTablet ? 24 : 20,
        right: isTablet ? 24 : 20,
        top: isTablet ? 24 : 20,
        bottom: isTablet ? 24 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.process, isTablet),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            content.process,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildTempleTab(TempleDetails templeDetails, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(templeDetails.heading, isTablet),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            templeDetails.description,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),

          if (templeDetails.url.isNotEmpty) ...[
            _buildSectionTitle('Temple', isTablet),
            SizedBox(height: isTablet ? 12 : 8),
            _buildTempleImage(templeDetails.url, isTablet),
          ],
        ],
      ),
    );
  }

  Widget _buildPackagesTab(List<PujaPackage> packages, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.availablePackages, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          ...packages.asMap().entries.map((entry) {
            final index = entry.key;
            final package = entry.value;
            final isSelected =
                _selectedPackageIndex == index &&
                _selectedPackageIndex < packages.length;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPackageIndex = index;
                });
              },
              child: Container(
                margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.orange.shade600
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Package Image
                    CachedNetworkImageWidget(
                      imageUrl: package.url,
                      width: isTablet ? 80 : 60,
                      height: isTablet ? 80 : 60,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      placeholder: Container(
                        width: isTablet ? 80 : 60,
                        height: isTablet ? 80 : 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
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
                        width: isTablet ? 80 : 60,
                        height: isTablet ? 80 : 60,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: Colors.orange.shade400,
                          size: isTablet ? 32 : 24,
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),

                    // Package Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.name,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            package.description,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: isTablet ? 8 : 6),
                          Text(
                            '₹${package.price}',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Selection Indicator
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Colors.orange.shade600,
                        size: isTablet ? 24 : 20,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(List<PujaReview> reviews, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('${l10n.reviews} (${reviews.length})', isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          ...reviews
              .map((review) => _buildReviewCard(review, isTablet))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildReviewCard(PujaReview review, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image
          CachedNetworkImageWidget(
            imageUrl: review.url,
            width: isTablet ? 50 : 40,
            height: isTablet ? 50 : 40,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
            placeholder: Container(
              width: isTablet ? 50 : 40,
              height: isTablet ? 50 : 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
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
              width: isTablet ? 50 : 40,
              height: isTablet ? 50 : 40,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.orange.shade400,
                size: isTablet ? 24 : 20,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),

          // Review Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.name,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  review.reviewText,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevoteeSection(bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final devoteeImages = widget.puja.devoteeImages.take(5).toList();
    final devoteeCount = widget.puja.devoteeCount;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating and Devotee Count Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Devotee Images
              Row(
                children: [
                  // Stack of overlapping devotee images
                  SizedBox(
                    width:
                        (isTablet ? 40 : 35) +
                        (devoteeImages.length - 1) *
                            (isTablet ? 30 : 25).toDouble(),
                    height: isTablet ? 40 : 35,
                    child: Stack(
                      children: devoteeImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final imageUrl = entry.value;
                        return Positioned(
                          left: index * (isTablet ? 30 : 25).toDouble(),
                          child: Container(
                            width: isTablet ? 40 : 35,
                            height: isTablet ? 40 : 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImageWidget(
                                imageUrl: imageUrl,
                                width: isTablet ? 40 : 35,
                                height: isTablet ? 40 : 35,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  width: isTablet ? 40 : 35,
                                  height: isTablet ? 40 : 35,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.grey.shade400,
                                    size: isTablet ? 20 : 18,
                                  ),
                                ),
                                errorWidget: Container(
                                  width: isTablet ? 40 : 35,
                                  height: isTablet ? 40 : 35,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.orange.shade400,
                                    size: isTablet ? 20 : 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(width: isTablet ? 20 : 16),

                  // Devotee Count
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.orange.shade600,
                        size: isTablet ? 20 : 18,
                      ),
                      SizedBox(width: isTablet ? 6 : 4),
                      Text(
                        '${_formatDevoteeCount(devoteeCount)} ${l10n.devotees}',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: isTablet ? 16 : 12),

          // Devotee Count Text
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              children: [
                TextSpan(text: 'Till now '),
                TextSpan(
                  text: '${_formatDevoteeCount(devoteeCount)} ${l10n.devotees}',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: l10n.tillNowDevoteesParticipated(
                    _formatDevoteeCount(devoteeCount),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDevoteeCount(int count) {
    if (count >= 100000) {
      return '${(count / 100000).toStringAsFixed(1)}L';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  Widget _buildSectionTitle(String title, bool isTablet) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isTablet ? 20 : 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTempleImage(String imageUrl, bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 200 : 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade100,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange.shade600,
                  ),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: isTablet ? 48 : 40,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Text(
                    'Image not available',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBookingBar(List<PujaPackage> packages, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;

    // Check if packages list is empty
    if (packages.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No packages available',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    final selectedPackage = packages[_selectedPackageIndex];

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.selectedPackage,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '₹${selectedPackage.price}',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Book Now Button
          ElevatedButton(
            onPressed: () {
              // Check if user is authenticated
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              if (!authService.isAuthenticated()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please login to book puja'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Navigate to payment screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PujaPaymentScreen(
                    puja: widget.puja,
                    selectedPackage: selectedPackage,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 24,
                vertical: isTablet ? 16 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              l10n.sankalpNow,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date TBD';
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Time TBD';
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
    return '${dateTime.day} ${months[dateTime.month - 1]} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
