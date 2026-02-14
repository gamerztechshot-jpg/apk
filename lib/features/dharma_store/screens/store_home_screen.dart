// features/dharma_store/screens/store_home_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../core/models/store.dart';
import '../../../core/services/language_service.dart';
import '../services/cart_service.dart';
import '../services/store_service.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController(
    viewportFraction: 0.92,
  );

  List<Store> _products = [];
  List<Store> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<String> _banners = [];
  int _currentBanner = 0;
  Timer? _bannerTimer;
  List<String> _categories = [];
  String _selectedCategory = 'All';
  LanguageService? _langService;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCart();
    _loadBanners();
    _loadCategories();
    // Listen to profile language changes and refresh categories accordingly
    _langService = Provider.of<LanguageService>(context, listen: false);
    _langService?.addListener(_onLanguageChanged);
  }

  Future<void> _loadCart() async {
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      await cartService.initialize();
      await cartService.loadCart();
    } catch (e) {}
  }

  Future<void> _loadCategories() async {
    try {
      final storeService = Provider.of<StoreService>(context, listen: false);
      final isHindi = Provider.of<LanguageService>(
        context,
        listen: false,
      ).isHindi;
      // Try localized categories first. If empty, fallback to legacy categories.
      List<String> cats = await storeService.getLocalizedCategories(
        isHindi: isHindi,
      );
      if (cats.isEmpty) {
        cats = await storeService.getCategories();
      }
      if (mounted) {
        setState(() {
          _categories = ['All', ...cats];
          _selectedCategory = 'All';
        });
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _langService?.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    // Re-fetch localized categories when user toggles language in profile
    _loadCategories();
    setState(() {});
  }

  Future<void> _loadBanners() async {
    try {
      final storeService = Provider.of<StoreService>(context, listen: false);
      await storeService.initialize();
      final urls = await storeService.getStoreBanners();
      if (mounted) {
        setState(() => _banners = urls);
        _startBannerAutoPlay();
      }
    } catch (e) {
      // Non-blocking: ignore banner errors
    }
  }

  void _startBannerAutoPlay() {
    _bannerTimer?.cancel();
    if (_banners.length <= 1) return; // no autoplay for single banner
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      if (_bannerController.hasClients) {
        final next = (_currentBanner + 1) % _banners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() => _currentBanner = next);
      }
    });
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      final storeService = Provider.of<StoreService>(context, listen: false);

      // Initialize store service with caching
      await storeService.initialize();

      // Test connection first
      await storeService.testConnection();

      final langNow = Provider.of<LanguageService>(
        context,
        listen: false,
      ).isHindi;
      final products = await storeService.getProducts(isHindi: langNow);
      setState(() {
        _products = products;
        _isLoading = false;
      });
      // Apply initial filtering
      _filterProducts();
      // refresh categories once products are available (fallback)
      await _loadCategories();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  void _filterProducts() {
    final q = _searchQuery.trim().toLowerCase();
    final cat = _selectedCategory.trim().toLowerCase();

    setState(() {
      _filteredProducts = _products.where((p) {
        final matchesSearch =
            q.isEmpty ||
            p.nameEn.toLowerCase().contains(q) ||
            p.nameHi.toLowerCase().contains(q);
        final matchesCategory =
            cat == 'all' || p.category.trim().toLowerCase() == cat;


        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  void _onProductTap(Store product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final cartService = Provider.of<CartService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5DC,
      ), // Light beige background like reference
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                'à¥',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isHindi ? 'धार्मिक स्टोर' : 'Dharmik Store',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cartService.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${cartService.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: isHindi ? 'उत्पाद खोजें' : 'Search for products',
                  prefixIcon: Icon(Icons.search, color: Colors.brown.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),

            // Banners Slider
            if (_banners.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width < 360
                          ? 120
                          : MediaQuery.of(context).size.width * 0.35,
                      child: PageView.builder(
                        controller: _bannerController,
                        onPageChanged: (i) =>
                            setState(() => _currentBanner = i),
                        itemCount: _banners.length,
                        itemBuilder: (context, index) {
                          final url = _banners[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.0),
                                          Colors.black.withOpacity(0.15),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Pagination dots above category filters
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (i) {
                        final active = i == _currentBanner;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          width: active ? 16 : 6,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.orange.shade600
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Category Chips below the pagination dots
                    if (_categories.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final selected = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _selectedCategory = cat);
                                _filterProducts();
                              },
                              selectedColor: Colors.orange.shade100,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.orange.shade800
                                    : Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                              visualDensity: const VisualDensity(
                                horizontal: -2,
                                vertical: -2,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: _categories.length,
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

            // Products List
            // Products List
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isHindi
                              ? 'कोई उत्पाद नहीं मिला'
                              : 'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate responsive columns based on screen width
                      final screenWidth = constraints.maxWidth;
                      int crossAxisCount;
                      double childAspectRatio;
                      double crossAxisSpacing;
                      double mainAxisSpacing;

                      if (screenWidth < 360) {
                        // Very small phones
                        crossAxisCount = 2;
                        childAspectRatio = 0.55;
                        crossAxisSpacing = 10;
                        mainAxisSpacing = 10;
                      } else if (screenWidth < 600) {
                        // Mobile phones - 2 columns
                        crossAxisCount = 2;
                        childAspectRatio =
                            0.6; // Taller cards to avoid overflow
                        crossAxisSpacing = 12;
                        mainAxisSpacing = 12;
                      } else if (screenWidth < 900) {
                        // Small tablets - 3 columns
                        crossAxisCount = 3;
                        childAspectRatio = 0.68;
                        crossAxisSpacing = 16;
                        mainAxisSpacing = 16;
                      } else {
                        // Large tablets and desktops - 4 columns
                        crossAxisCount = 4;
                        childAspectRatio = 0.72;
                        crossAxisSpacing = 20;
                        mainAxisSpacing = 20;
                      }

                      // Display already-filtered list
                      final filtered = _filteredProducts;

                      return GridView.builder(
                        padding: EdgeInsets.all(screenWidth < 600 ? 12 : 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: crossAxisSpacing,
                          mainAxisSpacing: mainAxisSpacing,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return ProductCard(
                            product: product,
                            onTap: () => _onProductTap(product),
                            onAddToCart: () async {
                              final cartService = Provider.of<CartService>(
                                context,
                                listen: false,
                              );
                              try {
                                await cartService.addToCart(
                                  itemId: product.id,
                                  nameEn: product.nameEn,
                                  nameHi: product.nameHi,
                                  price: product.price,
                                  imageUrl: product.imageUrl,
                                  quantity: 1,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isHindi
                                          ? 'कार्ट में जोड़ा गया'
                                          : 'Added to cart',
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      (isHindi
                                              ? 'कार्ट में जोड़ने में त्रुटि: '
                                              : 'Error adding to cart: ') +
                                          e.toString(),
                                    ),
                                    backgroundColor: Colors.red.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
