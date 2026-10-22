import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'mobile_api_config.dart';

class MaintenanceRecordEntry {
  const MaintenanceRecordEntry({
    required this.title,
    required this.maintenanceType,
    required this.status,
    required this.scheduledDate,
    this.technician,
  });

  factory MaintenanceRecordEntry.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid maintenance record.');
    final technician = value['technician'];
    return MaintenanceRecordEntry(
      title: value['title']?.toString() ?? 'Maintenance',
      maintenanceType: value['maintenance_type']?.toString() ?? 'maintenance',
      status: value['status']?.toString() ?? 'scheduled',
      scheduledDate: value['scheduled_date']?.toString() ?? '',
      technician: technician is Map ? technician['full_name']?.toString() : null,
    );
  }

  final String title, maintenanceType, status, scheduledDate;
  final String? technician;
}

class MaintenanceHistoryService {
  MaintenanceHistoryService({http.Client? client})
      : _ownsClient = client == null,
        _client = client ?? http.Client();

  final bool _ownsClient;
  final http.Client _client;

  Future<List<MaintenanceRecordEntry>> load(int computerId) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) throw const FormatException('Please sign in again.');
    final response = await _client.get(
      Uri.parse('$mobileApiBaseUrl/mobile/computers/$computerId/maintenance-history'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load maintenance history.');
    }
    final payload = jsonDecode(response.body);
    if (payload is! List) throw const FormatException('Invalid maintenance response.');
    return payload.map(MaintenanceRecordEntry.fromJson).toList();
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
