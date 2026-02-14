// features/home/widgets/home_highlights_section.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/audio_ebook_model.dart';
import '../../../core/models/puja_model.dart';
import '../../../core/models/store.dart';
import '../../../core/services/audio_ebook_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/puja_service.dart';
import '../../audio_ebook/audio_ebook_detail_screen.dart';
import '../../audio_ebook/audio_ebook_screen.dart';
import '../../dharma_store/screens/store_home_screen.dart';
import '../../dharma_store/services/cart_service.dart';
import '../../dharma_store/services/store_service.dart';
import '../../dharma_store/widgets/product_card.dart';
import '../../puja_booking/puja_detail_screen.dart';
import '../../puja_booking/puja_list.dart';
import '../../teacher/model/course.dart';
import '../../teacher/service/teacher_service.dart';
import '../../teacher/views/acharya_screen.dart';
import '../../teacher/views/widgets/course_card.dart';

class HomeHighlightsSection extends StatefulWidget {
  const HomeHighlightsSection({super.key});

  @override
  State<HomeHighlightsSection> createState() => _HomeHighlightsSectionState();
}

class _HomeHighlightsSectionState extends State<HomeHighlightsSection> {
  final TeacherService _teacherService = TeacherService();
  final AudioEbookService _audioEbookService = AudioEbookService();
  final PujaService _pujaService = PujaService();
  final StoreService _storeService = StoreService();

  List<Course> _homeCourses = [];
  List<AudioEbookModel> _homeAudioEbooks = [];
  List<PujaModel> _homePujas = [];
  List<Store> _homeProducts = [];
  bool _isLoading = true;
  bool? _lastIsHindi;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isHindi = Provider.of<LanguageService>(context).isHindi;
    if (_lastIsHindi == null || _lastIsHindi != isHindi) {
      _lastIsHindi = isHindi;
      _loadHomeHighlights(isHindi);
    }
  }

  Future<void> _loadHomeHighlights(bool isHindi) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _storeService.initialize();

      final results = await Future.wait([
        _teacherService.getCourses(),
        _audioEbookService.fetchAllData(),
        _pujaService.getAllPujas(),
        _storeService.getProducts(isHindi: isHindi),
      ]);

      final courses = results[0] as List<Course>;
      final audioData = results[1] as Map<String, List<AudioEbookModel>>;
      final pujas = results[2] as List<PujaModel>;
      final products = results[3] as List<Store>;

      final mixedAudioEbooks = [
        ...?audioData['audiobooks'],
        ...?audioData['ebooks'],
      ];
      mixedAudioEbooks.shuffle(Random());

      if (!mounted) return;

      setState(() {
        _homeCourses = courses;
        _homeAudioEbooks = mixedAudioEbooks;
        _homePujas = pujas;
        _homeProducts = products;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Provider.of<LanguageService>(context, listen: false).isHindi;

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_homeCourses.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            titleEn: 'Courses',
            titleHi: 'कोर्स',
            taglineEn: 'Learn from our Gurukul courses',
            taglineHi: 'हमारे गुरुकुल के कोर्स से सीखें',
            actionEn: 'View all',
            actionHi: 'सभी देखें',
            onActionTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AcharyaScreen()),
              );
            },
          ),
          _buildCoursesSlider(context),
          const SizedBox(height: 16),
        ],
        if (_homeAudioEbooks.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            titleEn: 'Audio & Ebooks',
            titleHi: 'ऑडियो और ईबुक्स',
            taglineEn: 'Read or listen to dharmic wisdom',
            taglineHi: 'धार्मिक ज्ञान पढ़ें या सुनें',
            actionEn: 'Explore',
            actionHi: 'देखें',
            onActionTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AudioEbookScreen()),
              );
            },
          ),
          _buildAudioEbookSlider(context, isHindi),
          const SizedBox(height: 16),
        ],
        if (_homeProducts.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            titleEn: 'Store Products',
            titleHi: 'स्टोर उत्पाद',
            taglineEn: 'Bring dharmik essentials home',
            taglineHi: 'धार्मिक सामग्री घर लाएं',
            actionEn: 'Shop',
            actionHi: 'खरीदें',
            onActionTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoreHomeScreen()),
              );
            },
          ),
          _buildStoreSlider(context, isHindi),
          const SizedBox(height: 24),
        ],
        if (_homePujas.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            titleEn: 'Puja Booking',
            titleHi: 'पूजा बुकिंग',
            taglineEn: 'Book sacred pujas with ease',
            taglineHi: 'आसानी से पवित्र पूजा बुक करें',
            actionEn: 'Book now',
            actionHi: 'बुक करें',
            onActionTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PujaListScreen()),
              );
            },
          ),
          _buildPujaSlider(context, isHindi),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String titleEn,
    required String titleHi,
    required String taglineEn,
    required String taglineHi,
    String? actionEn,
    String? actionHi,
    VoidCallback? onActionTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;
    final isHindi =
        Provider.of<LanguageService>(context, listen: false).isHindi;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalMargin, 20, horizontalMargin, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? titleHi : titleEn,
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  taglineEn,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  taglineHi,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (onActionTap != null && actionEn != null && actionHi != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                isHindi ? actionHi : actionEn,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoursesSlider(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;
    final courses = _homeCourses.take(10).toList();

    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return CourseCard(course: courses[index], onEnroll: () {});
        },
      ),
    );
  }

  Widget _buildAudioEbookSlider(BuildContext context, bool isHindi) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;
    final items = _homeAudioEbooks.take(10).toList();

    return SizedBox(
      height: 230,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _AudioEbookMiniCard(item: items[index], isHindi: isHindi);
        },
      ),
    );
  }

  Widget _buildPujaSlider(BuildContext context, bool isHindi) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;
    final pujas = _homePujas.take(10).toList();

    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        scrollDirection: Axis.horizontal,
        itemCount: pujas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final puja = pujas[index];
          return SizedBox(
            width: isTablet ? 320 : 280,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PujaDetailScreen(puja: puja),
                  ),
                );
              },
              child: _PujaMiniCard(puja: puja, isHindi: isHindi),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreSlider(BuildContext context, bool isHindi) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalMargin = isTablet ? 40.0 : 20.0;
    final products = _homeProducts.take(10).toList();
    final cartService = Provider.of<CartService>(context, listen: false);

    return SizedBox(
      height: 280,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: isTablet ? 220 : 200,
            child: ProductCard(
              product: product,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StoreHomeScreen(),
                  ),
                );
              },
              onAddToCart: () async {
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
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isHindi
                            ? 'कार्ट में जोड़ने में त्रुटि'
                            : 'Error adding to cart',
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
            ),
          );
        },
      ),
    );
  }
}

class _AudioEbookMiniCard extends StatelessWidget {
  final AudioEbookModel item;
  final bool isHindi;

  const _AudioEbookMiniCard({required this.item, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AudioEbookDetailScreen(item: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Container(
                  height: 110,
                  width: double.infinity,
                  color: Colors.orange.shade50,
                  child: item.displayImage.isNotEmpty
                      ? Image.network(
                          item.displayImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.menu_book,
                            color: Colors.orange,
                          ),
                        )
                      : const Icon(Icons.menu_book, color: Colors.orange),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.type,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.priceText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHindi ? 'और देखें' : 'Tap to view',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PujaMiniCard extends StatelessWidget {
  final PujaModel puja;
  final bool isHindi;

  const _PujaMiniCard({required this.puja, required this.isHindi});

  @override
  Widget build(BuildContext context) {
    final basic = isHindi ? puja.pujaBasicHi : puja.pujaBasic;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: puja.pujaImages.isNotEmpty
                  ? Image.network(
                      puja.pujaImages.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.orange.shade50,
                        child: const Icon(
                          Icons.temple_hindu,
                          color: Colors.orange,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.orange.shade50,
                      child: const Icon(
                        Icons.temple_hindu,
                        color: Colors.orange,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  basic.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  basic.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  basic.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
