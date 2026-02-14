// core/services/profile_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user profile by user ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      if (e.toString().contains('permission denied')) {}
      return null;
    }
  }

  // Create or update user profile
  Future<UserProfile?> createOrUpdateProfile(UserProfile profile) async {
    try {
      final response = await _supabase
          .from('profiles')
          .upsert(profile.toJson())
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update specific profile fields
  Future<UserProfile?> updateProfileFields({
    required String userId,
    String? displayName,
    String? email,
    String? phone,
    String? bio,
    String? location,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updateData['display_name'] = displayName;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      final response = await _supabase
          .from('profiles')
          .update(updateData)
          .eq('user_id', userId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create initial profile for new user
  Future<UserProfile?> createInitialProfile({
    required String userId,
    required String email,
    String? displayName,
    String? phone,
  }) async {
    try {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: userId,
        displayName: displayName ?? 'User',
        email: email,
        phone: phone,
        createdAt: now,
        updatedAt: now,
      );

      return await createOrUpdateProfile(profile);
    } catch (e) {
      return null;
    }
  }

  // Check if profile exists
  Future<bool> profileExists(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (e.toString().contains('permission denied')) {
      }
      return false;
    }
  }

  // Test database connectivity
  Future<bool> testDatabaseAccess() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('count')
          .limit(1);

      return true;
    } catch (e) {
      return false;
    }
  }
}
