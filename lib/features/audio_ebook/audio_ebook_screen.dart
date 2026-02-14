// features/audio_ebook/audio_ebook_screen.dart
import 'package:flutter/material.dart';
import '../../core/services/audio_ebook_service.dart';
import '../../core/models/audio_ebook_model.dart';
import 'audio_ebook_detail_screen.dart';
import 'my_library_screen.dart';
import '../../core/services/auth_service.dart';
import '../articles/article_list_screen.dart';

class AudioEbookScreen extends StatefulWidget {
  const AudioEbookScreen({super.key});

  @override
  State<AudioEbookScreen> createState() => _AudioEbookScreenState();
}

class _AudioEbookScreenState extends State<AudioEbookScreen>
    with SingleTickerProviderStateMixin {
  final AudioEbookService _audioEbookService = AudioEbookService();
  List<AudioEbookModel> _audiobooks = [];
  List<AudioEbookModel> _ebooks = [];
  List<AudioEbookModel> _filteredAudiobooks = [];
  List<AudioEbookModel> _filteredEbooks = [];
  bool _isLoading = true;
  bool _hasError = false;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Category filtering - separate for audio and ebooks
  List<String> _audioCategories = [];
  List<String> _ebookCategories = [];
  String _selectedAudioCategory = 'All';
  String _selectedEbookCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // Trigger rebuild to show correct categories for current tab
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final data = await _audioEbookService.fetchAllData();

      if (mounted) {
        setState(() {
          _audiobooks = data['audiobooks']!;
          _ebooks = data['ebooks']!;
          _filteredAudiobooks = _audiobooks;
          _filteredEbooks = _ebooks;
          _isLoading = false;

          // Extract unique categories
          _extractCategories();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _extractCategories() {
    // Extract categories from audiobooks
    Set<String> audioCategorySet = {};
    for (var audio in _audiobooks) {
      if (audio.category.isNotEmpty &&
          audio.category.toLowerCase() != 'custom' &&
          audio.category.toLowerCase() != 'filter') {
        audioCategorySet.add(audio.category);
      }
    }

    // Extract categories from ebooks
    Set<String> ebookCategorySet = {};
    for (var ebook in _ebooks) {
      if (ebook.category.isNotEmpty &&
          ebook.category.toLowerCase() != 'custom' &&
          ebook.category.toLowerCase() != 'filter') {
        ebookCategorySet.add(ebook.category);
      }
    }

    // Sort categories and ensure 'All' is first for both
    List<String> sortedAudioCategories = audioCategorySet.toList()..sort();
    List<String> sortedEbookCategories = ebookCategorySet.toList()..sort();

    _audioCategories = ['All', ...sortedAudioCategories];
    _ebookCategories = ['All', ...sortedEbookCategories];
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      // Filter audiobooks using audio category
      _filteredAudiobooks = _audiobooks.where((item) {
        bool matchesSearch =
            query.isEmpty || item.title.toLowerCase().contains(query);
        bool matchesCategory =
            _selectedAudioCategory == 'All' ||
            item.category == _selectedAudioCategory;
        return matchesSearch && matchesCategory;
      }).toList();

      // Filter ebooks using ebook category
      _filteredEbooks = _ebooks.where((item) {
        bool matchesSearch =
            query.isEmpty || item.title.toLowerCase().contains(query);
        bool matchesCategory =
            _selectedEbookCategory == 'All' ||
            item.category == _selectedEbookCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      if (_tabController.index == 0) {
        // Ebook tab
        _selectedEbookCategory = category;
      } else if (_tabController.index == 1) {
        // Audio tab
        _selectedAudioCategory = category;
      }
    });
    _applyFilters();
  }

  List<String> _getCurrentCategories() {
    if (_tabController.index == 0) {
      // Ebook tab
      return _ebookCategories;
    } else if (_tabController.index == 1) {
      // Audio tab
      return _audioCategories;
    }
    return [];
  }

  String _getCurrentSelectedCategory() {
    if (_tabController.index == 0) {
      // Ebook tab
      return _selectedEbookCategory;
    } else if (_tabController.index == 1) {
      // Audio tab
      return _selectedAudioCategory;
    }
    return 'All';
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged(); // Trigger search update to show all items
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vedalay'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'My Purchases',
            icon: const Icon(Icons.library_books_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyLibraryScreen(
                    userId: AuthService().getCurrentUser()?.id ?? '',
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Ebook'),
            Tab(icon: Icon(Icons.headphones), text: 'Audio'),
            Tab(icon: Icon(Icons.article), text: 'Articles'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5DC), // Warm beige background
        ),
        child: _isLoading
            ? _buildLoadingScreen()
            : _hasError
            ? _buildErrorScreen()
            : Column(
                children: [
                  _buildSearchBar(),
                  _buildCategoryFilters(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable swipe
                      children: [
                        _buildEbookTab(),
                        _buildAudioTab(),
                        _buildArticlesTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading spiritual content...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    // Only show search bar for Audio and Ebook tabs, not for Articles
    if (_tabController.index == 2) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            _onSearchChanged(); // Trigger search when text changes
          },
          decoration: InputDecoration(
            hintText: 'Search by title name',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade500,
              size: 24,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: _clearSearch,
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          style: const TextStyle(fontSize: 16, color: Color(0xFF8B4513)),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final currentCategories = _getCurrentCategories();
    final currentSelectedCategory = _getCurrentSelectedCategory();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (currentCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: currentCategories.length,
        itemBuilder: (context, index) {
          final category = currentCategories[index];
          final isSelected = category == currentSelectedCategory;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: GestureDetector(
                onTap: () => _onCategorySelected(category),
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: isDarkMode
                                    ? [
                                        Colors.orange.shade400,
                                        Colors.orange.shade600,
                                      ]
                                    : [
                                        Colors.orange.shade300,
                                        Colors.orange.shade500,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isDarkMode
                                ? Colors.grey.shade200
                                : Colors.grey.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAudioTab() {
    return _buildContentTab(_filteredAudiobooks, 'Audio');
  }

  Widget _buildEbookTab() {
    return _buildEbookGrid(_filteredEbooks);
  }

  Widget _buildArticlesTab() {
    return const ArticleListScreen();
  }

  Widget _buildContentTab(List<AudioEbookModel> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == 'Audio' ? Icons.headphones : Icons.menu_book,
                size: 80,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'No ${type.toLowerCase()}s Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check back later for new spiritual content.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildContentCard(items[index]);
      },
    );
  }

  Widget _buildEbookGrid(List<AudioEbookModel> ebooks) {
    if (ebooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 80, color: Colors.orange.shade400),
              const SizedBox(height: 24),
              Text(
                'No Ebooks Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check back later for new spiritual content.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.60, // Adjust this to make cards taller/shorter
        ),
        itemCount: ebooks.length,
        itemBuilder: (context, index) {
          return _buildEbookCard(ebooks[index]);
        },
      ),
    );
  }

  Widget _buildEbookCard(AudioEbookModel item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioEbookDetailScreen(item: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange.shade300, Colors.orange.shade500],
                  ),
                ),
                child: item.displayImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          item.displayImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 40,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.shade300,
                              Colors.orange.shade500,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.menu_book,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),

            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      item.description.isNotEmpty
                          ? item.description
                          : 'A spiritual guide for your journey',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AudioEbookDetailScreen(item: item),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          item.paid ? 'Purchase' : 'Read',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
  }

  Widget _buildContentCard(AudioEbookModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioEbookDetailScreen(item: item),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Cover Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: item.displayImage.isNotEmpty
                        ? Image.network(
                            item.displayImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              item.type == 'Audio'
                                  ? Icons.headphones
                                  : Icons.menu_book,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and FREE/PAID tag
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B4513), // Dark brown color
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // FREE/PAID Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: item.paid
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.paid
                                    ? Colors.orange.shade300
                                    : Colors.green.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              item.paid ? 'PAID' : 'FREE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.paid
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        item.description.isNotEmpty
                            ? item.description
                            : 'A collection of spiritual content',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Action Button (Play for Audio, Read for Ebook)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513), // Dark brown color
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AudioEbookDetailScreen(item: item),
                        ),
                      );
                    },
                    icon: Icon(
                      item.type == 'Audio' ? Icons.play_arrow : Icons.menu_book,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
