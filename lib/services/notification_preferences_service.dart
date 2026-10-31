import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'mobile_api_config.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.reportStatusUpdates,
    required this.maintenanceAlerts,
    required this.labClosureNotices,
    required this.dailySummaryReports,
    required this.directCommunications,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        reportStatusUpdates: json['report_status_updates'] == true,
        maintenanceAlerts: json['maintenance_alerts'] == true,
        labClosureNotices: json['lab_closure_notices'] == true,
        dailySummaryReports: json['daily_summary_reports'] == true,
        directCommunications: json['direct_communications'] == true,
      );

  final bool reportStatusUpdates;
  final bool maintenanceAlerts;
  final bool labClosureNotices;
  final bool dailySummaryReports;
  final bool directCommunications;

  Map<String, dynamic> toJson() => {
    'report_status_updates': reportStatusUpdates,
    'maintenance_alerts': maintenanceAlerts,
    'lab_closure_notices': labClosureNotices,
    'daily_summary_reports': dailySummaryReports,
    'direct_communications': directCommunications,
  };
}

class NotificationPreferencesService {
  NotificationPreferencesService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<NotificationPreferences> load() async {
    final response = await _request('GET');
    return NotificationPreferences.fromJson(jsonDecode(response.body));
  }

  Future<NotificationPreferences> save(NotificationPreferences preferences) async {
    final response = await _request('PUT', body: preferences.toJson());
    return NotificationPreferences.fromJson(jsonDecode(response.body));
  }

  Future<http.Response> _request(String method, {Map<String, dynamic>? body}) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null || token.isEmpty) throw const FormatException('Not signed in.');
    final uri = Uri.parse('$mobileApiBaseUrl/mobile/notification-preferences');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final response = method == 'PUT'
        ? await _client.put(uri, headers: headers, body: jsonEncode(body))
        : await _client.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException('Notification preferences request failed.');
    }
    return response;
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
