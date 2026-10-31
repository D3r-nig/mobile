import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'mobile_api_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) registerCurrentDevice();
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      registerCurrentDevice();
    });
  }

  static Future<void> registerCurrentDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await FirebaseMessaging.instance.getToken();
    if (user == null || token == null || token.isEmpty) return;

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) return;
    try {
      await http.post(
        Uri.parse('$mobileApiBaseUrl/mobile/push-token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );
    } catch (_) {
      // Push registration retries on the next token refresh or app start.
    }
  }
}
