// features/mantra_generator/views/screens/problem_content_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/language_service.dart';
import '../../models/main_problem_model.dart';
import '../../models/sub_problem_model.dart';
import '../../../audio_ebook/audio_ebook_detail_screen.dart';
import '../../../puja_booking/puja_detail_screen.dart';
import '../../../astro/views/astrologer_screen.dart';
import '../../../dharma_store/screens/product_detail_screen.dart';
import '../../../ramnam_lekhan/screens/mantra_detail/mantra_detail_screen.dart';
import '../../../../core/services/audio_ebook_service.dart';
import '../../../../core/services/puja_service.dart';
import '../../../../core/services/mantra_service.dart';
import '../../../../features/dharma_store/services/store_service.dart';

class ProblemContentScreen extends StatefulWidget {
  final MainProblem mainProblem;
  final SubProblem? subProblem;

  const ProblemContentScreen({
    super.key,
    required this.mainProblem,
    this.subProblem,
  });

  @override
  State<ProblemContentScreen> createState() => _ProblemContentScreenState();
}

class _ProblemContentScreenState extends State<ProblemContentScreen> {
  final AudioEbookService _audioEbookService = AudioEbookService();
  final PujaService _pujaService = PujaService();
  final StoreService _storeService = StoreService();
  final MantraService _mantraService = MantraService();
  bool _isLoading = true;
  String? _errorMessage;

  // Get the actual problem (sub-problem if exists, else main problem)
  dynamic get problem => widget.subProblem ?? widget.mainProblem;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Determine which content to load based on available IDs
      if (problem.audioId != null && problem.audioId!.isNotEmpty) {
        await _loadAndNavigateToAudio();
      } else if (problem.ebookId != null && problem.ebookId!.isNotEmpty) {
        await _loadAndNavigateToEbook();
      } else if (problem.mantraId != null && problem.mantraId!.isNotEmpty) {
        await _loadAndNavigateToMantra();
      } else if (problem.pujaId != null && problem.pujaId!.isNotEmpty) {
        await _loadAndNavigateToPuja();
      } else if (problem.astrologerId != null &&
          problem.astrologerId!.isNotEmpty) {
        await _loadAndNavigateToAstrologer();
      } else if (problem.dharmaStoreId != null &&
          problem.dharmaStoreId!.isNotEmpty) {
        await _loadAndNavigateToStore();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No content available for this problem';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load content: ${e.toString()}';
      });
    }
  }

  Future<void> _loadAndNavigateToAudio() async {
    try {
      final allAudios = await _audioEbookService.fetchAudiobooks();
      final audioItem = allAudios.firstWhere(
        (audio) => audio.id.toString() == problem.audioId,
        orElse: () => throw Exception('Audio not found'),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AudioEbookDetailScreen(item: audioItem),
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to load audio: $e');
    }
  }

  Future<void> _loadAndNavigateToEbook() async {
    try {
      final allEbooks = await _audioEbookService.fetchEbooks();
      final ebookItem = allEbooks.firstWhere(
        (ebook) => ebook.id.toString() == problem.ebookId,
        orElse: () => throw Exception('Ebook not found'),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AudioEbookDetailScreen(item: ebookItem),
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to load ebook: $e');
    }
  }

  Future<void> _loadAndNavigateToMantra() async {
    try {
      // Mantra IDs in the problem might be UUIDs from mantras table
      // We need to fetch all mantras and find the matching one
      final allMantras = await _mantraService.getAllMantras();
      final mantra = allMantras.firstWhere(
        (m) => m.id == problem.mantraId,
        orElse: () => throw Exception('Mantra not found'),
      );

      if (mounted) {
        // Navigate to mantra detail screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MantraDetailScreen(mantra: mantra),
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to load mantra: $e');
    }
  }

  Future<void> _loadAndNavigateToPuja() async {
    try {
      final pujaId = int.tryParse(problem.pujaId ?? '');
      if (pujaId == null) {
        throw Exception('Invalid puja ID');
      }

      final puja = await _pujaService.getPujaById(pujaId);
      if (puja == null) {
        throw Exception('Puja not found');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PujaDetailScreen(puja: puja),
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to load puja: $e');
    }
  }

  Future<void> _loadAndNavigateToAstrologer() async {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AstrologerScreen(),
        ),
      );
    }
  }

  Future<void> _loadAndNavigateToStore() async {
    try {
      final product = await _storeService.getProductById(problem.dharmaStoreId!);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to load store product: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(problem.title),
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB366)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(problem.title),
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadContent,
                  icon: const Icon(Icons.refresh),
                  label: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // This should not be reached as we navigate away, but just in case
    return Scaffold(
      appBar: AppBar(
        title: Text(problem.title),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          isHindi
              ? 'सामग्री लोड हो रही है...'
              : 'Loading content...',
        ),
      ),
    );
  }
}
