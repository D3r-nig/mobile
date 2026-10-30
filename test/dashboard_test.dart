import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itlabcare/screens/dashboard_screen.dart';
import 'package:itlabcare/services/dashboard_service.dart';

class _FakeDashboardDataSource implements DashboardDataSource {
  _FakeDashboardDataSource(this.load, {this.cachedStudentName});

  final Future<DashboardData> Function() load;
  @override
  final String? cachedStudentName;
  int calls = 0;

  @override
  Future<DashboardData> loadDashboard({bool forceRefresh = false}) {
    calls++;
    return load();
  }
}

const _loadedData = DashboardData(
  studentName: 'Jordan Lee',
  totalReports: 5,
  inProgressReports: 2,
  resolvedReports: 1,
);

Future<void> _pumpDashboard(
  WidgetTester tester,
  DashboardDataSource dataSource,
) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: DashboardScreen(dataSource: dataSource),
    ),
  );
}

void main() {
  testWidgets('shows an initial loading state', (tester) async {
    final result = Completer<DashboardData>();
    final dataSource = _FakeDashboardDataSource(
      () => result.future,
      cachedStudentName: 'Aspiras Alexander J.',
    );

    await _pumpDashboard(tester, dataSource);

    expect(find.byKey(const Key('dashboard-loading')), findsOneWidget);
    expect(find.text('Hello, Aspiras Alexander J.!'), findsOneWidget);
    result.complete(_loadedData);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-loading')), findsNothing);
  });

  testWidgets('renders the real profile name and report summary counts', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      _FakeDashboardDataSource(() async => _loadedData),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello, Jordan Lee!'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-total-count')), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows empty reports state with zero summary counts', (
    tester,
  ) async {
    const data = DashboardData(
      studentName: 'Student',
      totalReports: 0,
      inProgressReports: 0,
      resolvedReports: 0,
    );
    await _pumpDashboard(tester, _FakeDashboardDataSource(() async => data));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-total-count')), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
  });

  testWidgets('shows API errors and retries successfully', (tester) async {
    var attempt = 0;
    final dataSource = _FakeDashboardDataSource(() async {
      if (attempt++ == 0) throw const DashboardApiException(403);
      return _loadedData;
    });
    await _pumpDashboard(tester, dataSource);
    await tester.pumpAndSettle();

    expect(
      find.text('This student account is inactive or is not authorized.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(dataSource.calls, 2);
    expect(find.text('Hello, Jordan Lee!'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('pulling down refreshes Home data', (tester) async {
    final dataSource = _FakeDashboardDataSource(() async => _loadedData);
    await _pumpDashboard(tester, dataSource);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 350));
    await tester.pumpAndSettle();

    expect(dataSource.calls, 2);
  });

  testWidgets('Home quick actions open the existing destination screens', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      _FakeDashboardDataSource(() async => _loadedData),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan QR Code').first);
    await tester.pumpAndSettle();
    expect(find.text('Scan QR Code'), findsWidgets);

    await _pumpDashboard(
      tester,
      _FakeDashboardDataSource(() async => _loadedData),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Reports').first);
    await tester.pumpAndSettle();
    expect(find.text('Reports overview'), findsOneWidget);

    await _pumpDashboard(
      tester,
      _FakeDashboardDataSource(() async => _loadedData),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lab Computers'));
    await tester.pumpAndSettle();
    expect(find.text('Computer List'), findsOneWidget);

    await _pumpDashboard(
      tester,
      _FakeDashboardDataSource(() async => _loadedData),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications').first);
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsOneWidget);
  });

  testWidgets(
    'bottom navigation opens Reports, Scan, Notifications, and Profile',
    (tester) async {
      await _pumpDashboard(
        tester,
        _FakeDashboardDataSource(() async => _loadedData),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();
      expect(find.text('Reports overview'), findsOneWidget);

      await tester.tap(find.text('Scan').last);
      await tester.pumpAndSettle();
      expect(find.text('Scan QR Code'), findsWidgets);

      await tester.tap(find.text('Notifications').last);
      await tester.pumpAndSettle();
      expect(find.text('Inbox'), findsOneWidget);

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('Account settings'), findsOneWidget);
    },
  );
}
