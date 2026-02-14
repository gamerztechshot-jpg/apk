import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/services/mantra_service.dart';
import '../../models/mantra_model.dart';
import '../../models/deity_model.dart';
import '../practice_setup/practice_setup_screen.dart';

class MantraDetailScreen extends StatefulWidget {
  final MantraModel mantra;

  const MantraDetailScreen({
    super.key,
    required this.mantra,
  });

  @override
  State<MantraDetailScreen> createState() => _MantraDetailScreenState();
}

class _MantraDetailScreenState extends State<MantraDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String? _getDeityImageUrl(String? deityId) {
    if (deityId == null || deityId.isEmpty || DeityModel.deities.isEmpty) {
      return null;
    }
    
    final deity = DeityModel.deities.firstWhere(
      (d) => d.id == deityId,
      orElse: () => DeityModel.deities.first,
    );
    return deity.imageUrl;
  }

  Widget _buildDeityImage() {
    final String? imageUrl = _getDeityImageUrl(widget.mantra.deityId);
    
    // Return placeholder if no valid URL
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          color: Color(0xFFFFB366),
          size: 40,
        ),
      );
    }
    
    // At this point, imageUrl is guaranteed to be non-null and non-empty
    final String validUrl = imageUrl;
    
    return Image.network(
      validUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFFFFB366),
            size: 40,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFB366),
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final favoritesService = Provider.of<FavoritesService>(context);
    final isHindi = languageService.isHindi;
    final isFavorite = favoritesService.isFavorite(widget.mantra.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? 'मंत्र विवरण' : 'Mantra Details',
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
        actions: [
          IconButton(
            onPressed: () => favoritesService.toggleFavorite(widget.mantra.id),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                color: isFavorite ? Colors.red : Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Clean header section
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Deity image
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFB366),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFB366).withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _buildDeityImage(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Mantra text
                          Container(
                            padding: const EdgeInsets.all(20),
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
                            child: Column(
                              children: [
                                Text(
                                  isHindi ? widget.mantra.hindiMantra : widget.mantra.mantra,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB366),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isHindi ? widget.mantra.hindiMeaning : widget.mantra.meaning,
                                  style: const TextStyle(
                                    color: Color(0xFF2C3E50),
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Difficulty and category badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBadge(
                                isHindi 
                                    ? widget.mantra.difficultyLevel.hindiDisplayName
                                    : widget.mantra.difficultyLevel.displayName,
                                _getDifficultyColor(widget.mantra.difficultyLevel),
                                Colors.white,
                              ),
                              const SizedBox(width: 12),
                              _buildBadge(
                                widget.mantra.category,
                                const Color(0xFFFFB366),
                                Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // ⭐ HIGHLIGHTED START PRACTICE BUTTON ⭐
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFFCC80), // Light orange-yellow
                                    Color(0xFFFF9500), // Deep orange
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9500).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFF9500).withOpacity(0.2),
                                    blurRadius: 40,
                                    offset: const Offset(0, 15),
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PracticeSetupScreen(mantra: widget.mantra),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 18,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.play_circle_filled_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          isHindi ? 'अभ्यास शुरू करें' : 'Start Practice',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content sections
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Benefits section
                      _buildSection(
                        isHindi ? 'लाभ' : 'Benefits',
                        Icons.health_and_safety,
                        const Color(0xFFFFB366),
                        isHindi ? widget.mantra.hindiBenefits : widget.mantra.benefits,
                      ),
                      const SizedBox(height: 24),
                      // Practice section
                      _buildPracticeSection(isHindi),
                      const SizedBox(height: 24),
                      // Related mantras section
                      _buildRelatedMantrasSection(isHindi, favoritesService),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: backgroundColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2C3E50),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeSection(bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.self_improvement_rounded,
                  color: Color(0xFFFFB366),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isHindi ? 'अभ्यास के लिए सुझाव' : 'Practice Suggestions',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPracticeTip(
            isHindi ? 'सुबह के समय जप करें' : 'Chant in the morning',
            isHindi ? 'सुबह 5-7 बजे के बीच जप करना सबसे अच्छा होता है' : 'Best time is between 5-7 AM',
            Icons.wb_sunny_rounded,
            const Color(0xFFFFB366),
          ),
          const SizedBox(height: 12),
          _buildPracticeTip(
            isHindi ? 'शांत स्थान चुनें' : 'Choose a quiet place',
            isHindi ? 'शोर-शराबे से दूर एक शांत स्थान पर बैठें' : 'Sit in a quiet place away from noise',
            Icons.place_rounded,
            const Color(0xFF6C757D),
          ),
          const SizedBox(height: 12),
          _buildPracticeTip(
            isHindi ? 'नियमित अभ्यास करें' : 'Practice regularly',
            isHindi ? 'प्रतिदिन कम से कम 108 बार जप करें' : 'Chant at least 108 times daily',
            Icons.repeat_rounded,
            const Color(0xFF2C3E50),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeTip(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedMantrasSection(bool isHindi, FavoritesService favoritesService) {
    final mantraService = Provider.of<MantraService>(context, listen: false);

    return FutureBuilder<List<MantraModel>>(
      future: _getRelatedMantras(mantraService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final relatedMantras = snapshot.data ?? [];
        
        if (relatedMantras.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no related mantras
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Color(0xFFFFB366),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isHindi ? 'संबंधित मंत्र' : 'Related Mantras',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...relatedMantras.map((mantra) => _buildRelatedMantraCard(mantra, isHindi, favoritesService)),
            ],
          ),
        );
      },
    );
  }

  /// Get related mantras - first try same deity, then same category
  Future<List<MantraModel>> _getRelatedMantras(MantraService mantraService) async {
    try {
      List<MantraModel> mantras = [];

      // First try: Get mantras from same deity
      if (widget.mantra.deityId != null) {
        mantras = await mantraService.getMantrasByDeity(widget.mantra.deityId!);
        mantras = mantras.where((m) => m.id != widget.mantra.id).take(3).toList();
      }

      // Fallback: If no mantras from same deity, get from same category
      if (mantras.isEmpty) {
        mantras = await mantraService.getMantrasByCategory(widget.mantra.category);
        mantras = mantras.where((m) => m.id != widget.mantra.id).take(3).toList();
      }

      return mantras;
    } catch (e) {
      return [];
    }
  }

  Widget _buildRelatedMantraCard(MantraModel mantra, bool isHindi, FavoritesService favoritesService) {
    final isFavorite = favoritesService.isFavorite(mantra.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MantraDetailScreen(mantra: mantra),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
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
                      maxLines: 1,
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
              IconButton(
                onPressed: () => favoritesService.toggleFavorite(mantra.id),
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.red : const Color(0xFFADB5BD),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
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
