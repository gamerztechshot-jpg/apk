// core/services/database_test_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseTestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Test database connection
  Future<bool> testConnection() async {
    try {
      await _supabase.from('puja_booking').select('count').limit(1);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get table info
  Future<Map<String, dynamic>> getTableInfo() async {
    try {
      final response = await _supabase
          .from('puja_booking')
          .select('*')
          .limit(1);

      return {'success': true, 'data': response, 'count': response.length};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Insert a test puja (for testing purposes)
  Future<Map<String, dynamic>> insertTestPuja() async {
    try {
      final testPuja = {
        'puja_basic': {
          'name': 'Test Puja',
          'title': 'Test Puja Title',
          'short_description': 'This is a test puja for development',
          'location': 'Test Temple, Test City',
        },
        'puja_basic_hi': {
          'name': 'टेस्ट पूजा',
          'title': 'टेस्ट पूजा शीर्षक',
          'short_description': 'यह विकास के लिए एक टेस्ट पूजा है',
          'location': 'टेस्ट मंदिर, टेस्ट शहर',
        },
        'event_date': DateTime.now()
            .add(Duration(days: 30))
            .toIso8601String()
            .split('T')[0],
        'booking_closes_at': DateTime.now()
            .add(Duration(days: 29))
            .toIso8601String(),
        'devotee_count': 50,
        'devotee_images': ['https://picsum.photos/400/300?random=1'],
        'puja_images': [
          'https://picsum.photos/400/300?random=1',
          'https://picsum.photos/400/300?random=2',
          'https://picsum.photos/400/300?random=3',
        ],
        'content': {
          'about_puja': 'This is a test puja for development purposes.',
          'benefits': 'Test benefits of the puja.',
          'process': 'Test process of the puja.',
        },
        'content_hi': {
          'about_puja': 'यह विकास उद्देश्यों के लिए एक टेस्ट पूजा है।',
          'benefits': 'पूजा के टेस्ट लाभ।',
          'process': 'पूजा की टेस्ट प्रक्रिया।',
        },
        'temple_details': {
          'heading': 'Test Temple',
          'url': 'https://testtemple.com',
          'description': 'This is a test temple for development.',
        },
        'temple_details_hi': {
          'heading': 'टेस्ट मंदिर',
          'url': 'https://testtemple.com',
          'description': 'यह विकास के लिए एक टेस्ट मंदिर है।',
        },
        'packages': [
          {
            'name': 'Test Package',
            'price': 1000,
            'description': 'Test package description',
            'url': 'https://picsum.photos/300/200?random=4',
          },
        ],
        'packages_hi': [
          {
            'name': 'टेस्ट पैकेज',
            'price': 1000,
            'description': 'टेस्ट पैकेज विवरण',
            'url': 'https://picsum.photos/300/200?random=4',
          },
        ],
        'reviews': [
          {
            'name': 'Test User',
            'url': 'https://picsum.photos/100/100?random=5',
            'review_text': 'This is a test review.',
          },
        ],
        'reviews_hi': [
          {
            'name': 'टेस्ट यूजर',
            'url': 'https://picsum.photos/100/100?random=5',
            'review_text': 'यह एक टेस्ट समीक्षा है।',
          },
        ],
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('puja_booking')
          .insert(testPuja)
          .select()
          .single();

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
