import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'mobile_api_config.dart';

class QrComputer {
  const QrComputer({
    required this.id,
    required this.assetTag,
    this.lab,
    this.status,
    this.brand,
    this.processor,
    this.ram,
    this.storage,
    this.operatingSystem,
  });

  final int id;
  final String assetTag;
  final String? lab;
  final String? status;
  final String? brand;
  final String? processor;
  final String? ram;
  final String? storage;
  final String? operatingSystem;
}

class QrComputerService {
  QrComputerService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<QrComputer> resolve(String token) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) throw Exception('Please sign in again before scanning.');

    final response = await _client.get(
      Uri.parse('$mobileApiBaseUrl/mobile/computers/qr/${Uri.encodeComponent(token)}'),
      headers: {'Authorization': 'Bearer $idToken', 'Accept': 'application/json'},
    );
    final body = jsonDecode(response.body);
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw Exception(body is Map && body['message'] != null
          ? body['message'].toString()
          : 'Unable to identify this computer.');
    }

    return QrComputer(
      id: (body['id'] as num).toInt(),
      assetTag: body['asset_tag']?.toString() ?? 'Unknown computer',
      lab: body['lab']?.toString(),
      status: body['status']?.toString(),
      brand: body['brand']?.toString(),
      processor: body['processor']?.toString(),
      ram: body['ram']?.toString(),
      storage: body['storage']?.toString(),
      operatingSystem: body['operating_system']?.toString(),
    );
  }

  void dispose() => _client.close();
}
