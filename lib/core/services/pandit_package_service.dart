// core/services/pandit_package_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pandit_package_model.dart';

class PanditPackageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PanditPackageModel>> getPackages({
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _supabase
          .from('pandit_packages')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => PanditPackageModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pandit packages: $e');
    }
  }
}
