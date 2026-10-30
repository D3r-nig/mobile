import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itlabcare/screens/report_tracking_screen.dart';
import 'package:itlabcare/screens/reports_screen.dart';
import 'package:itlabcare/services/reports_service.dart';

class _FakeReportsDataSource implements StudentReportsDataSource {
  _FakeReportsDataSource({required this.load, required this.detail});

  final Future<List<StudentReport>> Function() load;
  final Future<StudentReport> Function(String id) detail;
  int listRequests = 0;
  final requestedDetails = <String>[];

  @override
  Future<List<StudentReport>> loadReports({bool forceRefresh = false}) {
    listRequests++;
    return load();
  }

  @override
  Future<StudentReport> loadReport(String reportId) {
    requestedDetails.add(reportId);
    return detail(reportId);
  }
}

StudentReport _report({
  required String id,
  required String reportNo,
  required String status,
  String description = 'Computer will not start',
}) => StudentReport.fromJson({
  'id': id,
  'report_no': reportNo,
  'category': 'hardware',
  'description': description,
  'priority': 'high',
  'status': status,
  'reported_at': '2026-10-17T10:00:00Z',
  'computer': {
    'asset_tag': 'PC-$id',
    'lab': {'name': 'Lab $id'},
  },
  'technician': {'full_name': 'Alex Tech'},
});

final _reports = [
  _report(id: '1', reportNo: 'RPT-1', status: 'pending'),
  _report(id: '2', reportNo: 'RPT-2', status: 'assigned'),
  _report(id: '3', reportNo: 'RPT-3', status: 'under_repair'),
  _report(id: '4', reportNo: 'RPT-4', status: 'in_progress'),
  _report(id: '5', reportNo: 'RPT-5', status: 'resolved'),
  _report(id: '6', reportNo: 'RPT-6', status: 'completed'),
  _report(id: '7', reportNo: 'RPT-7', status: 'cancelled'),
];

Future<void> _pumpReports(
  WidgetTester tester,
  StudentReportsDataSource source,
) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: ReportsScreen(dataSource: source),
    ),
  );
}

void main() {
  testWidgets('shows loading before the reports request completes', (
    tester,
  ) async {
    final result = Completer<List<StudentReport>>();
    final source = _FakeReportsDataSource(
      load: () => result.future,
      detail: (_) async => _reports.first,
    );
    await _pumpReports(tester, source);

    expect(find.byKey(const Key('reports-loading')), findsOneWidget);
    result.complete(_reports);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reports-loading')), findsNothing);
  });

  testWidgets(
    'calculates live summary counts and displays dynamic report cards',
    (tester) async {
      final source = _FakeReportsDataSource(
        load: () async => _reports,
        detail: (_) async => _reports.first,
      );
      await _pumpReports(tester, source);
      await tester.pumpAndSettle();

      expect(find.text('RPT-1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('report-summary-total')),
        findsOneWidget,
      );
      expect(find.text('7'), findsWidgets);
      expect(
        find.byKey(const ValueKey('report-summary-pending')),
        findsOneWidget,
      );
      expect(find.text('1'), findsWidgets);
      expect(
        find.byKey(const ValueKey('report-summary-active')),
        findsOneWidget,
      );
      expect(find.text('3'), findsWidgets);
      expect(
        find.byKey(const ValueKey('report-summary-completed')),
        findsOneWidget,
      );
      expect(find.text('#1021'), findsNothing);
      expect(find.text('Lab 1'), findsOneWidget);
    },
  );

  testWidgets(
    'filters normalized Pending, In Progress, Completed and Cancelled statuses',
    (tester) async {
      await _pumpReports(
        tester,
        _FakeReportsDataSource(
          load: () async => _reports,
          detail: (_) async => _reports.first,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('report-tab-Pending')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('report-card-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-card-2')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('report-tab-In Progress')));
      await tester.pumpAndSettle();
      for (final id in ['2', '3', '4']) {
        expect(find.byKey(ValueKey('report-card-$id')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('report-card-1')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('report-tab-Completed')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('report-card-5')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-card-6')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-card-3')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('report-tab-Cancelled')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('report-card-7')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-card-5')), findsNothing);
    },
  );

  testWidgets('shows the empty state for a successful empty list', (
    tester,
  ) async {
    await _pumpReports(
      tester,
      _FakeReportsDataSource(
        load: () async => [],
        detail: (_) async => _reports.first,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No reports yet.'), findsOneWidget);
    expect(find.text('Return to Home'), findsOneWidget);
    expect(find.byKey(const ValueKey('report-summary-total')), findsOneWidget);
  });

  testWidgets('shows API errors and retries the list request', (tester) async {
    var attempts = 0;
    final source = _FakeReportsDataSource(
      load: () async {
        if (attempts++ == 0) throw const ReportsApiException(404);
        return _reports;
      },
      detail: (_) async => _reports.first,
    );
    await _pumpReports(tester, source);
    await tester.pumpAndSettle();

    expect(
      find.text('Report data could not be found. Please try again later.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(source.listRequests, 2);
    expect(find.text('RPT-1'), findsOneWidget);
  });

  testWidgets(
    'pull-to-refresh updates data, preserves filter and avoids duplicates',
    (tester) async {
      var refresh = false;
      final source = _FakeReportsDataSource(
        load: () async => refresh
            ? [_report(id: '9', reportNo: 'RPT-9', status: 'under_repair')]
            : _reports,
        detail: (_) async => _reports.first,
      );
      await _pumpReports(tester, source);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('report-tab-In Progress')));
      await tester.pumpAndSettle();
      refresh = true;

      await tester.drag(
        find.byKey(const Key('reports-list')),
        const Offset(0, 420),
      );
      await tester.pumpAndSettle();

      expect(source.listRequests, 2);
      expect(
        find.byKey(const ValueKey('report-tab-In Progress')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('report-card-9')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-card-2')), findsNothing);
      expect(find.text('RPT-9'), findsOneWidget);
    },
  );

  testWidgets('opening a report loads and displays real dynamic details', (
    tester,
  ) async {
    final detailReport = StudentReport.fromJson({
      'id': '41',
      'report_no': 'RPT-41',
      'category': 'network',
      'description': 'Network connection drops during use',
      'priority': 'medium',
      'status': 'in_progress',
      'reported_at': '2026-10-17T10:00:00Z',
      'computer': {
        'asset_tag': 'WORKSTATION-41',
        'lab': {'name': 'North Lab'},
      },
      'technician': {'full_name': 'Morgan Technician'},
    });
    final source = _FakeReportsDataSource(
      load: () async => [detailReport],
      detail: (id) async {
        expect(id, '41');
        return detailReport;
      },
    );
    await _pumpReports(tester, source);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-card-41')));
    await tester.pumpAndSettle();

    expect(source.requestedDetails, ['41']);
    expect(find.byType(ReportTrackingScreen), findsOneWidget);
    expect(find.text('RPT-41'), findsOneWidget);
    expect(find.text('WORKSTATION-41'), findsOneWidget);
    expect(find.text('North Lab'), findsOneWidget);
    expect(find.text('network'), findsOneWidget);
    expect(find.text('Network connection drops during use'), findsWidgets);
    expect(find.text('Morgan Technician'), findsWidgets);
    expect(find.text('Waiting for assignment'), findsNothing);
    expect(find.text('#1021'), findsNothing);
  });

  testWidgets('report detail shows retryable not-found error', (tester) async {
    var detailAttempts = 0;
    final report = _reports.first;
    final source = _FakeReportsDataSource(
      load: () async => [report],
      detail: (_) async {
        if (detailAttempts++ == 0) {
          throw const ReportsApiException(404, isDetail: true);
        }
        return report;
      },
    );
    await _pumpReports(tester, source);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-card-1')));
    await tester.pumpAndSettle();

    expect(find.text('This report could not be found.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('RPT-1'), findsOneWidget);
    expect(detailAttempts, 2);
  });

  testWidgets(
    'Reports bottom navigation returns to Dashboard without stacking',
    (tester) async {
      final source = _FakeReportsDataSource(
        load: () async => _reports,
        detail: (_) async => _reports.first,
      );
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/dashboard',
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => settings.name == '/dashboard'
                ? Scaffold(
                    body: Center(
                      child: Column(
                        children: [
                          const Text('Dashboard'),
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                tester.element(find.text('Dashboard')),
                              ).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ReportsScreen(dataSource: source),
                                ),
                              );
                            },
                            child: const Text('Open reports'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ReportsScreen(dataSource: source),
          ),
        ),
      );
      await tester.tap(find.text('Open reports'));
      await tester.pumpAndSettle();
      expect(find.text('My Reports'), findsOneWidget);

      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('My Reports'), findsNothing);
    },
  );
}
