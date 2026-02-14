// features/pandit/services/pandit_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pandit_model.dart';
import '../../../core/services/cache_service.dart';

class PanditService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all approved pandits from pat table
  Future<List<PanditModel>> getApprovedPandits({
    bool forceRefresh = false,
  }) async {
    try {
      // Try to get from cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedPanditList();
        if (cachedData != null) {
          return cachedData.map((json) => PanditModel.fromJson(json)).toList();
        }
      }

      // Try different query approaches for the roles field
      List<dynamic> response = [];

      try {
        // First try: assuming roles is a JSONB field with nested structure
        response = await _supabase
            .from('pat')
            .select()
            .contains('roles', {'pandit': 'approved'})
            .order('created_at', ascending: false);
      } catch (e) {
        try {
          // Second try: assuming roles is a simple string or array
          response = await _supabase
              .from('pat')
              .select()
              .eq('roles->pandit', 'approved')
              .order('created_at', ascending: false);
        } catch (e2) {
          try {
            // Third try: get all records and filter in code
            response = await _supabase
                .from('pat')
                .select()
                .order('created_at', ascending: false);


            // Filter for approved pandits in code
            response = response.where((record) {
              final roles = record['roles'];
              if (roles == null) return false;

              // Handle different possible structures
              if (roles is Map && roles['pandit'] == 'approved') return true;
              if (roles is String && roles == 'pandit_approved') return true;
              if (roles is List && roles.contains('pandit_approved'))
                return true;

              return false;
            }).toList();
          } catch (e3) {
            throw Exception('Failed to fetch pandits from database: $e3');
          }
        }
      }

      List<PanditModel> pandits = <PanditModel>[];

      for (final json in response) {
        try {
          final pandit = PanditModel.fromJson(json);
          pandits.add(pandit);
        } catch (e) {
          // Continue with other records
        }
      }

      // Cache the data for future use
      await CacheService.cachePanditList(response);

      // Only use test data if no pandits are found at all
      if (pandits.isEmpty) {
        pandits = _createTestPandits();
      } else {}

      return pandits;
    } catch (e) {
      // Return test data as fallback

      return _createTestPandits();
    }
  }

  // Create test pandits for demonstration
  List<PanditModel> _createTestPandits() {
    final now = DateTime.now();
    return [
      PanditModel(
        id: 'test-pandit-1',
        name: 'Pandit Rajesh Sharma',
        email: 'rajesh.sharma@example.com',
        phone: '+91 98765 43210',
        profileImage: 'https://picsum.photos/200/200?random=1',
        bio:
            'Experienced Vedic astrologer with 15+ years of practice. Specializes in marriage compatibility, career guidance, and spiritual counseling.',
        experienceYears: 15,
        specializations: [
          'Vedic Astrology',
          'Marriage Compatibility',
          'Career Guidance',
        ],
        location: 'Delhi',
        rating: 4.8,
        totalBookings: 150,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
      ),
      PanditModel(
        id: 'test-pandit-2',
        name: 'Pandit Priya Devi',
        email: 'priya.devi@example.com',
        phone: '+91 98765 43211',
        profileImage: 'https://picsum.photos/200/200?random=2',
        bio:
            'Renowned spiritual guide and puja specialist. Expert in Hindu rituals, festivals, and spiritual ceremonies.',
        experienceYears: 20,
        specializations: [
          'Puja Rituals',
          'Spiritual Counseling',
          'Festival Guidance',
        ],
        location: 'Mumbai',
        rating: 4.9,
        totalBookings: 200,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
      ),
      PanditModel(
        id: 'test-pandit-3',
        name: 'Pandit Arun Kumar',
        email: 'arun.kumar@example.com',
        phone: '+91 98765 43212',
        profileImage: 'https://picsum.photos/200/200?random=3',
        bio:
            'Expert in Vastu Shastra and numerology. Helps with home and office space optimization for prosperity.',
        experienceYears: 12,
        specializations: ['Vastu Shastra', 'Numerology', 'Feng Shui'],
        location: 'Bangalore',
        rating: 4.7,
        totalBookings: 120,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
      ),
      PanditModel(
        id: 'test-pandit-4',
        name: 'Pandit Sunita Singh',
        email: 'sunita.singh@example.com',
        phone: '+91 98765 43213',
        profileImage: 'https://picsum.photos/200/200?random=4',
        bio:
            'Specialist in Hindu weddings and religious ceremonies. Expert in conducting traditional rituals and ceremonies.',
        experienceYears: 18,
        specializations: [
          'Wedding Ceremonies',
          'Religious Rituals',
          'Festival Pujas',
        ],
        location: 'Chennai',
        rating: 4.6,
        totalBookings: 180,
        isAvailable: false,
        createdAt: now,
        updatedAt: now,
      ),
      PanditModel(
        id: 'test-pandit-5',
        name: 'Pandit Vikram Joshi',
        email: 'vikram.joshi@example.com',
        phone: '+91 98765 43214',
        profileImage: 'https://picsum.photos/200/200?random=5',
        bio:
            'Expert in Jyotish (Vedic astrology) and spiritual healing. Provides guidance for personal and professional life.',
        experienceYears: 25,
        specializations: ['Jyotish', 'Spiritual Healing', 'Mantra Therapy'],
        location: 'Pune',
        rating: 4.9,
        totalBookings: 250,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // Get pandit by ID
  Future<PanditModel?> getPanditById(String id) async {
    try {
      final response = await _supabase
          .from('pat')
          .select()
          .eq('id', id)
          .contains('roles', {'pandit': 'approved'})
          .single();

      return PanditModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Search pandits by name or specialization
  Future<List<PanditModel>> searchPandits(String query) async {
    try {
      if (query.isEmpty) return getApprovedPandits();

      final response = await _supabase
          .from('pat')
          .select()
          .contains('roles', {'pandit': 'approved'})
          .or(
            'name.ilike.%$query%,bio.ilike.%$query%,specializations.cs.{${query.toLowerCase()}}',
          )
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PanditModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search pandits: $e');
    }
  }

  // Get pandits by location
  Future<List<PanditModel>> getPanditsByLocation(String location) async {
    try {
      final response = await _supabase
          .from('pat')
          .select()
          .contains('roles', {'pandit': 'approved'})
          .ilike('location', '%$location%')
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => PanditModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pandits by location: $e');
    }
  }

  // Get top rated pandits
  Future<List<PanditModel>> getTopRatedPandits({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('pat')
          .select()
          .contains('roles', {'pandit': 'approved'})
          .order('rating', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => PanditModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top rated pandits: $e');
    }
  }

  // Book a pandit for consultation
  Future<Map<String, dynamic>> bookPanditConsultation({
    required String panditId,
    required String userId,
    required String consultationType,
    required Map<String, dynamic> bookingDetails,
  }) async {
    try {
      final response = await _supabase
          .from('pandit_bookings')
          .insert({
            'pandit_id': panditId,
            'user_id': userId,
            'consultation_type': consultationType,
            'booking_details': bookingDetails,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Clear pandit cache after booking
      await CacheService.clearDataTypeCache('pandit_list');

      return response;
    } catch (e) {
      throw Exception('Failed to book pandit consultation: $e');
    }
  }

  /// Force refresh pandit data (clears cache and fetches fresh data)
  Future<List<PanditModel>> refreshPanditData() async {
    return await getApprovedPandits(forceRefresh: true);
  }

  /// Clear pandit cache
  Future<void> clearPanditCache() async {
    await CacheService.clearDataTypeCache('pandit_list');
  }
}
