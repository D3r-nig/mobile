import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'dashboard_service.dart';
import 'mobile_api_config.dart';

abstract interface class StudentReportSubmissionDataSource {
  Future<Map<String, dynamic>> submitReport({
    required int computerId,
    required String category,
    required String description,
    required String priority,
    XFile? image,
  });
}

class ReportSubmissionException implements Exception {
  const ReportSubmissionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FirebaseStudentReportSubmissionDataSource
    implements StudentReportSubmissionDataSource {
  FirebaseStudentReportSubmissionDataSource({
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
  Future<Map<String, dynamic>> submitReport({
    required int computerId,
    required String category,
    required String description,
    required String priority,
    XFile? image,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const ReportSubmissionException(
        'Mobile API URL is not configured.',
      );
    }
    final token = await _tokenProvider.getIdToken();
    if (token == null || token.isEmpty) {
      throw const ReportSubmissionException(
        'Your sign-in has expired. Please sign in again.',
      );
    }
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('$_baseUrl/mobile/problem-reports'),
            )
            ..headers.addAll({
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            })
            ..fields.addAll({
              'computer_id': computerId.toString(),
              'category': category,
              'description': description.trim(),
              'priority': priority,
            });
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      final payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = payload is Map && payload['message'] is String
            ? payload['message'] as String
            : 'Unable to submit your report.';
        throw ReportSubmissionException(message);
      }
      if (payload is! Map) {
        throw const FormatException('Invalid report response.');
      }
      return Map<String, dynamic>.from(payload);
    } on ReportSubmissionException {
      rethrow;
    } on SocketException {
      throw const ReportSubmissionException('Could not connect to the server.');
    } on TimeoutException {
      throw const ReportSubmissionException(
        'The request timed out. Please retry.',
      );
    } on FormatException {
      throw const ReportSubmissionException(
        'The server returned invalid report data.',
      );
    }
  }
}
