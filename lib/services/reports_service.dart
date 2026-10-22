import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'dashboard_service.dart';
import 'mobile_api_config.dart';

@immutable
class StudentReport {
  const StudentReport({
    required this.id,
    required this.reportNumber,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    required this.computer,
    required this.lab,
    required this.technician,
    required this.reportedAt,
    required this.resolvedAt,
  });

  factory StudentReport.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('The server returned an invalid report.');
    }

    final computerValue = value['computer'];
    final computer = computerValue is Map ? computerValue : const {};
    final labValue = computer['lab'];
    final lab = labValue is Map ? labValue : const {};
    final technicianValue = value['technician'];
    final technician = technicianValue is Map ? technicianValue : const {};
    final id = _stringValue(value['id']);
    final reportId = _stringValue(value['reportId']);
    final reportNo = _stringValue(value['report_no']);

    return StudentReport(
      id: id ?? reportId ?? reportNo,
      reportNumber: reportNo ?? reportId ?? (id == null ? null : '#$id'),
      category: _displayValue(value['category']),
      description: _displayValue(value['description']) ?? 'No description',
      priority: _displayValue(value['priority']),
      status: normalizeReportStatus(value['status']),
      computer: _displayValue(computer['asset_tag']) ?? 'Unknown computer',
      lab: _displayValue(lab['name']),
      technician: _displayValue(technician['full_name']) ?? 'Unassigned',
      reportedAt:
          _stringValue(value['reported_at']) ??
          _stringValue(value['createdAt']),
      resolvedAt:
          _stringValue(value['resolved_at']) ??
          _stringValue(value['resolvedAt']),
    );
  }

  final String? id;
  final String? reportNumber;
  final String? category;
  final String description;
  final String? priority;
  final String status;
  final String computer;
  final String? lab;
  final String technician;
  final String? reportedAt;
  final String? resolvedAt;

  String get displayReportNumber => reportNumber ?? 'Unknown report';
  String get submittedDate => formatReportDate(reportedAt);
  String get completedDate => formatReportDate(resolvedAt);

  bool get isPending => status == 'pending';
  bool get isAwaitingTeacherReview => status == 'pending_teacher_review';
  bool get isInProgress => status == 'assigned' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  String get statusLabel => switch (status) {
    'pending_teacher_review' => 'Awaiting Teacher Review',
    'pending' => 'Pending',
    'assigned' => 'Assigned',
    'in_progress' => 'In Progress',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    _ => 'Unknown status',
  };

  bool get assignmentComplete =>
      const {'assigned', 'in_progress', 'completed'}.contains(status);

  bool get inProgressComplete =>
      const {'in_progress', 'completed'}.contains(status);

  bool get completionComplete => status == 'completed';
}

String normalizeReportStatus(Object? value) {
  if (value is! String) return 'unknown';
  return switch (value.trim().toLowerCase()) {
    'pending' => 'pending',
    'pending_teacher_review' => 'pending_teacher_review',
    'assigned' => 'assigned',
    'under_repair' || 'in_progress' => 'in_progress',
    'resolved' || 'completed' => 'completed',
    'cancelled' => 'cancelled',
    _ => 'unknown',
  };
}

String formatReportDate(String? value) {
  if (value == null || value.trim().isEmpty) return 'Unknown date';
  final date = DateTime.tryParse(value);
  if (date == null) return 'Unknown date';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

String? _displayValue(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

String? _stringValue(Object? value) {
  if (value is num) return value.toString();
  final result = _displayValue(value);
  return result;
}

abstract interface class StudentReportsDataSource {
  Future<List<StudentReport>> loadReports();
  Future<StudentReport> loadReport(String reportId);
}

class ReportsApiException implements Exception {
  const ReportsApiException(this.statusCode, {this.isDetail = false});

  final int statusCode;
  final bool isDetail;
}

class ReportsConfigurationException implements Exception {
  const ReportsConfigurationException();
}

class FirebaseStudentReportsDataSource implements StudentReportsDataSource {
  FirebaseStudentReportsDataSource({
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

  @override
  Future<List<StudentReport>> loadReports() async {
    final payload = await _request('/mobile/problem-reports', isDetail: false);
    return _reportList(payload).map(StudentReport.fromJson).toList();
  }

  @override
  Future<StudentReport> loadReport(String reportId) async {
    if (reportId.trim().isEmpty) {
      throw const FormatException('The report identifier is missing.');
    }
    final payload = await _request(
      '/mobile/problem-reports/${Uri.encodeComponent(reportId)}',
      isDetail: true,
    );
    final report = payload is Map && payload.containsKey('report')
        ? payload['report']
        : payload;
    return StudentReport.fromJson(report);
  }

  Future<Object?> _request(String path, {required bool isDetail}) async {
    if (_baseUrl.isEmpty) throw const ReportsConfigurationException();

    final token = await _tokenProvider.getIdToken();
    if (token == null || token.isEmpty) {
      throw ReportsApiException(401, isDetail: isDetail);
    }

    final response = await _client
        .get(
          Uri.parse('$_baseUrl$path'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReportsApiException(response.statusCode, isDetail: isDetail);
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned invalid JSON.');
    }
  }

  List<Object?> _reportList(Object? payload) {
    if (payload is List) return payload.cast<Object?>();
    if (payload is Map) {
      for (final key in ['data', 'reports', 'problem_reports']) {
        final reports = payload[key];
        if (reports is List) return reports.cast<Object?>();
      }
    }
    throw const FormatException(
      'The server returned an invalid reports response.',
    );
  }
}

String reportsErrorMessage(Object error, {bool isDetail = false}) {
  if (error is ReportsApiException) {
    return switch (error.statusCode) {
      401 => 'Your sign-in has expired. Please sign in again.',
      403 => 'This student account is inactive or is not authorized.',
      404 =>
        error.isDetail
            ? 'This report could not be found.'
            : 'Report data could not be found. Please try again later.',
      _ =>
        'Could not load ${error.isDetail ? 'this report' : 'your reports'}. '
            'Please try again.',
    };
  }
  if (error is ReportsConfigurationException) {
    return 'Mobile API URL is not configured. Rebuild with the Laravel API URL.';
  }
  if (error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return 'Could not connect to the server. Check your connection and retry.';
  }
  if (error is FormatException) {
    return 'The server returned invalid report data. Please retry.';
  }
  return 'Could not load ${isDetail ? 'this report' : 'your reports'}. '
      'Please try again.';
}
