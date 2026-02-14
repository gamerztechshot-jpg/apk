import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/ramnam_lekhan/models/deity_model.dart';
import '../../features/ramnam_lekhan/models/mantra_model.dart';

class ContentLoaderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> loadDeitiesAndMantras() async {
    try {
      // Fetch active deities ordered by display_order
      final rawDeities = await _supabase
          .from('deities')
          .select('id, english_name, hindi_name, icon, description_en, description_hi, colors, image_url, is_active, display_order')
          .eq('is_active', true)
          .order('display_order');

      // Build slug map and map to DeityModel with slug IDs compatible with app
      final List<Map<String, dynamic>> deityRows = List<Map<String, dynamic>>.from(rawDeities);
      final Map<String, String> dbIdToSlug = {};
      final List<DeityModel> fetchedDeities = deityRows.map((d) {
        final englishName = (d['english_name'] as String? ?? '').trim();
        final slug = _slugifyFirstWord(englishName);
        final dbId = (d['id'] as String?) ?? '';
        if (dbId.isNotEmpty) {
          dbIdToSlug[dbId] = slug;
        }
        return DeityModel(
          id: slug,
          englishName: englishName,
          hindiName: d['hindi_name'] as String? ?? '',
          icon: d['icon'] as String? ?? '🕉️',
          description: d['description_en'] as String? ?? '',
          hindiDescription: d['description_hi'] as String? ?? '',
          colors: (d['colors'] is List)
              ? List<String>.from(d['colors'] as List)
              : (d['colors'] != null)
                  ? List<String>.from((d['colors'] as List<dynamic>?) ?? [])
                  : <String>[],
          imageUrl: d['image_url'] as String?,
        );
      }).toList();

      if (fetchedDeities.isNotEmpty) {
        DeityModel.deities = fetchedDeities;
      }

      // Fetch active mantras ordered by display_order
      final rawMantras = await _supabase
          .from('mantras')
          .select('id, deity_id, mantra_en, mantra_hi, meaning_en, meaning_hi, benefits_en, benefits_hi, category, difficulty_level, is_active, display_order')
          .eq('is_active', true)
          .order('display_order');

      final List<Map<String, dynamic>> mantraRows = List<Map<String, dynamic>>.from(rawMantras);
      final List<MantraModel> fetchedMantras = mantraRows.map((m) {
        final dbDeityId = (m['deity_id'] as String?) ?? '';
        final slug = dbIdToSlug[dbDeityId] ?? _slugifyFirstWord(m['category'] as String? ?? '');
        final displayOrder = (m['display_order'] is int)
            ? (m['display_order'] as int)
            : int.tryParse('${m['display_order']}') ?? 0;
        final stableId = '${slug}_${displayOrder + 1}';
        return MantraModel(
          id: stableId,
          mantra: m['mantra_en'] as String? ?? '',
          hindiMantra: m['mantra_hi'] as String? ?? '',
          meaning: m['meaning_en'] as String? ?? '',
          hindiMeaning: m['meaning_hi'] as String? ?? '',
          benefits: m['benefits_en'] as String? ?? '',
          hindiBenefits: m['benefits_hi'] as String? ?? '',
          deityId: slug,
          category: m['category'] as String? ?? '',
          difficultyLevel: _difficultyFromString(m['difficulty_level'] as String?),
        );
      }).toList();

      if (fetchedMantras.isNotEmpty) {
        MantraModel.allMantras = fetchedMantras;
      }
    } catch (e) {
      // Swallow and keep defaults if fetch fails
    }
  }

  String _slugifyFirstWord(String source) {
    final normalized = (source).toLowerCase().trim();
    if (normalized.isEmpty) return '';
    final firstWord = normalized.split(RegExp(r'\s+')).first;
    return firstWord.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  DifficultyLevel _difficultyFromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'medium':
        return DifficultyLevel.medium;
      case 'difficult':
        return DifficultyLevel.difficult;
      default:
        return DifficultyLevel.easy;
    }
  }

  // (unused) Kept for reference if ID strategy changes in future
  // String _composeFallbackMantraId(Map<String, dynamic> m) {
  //   final deity = (m['deity_id'] as String?) ?? 'deity';
  //   final name = (m['mantra_en'] as String? ?? 'mantra').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  //   return '${deity}_$name';
  // }
}


