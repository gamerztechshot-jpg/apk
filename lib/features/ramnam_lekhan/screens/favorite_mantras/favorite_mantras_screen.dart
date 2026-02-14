import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/favorites_service.dart';
import '../../models/mantra_model.dart';
import '../mantra_detail/mantra_detail_screen.dart';

class FavoriteMantrasScreen extends StatefulWidget {
  const FavoriteMantrasScreen({super.key});

  @override
  State<FavoriteMantrasScreen> createState() => _FavoriteMantrasScreenState();
}

class _FavoriteMantrasScreenState extends State<FavoriteMantrasScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context);
    final favoritesService = Provider.of<FavoritesService>(context);
    final isHindi = languageService.isHindi;

    // Get favorite mantras
    final favoriteMantras = MantraModel.allMantras
        .where((mantra) => favoritesService.isFavorite(mantra.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          l10n.favorites,
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
          // Remove all favorites button
          if (favoriteMantras.isNotEmpty)
            IconButton(
              onPressed: () => _showRemoveAllDialog(context, isHindi, favoritesService),
              icon: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
              ),
              tooltip: isHindi ? 'सभी पसंदीदा हटाएं' : 'Remove All Favorites',
            ),
        ],
      ),
      body: favoriteMantras.isEmpty
          ? _buildEmptyState(isHindi)
          : _buildFavoriteMantrasList(favoriteMantras, isHindi, favoritesService),
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 80,
            color: const Color(0xFFADB5BD),
          ),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'कोई पसंदीदा मंत्र नहीं' : 'No Favorite Mantras',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? 'मंत्रों को पसंदीदा बनाने के लिए हृदय आइकन पर टैप करें'
                : 'Tap the heart icon on mantras to add them to favorites',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6C757D),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteMantrasList(List<MantraModel> favoriteMantras, bool isHindi, FavoritesService favoritesService) {
    return Column(
      children: [
        // Header with count
        Container(
          width: double.infinity,
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    isHindi ? 'आपके पसंदीदा मंत्र' : 'Your Favorite Mantras',
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isHindi 
                        ? '${favoriteMantras.length} मंत्र पसंदीदा में'
                        : '${favoriteMantras.length} mantras in favorites',
                    style: const TextStyle(
                      color: Color(0xFF6C757D),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Mantras list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteMantras.length,
            itemBuilder: (context, index) {
              final mantra = favoriteMantras[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                              onPressed: () => favoritesService.toggleFavorite(mantra.id),
                              icon: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(mantra.difficultyLevel).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getDifficultyColor(mantra.difficultyLevel).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                isHindi 
                                    ? mantra.difficultyLevel.hindiDisplayName
                                    : mantra.difficultyLevel.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getDifficultyColor(mantra.difficultyLevel),
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
          ),
        ),
      ],
    );
  }

  void _onMantraTap(MantraModel mantra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MantraDetailScreen(mantra: mantra),
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

  void _showRemoveAllDialog(BuildContext context, bool isHindi, FavoritesService favoritesService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isHindi ? 'सभी पसंदीदा हटाएं' : 'Remove All Favorites',
        ),
        content: Text(
          isHindi 
              ? 'क्या आप वाकई सभी पसंदीदा मंत्रों को हटाना चाहते हैं?'
              : 'Are you sure you want to remove all favorite mantras?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isHindi ? 'रद्द करें' : 'Cancel',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final removedCount = await favoritesService.clearAllFavorites();
              
              // Show success message with count
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isHindi 
                        ? '$removedCount पसंदीदा मंत्र हटा दिए गए'
                        : '$removedCount favorite mantras removed',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isHindi ? 'हटाएं' : 'Remove All',
            ),
          ),
        ],
      ),
    );
  }
}
