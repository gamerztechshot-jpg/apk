// features/astro/reposistries/astrologer_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/astrologer_model.dart';
import '../models/kundli_type_model.dart';

class AstrologerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Test database connection
  Future<bool> testConnection() async {
    try {
      final response = await _supabase
          .from('astrologers')
          .select('count')
          .limit(1);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all active astrologers with real ratings and charges
  Future<List<AstrologerModel>> getAstrologers({int? limit}) async {
    try {

      // Use the existing astrologers table with real ratings and charges
      var query = _supabase
          .from('astrologers')
          .select('*')
          .eq('is_active', true)
          .order('priority', ascending: true, nullsFirst: true)
          .order('rating', ascending: false, nullsFirst: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      final astrologers = response.map<AstrologerModel>((json) {
        return AstrologerModel.fromJson(json);
      }).toList();


      for (int i = 0; i < astrologers.length; i++) {
        final astrologer = astrologers[i];

      }

      return astrologers;
    } catch (e) {
      throw Exception('Failed to fetch astrologers: $e');
    }
  }

  // Get astrologer by ID
  Future<AstrologerModel?> getAstrologerById(String id) async {
    try {
      final response = await _supabase
          .from('astrologers')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .single();

      return AstrologerModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Search astrologers by name or qualification
  Future<List<AstrologerModel>> searchAstrologers(String query) async {
    try {
      // Prefer searching across both English and Hindi columns (if present).
      // If the DB doesn't have *_hi columns yet, fall back to the older query.
      List<dynamic> response;
      try {
        response = await _supabase
            .from('astrologers')
            .select()
            .eq('is_active', true)
            .or(
              'name.ilike.%$query%,name_hi.ilike.%$query%,qualification.ilike.%$query%,qualification_hi.ilike.%$query%',
            )
            .order('priority', ascending: false);
      } catch (_) {
        response = await _supabase
            .from('astrologers')
            .select()
            .eq('is_active', true)
            .or('name.ilike.%$query%,qualification.ilike.%$query%')
            .order('priority', ascending: false);
      }

      return response
          .map<AstrologerModel>((json) => AstrologerModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search astrologers: $e');
    }
  }

  // Get all active kundli types
  Future<List<KundliTypeModel>> getKundliTypes() async {
    try {
      final response = await _supabase
          .from('kundli_types')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response
          .map<KundliTypeModel>((json) => KundliTypeModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch kundli types: $e');
    }
  }

  // Get kundli type by ID
  Future<KundliTypeModel?> getKundliTypeById(String id) async {
    try {
      final response = await _supabase
          .from('kundli_types')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .single();

      return KundliTypeModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Book astrologer consultation
  Future<bool> bookAstrologer({
    required String astrologerId,
    required String userId,
    required String consultationType,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    try {
      await _supabase.from('astrologer_bookings').insert({
        'astrologer_id': astrologerId,
        'user_id': userId,
        'consultation_type': consultationType,
        'scheduled_time': scheduledTime.toIso8601String(),
        'notes': notes,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to book astrologer: $e');
    }
  }

  // Download kundli report
  Future<bool> downloadKundliReport({
    required String kundliTypeId,
    required String userId,
    required Map<String, dynamic> userDetails,
  }) async {
    try {
      await _supabase.from('kundli_downloads').insert({
        'kundli_type_id': kundliTypeId,
        'user_id': userId,
        'user_details': userDetails,
        'downloaded_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to download kundli report: $e');
    }
  }
}
