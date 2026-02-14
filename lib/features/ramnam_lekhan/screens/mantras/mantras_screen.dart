// features/ramnam_lekhan/screens/mantras/mantras_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/services/mantra_service.dart';
import '../../../../core/services/language_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/mantra_model.dart';
import '../mantra_detail/mantra_detail_screen.dart';

class MantrasScreen extends StatefulWidget {
  final String? initialCategory;

  const MantrasScreen({super.key, this.initialCategory});

  @override
  State<MantrasScreen> createState() => _MantrasScreenState();
}

class _MantrasScreenState extends State<MantrasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MantraService _mantraService = MantraService();
  
  List<MantraModel> _allMantras = [];
  List<MantraModel> _filteredMantras = [];
  bool _isSearching = false;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _searchController.addListener(_onSearchChanged);
    _loadMantras();
  }

  /// Load mantras from Supabase
  Future<void> _loadMantras() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _allMantras = await _mantraService.getAllMantras();
      _filterMantras();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load mantras. Please check your internet connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      _filterMantras();
    });
  }

  /// Deity filter icons (Unicode escapes avoid encoding issues).
  String _getDeityIcon(String category) {
    switch (category) {
      case 'Durga':
        return 'दुर्गा';
      case 'Ganesha':
        return 'गणेश';
      case 'Hanuman':
        return 'हनुमान';
      case 'Krishna':
        return 'कृष्ण';
      case 'Lakshmi':
        return 'लक्ष्मी';
      case 'Narasimha':
        return 'नरसिंह';
      case 'Parvati':
        return 'पार्वती';
      case 'Radha':
        return 'राधा';
      case 'Ram':
        return 'राम';
      case 'Saraswati':
        return 'सरस्वती';
      case 'Shani':
        return 'शनि';
      case 'Shiv':
        return 'शिव';
      case 'Sita':
        return 'सीता';
      case 'Vishnu':
        return 'विष्णु';
      default:
        return '\u{1F549}'; // Default
    }
  }

  String _getCategoryDisplayName(String category, bool isHindi) {
    if (!isHindi) return category;
    
    // Hindi translations for deity categories
    switch (category) {
      case 'All':
        return 'सभी';
      case 'Durga':
        return 'दुर्गा';
      case 'Ganesha':
        return 'गणेश';
      case 'Hanuman':
        return 'हनुमान';
      case 'Krishna':
        return 'कृष्ण';
      case 'Lakshmi':
        return 'लक्ष्मी';
      case 'Narasimha':
        return 'नरसिंह';
      case 'Parvati':
        return 'पार्वती';
      case 'Radha':
        return 'राधा';
      case 'Ram':
        return 'राम';
      case 'Saraswati':
        return 'सरस्वती';
      case 'Shani':
        return 'शनि';
      case 'Shiv':
        return 'शिव';
      case 'Sita':
        return 'सीता';
      case 'Vishnu':
        return 'विष्णु';
      default:
        return category;
    }
  }

  void _filterMantras() {
    setState(() {
      final query = _searchController.text.toLowerCase();

      _filteredMantras = _allMantras.where((mantra) {
        final matchesSearch =
            query.isEmpty ||
            mantra.mantra.toLowerCase().contains(query) ||
            mantra.hindiMantra.contains(query) ||
            mantra.meaning.toLowerCase().contains(query) ||
            mantra.hindiMeaning.contains(query);

        final matchesCategory =
            _selectedCategory == 'All' || mantra.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filterMantras();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _filterMantras();
    });
  }

  void _onMantraTap(MantraModel mantra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MantraDetailScreen(mantra: mantra),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesService = Provider.of<FavoritesService>(context);
    final languageService = Provider.of<LanguageService>(context);
    final l10n = AppLocalizations.of(context)!;
    final isHindi = languageService.isHindi;

    // Show loading indicator
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            l10n.mantrasTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFFFFB366),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB366)),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.mantrasLoading,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error message
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            l10n.mantrasTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFFFFB366),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 80,
                  color: Color(0xFFADB5BD),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noInternetConnection,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isHindi
                      ? l10n.mantrasLoadFailed
                      : _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6C757D),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadMantras,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          children: [
            if (_selectedCategory != 'All') ...[
              Text(
                _getDeityIcon(_selectedCategory),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              l10n.mantrasTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFB366),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Leaderboard/Sadhak Profile Icon
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            tooltip: l10n.sadhakProfile,
            onPressed: () {
              Navigator.pushNamed(context, '/sadhna-dashboard');
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.divineMantras,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.discoverFavoriteMantras,
                        style: const TextStyle(
                          color: Color(0xFF6C757D),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE9ECEF),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2C3E50).withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: l10n.searchMantrasHint,
                            hintStyle: const TextStyle(
                              color: Color(0xFFADB5BD),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB366).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFFFFB366),
                                size: 20,
                              ),
                            ),
                            suffixIcon: _isSearching
                                ? Container(
                                    margin: const EdgeInsets.all(12),
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE9ECEF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.clear_rounded,
                                          color: Color(0xFF6C757D),
                                          size: 16,
                                        ),
                                      ),
                                      onPressed: _clearSearch,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (favoritesService.favoritesCount > 0)
            SliverToBoxAdapter(
              child: _buildFavoritesSection(favoritesService),
            ),
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),
          if (_filteredMantras.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final mantra = _filteredMantras[index];
                  final isFavorite = favoritesService.isFavorite(mantra.id);

                  return Container(
                    margin: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2C3E50).withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _onMantraTap(mantra),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isHindi ? mantra.hindiMantra : mantra.mantra,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFFFB366),
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isHindi ? mantra.hindiMeaning : mantra.meaning,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF2C3E50),
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      favoritesService.toggleFavorite(mantra.id),
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFavorite
                                        ? Colors.red
                                        : const Color(0xFFADB5BD),
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(
                                      mantra.difficultyLevel,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getDifficultyColor(
                                        mantra.difficultyLevel,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    isHindi
                                        ? mantra.difficultyLevel.hindiDisplayName
                                        : mantra.difficultyLevel.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getDifficultyColor(
                                        mantra.difficultyLevel,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  mantra.category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6C757D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _filteredMantras.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(FavoritesService favoritesService) {
    final l10n = AppLocalizations.of(context)!;
    final isHindi = Provider.of<LanguageService>(context).isHindi;
    final favoriteMantras = _allMantras
        .where((mantra) => favoritesService.isFavorite(mantra.id))
        .toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.favoriteMantras,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${favoritesService.favoritesCount}',
                  style: const TextStyle(
                    color: Color(0xFFFFB366),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteMantras.length,
              itemBuilder: (context, index) {
                final mantra = favoriteMantras[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE9ECEF),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2C3E50).withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _onMantraTap(mantra),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi ? mantra.hindiMantra : mantra.mantra,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFB366),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isHindi ? mantra.hindiMeaning : mantra.meaning,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6C757D),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;
    
    final allCategories = [
      'All',
      'Durga',
      'Ganesha',
      'Hanuman',
      'Krishna',
      'Lakshmi',
      'Narasimha',
      'Parvati',
      'Radha',
      'Ram',
      'Saraswati',
      'Shani',
      'Shiv',
      'Sita',
      'Vishnu',
    ];

    // Create a custom list where selected category appears right after "All"
    List<String> categories = ['All'];
    if (_selectedCategory != 'All') {
      categories.add(_selectedCategory);
    }
    // Add remaining categories (excluding the selected one)
    categories.addAll(
      allCategories.where((cat) => cat != 'All' && cat != _selectedCategory),
    );

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                _getCategoryDisplayName(category, isHindi),
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFFFB366),
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onCategoryChanged(category);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFFFB366),
              checkmarkColor: Colors.white,
              elevation: isSelected ? 4 : 1,
              shadowColor: const Color(0xFFFFB366).withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: const Color(0xFFADB5BD),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noMantrasFound,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tryChangingSearchTerms,
            style: const TextStyle(fontSize: 16, color: Color(0xFF6C757D)),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.difficult:
        return Colors.red;
    }
  }
}


