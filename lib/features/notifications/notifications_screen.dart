// features/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/user_notification.dart';
import '../../core/services/notifications_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsService _service = NotificationsService();
  bool _isLoading = true;
  String? _error;
  List<UserNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool showLoading = true}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please sign in to view notifications.';
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final results = await _service.fetchForUser(userId: userId);
    if (!mounted) return;
    setState(() {
      _notifications = results;
      _isLoading = false;
      _error = null;
    });
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('dd MMM, hh:mm a').format(timestamp.toLocal());
  }

  Future<void> _markAsRead(UserNotification notification) async {
    if (notification.readAt != null) return;
    await _service.markAsRead(notificationId: notification.id);
    if (!mounted) return;
    setState(() {
      _notifications = _notifications
          .map(
            (item) => item.id == notification.id
                ? UserNotification(
                    id: item.id,
                    title: item.title,
                    body: item.body,
                    status: item.status,
                    createdAt: item.createdAt,
                    readAt: DateTime.now(),
                    data: item.data,
                    entityType: item.entityType,
                    entityId: item.entityId,
                  )
                : item,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: Colors.orange.shade600,
        onRefresh: () => _loadNotifications(showLoading: false),
        child: _buildBody(horizontalPadding, isTablet),
      ),
    );
  }

  Widget _buildBody(double horizontalPadding, bool isTablet) {
    if (_isLoading) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        children: const [
          SizedBox(height: 80),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.notifications_off, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _loadNotifications(),
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.notifications_none, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            'No notifications yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        24,
      ),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final isUnread = notification.readAt == null;
        return _NotificationCard(
          notification: notification,
          isUnread: isUnread,
          isTablet: isTablet,
          timestamp: _formatTimestamp(notification.createdAt),
          onTap: () => _markAsRead(notification),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final UserNotification notification;
  final bool isUnread;
  final bool isTablet;
  final String timestamp;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isUnread,
    required this.isTablet,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? Colors.orange.shade200 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications,
                  color: Colors.orange.shade600,
                  size: isTablet ? 22 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title.isNotEmpty
                                ? notification.title
                                : 'Notification',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body.isNotEmpty
                          ? notification.body
                          : 'No details available.',
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (timestamp.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
