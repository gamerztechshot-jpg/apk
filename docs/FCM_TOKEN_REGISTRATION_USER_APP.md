# FCM Token Registration - User App

## Overview
This document describes how to register user-app FCM tokens with Supabase. It follows the same pattern as the admin app, with `p_app = 'user'`. This enables sending notifications to user devices via their stored FCM tokens.

---

## 1) Dependency
Add the dependency to `pubspec.yaml`:

```yaml
dependencies:
  firebase_messaging: ^15.1.3
```

Run:

```bash
flutter pub get
```

---

## 2) Create Service
Create `lib/core/services/fcm_token_service.dart` (or reuse a shared service):

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmTokenService {
  static bool _listenerStarted = false;

  static Future<void> registerUserToken() async {
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
        params: {'p_app': 'user', 'p_token': token},
      );
    } catch (e) {
      if (kDebugMode) print('FCM register error: $e');
    }
  }

  static void startUserTokenRefreshListener() {
    if (_listenerStarted) return;
    _listenerStarted = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) return;

      try {
        await supabase.rpc(
          'register_fcm_token',
          params: {'p_app': 'user', 'p_token': token},
        );
      } catch (e) {
        if (kDebugMode) print('FCM refresh error: $e');
      }
    });
  }
}
```

---

## 3) Call It After Login
After user login success:

```dart
await FcmTokenService.registerUserToken();
FcmTokenService.startUserTokenRefreshListener();
```

---

## 4) Call It On App Start (If Session Exists)
In your auth wrapper or splash:

```dart
if (Supabase.instance.client.auth.currentUser != null) {
  await FcmTokenService.registerUserToken();
  FcmTokenService.startUserTokenRefreshListener();
}
```

---

## 5) Platform Setup Notes
- Android 13+ requires `POST_NOTIFICATIONS` permission.
- iOS requires APNs setup and the Push Notifications capability.
- Web requires a VAPID key and a service worker.

---

## 6) Server Requirement
Make sure the RPC is deployed:

```sql
select public.register_fcm_token('user', '<token>');
```

Tokens are stored with no duplicates.

---

## Optional Next Steps
- Handle push payloads using `onMessage` and `onMessageOpenedApp`.
- Deep-link navigation using a `data.route` field from the `notifications` table.
