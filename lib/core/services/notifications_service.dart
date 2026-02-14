// core/services/notifications_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_notification.dart';

class NotificationsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserNotification>> fetchForUser({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('recipient_user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => UserNotification.fromMap(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead({required String notificationId}) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (_) {}
  }
}
