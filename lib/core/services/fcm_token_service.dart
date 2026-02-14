import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmTokenService {
  static bool _listenerStarted = false;

  static Future<void> registerUserToken() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      return;
    }

    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission();
    } catch (_) {
    }

    String? token;
    try {
      token = await messaging.getToken();
    } catch (e) {
    }

    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await supabase.rpc(
        'register_fcm_token',
        params: {'p_app': 'user', 'p_token': token},
      );
      if (kDebugMode) {
      }
    } catch (e) {
    }
  }

  static void startUserTokenRefreshListener() {
    if (_listenerStarted) return;
    _listenerStarted = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (token.isEmpty) {
        return;
      }
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        return;
      }

      try {
        await supabase.rpc(
          'register_fcm_token',
          params: {'p_app': 'user', 'p_token': token},
        );
        if (kDebugMode) {
        }
      } catch (e) {
      }
    });
  }

  static Future<void> unregisterUserToken() async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      return;
    }

    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {
    }

    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await supabase.rpc(
        'remove_fcm_token',
        params: {'p_app': 'user', 'p_token': token},
      );
      if (kDebugMode) {
      }
    } catch (e) {
    }
  }
}
