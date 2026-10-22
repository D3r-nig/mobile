import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itlabcare/services/dashboard_service.dart';
import 'package:itlabcare/services/reports_service.dart';
import 'package:itlabcare/services/report_submission_service.dart';

class _TokenProvider implements FirebaseIdTokenProvider {
  @override
  String? get displayName => null;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async =>
      'student-id-token';
}

void main() {
  test('submits a mobile report to the teacher-review queue', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/mobile/problem-reports');
      expect(request.headers['authorization'], 'Bearer student-id-token');
      expect(request.body, contains('Keyboard stopped working'));
      return http.Response('{"id":7,"status":"pending_teacher_review"}', 201);
    });
    addTearDown(client.close);

    final result = await FirebaseStudentReportSubmissionDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: _TokenProvider(),
    ).submitReport(
      computerId: 7,
      category: 'hardware',
      description: 'Keyboard stopped working',
      priority: 'high',
    );

    expect(result['status'], 'pending_teacher_review');
  });

  test(
    'uses the deployed API when no build-time API root is supplied',
    () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'itlabcare-api.onrender.com');
        expect(request.url.path, '/api/mobile/problem-reports');
        return http.Response('[]', 200);
      });
      addTearDown(client.close);

      final reports = await FirebaseStudentReportsDataSource(
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadReports();

      expect(reports, isEmpty);
    },
  );

  test('attaches the Firebase ID token and parses array responses', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/mobile/problem-reports');
      expect(request.headers['authorization'], 'Bearer student-id-token');
      return http.Response(
        '[{"id":42,"report_no":"RPT-42","status":"pending"}]',
        200,
      );
    });
    addTearDown(client.close);

    final reports = await FirebaseStudentReportsDataSource(
      baseUrl: 'https://api.example.test/api/',
      client: client,
      tokenProvider: _TokenProvider(),
    ).loadReports();

    expect(reports, hasLength(1));
    expect(reports.single.reportNumber, 'RPT-42');
    expect(reports.single.statusLabel, 'Pending');
  });

  test('parses wrapped API responses and nested report fields', () async {
    final client = MockClient(
      (_) async => http.Response('''
      {"data":[
        {
          "id":8,
          "report_no":"RPT-008",
          "category":"hardware",
          "description":"Keyboard stopped working",
          "priority":"high",
          "status":"under_repair",
          "reported_at":"2026-10-17T09:00:00Z",
          "computer":{"asset_tag":"PC-008","lab":{"name":"Lab 8"}},
          "technician":{"full_name":"Casey Rivera"}
        }
      ]}
      ''', 200),
    );
    addTearDown(client.close);

    final report = (await FirebaseStudentReportsDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: _TokenProvider(),
    ).loadReports()).single;

    expect(report.id, '8');
    expect(report.reportNumber, 'RPT-008');
    expect(report.description, 'Keyboard stopped working');
    expect(report.category, 'hardware');
    expect(report.priority, 'high');
    expect(report.statusLabel, 'In Progress');
    expect(report.computer, 'PC-008');
    expect(report.lab, 'Lab 8');
    expect(report.technician, 'Casey Rivera');
    expect(report.submittedDate, 'Oct 17, 2026');
  });

  test('parses reports and problem_reports wrapper keys', () async {
    for (final key in ['reports', 'problem_reports']) {
      final client = MockClient(
        (_) => Future.value(http.Response('{"$key":[]}', 200)),
      );
      final reports = await FirebaseStudentReportsDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadReports();
      client.close();
      expect(reports, isEmpty);
    }
  });

  test('parses a direct or wrapped report detail response', () async {
    for (final wrapped in [false, true]) {
      final reportJson = '{"id":7,"report_no":"RPT-007","status":"resolved"}';
      final client = MockClient((request) async {
        expect(request.url.path, '/api/mobile/problem-reports/RPT-007');
        expect(request.headers['authorization'], 'Bearer student-id-token');
        return http.Response(
          wrapped ? '{"report":$reportJson}' : reportJson,
          200,
        );
      });
      final report = await FirebaseStudentReportsDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadReport('RPT-007');
      client.close();
      expect(report.statusLabel, 'Completed');
    }
  });

  test('supports alternate report field names and resolved dates', () {
    final report = StudentReport.fromJson({
      'reportId': 'external-42',
      'status': 'completed',
      'category': 'network',
      'description': 'Router unavailable',
      'createdAt': '2026-10-16T09:30:00Z',
      'resolvedAt': '2026-10-17T09:30:00Z',
      'computer': {
        'asset_tag': 'LAB-42',
        'lab': {'name': 'West Lab'},
      },
      'technician': {'full_name': 'Sam Technician'},
    });

    expect(report.id, 'external-42');
    expect(report.displayReportNumber, 'external-42');
    expect(report.submittedDate, 'Oct 16, 2026');
    expect(report.completedDate, 'Oct 17, 2026');
    expect(report.lab, 'West Lab');
    expect(report.technician, 'Sam Technician');
  });

  test('normalizes all supported backend statuses', () {
    expect(normalizeReportStatus('pending'), 'pending');
    expect(normalizeReportStatus('assigned'), 'assigned');
    expect(normalizeReportStatus('under_repair'), 'in_progress');
    expect(normalizeReportStatus('in_progress'), 'in_progress');
    expect(normalizeReportStatus('resolved'), 'completed');
    expect(normalizeReportStatus('completed'), 'completed');
    expect(normalizeReportStatus('cancelled'), 'cancelled');
  });

  test('uses safe optional-field fallbacks', () {
    final report = StudentReport.fromJson({'status': 'pending'});

    expect(report.computer, 'Unknown computer');
    expect(report.description, 'No description');
    expect(report.submittedDate, 'Unknown date');
    expect(report.technician, 'Unassigned');
  });

  test('empty list is a successful empty result', () async {
    final client = MockClient((_) async => http.Response('[]', 200));
    addTearDown(client.close);
    final reports = await FirebaseStudentReportsDataSource(
      baseUrl: 'https://api.example.test/api',
      client: client,
      tokenProvider: _TokenProvider(),
    ).loadReports();
    expect(reports, isEmpty);
  });

  test('network errors and API status codes remain retryable errors', () async {
    final networkClient = MockClient(
      (_) => throw const SocketException('network offline'),
    );
    await expectLater(
      FirebaseStudentReportsDataSource(
        baseUrl: 'https://api.example.test/api',
        client: networkClient,
        tokenProvider: _TokenProvider(),
      ).loadReports(),
      throwsA(isA<SocketException>()),
    );
    networkClient.close();

    for (final status in [401, 403, 404, 500]) {
      final client = MockClient(
        (_) async => http.Response('{"message":"error"}', status),
      );
      final detail = status == 404;
      final source = FirebaseStudentReportsDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: _TokenProvider(),
      );
      await expectLater(
        detail ? source.loadReport('RPT-MISSING') : source.loadReports(),
        throwsA(
          isA<ReportsApiException>()
              .having((error) => error.statusCode, 'statusCode', status)
              .having((error) => error.isDetail, 'isDetail', detail),
        ),
      );
      client.close();
    }
  });

  test('invalid JSON and invalid report shapes are rejected', () async {
    for (final body in ['not json', '{"unexpected":true}']) {
      final client = MockClient((_) async => http.Response(body, 200));
      await expectLater(
        FirebaseStudentReportsDataSource(
          baseUrl: 'https://api.example.test/api',
          client: client,
          tokenProvider: _TokenProvider(),
        ).loadReports(),
        throwsA(isA<FormatException>()),
      );
      client.close();
    }

    final client = MockClient(
      (_) async => http.Response('{"report":null}', 200),
    );
    await expectLater(
      FirebaseStudentReportsDataSource(
        baseUrl: 'https://api.example.test/api',
        client: client,
        tokenProvider: _TokenProvider(),
      ).loadReport('RPT-1'),
      throwsA(isA<FormatException>()),
    );
    client.close();
  });
}
