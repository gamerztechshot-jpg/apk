// features/mantra_generator/views/screens/sub_problem_content_cards_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/language_service.dart';
import 'package:karmasu/core/models/audio_ebook_model.dart';
import 'package:karmasu/core/models/puja_model.dart';
import 'package:karmasu/core/models/store.dart';
import 'package:karmasu/features/ramnam_lekhan/models/mantra_model.dart';
import 'package:karmasu/features/dharma_store/widgets/product_card.dart';
import 'package:karmasu/core/widgets/cached_network_image_widget.dart';
import '../../models/main_problem_model.dart';
import '../../models/sub_problem_model.dart';
import '../../../audio_ebook/audio_ebook_detail_screen.dart';
import '../../../puja_booking/puja_detail_screen.dart';
import '../../../dharma_store/screens/product_detail_screen.dart';
import '../../../ramnam_lekhan/screens/mantra_detail/mantra_detail_screen.dart';
import 'package:karmasu/features/astro/models/astrologer_model.dart';
import 'package:karmasu/features/astro/views/astrologer_detail_screen.dart';
import 'package:karmasu/features/astro/views/widgets/astrologer_card.dart';
import 'package:karmasu/features/astro/reposistries/astrologer_repository.dart';
import '../../../../core/services/audio_ebook_service.dart';
import '../../../../core/services/puja_service.dart';
import '../../../../core/services/mantra_service.dart';
import '../../../../features/dharma_store/services/store_service.dart';

class SubProblemContentCardsScreen extends StatefulWidget {
  final MainProblem mainProblem;
  final SubProblem subProblem;

  const SubProblemContentCardsScreen({
    super.key,
    required this.mainProblem,
    required this.subProblem,
  });

  @override
  State<SubProblemContentCardsScreen> createState() =>
      _SubProblemContentCardsScreenState();
}

class _SubProblemContentCardsScreenState
    extends State<SubProblemContentCardsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  final List<AudioEbookModel> _audioItems = [];
  final List<AudioEbookModel> _ebookItems = [];
  final List<PujaModel> _pujaItems = [];
  final List<Store> _storeItems = [];
  final List<AstrologerModel> _astrologerItems = [];
  MantraModel? _mantraItem;

  @override
  void initState() {
    super.initState();
    _fetchContentData();
  }

  Future<void> _fetchContentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final audioEbookService = AudioEbookService();
      final pujaService = PujaService();
      final mantraService = MantraService();
      final storeService = StoreService();
      final astrologerRepo = AstrologerRepository();

      // Helper to collect all IDs (legacy + array)
      List<String> getAllIds(List<String> ids, String? legacyId) {
        final Set<String> allIds = {};
        if (ids.isNotEmpty) allIds.addAll(ids);
        if (legacyId != null && legacyId.isNotEmpty) allIds.add(legacyId);
        return allIds.toList();
      }

      // 1. Fetch Audios
      final audioIds = getAllIds(
        widget.subProblem.audioIds,
        widget.subProblem.audioId,
      );
      if (audioIds.isNotEmpty) {
        final allAudios = await audioEbookService.fetchAudiobooks();
        for (final id in audioIds) {
          final item = allAudios.firstWhere(
            (a) => a.id.toString() == id,
            orElse: () => throw Exception('Audio $id not found'),
          );
          _audioItems.add(item);
        }
      }

      // 2. Fetch Ebooks
      final ebookIds = getAllIds(
        widget.subProblem.ebookIds,
        widget.subProblem.ebookId,
      );
      if (ebookIds.isNotEmpty) {
        final allEbooks = await audioEbookService.fetchEbooks();
        for (final id in ebookIds) {
          final item = allEbooks.firstWhere(
            (e) => e.id.toString() == id,
            orElse: () => throw Exception('Ebook $id not found'),
          );
          _ebookItems.add(item);
        }
      }

      // 3. Fetch Mantra
      if (widget.subProblem.mantraId != null &&
          widget.subProblem.mantraId!.isNotEmpty) {
        final mantra = await mantraService.getMantraById(
          widget.subProblem.mantraId!,
        );
        if (mantra != null) {
          _mantraItem = mantra;
        }
      }

      // 4. Fetch Pujas
      final pujaIds = getAllIds(
        widget.subProblem.pujaIds,
        widget.subProblem.pujaId,
      );
      if (pujaIds.isNotEmpty) {
        for (final id in pujaIds) {
          final pujaIdInt = int.tryParse(id);
          if (pujaIdInt != null) {
            final puja = await pujaService.getPujaById(pujaIdInt);
            if (puja != null) {
              _pujaItems.add(puja);
            }
          }
        }
      }

      // 5. Fetch Store Items
      final storeIds = getAllIds(
        widget.subProblem.dharmaStoreIds,
        widget.subProblem.dharmaStoreId,
      );
      if (storeIds.isNotEmpty) {
        for (final id in storeIds) {
          final product = await storeService.getProductById(id);
          _storeItems.add(product);
        }
      }

      // 6. Fetch Astrologers
      final astrologerIds = getAllIds(
        widget.subProblem.astrologerIds,
        widget.subProblem.astrologerId,
      );
      if (astrologerIds.isNotEmpty) {
        for (final id in astrologerIds) {
          try {
            final astrologer = await astrologerRepo.getAstrologerById(id);
            if (astrologer != null) {
              _astrologerItems.add(astrologer);
            }
          } catch (e) {
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.subProblem.getTitle(isHindi ? 'hi' : 'en'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : CustomScrollView(
              slivers: [
                // Title and Description Section
                SliverToBoxAdapter(
                  child: _buildTitleAndDescription(context, isHindi),
                ),

                // Content Section
                if (_isEmpty())
                  SliverFillRemaining(child: _buildEmptyState(context, isHindi))
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Mantra section (Single Card)
                        if (widget.subProblem.getMantra(
                                  isHindi ? 'hi' : 'en',
                                ) !=
                                null &&
                            widget.subProblem
                                .getMantra(isHindi ? 'hi' : 'en')!
                                .isNotEmpty) ...[
                          _buildSectionTitle(isHindi ? 'मंत्र' : 'Mantra'),
                          _buildSimpleMantraCard(
                            widget.subProblem.getMantra(isHindi ? 'hi' : 'en')!,
                            isHindi,
                          ),
                          const SizedBox(height: 20),
                        ] else if (_mantraItem != null) ...[
                          _buildSectionTitle(isHindi ? 'मंत्र' : 'Mantra'),
                          _buildMantraCard(_mantraItem!),
                          const SizedBox(height: 20),
                        ],

                        // Audio section
                        if (_audioItems.isNotEmpty) ...[
                          _buildSectionTitle(isHindi ? 'ऑडियो' : 'Audio'),
                          ..._audioItems.map((item) => _buildAudioCard(item)),
                          const SizedBox(height: 10),
                        ],

                        // Ebook section (Grid-like)
                        if (_ebookItems.isNotEmpty) ...[
                          _buildSectionTitle(isHindi ? 'ई-बुक' : 'E-Book'),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.65,
                                ),
                            itemCount: _ebookItems.length,
                            itemBuilder: (context, index) =>
                                _buildEbookCard(_ebookItems[index]),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Puja section
                        if (_pujaItems.isNotEmpty) ...[
                          _buildSectionTitle(isHindi ? 'पूजा' : 'Puja'),
                          ..._pujaItems.map(
                            (puja) => _buildPujaCard(puja, isHindi),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Store section (Grid-like)
                        if (_storeItems.isNotEmpty) ...[
                          _buildSectionTitle(
                            isHindi ? 'धर्म स्टोर' : 'Dharma Store',
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: _storeItems.length,
                            itemBuilder: (context, index) => ProductCard(
                              product: _storeItems[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      product: _storeItems[index],
                                    ),
                                  ),
                                );
                              },
                              onAddToCart: () {
                                // Add to cart logic or navigate to detail
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      product: _storeItems[index],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Astrologer Section
                        if (_astrologerItems.isNotEmpty) ...[
                          _buildSectionTitle(
                            isHindi ? 'ज्योतिषी' : 'Astrologer',
                          ),
                          ..._astrologerItems.map(
                            (astrologer) =>
                                _buildAstrologerCard(astrologer, isHindi),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }

  bool _isEmpty() {
    final hasLocalMantra =
        (widget.subProblem.mantraEn?.isNotEmpty ?? false) ||
        (widget.subProblem.mantraHi?.isNotEmpty ?? false);

    return _audioItems.isEmpty &&
        _ebookItems.isEmpty &&
        _pujaItems.isEmpty &&
        _storeItems.isEmpty &&
        _mantraItem == null &&
        _astrologerItems.isEmpty &&
        !hasLocalMantra;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleAndDescription(BuildContext context, bool isHindi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subProblem.getTitle(isHindi ? 'hi' : 'en'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
              letterSpacing: 0.5,
            ),
          ),
          if ((widget.subProblem.getDescription(isHindi ? 'hi' : 'en') !=
                      null &&
                  widget.subProblem
                      .getDescription(isHindi ? 'hi' : 'en')!
                      .isNotEmpty) ||
              (widget.mainProblem.getDescription(isHindi ? 'hi' : 'en') !=
                      null &&
                  widget.mainProblem
                      .getDescription(isHindi ? 'hi' : 'en')!
                      .isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200, width: 1),
              ),
              child: Text(
                (widget.subProblem.getDescription(isHindi ? 'hi' : 'en') !=
                            null &&
                        widget.subProblem
                            .getDescription(isHindi ? 'hi' : 'en')!
                            .isNotEmpty)
                    ? widget.subProblem.getDescription(isHindi ? 'hi' : 'en')!
                    : widget.mainProblem.getDescription(isHindi ? 'hi' : 'en')!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioCard(AudioEbookModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.displayImage.isNotEmpty
              ? CachedNetworkImageWidget(
                  imageUrl: item.displayImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.orange.shade100,
                  child: const Icon(Icons.headphones, color: Colors.orange),
                ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          item.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioEbookDetailScreen(item: item),
            ),
          );
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: item.displayImage.isNotEmpty
                    ? CachedNetworkImageWidget(
                        imageUrl: item.displayImage,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        color: Colors.purple.shade50,
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.purple,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPujaCard(PujaModel puja, bool isHindi) {
    final basic = isHindi ? puja.pujaBasicHi : puja.pujaBasic;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PujaDetailScreen(puja: puja)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: puja.pujaImages.isNotEmpty
                  ? CachedNetworkImageWidget(
                      imageUrl: puja.pujaImages.first,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.red.shade50,
                      child: const Icon(Icons.temple_hindu, color: Colors.red),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    basic.title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    basic.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        basic.location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
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

  Widget _buildMantraCard(MantraModel mantra) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Universal Remedy',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mantra.hindiMantra,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MantraDetailScreen(mantra: mantra),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('View Detail'),
          ),
        ],
      ),
    );
  }

  Widget _buildAstrologerCard(AstrologerModel astrologer, bool isHindi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AstrologerCard(
        astrologer: astrologer,
        onBook: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AstrologerDetailScreen(astrologer: astrologer),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isHindi) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'कोई सामग्री उपलब्ध नहीं' : 'No content available',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'An error occurred'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchContentData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMantraCard(String mantraText, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'मंत्र' : 'Mantra',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mantraText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
