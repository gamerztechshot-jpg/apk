// core/services/pandit_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class PanditService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchAssignedPanditForUser(
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedFamilyPandit(userId);
        if (cachedData != null && cachedData.isNotEmpty) {
          return cachedData;
        }
      }

      final List<dynamic> orders = await _supabase
          .from('pandit_package_orders')
          .select('pandit_assigned, created_at, validity_days')
          .eq('user_id', userId)
          .not('pandit_assigned', 'is', null)
          .order('created_at', ascending: false)
          .limit(1);

      if (orders.isEmpty || orders.first['pandit_assigned'] == null) {
        await CacheService.cacheFamilyPandit(userId, {});
        return null;
      }

      final String panditId = orders.first['pandit_assigned'].toString();
      final int validityDays = _parseInt(orders.first['validity_days']) ?? 0;

      Map<String, dynamic>? panditData;
      try {
        final PostgrestMap? pandit = await _supabase
            .from('pat')
            .select()
            .eq('id', panditId)
            .maybeSingle();

        if (pandit != null) {
          final Map<String, dynamic> raw = Map<String, dynamic>.from(pandit);
          final Map<String, dynamic> basicInfo =
              (raw['basic_info'] is Map<String, dynamic>)
              ? Map<String, dynamic>.from(raw['basic_info'] as Map)
              : <String, dynamic>{};

          final String name =
              (basicInfo['name']?.toString() ??
                      raw['name']?.toString() ??
                      'Unknown')
                  .trim();
          final String bio =
              (basicInfo['about_you']?.toString() ??
                      raw['bio']?.toString() ??
                      '')
                  .trim();
          final int experienceYears =
              _parseInt(basicInfo['experience']) ??
              _parseInt(raw['experience_years']) ??
              0;

          int finalValidityDays =
              _parseInt(raw['validity_days']) ??
              _parseInt(raw['validay_days']) ??
              _parseInt(basicInfo['validity_days']) ??
              0;

          if (validityDays > 0) {
            finalValidityDays = validityDays;
          }

          final String photoUrl =
              (basicInfo['photo_url']?.toString() ??
                      raw['profile_image']?.toString() ??
                      '')
                  .trim();

          panditData = {
            'id': panditId,
            'name': name,
            'bio': bio,
            'experience_years': experienceYears,
            'validity_days': finalValidityDays,
            'photo_url': photoUrl,
          };
        } else {
          panditData = {'id': panditId};
        }
      } catch (e) {
        panditData = {'id': panditId};
      }

      await CacheService.cacheFamilyPandit(userId, panditData);

      return panditData;
    } catch (e) {
      return null;
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<Map<String, dynamic>?> refreshFamilyPanditData(String userId) async {
    return await fetchAssignedPanditForUser(userId, forceRefresh: true);
  }

  Future<void> clearFamilyPanditCache(String userId) async {
    await CacheService.clearFamilyPanditCache(userId);
  }
}
