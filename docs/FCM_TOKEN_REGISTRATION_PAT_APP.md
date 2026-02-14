# FCM Token Registration - PAT App

## Overview
This document explains how to register PAT-app FCM tokens with Supabase and how to receive/display notifications in Flutter. It mirrors the user app pattern, with `p_app = 'pat'`.

---

## 1) Dependency
Add the dependency to `pubspec.yaml`:

```yaml
dependencies:
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1
```

Run:

```bash
flutter pub get
```

---

## 2) Create/Reuse FCM Token Service
Create or reuse `lib/core/services/fcm_token_service.dart` (PAT version shown):

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmTokenService {
  static bool _listenerStarted = false;

  static Future<void> registerPatToken() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) return;

    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission();
    } catch (_) {}

    String? token;
    try {
      token = await messaging.getToken();
    } catch (_) {}

    if (token == null || token.isEmpty) return;

    try {
      await supabase.rpc(
        'register_fcm_token',
        params: {'p_app': 'pat', 'p_token': token},
      );
    } catch (e) {
      if (kDebugMode) print('FCM register error: $e');
    }
  }

  static void startPatTokenRefreshListener() {
    if (_listenerStarted) return;
    _listenerStarted = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) return;

      try {
        await supabase.rpc(
          'register_fcm_token',
          params: {'p_app': 'pat', 'p_token': token},
        );
      } catch (e) {
        if (kDebugMode) print('FCM refresh error: $e');
      }
    });
  }
}
```

---

## 3) Call After Login/Signup
After PAT login or signup success:

```dart
await FcmTokenService.registerPatToken();
FcmTokenService.startPatTokenRefreshListener();
```

---

## 4) Call On App Start (If Session Exists)
In your auth wrapper / splash:

```dart
if (Supabase.instance.client.auth.currentUser != null) {
  await FcmTokenService.registerPatToken();
  FcmTokenService.startPatTokenRefreshListener();
}
```

Also call on app resume (optional but recommended):

```dart
if (Supabase.instance.client.auth.currentUser != null) {
  await FcmTokenService.registerPatToken();
}
```

---

## 5) Flutter UI: Receiving Notifications
Use `flutter_local_notifications` to display foreground messages.

Create `lib/core/services/notification_service.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(initSettings);

    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((message) {
      _showForegroundNotification(message);
    });
  }

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'Notification';
    final body =
        notification?.body ?? message.data['body']?.toString() ?? '';

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: message.data['route']?.toString(),
    );
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await initialize();
    await _showForegroundNotification(message);
  }
}
```

Hook it in `main.dart`:

```dart
await Firebase.initializeApp();
FirebaseMessaging.onBackgroundMessage(
  NotificationService.handleBackgroundMessage,
);
await NotificationService.initialize();
```

---

## 6) Platform Notes
- Android 13+: add `POST_NOTIFICATIONS` permission.
- iOS: enable Push Notifications capability + APNs.
- Web: requires VAPID key and service worker.

---

## 7) Server Requirement
Ensure RPC exists:

```sql
select public.register_fcm_token('pat', '<token>');
```

Tokens are stored without duplicates.
