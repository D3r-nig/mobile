import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'mobile_api_config.dart';
import 'memory_cache.dart';

@immutable
class DashboardData {
  const DashboardData({
    required this.studentName,
    required this.totalReports,
    required this.inProgressReports,
    required this.resolvedReports,
  });

  final String studentName;
  final int totalReports;
  final int inProgressReports;
  final int resolvedReports;
}

abstract interface class DashboardDataSource {
  Future<DashboardData> loadDashboard({bool forceRefresh = false});
  String? get cachedStudentName;
}

abstract interface class FirebaseIdTokenProvider {
  Future<String?> getIdToken({bool forceRefresh = false});
  String? get displayName;
}

class CurrentFirebaseIdTokenProvider implements FirebaseIdTokenProvider {
  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((candidate) => candidate != null)
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        return null;
      }
    }

    return user?.getIdToken(forceRefresh);
  }

  @override
  String? get displayName {
    try {
      return FirebaseAuth.instance.currentUser?.displayName;
    } on FirebaseException {
      return null;
    }
  }
}

class DashboardApiException implements Exception {
  const DashboardApiException(this.statusCode);

  final int statusCode;
}

class DashboardConfigurationException implements Exception {
  const DashboardConfigurationException();
}

class FirebaseDashboardDataSource implements DashboardDataSource {
  static DashboardData? _cachedDashboard;

  FirebaseDashboardDataSource({
    http.Client? client,
    FirebaseIdTokenProvider? tokenProvider,
    String? baseUrl,
  }) : _ownsClient = client == null,
       _client = client ?? http.Client(),
       _tokenProvider = tokenProvider ?? CurrentFirebaseIdTokenProvider(),
       _cacheEnabled = baseUrl == null,
       _baseUrl = (baseUrl ?? mobileApiBaseUrl).trim().replaceFirst(
         RegExp(r'/+$'),
         '',
       );

  final bool _ownsClient;
  final http.Client _client;
  final FirebaseIdTokenProvider _tokenProvider;
  final bool _cacheEnabled;
  final String _baseUrl;
  Future<String?>? _refreshingToken;

  @override
  String? get cachedStudentName {
    final name = _tokenProvider.displayName?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }

  static DashboardData? get cachedDashboard => _cachedDashboard;

  static void clearCache() {
    _cachedDashboard = null;
    MemoryCache.remove('dashboard');
  }

  @override
  Future<DashboardData> loadDashboard({bool forceRefresh = false}) async {
    if (_baseUrl.isEmpty) throw const DashboardConfigurationException();
    if (_cacheEnabled && !forceRefresh) {
      final cached = MemoryCache.read<DashboardData>(
        'dashboard',
        const Duration(minutes: 2),
      );
      if (cached != null) {
        _cachedDashboard = cached;
        return cached;
      }
    }

    var token = await _tokenProvider.getIdToken();
    if (token == null || token.isEmpty) {
      token = await _refreshToken();
    }
    if (token == null || token.isEmpty) {
      throw const DashboardApiException(401);
    }

    final profileAndReports = await Future.wait([
      _get('/mobile/me', token),
      _get('/mobile/problem-reports', token),
    ]);

    final profileName = _studentName(profileAndReports[0]);
    final authName = _tokenProvider.displayName?.trim();
    final reportCounts = _reportCounts(profileAndReports[1]);
    final data = DashboardData(
      studentName:
          profileName ??
          (authName != null && authName.isNotEmpty ? authName : 'Student'),
      totalReports: reportCounts.total,
      inProgressReports: reportCounts.inProgress,
      resolvedReports: reportCounts.resolved,
    );
    _cachedDashboard = data;
    if (_cacheEnabled) MemoryCache.write('dashboard', data);
    return data;
  }

  Future<Object?> _get(String path, String token) async {
    var response = await _client
        .get(
          Uri.parse('$_baseUrl$path'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final refreshedToken = await _refreshToken();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        response = await _client
            .get(
              Uri.parse('$_baseUrl$path'),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $refreshedToken',
              },
            )
            .timeout(const Duration(seconds: 15));
      }
    }

    if (response.statusCode == 401) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final refreshedToken = await _refreshToken();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        response = await _client
            .get(
              Uri.parse('$_baseUrl$path'),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $refreshedToken',
              },
            )
            .timeout(const Duration(seconds: 15));
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DashboardApiException(response.statusCode);
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const FormatException('The server returned invalid JSON.');
    }
  }

  Future<String?> _refreshToken() {
    final refreshingToken = _refreshingToken;
    if (refreshingToken != null) return refreshingToken;

    late final Future<String?> refresh;
    refresh = _tokenProvider.getIdToken(forceRefresh: true).whenComplete(() {
      if (identical(_refreshingToken, refresh)) _refreshingToken = null;
    });
    _refreshingToken = refresh;
    return refresh;
  }

  String? _studentName(Object? payload) {
    if (payload is! Map) return null;
    final user = payload['user'];
    final student = payload['student'];
    final profiles = [user, student, payload];
    for (final profile in profiles) {
      if (profile is! Map) continue;
      for (final key in ['full_name', 'fullName', 'student_name', 'name']) {
        final name = profile[key];
        if (name is String && name.trim().isNotEmpty) return name.trim();
      }
    }
    return null;
  }

  ({int total, int inProgress, int resolved}) _reportCounts(Object? payload) {
    final reports = _reportList(payload);
    var inProgress = 0;
    var resolved = 0;
    for (final report in reports) {
      if (report is! Map) continue;
      final value = report['status'];
      if (value is! String) continue;
      switch (value.trim().toLowerCase()) {
        case 'pending':
        case 'assigned':
        case 'in_progress':
          inProgress++;
        case 'resolved':
        case 'completed':
          resolved++;
      }
    }
    return (total: reports.length, inProgress: inProgress, resolved: resolved);
  }

  List<Object?> _reportList(Object? payload) {
    if (payload == null) return const [];
    if (payload is List) return payload.cast<Object?>();
    if (payload is Map) {
      for (final key in ['data', 'reports', 'problem_reports']) {
        final value = payload[key];
        if (value is List) return value.cast<Object?>();
        if (value is Map) {
          for (final nestedKey in ['data', 'reports', 'problem_reports']) {
            final nested = value[nestedKey];
            if (nested is List) return nested.cast<Object?>();
          }
        }
      }
    }
    throw const FormatException('The server returned an invalid reports list.');
  }
}

String dashboardLoadErrorMessage(Object error) {
  if (error is DashboardApiException) {
    return switch (error.statusCode) {
      401 => 'Your sign-in has expired. Please sign in again.',
      403 => 'This student account is inactive or is not authorized.',
      404 => 'The Home data could not be found. Please try again later.',
      _ => 'Could not load your Home data. Please try again.',
    };
  }
  if (error is DashboardConfigurationException) {
    return 'Mobile API URL is not configured. Rebuild the app with the Laravel API URL.';
  }
  if (error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return 'Could not connect to the server. Check your connection and retry.';
  }
  if (error is FormatException) {
    return 'The server returned incomplete or invalid Home data. Please retry.';
  }
  return 'Could not load your Home data. Please try again.';
}
