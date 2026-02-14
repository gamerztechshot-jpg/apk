import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/ramnam_lekhan/models/mantra_model.dart';

/// Service for managing mantras from Supabase
class MantraService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all active mantras ordered by display_order
  Future<List<MantraModel>> getAllMantras() async {
    try {
      final response = await _supabase
          .from('mantra_master_collection')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MantraModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get mantras by deity ID
  Future<List<MantraModel>> getMantrasByDeity(String deityId) async {
    try {
      final response = await _supabase
          .from('mantra_master_collection')
          .select()
          .eq('deity_id', deityId)
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => MantraModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get mantras by category
  Future<List<MantraModel>> getMantrasByCategory(String category) async {
    try {
      final response = await _supabase
          .from('mantra_master_collection')
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => MantraModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get mantra by ID
  Future<MantraModel?> getMantraById(String id) async {
    try {
      final response = await _supabase
          .from('mantra_master_collection')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .single();

      return MantraModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Search mantras by text
  Future<List<MantraModel>> searchMantras(String query) async {
    try {
      if (query.isEmpty) return getAllMantras();

      final response = await _supabase
          .from('mantra_master_collection')
          .select()
          .or('mantra_en.ilike.%$query%,'
              'mantra_hi.ilike.%$query%,'
              'meaning_en.ilike.%$query%,'
              'meaning_hi.ilike.%$query%,'
              'category.ilike.%$query%')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => MantraModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get mantras by difficulty level
  Future<List<MantraModel>> getMantrasByDifficulty(String difficultyLevel) async {
    try {
      final response = await _supabase
          .from('mantra_master_collection')
          .select()
          .eq('difficulty_level', difficultyLevel)
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => MantraModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Create a new mantra (Admin only)
  Future<MantraModel?> createMantra({
    required String mantraEn,
    required String mantraHi,
    required String meaningEn,
    required String meaningHi,
    required String benefitsEn,
    required String benefitsHi,
    required String category,
    required String difficultyLevel,
    String? deityId,
    int displayOrder = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('mantra_master_collection')
          .insert({
            'mantra_en': mantraEn,
            'mantra_hi': mantraHi,
            'meaning_en': meaningEn,
            'meaning_hi': meaningHi,
            'benefits_en': benefitsEn,
            'benefits_hi': benefitsHi,
            'deity_id': deityId,
            'category': category,
            'difficulty_level': difficultyLevel,
            'is_custom': true,
            'is_active': true,
            'display_order': displayOrder,
            'created_by': userId,
          })
          .select()
          .single();

      return MantraModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update existing mantra (Admin only)
  Future<bool> updateMantra(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('mantra_master_collection')
          .update(updates)
          .eq('id', id);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Soft delete mantra (Admin only)
  Future<bool> deleteMantra(String id) async {
    try {
      await _supabase
          .from('mantra_master_collection')
          .update({'is_active': false})
          .eq('id', id);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Hard delete mantra (Admin only - use with caution)
  Future<bool> permanentlyDeleteMantra(String id) async {
    try {
      await _supabase
          .from('mantra_master_collection')
          .delete()
          .eq('id', id);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore soft-deleted mantra
  Future<bool> restoreMantra(String id) async {
    try {
      await _supabase
          .from('mantra_master_collection')
          .update({'is_active': true})
          .eq('id', id);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all categories
  Future<List<String>> getAllCategories() async {
    try {
      final response = await _supabase
          .from('mantra_master_collection')
          .select('category')
          .eq('is_active', true);

      final categories = (response as List)
          .map((item) => item['category'] as String)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (e) {
      return [];
    }
  }
}
