import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itlabcare/services/dashboard_service.dart';
import 'package:itlabcare/services/profile_service.dart';

class _ProfileSource implements StudentProfileDataSource {
  _ProfileSource(this.load);

  final Future<StudentProfile> Function() load;
  int calls = 0;

  @override
  Future<StudentProfile> loadProfile() {
    calls++;
    return load();
  }

  @override
  void dispose() {}
}

const _cachedProfile = StudentProfile(
  fullName: 'Student A',
  email: 'student-a@example.test',
  studentNumber: 'STU-A',
  section: 'Class A',
  adviser: null,
  accountStatus: 'active',
);

const _otherProfile = StudentProfile(
  fullName: 'Student B',
  email: 'student-b@example.test',
  studentNumber: 'STU-B',
  section: 'Class B',
  adviser: null,
  accountStatus: 'active',
);

class _TokenProvider implements FirebaseIdTokenProvider {
  int normalCalls = 0;
  int forcedCalls = 0;

  @override
  String? get displayName => null;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      forcedCalls++;
      return 'refreshed-token';
    }
    normalCalls++;
    return 'profile-token';
  }
}

void main() {
  test(
    'uses the deployed API when no build-time API root is supplied',
    () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'itlabcare-api.onrender.com');
        expect(request.url.path, '/api/mobile/me');
        return http.Response('{"user":{"full_name":"Jordan Lee"}}', 200);
      });
      addTearDown(client.close);

      final profile = await FirebaseStudentProfileDataSource(
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadProfile();

      expect(profile.fullName, 'Jordan Lee');
    },
  );

  test('loads authenticated profile fields from mobile me', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/mobile/me');
      expect(request.headers['authorization'], 'Bearer profile-token');
      return http.Response('''
        {"user":{
          "full_name":"Aspiras Alexander J.",
          "email":"alexander@example.test",
          "student_no":"STU-1024",
          "section":"BSIT 2A",
          "adviser":"Dr. Reyes",
          "status":"active"
        }}
        ''', 200);
    });
    addTearDown(client.close);

    final profile = await FirebaseStudentProfileDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: _TokenProvider(),
    ).loadProfile();

    expect(profile.fullName, 'Aspiras Alexander J.');
    expect(profile.email, 'alexander@example.test');
    expect(profile.studentNumber, 'STU-1024');
    expect(profile.section, 'BSIT 2A');
    expect(profile.adviser, 'Dr. Reyes');
    expect(profile.accountStatus, 'active');
    expect(profile.isEmpty, isFalse);
  });

  test('parses missing optional values safely', () async {
    final client = MockClient(
      (_) async => http.Response('{"user":{"full_name":"Student"}}', 200),
    );
    addTearDown(client.close);

    final profile = await FirebaseStudentProfileDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: _TokenProvider(),
    ).loadProfile();

    expect(profile.email, isNull);
    expect(profile.studentNumber, isNull);
    expect(profile.section, isNull);
    expect(profile.adviser, isNull);
    expect(profile.accountStatus, isNull);
    expect(profile.isEmpty, isFalse);
  });

  test('force-refreshes the Firebase ID token once after a 401', () async {
    final tokenProvider = _TokenProvider();
    final client = MockClient((request) async {
      expect(
        request.headers['authorization'],
        'Bearer ${tokenProvider.normalCalls == 1 && tokenProvider.forcedCalls == 0 ? 'profile-token' : 'refreshed-token'}',
      );
      if (tokenProvider.forcedCalls == 0) {
        return http.Response('{"message":"Unauthenticated"}', 401);
      }
      return http.Response('{"user":{"full_name":"Student"}}', 200);
    });
    addTearDown(client.close);

    final profile = await FirebaseStudentProfileDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: tokenProvider,
    ).loadProfile();

    expect(profile.fullName, 'Student');
    expect(tokenProvider.forcedCalls, 1);
  });

  test('reports forbidden and not-found profile responses', () async {
    for (final statusCode in [403, 404]) {
      final client = MockClient((_) async => http.Response('{}', statusCode));
      final source = FirebaseStudentProfileDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: _TokenProvider(),
      );

      await expectLater(
        source.loadProfile(),
        throwsA(
          isA<ProfileApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            statusCode,
          ),
        ),
      );
      client.close();
    }
  });

  test('reports malformed profile JSON', () async {
    final client = MockClient((_) async => http.Response('{invalid', 200));
    addTearDown(client.close);

    await expectLater(
      FirebaseStudentProfileDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadProfile(),
      throwsA(isA<FormatException>()),
    );
  });

  test('propagates network failures for retry UI', () async {
    final client = MockClient((_) async {
      throw const SocketException('offline');
    });
    addTearDown(client.close);

    await expectLater(
      FirebaseStudentProfileDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadProfile(),
      throwsA(isA<SocketException>()),
    );
  });

  test(
    'coalesces simultaneous profile requests for the same Firebase user',
    () async {
      final result = Completer<StudentProfile>();
      final source = _ProfileSource(() => result.future);
      final repository = StudentProfileRepository(
        dataSource: source,
        userIdProvider: () => 'firebase-user-a',
      );

      final first = repository.loadProfile();
      final second = repository.loadProfile();
      await Future<void>.delayed(Duration.zero);

      expect(source.calls, 1);
      result.complete(_cachedProfile);
      expect(await first, _cachedProfile);
      expect(await second, _cachedProfile);
      repository.dispose();
    },
  );

  test(
    'clears cached profile when Firebase authentication changes accounts',
    () async {
      final accountChanges = StreamController<String?>.broadcast();
      addTearDown(accountChanges.close);
      var userId = 'firebase-user-a';
      final source = _ProfileSource(
        () async =>
            userId == 'firebase-user-a' ? _cachedProfile : _otherProfile,
      );
      final repository = StudentProfileRepository(
        dataSource: source,
        userIdProvider: () => userId,
        accountChanges: accountChanges.stream,
      );
      addTearDown(repository.dispose);

      await repository.loadProfile();
      expect(repository.cachedProfile?.email, 'student-a@example.test');

      userId = 'firebase-user-b';
      accountChanges.add(userId);
      await Future<void>.delayed(Duration.zero);

      expect(repository.cachedProfile, isNull);
      expect((await repository.loadProfile()).email, 'student-b@example.test');
      expect(repository.cachedProfile?.email, 'student-b@example.test');
    },
  );

  test('clears cached profile explicitly after logout', () async {
    final repository = StudentProfileRepository(
      dataSource: _ProfileSource(() async => _cachedProfile),
      userIdProvider: () => 'firebase-user-a',
    );
    addTearDown(repository.dispose);

    await repository.loadProfile();
    repository.clear();

    expect(repository.cachedProfile, isNull);
  });

  test('does not return one Firebase user profile for another user', () async {
    var userId = 'firebase-user-a';
    final repository = StudentProfileRepository(
      dataSource: _ProfileSource(
        () async =>
            userId == 'firebase-user-a' ? _cachedProfile : _otherProfile,
      ),
      userIdProvider: () => userId,
    );
    addTearDown(repository.dispose);

    await repository.loadProfile();
    userId = 'firebase-user-b';

    expect(repository.cachedProfile, isNull);
    expect((await repository.loadProfile()).email, 'student-b@example.test');
  });
}
