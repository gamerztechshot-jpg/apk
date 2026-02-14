import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/ramnam_lekhan/models/mantra_model.dart';
import 'mantra_service.dart';

/// Optimized service for managing user favorite mantras
/// Uses a dedicated table with proper indexing for scalability
class FavoritesService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MantraService _mantraService = MantraService();

  Set<String> _favoriteMantraIds = {};
  String? _currentUserId;

  Set<String> get favoriteMantraIds => _favoriteMantraIds;

  FavoritesService() {
    _initializeService();
  }

  void _initializeService() {
    _currentUserId = _supabase.auth.currentUser?.id;
    if (_currentUserId != null) {
      _loadFavorites();
    }

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _currentUserId = data.session?.user.id;
        _loadFavorites();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUserId = null;
        _favoriteMantraIds.clear();
        notifyListeners();
      }
    });
  }

  Future<void> _loadFavorites() async {
    if (_currentUserId == null) return;

    try {
      // Use the optimized database function for better performance
      final response = await _supabase.rpc(
        'get_user_favorite_mantras',
        params: {'p_user_id': _currentUserId!},
      );

      _favoriteMantraIds = (response as List)
          .map((item) => item['mantra_id'] as String)
          .toSet();

      notifyListeners();
    } catch (e) {
      // Fallback to direct table query using new table structure
      try {
        final fallbackResponse = await _supabase
            .from('user_favorite_mantras')
            .select('mantra_id')
            .eq('user_id', _currentUserId!);

        _favoriteMantraIds = (fallbackResponse as List)
            .map((item) => item['mantra_id'] as String)
            .toSet();

        notifyListeners();
      } catch (fallbackError) {
        _favoriteMantraIds = {};
      }
    }
  }

  bool isFavorite(String mantraId) {
    return _favoriteMantraIds.contains(mantraId);
  }

  /// Toggle favorite status for a mantra
  /// Returns true if added to favorites, false if removed
  Future<bool> toggleFavorite(String mantraId) async {
    if (_currentUserId == null) return false;

    try {
      // Get mantra details from database
      MantraModel? mantra;
      try {
        mantra = await _mantraService.getMantraById(mantraId);
      } catch (e) {
      }

      // Fallback if mantra not found
      if (mantra == null) {
        mantra = MantraModel(
          id: mantraId,
          mantra: mantraId,
          hindiMantra: mantraId,
          meaning: '',
          hindiMeaning: '',
          benefits: '',
          hindiBenefits: '',
          deityId: null,
          category: '',
          difficultyLevel: DifficultyLevel.easy,
        );
      }

      // Use the optimized database function
      final result = await _supabase.rpc(
        'toggle_mantra_favorite',
        params: {
          'p_user_id': _currentUserId!,
          'p_mantra_id': mantraId,
          'p_mantra_name': mantra.mantra,
          'p_mantra_category': mantra.category,
          'p_mantra_deity_id': mantra.deityId,
        },
      );

      // Update local state based on result
      if (result == true) {
        _favoriteMantraIds.add(mantraId);
      } else {
        _favoriteMantraIds.remove(mantraId);
      }

      notifyListeners();
      return result as bool;
    } catch (e) {
      // Fallback to direct table operations using new table structure
      try {
        if (_favoriteMantraIds.contains(mantraId)) {
          // Remove from favorites
          await _supabase
              .from('user_favorite_mantras')
              .delete()
              .eq('user_id', _currentUserId!)
              .eq('mantra_id', mantraId);

          _favoriteMantraIds.remove(mantraId);
          notifyListeners();
          return false;
        } else {
          // Add to favorites
          final mantra = MantraModel.allMantras.firstWhere(
            (m) => m.id == mantraId,
            orElse: () => MantraModel(
              id: mantraId,
              mantra: mantraId,
              hindiMantra: mantraId,
              meaning: '',
              hindiMeaning: '',
              benefits: '',
              hindiBenefits: '',
              deityId: '',
              category: '',
              difficultyLevel: DifficultyLevel.easy,
            ),
          );

          await _supabase.from('user_favorite_mantras').insert({
            'user_id': _currentUserId!,
            'mantra_id': mantraId,
            'mantra_name': mantra.mantra,
            'mantra_category': mantra.category,
            'deity_id': mantra.deityId,
          });

          _favoriteMantraIds.add(mantraId);
          notifyListeners();
          return true;
        }
      } catch (fallbackError) {
        return false;
      }
    }
  }

  /// Add a mantra to favorites (if not already favorited)
  Future<bool> addToFavorites(String mantraId) async {
    if (_currentUserId == null || _favoriteMantraIds.contains(mantraId))
      return false;

    try {
      final mantra = MantraModel.allMantras.firstWhere(
        (m) => m.id == mantraId,
        orElse: () => MantraModel(
          id: mantraId,
          mantra: mantraId,
          hindiMantra: mantraId,
          meaning: '',
          hindiMeaning: '',
          benefits: '',
          hindiBenefits: '',
          deityId: '',
          category: '',
          difficultyLevel: DifficultyLevel.easy,
        ),
      );

      await _supabase.from('user_favorite_mantras').insert({
        'user_id': _currentUserId!,
        'mantra_id': mantraId,
        'mantra_name': mantra.mantra,
        'mantra_category': mantra.category,
        'deity_id': mantra.deityId,
      });

      _favoriteMantraIds.add(mantraId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a mantra from favorites
  Future<bool> removeFromFavorites(String mantraId) async {
    if (_currentUserId == null || !_favoriteMantraIds.contains(mantraId))
      return false;

    try {
      await _supabase
          .from('user_favorite_mantras')
          .delete()
          .eq('user_id', _currentUserId!)
          .eq('mantra_id', mantraId);

      _favoriteMantraIds.remove(mantraId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all favorite mantras for the current user
  /// Returns the number of favorites that were removed
  Future<int> clearAllFavorites() async {
    if (_currentUserId == null) return 0;

    try {
      // Use the optimized database function
      final deletedCount = await _supabase.rpc(
        'clear_all_user_favorites',
        params: {'p_user_id': _currentUserId!},
      );

      _favoriteMantraIds.clear();
      notifyListeners();
      return deletedCount as int;
    } catch (e) {
      // Fallback to direct table operation
      try {
        await _supabase
            .from('user_favorite_mantras')
            .delete()
            .eq('user_id', _currentUserId!);

        final count = _favoriteMantraIds.length;
        _favoriteMantraIds.clear();
        notifyListeners();
        return count;
      } catch (fallbackError) {
        return 0;
      }
    }
  }

  int get favoritesCount => _favoriteMantraIds.length;

  // Get favorite mantras by category
  Future<Map<String, int>> getFavoriteCountByCategory() async {
    if (_currentUserId == null) return {};

    try {
      final response = await _supabase.rpc(
        'get_favorite_count_by_category',
        params: {'p_user_id': _currentUserId!},
      );

      final Map<String, int> categoryCounts = {};
      for (var item in response) {
        categoryCounts[item['category'] as String] = item['count'] as int;
      }

      return categoryCounts;
    } catch (e) {
      return {};
    }
  }

  // Get favorite mantras by deity
  Future<Map<String, int>> getFavoriteCountByDeity() async {
    if (_currentUserId == null) return {};

    try {
      final response = await _supabase.rpc(
        'get_favorite_count_by_deity',
        params: {'p_user_id': _currentUserId!},
      );

      final Map<String, int> deityCounts = {};
      for (var item in response) {
        deityCounts[item['deity_id'] as String] = item['count'] as int;
      }

      return deityCounts;
    } catch (e) {
      return {};
    }
  }

  /// Get favorite mantras with full details
  Future<List<Map<String, dynamic>>> getFavoriteMantrasWithDetails() async {
    if (_currentUserId == null) return [];

    try {
      final response = await _supabase.rpc(
        'get_user_favorite_mantras_with_details',
        params: {'p_user_id': _currentUserId!},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Check if a mantra is favorited (with database check)
  Future<bool> isFavoriteAsync(String mantraId) async {
    if (_currentUserId == null) return false;

    try {
      final response = await _supabase.rpc(
        'is_mantra_favorited',
        params: {'p_user_id': _currentUserId!, 'p_mantra_id': mantraId},
      );

      return response as bool;
    } catch (e) {
      return _favoriteMantraIds.contains(mantraId);
    }
  }

  /// Get user's favorite count from database
  Future<int> getFavoriteCountAsync() async {
    if (_currentUserId == null) return 0;

    try {
      final response = await _supabase.rpc(
        'get_user_favorite_count',
        params: {'p_user_id': _currentUserId!},
      );

      return response as int;
    } catch (e) {
      return _favoriteMantraIds.length;
    }
  }

  /// Refresh favorites from database
  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }

  /// Get favorite mantras by category
  Future<List<String>> getFavoriteMantrasByCategory(String category) async {
    if (_currentUserId == null) return [];

    try {
      final response = await _supabase
          .from('user_favorite_mantras')
          .select('mantra_id')
          .eq('user_id', _currentUserId!)
          .eq('mantra_category', category);

      return (response as List)
          .map((item) => item['mantra_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get favorite mantras by deity
  Future<List<String>> getFavoriteMantrasByDeity(String deityId) async {
    if (_currentUserId == null) return [];

    try {
      final response = await _supabase
          .from('user_favorite_mantras')
          .select('mantra_id')
          .eq('user_id', _currentUserId!)
          .eq('deity_id', deityId);

      return (response as List)
          .map((item) => item['mantra_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
