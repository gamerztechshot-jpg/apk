import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/ramnam_lekhan/models/deity_model.dart';

/// Service for managing deities from Supabase
class DeityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize deities - Load from Supabase and populate static list
  /// Call this at app startup to populate DeityModel.deities
  static Future<void> initializeDeities() async {
    try {
      final service = DeityService();
      final deities = await service.getAllDeities();
      
      // Populate the static list in DeityModel
      DeityModel.deities = deities;
      
    } catch (e) {
      // Set empty list to prevent crashes
      DeityModel.deities = [];
    }
  }

  /// Get all active deities ordered by display_order
  Future<List<DeityModel>> getAllDeities() async {
    try {
      final response = await _supabase
          .from('deities')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('english_name', ascending: true);

      return (response as List)
          .map((json) => DeityModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get deity by ID
  Future<DeityModel?> getDeityById(String id) async {
    try {
      final response = await _supabase
          .from('deities')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .single();

      return DeityModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get deity by english name
  Future<DeityModel?> getDeityByName(String englishName) async {
    try {
      final response = await _supabase
          .from('deities')
          .select()
          .eq('english_name', englishName)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return DeityModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create a new deity (Admin only)
  Future<DeityModel?> createDeity({
    required String englishName,
    required String hindiName,
    required String icon,
    required String descriptionEn,
    required String descriptionHi,
    required List<String> colors,
    String? imageUrl,
    int displayOrder = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      final response = await _supabase
          .from('deities')
          .insert({
            'english_name': englishName,
            'hindi_name': hindiName,
            'icon': icon,
            'description_en': descriptionEn,
            'description_hi': descriptionHi,
            'colors': colors,
            'image_url': imageUrl,
            'is_custom': true,
            'is_active': true,
            'display_order': displayOrder,
            'created_by': userId,
          })
          .select()
          .single();

      return DeityModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update existing deity (Admin only)
  Future<bool> updateDeity(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('deities')
          .update(updates)
          .eq('id', id);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Soft delete deity (Admin only)
  Future<bool> deleteDeity(String id) async {
    try {
      await _supabase
          .from('deities')
          .update({'is_active': false})
          .eq('id', id);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Hard delete deity (Admin only - use with caution)
  Future<bool> permanentlyDeleteDeity(String id) async {
    try {
      await _supabase
          .from('deities')
          .delete()
          .eq('id', id);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore soft-deleted deity
  Future<bool> restoreDeity(String id) async {
    try {
      await _supabase
          .from('deities')
          .update({'is_active': true})
          .eq('id', id);

      return true;
    } catch (e) {
      return false;
    }
  }
}
