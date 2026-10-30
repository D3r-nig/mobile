import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itlabcare/services/dashboard_service.dart';

class _TokenProvider implements FirebaseIdTokenProvider {
  _TokenProvider({this.displayName});

  @override
  final String? displayName;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async =>
      'firebase-test-token';
}

class _RefreshingTokenProvider implements FirebaseIdTokenProvider {
  int calls = 0;

  @override
  String? get displayName => null;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    calls++;
    return forceRefresh ? 'refreshed-token' : 'initial-token';
  }
}

class _InitiallyMissingTokenProvider implements FirebaseIdTokenProvider {
  int normalCalls = 0;
  int forcedCalls = 0;

  @override
  String? get displayName => 'Aspiras Alexander J.';

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      forcedCalls++;
      return 'refreshed-token';
    }
    normalCalls++;
    return null;
  }
}

void main() {
  test(
    'uses the deployed API when no build-time API root is supplied',
    () async {
      final seen = <Uri>[];
      final client = MockClient((request) async {
        seen.add(request.url);
        if (request.url.path == '/api/mobile/me') {
          return http.Response('{"user":{"full_name":"Jordan Lee"}}', 200);
        }
        if (request.url.path == '/api/mobile/problem-reports') {
          return http.Response('[]', 200);
        }
        return http.Response('Not found', 404);
      });
      addTearDown(client.close);

      final data = await FirebaseDashboardDataSource(
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadDashboard();

      expect(
        seen.map((uri) => uri.host),
        everyElement('itlabcare-api.onrender.com'),
      );
      expect(seen.map((uri) => uri.path).toSet(), {
        '/api/mobile/me',
        '/api/mobile/problem-reports',
      });
      expect(data.studentName, 'Jordan Lee');
    },
  );

  test('force-refreshes when Firebase initially returns no ID token', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], startsWith('Bearer '));
      if (request.url.path.endsWith('/mobile/me')) {
        return http.Response(
          '{"user":{"full_name":"Aspiras Alexander J."}}',
          200,
        );
      }
      return http.Response('[{"status":"pending"}]', 200);
    });
    addTearDown(client.close);
    final tokenProvider = _InitiallyMissingTokenProvider();

    final data = await FirebaseDashboardDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: tokenProvider,
    ).loadDashboard();

    expect(data.studentName, 'Aspiras Alexander J.');
    expect(data.totalReports, 1);
    expect(tokenProvider.normalCalls, 1);
    expect(tokenProvider.forcedCalls, 1);
  });

  test(
    'refreshes Firebase token and retries transient initial 401 responses',
    () async {
      final requestsByPath = <String, int>{};
      final client = MockClient((request) async {
        final path = request.url.path;
        expect(
          request.headers['authorization'],
          requestsByPath[path] == null
              ? 'Bearer initial-token'
              : 'Bearer refreshed-token',
        );
        final attempt = (requestsByPath[path] ?? 0) + 1;
        requestsByPath[path] = attempt;
        if (attempt == 1) {
          return http.Response('{"message":"Unauthenticated"}', 401);
        }
        if (path.endsWith('/mobile/me')) {
          return http.Response(
            '{"user":{"full_name":"Aspiras Alexander J."}}',
            200,
          );
        }
        return http.Response('[{"status":"pending"}]', 200);
      });
      addTearDown(client.close);
      final tokenProvider = _RefreshingTokenProvider();

      final data = await FirebaseDashboardDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: tokenProvider,
      ).loadDashboard();

      expect(data.studentName, 'Aspiras Alexander J.');
      expect(data.totalReports, 1);
      expect(requestsByPath.values, everyElement(2));
      expect(tokenProvider.calls, 2);
    },
  );

  test('retries a report request after a second startup 401', () async {
    var reportsRequests = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/mobile/me')) {
        return http.Response(
          '{"user":{"full_name":"Aspiras Alexander J."}}',
          200,
        );
      }

      reportsRequests++;
      if (reportsRequests < 3) {
        return http.Response('{"message":"Unauthenticated"}', 401);
      }
      return http.Response('[{"status":"pending"}]', 200);
    });
    addTearDown(client.close);

    final data = await FirebaseDashboardDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: _RefreshingTokenProvider(),
    ).loadDashboard();

    expect(data.studentName, 'Aspiras Alexander J.');
    expect(data.totalReports, 1);
    expect(reportsRequests, 3);
  });

  test(
    'loads profile and counts supported report statuses with ID token',
    () async {
      final seen = <Uri>[];
      final client = MockClient((request) async {
        seen.add(request.url);
        expect(request.headers['authorization'], 'Bearer firebase-test-token');
        if (request.url.path.endsWith('/mobile/me')) {
          return http.Response('{"user":{"full_name":"Jordan Lee"}}', 200);
        }
        return http.Response('''
        [
          {"status":"pending"},
          {"status":"assigned"},
          {"status":"in_progress"},
          {"status":"resolved"},
          {"status":"completed"},
          {"status":"cancelled"},
          {}
        ]
        ''', 200);
      });
      addTearDown(client.close);

      final data = await FirebaseDashboardDataSource(
        baseUrl: 'https://api.example.test/api/',
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadDashboard();

      expect(seen.map((uri) => uri.path).toSet(), {
        '/api/mobile/me',
        '/api/mobile/problem-reports',
      });
      expect(data.studentName, 'Jordan Lee');
      expect(data.totalReports, 7);
      expect(data.inProgressReports, 3);
      expect(data.resolvedReports, 2);
    },
  );

  test('does not turn a missing Home endpoint into fake zero counts', () async {
    final client = MockClient((_) async => http.Response('', 404));
    addTearDown(client.close);

    await expectLater(
      FirebaseDashboardDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadDashboard(),
      throwsA(
        isA<DashboardApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          404,
        ),
      ),
    );
  });

  test('falls back to the signed-in Firebase display name', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/mobile/me')) {
        return http.Response('{}', 200);
      }
      return http.Response('[]', 200);
    });
    addTearDown(client.close);

    final data = await FirebaseDashboardDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: _TokenProvider(displayName: 'Taylor Student'),
    ).loadDashboard();

    expect(data.studentName, 'Taylor Student');
  });

  test('throws status-specific API errors', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/mobile/me')) {
        return http.Response('{}', 200);
      }
      return http.Response('{}', 403);
    });
    addTearDown(client.close);

    await expectLater(
      FirebaseDashboardDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadDashboard(),
      throwsA(
        isA<DashboardApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          403,
        ),
      ),
    );
  });

  test(
    'rejects malformed reports payloads instead of showing fake counts',
    () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/mobile/me')) {
          return http.Response('{"fullName":""}', 200);
        }
        return http.Response('{"unexpected":true}', 200);
      });
      addTearDown(client.close);

      await expectLater(
        FirebaseDashboardDataSource(
          baseUrl: 'https://api.example.test/api',
          client: client,
          tokenProvider: _TokenProvider(),
        ).loadDashboard(),
        throwsA(isA<FormatException>()),
      );
    },
  );
}
