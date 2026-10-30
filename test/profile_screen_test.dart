import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itlabcare/screens/profile_screen.dart';
import 'package:itlabcare/services/profile_service.dart';
import 'package:itlabcare/widgets/navigation.dart';

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

const _profile = StudentProfile(
  fullName: 'Aspiras Alexander J.',
  email: 'alexander@example.test',
  studentNumber: 'STU-1024',
  section: 'BSIT 2A',
  adviser: 'Dr. Reyes',
  accountStatus: 'active',
);

Future<void> _pumpProfile(
  WidgetTester tester,
  StudentProfileDataSource source, {
  StudentProfileRepository? repository,
  Future<void> Function()? signOut,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProfileScreen(
        repository:
            repository ??
            StudentProfileRepository(
              dataSource: source,
              userIdProvider: () => 'firebase-user-a',
            ),
        signOut: signOut,
      ),
    ),
  );
}

void main() {
  testWidgets('shows a loading state until the profile response arrives', (
    tester,
  ) async {
    final result = Completer<StudentProfile>();
    await _pumpProfile(tester, _ProfileSource(() => result.future));

    expect(find.byKey(const Key('profile-loading')), findsOneWidget);
    result.complete(_profile);
    await tester.pumpAndSettle();

    expect(find.text('Aspiras Alexander J.'), findsOneWidget);
  });

  testWidgets('renders live profile fields and optional adviser', (
    tester,
  ) async {
    await _pumpProfile(tester, _ProfileSource(() async => _profile));
    await tester.pumpAndSettle();

    expect(find.text('Aspiras Alexander J.'), findsOneWidget);
    expect(find.text('alexander@example.test'), findsOneWidget);
    expect(find.text('STU-1024'), findsOneWidget);
    expect(find.text('BSIT 2A'), findsOneWidget);
    expect(find.text('Dr. Reyes'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('My Section'), findsNothing);
  });

  testWidgets('personal information details reuse live profile data', (
    tester,
  ) async {
    await _pumpProfile(tester, _ProfileSource(() async => _profile));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Personal Information'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Personal Information'));
    await tester.pumpAndSettle();

    expect(find.text('Aspiras Alexander J.'), findsOneWidget);
    expect(find.text('alexander@example.test'), findsOneWidget);
    expect(find.text('STU-1024'), findsOneWidget);
    expect(find.text('BSIT 2A'), findsOneWidget);
  });

  testWidgets('shows an incomplete profile state with safe field fallbacks', (
    tester,
  ) async {
    const incomplete = StudentProfile(
      fullName: null,
      email: null,
      studentNumber: null,
      section: null,
      adviser: null,
      accountStatus: null,
    );
    await _pumpProfile(tester, _ProfileSource(() async => incomplete));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-empty-state')), findsOneWidget);
    expect(find.text('Name unavailable'), findsOneWidget);
    expect(find.text('Not provided'), findsWidgets);
  });

  testWidgets('shows retryable errors and retries profile loading', (
    tester,
  ) async {
    var attempt = 0;
    var signOutCalls = 0;
    final source = _ProfileSource(() async {
      if (attempt++ == 0) throw const SocketException('offline');
      return _profile;
    });
    await _pumpProfile(tester, source, signOut: () async => signOutCalls++);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not connect to the server. Check your connection and retry.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(source.calls, 2);
    expect(signOutCalls, 0);
    expect(find.text('Aspiras Alexander J.'), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads profile without signing out', (
    tester,
  ) async {
    var signOutCalls = 0;
    final source = _ProfileSource(() async => _profile);
    await _pumpProfile(tester, source, signOut: () async => signOutCalls++);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 350));
    await tester.pumpAndSettle();

    expect(source.calls, 2);
    expect(signOutCalls, 0);
  });

  testWidgets(
    'returning to Profile immediately shows the session-cached profile',
    (tester) async {
      final source = _ProfileSource(() async => _profile);
      final repository = StudentProfileRepository(
        dataSource: source,
        userIdProvider: () => 'firebase-user-a',
      );
      final navigatorKey = GlobalKey<NavigatorState>();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  noAnimationRoute(
                    (_) => ProfileScreen(repository: repository),
                  ),
                ),
                child: const Text('Open profile'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open profile'));
      await tester.pumpAndSettle();
      expect(find.text('Aspiras Alexander J.'), findsOneWidget);
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open profile'));
      await tester.pump();

      expect(find.text('Aspiras Alexander J.'), findsOneWidget);
      expect(find.byKey(const Key('profile-loading')), findsNothing);
      await tester.pumpAndSettle();
      expect(source.calls, 1);
    },
  );

  testWidgets(
    'stale cached profile remains visible during background refresh',
    (tester) async {
      final refresh = Completer<StudentProfile>();
      var calls = 0;
      final source = _ProfileSource(() {
        calls++;
        return calls == 1 ? Future.value(_profile) : refresh.future;
      });
      var now = DateTime(2026, 10, 20);
      final repository = StudentProfileRepository(
        dataSource: source,
        userIdProvider: () => 'firebase-user-a',
        refreshInterval: const Duration(minutes: 5),
        clock: () => now,
      );
      final navigatorKey = GlobalKey<NavigatorState>();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  noAnimationRoute(
                    (_) => ProfileScreen(repository: repository),
                  ),
                ),
                child: const Text('Open profile'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open profile'));
      await tester.pumpAndSettle();
      expect(find.text('Aspiras Alexander J.'), findsOneWidget);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      now = now.add(const Duration(minutes: 6));
      await tester.tap(find.text('Open profile'));
      await tester.pump();

      expect(find.text('Aspiras Alexander J.'), findsOneWidget);
      expect(find.byKey(const Key('profile-loading')), findsNothing);
      expect(calls, 2);

      refresh.complete(_profile);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'refresh failure keeps cached profile visible with a retry action',
    (tester) async {
      var attempt = 0;
      final source = _ProfileSource(() async {
        if (attempt++ > 0) throw const SocketException('offline');
        return _profile;
      });
      final repository = StudentProfileRepository(
        dataSource: source,
        userIdProvider: () => 'firebase-user-a',
      );
      addTearDown(repository.dispose);
      await _pumpProfile(tester, source, repository: repository);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 350));
      await tester.pumpAndSettle();

      expect(find.text('Aspiras Alexander J.'), findsOneWidget);
      expect(find.byKey(const Key('profile-loading')), findsNothing);
      expect(find.byKey(const Key('profile-refresh-error')), findsOneWidget);
      expect(
        find.text(
          'Could not connect to the server. Check your connection and retry.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'logout requires confirmation and cancel keeps the profile open',
    (tester) async {
      var signOutCalls = 0;
      await _pumpProfile(
        tester,
        _ProfileSource(() async => _profile),
        signOut: () async => signOutCalls++,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Log Out Account'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out Account'));
      await tester.pumpAndSettle();

      expect(find.text('Log Out?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(signOutCalls, 0);
      expect(find.text('Profile'), findsWidgets);
    },
  );

  testWidgets('confirmed logout returns to Login and clears history', (
    tester,
  ) async {
    var signOutCalls = 0;
    final repository = StudentProfileRepository(
      dataSource: _ProfileSource(() async => _profile),
      userIdProvider: () => 'firebase-user-a',
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfileScreen(
                    repository: repository,
                    signOut: () async => signOutCalls++,
                  ),
                ),
              ),
              child: const Text('Open profile'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Log Out Account'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out').last);
    await tester.pumpAndSettle();

    expect(signOutCalls, 1);
    expect(repository.cachedProfile, isNull);
    expect(find.text('Welcome Back!'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
