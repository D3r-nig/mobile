import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'dashboard_service.dart';
import 'mobile_api_config.dart';

@immutable
class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
  });

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

  StudentNotification copyWith({String? status}) => StudentNotification(
    id: id,
    title: title,
    message: message,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}

abstract interface class NotificationsDataSource {
  Future<List<StudentNotification>> loadNotifications({
    bool forceRefresh = false,
  });
  Future<StudentNotification> markAsRead(String id);
  Future<void> markAllAsRead();
}

class FirebaseNotificationsDataSource implements NotificationsDataSource {
  static List<StudentNotification>? _cachedNotifications;
  static DateTime? _cachedAt;
  static const cacheTtl = Duration(seconds: 30);

  FirebaseNotificationsDataSource({
    http.Client? client,
    FirebaseIdTokenProvider? tokenProvider,
    String? baseUrl,
  }) : _ownsClient = client == null,
       _client = client ?? http.Client(),
       _tokenProvider = tokenProvider ?? CurrentFirebaseIdTokenProvider(),
       _baseUrl = (baseUrl ?? mobileApiBaseUrl).trim().replaceFirst(
         RegExp(r'/+$'),
         '',
       );

  final bool _ownsClient;
  final http.Client _client;
  final FirebaseIdTokenProvider _tokenProvider;
  final String _baseUrl;

  void dispose() {
    if (_ownsClient) _client.close();
  }

  static List<StudentNotification>? get cachedNotifications =>
      _cachedNotifications;

  static void clearCache() {
    _cachedNotifications = null;
    _cachedAt = null;
  }

  @override
  Future<List<StudentNotification>> loadNotifications({
    bool forceRefresh = false,
  }) async {
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        _cachedNotifications != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < cacheTtl) {
      return _cachedNotifications!;
    }

    final token = await _tokenProvider.getIdToken();
    if (_baseUrl.isEmpty || token == null || token.isEmpty) {
      throw const NotificationsApiException(401);
    }
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/mobile/notifications'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationsApiException(response.statusCode);
    }
    final payload = jsonDecode(response.body);
    if (payload is! List) {
      throw const FormatException('Invalid notifications response.');
    }
    final notifications = payload.map(StudentNotification.fromJson).toList();
    _cachedNotifications = notifications;
    _cachedAt = DateTime.now();
    return notifications;
  }

  @override
  Future<StudentNotification> markAsRead(String id) async {
    final token = await _tokenProvider.getIdToken();
    if (_baseUrl.isEmpty || token == null || token.isEmpty) {
      throw const NotificationsApiException(401);
    }
    final response = await _client
        .put(
          Uri.parse('$_baseUrl/mobile/notifications/$id/read'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationsApiException(response.statusCode);
    }
    final notification = StudentNotification.fromJson(
      jsonDecode(response.body),
    );
    _cachedNotifications = _cachedNotifications
        ?.map((item) => item.id == notification.id ? notification : item)
        .toList();
    return notification;
  }

  @override
  Future<void> markAllAsRead() async {
    final token = await _tokenProvider.getIdToken();
    if (_baseUrl.isEmpty || token == null || token.isEmpty) {
      throw const NotificationsApiException(401);
    }
    final response = await _client
        .put(
          Uri.parse('$_baseUrl/mobile/notifications/read-all'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationsApiException(response.statusCode);
    }
    _cachedNotifications = _cachedNotifications
        ?.map((item) => item.copyWith(status: 'read'))
        .toList();
  }
}

class NotificationsApiException implements Exception {
  const NotificationsApiException(this.statusCode);
  final int statusCode;
}
