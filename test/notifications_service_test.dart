import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itlabcare/services/dashboard_service.dart';
import 'package:itlabcare/services/notifications_service.dart';

class _TokenProvider implements FirebaseIdTokenProvider {
  @override
  String? get displayName => null;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async =>
      'student-id-token';
}

void main() {
  tearDown(FirebaseNotificationsDataSource.clearCache);

  test('reuses a fresh notification cache without refetching', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response(
        '[{"id":1,"title":"Report updated","message":"Ready","status":"unread"}]',
        200,
      );
    });
    addTearDown(client.close);
    final source = FirebaseNotificationsDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: _TokenProvider(),
    );

    await source.loadNotifications();
    final cached = await source.loadNotifications();

    expect(requests, 1);
    expect(cached.single.isUnread, isTrue);
  });

  test('marks a notification as read through the mobile API', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/mobile/notifications/1/read');
      expect(request.headers['authorization'], 'Bearer student-id-token');
      return http.Response(
        '{"id":1,"title":"Report updated","message":"Ready","status":"read"}',
        200,
      );
    });
    addTearDown(client.close);
    final source = FirebaseNotificationsDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: _TokenProvider(),
    );

    final notification = await source.markAsRead('1');

    expect(notification.isUnread, isFalse);
  });
}
