// core/models/user_notification.dart
class UserNotification {
  final String id;
  final String title;
  final String body;
  final String? status;
  final DateTime? createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;
  final String? entityType;
  final String? entityId;

  UserNotification({
    required this.id,
    required this.title,
    required this.body,
    this.status,
    this.createdAt,
    this.readAt,
    this.data,
    this.entityType,
    this.entityId,
  });

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    return UserNotification(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      status: map['status'] as String?,
      createdAt: _parseDate(map['created_at']),
      readAt: _parseDate(map['read_at']),
      data: map['data'] is Map<String, dynamic>
          ? map['data'] as Map<String, dynamic>
          : null,
      entityType: map['entity_type'] as String?,
      entityId: map['entity_id']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
