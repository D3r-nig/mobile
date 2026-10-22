import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'dashboard_service.dart';
import 'mobile_api_config.dart';

@immutable
class StudentNotification {
  const StudentNotification({required this.id, required this.title, required this.message, required this.status, required this.createdAt});

  factory StudentNotification.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid notification.');
    return StudentNotification(
      id: value['id']?.toString() ?? '',
      title: value['title']?.toString() ?? 'Notification',
      message: value['message']?.toString() ?? '',
      status: value['status']?.toString() ?? 'unread',
      createdAt: value['created_at']?.toString(),
    );
  }

  final String id;
  final String title;
  final String message;
  final String status;
  final String? createdAt;
  bool get isUnread => status == 'unread';
}

abstract interface class NotificationsDataSource {
  Future<List<StudentNotification>> loadNotifications();
}

class FirebaseNotificationsDataSource implements NotificationsDataSource {
  static List<StudentNotification>? _cachedNotifications;

  FirebaseNotificationsDataSource({http.Client? client, FirebaseIdTokenProvider? tokenProvider, String? baseUrl})
      : _ownsClient = client == null,
        _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? CurrentFirebaseIdTokenProvider(),
        _baseUrl = (baseUrl ?? mobileApiBaseUrl).trim().replaceFirst(RegExp(r'/+$'), '');

  final bool _ownsClient;
  final http.Client _client;
  final FirebaseIdTokenProvider _tokenProvider;
  final String _baseUrl;

  void dispose() {
    if (_ownsClient) _client.close();
  }

  static List<StudentNotification>? get cachedNotifications => _cachedNotifications;

  static void clearCache() => _cachedNotifications = null;

  @override
  Future<List<StudentNotification>> loadNotifications() async {
    final token = await _tokenProvider.getIdToken();
    if (_baseUrl.isEmpty || token == null || token.isEmpty) throw const NotificationsApiException(401);
    final response = await _client.get(
      Uri.parse('$_baseUrl/mobile/notifications'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) throw NotificationsApiException(response.statusCode);
    final payload = jsonDecode(response.body);
    if (payload is! List) throw const FormatException('Invalid notifications response.');
    final notifications = payload.map(StudentNotification.fromJson).toList();
    _cachedNotifications = notifications;
    return notifications;
  }
}

class NotificationsApiException implements Exception {
  const NotificationsApiException(this.statusCode);
  final int statusCode;
}
