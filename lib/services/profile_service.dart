import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'dashboard_service.dart';
import 'mobile_api_config.dart';

@immutable
class StudentProfile {
  const StudentProfile({
    required this.fullName,
    required this.email,
    required this.studentNumber,
    required this.section,
    required this.adviser,
    required this.accountStatus,
  });

  factory StudentProfile.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('The server returned an invalid profile.');
    }
    final profile = value['user'] is Map ? value['user'] as Map : value;
    final adviserValue = profile['adviser'];
    final adviser = adviserValue is Map
        ? _profileString(adviserValue['full_name']) ??
              _profileString(adviserValue['name'])
        : _profileString(adviserValue);

    return StudentProfile(
      fullName: _profileString(profile['full_name']),
      email: _profileString(profile['email']),
      studentNumber: _profileString(
        profile['student_no'] ?? profile['student_number'],
      ),
      section: _profileString(profile['section']),
      adviser: adviser,
      accountStatus: _profileString(profile['status']),
    );
  }

  final String? fullName;
  final String? email;
  final String? studentNumber;
  final String? section;
  final String? adviser;
  final String? accountStatus;

  bool get isEmpty =>
      fullName == null &&
      email == null &&
      studentNumber == null &&
      section == null &&
      adviser == null &&
      accountStatus == null;

  bool get isIncomplete =>
      fullName == null ||
      email == null ||
      studentNumber == null ||
      section == null;
}

String? _profileString(Object? value) {
  if (value is! String) return null;
  final result = value.trim();
  return result.isEmpty ? null : result;
}

abstract interface class StudentProfileDataSource {
  Future<StudentProfile> loadProfile();
  void dispose();
}

class ProfileApiException implements Exception {
  const ProfileApiException(this.statusCode);

  final int statusCode;
}

class ProfileConfigurationException implements Exception {
  const ProfileConfigurationException();
}

class FirebaseStudentProfileDataSource implements StudentProfileDataSource {
  FirebaseStudentProfileDataSource({
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
  Future<String?>? _refreshingToken;

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }

  @override
  Future<StudentProfile> loadProfile() async {
    if (_baseUrl.isEmpty) throw const ProfileConfigurationException();

    var token = await _tokenProvider.getIdToken();
    if (token == null || token.isEmpty) token = await _refreshToken();
    if (token == null || token.isEmpty) throw const ProfileApiException(401);

    var response = await _get(token);
    if (response.statusCode == 401) {
      token = await _refreshToken();
      if (token != null && token.isNotEmpty) response = await _get(token);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(response.statusCode);
    }

    try {
      return StudentProfile.fromJson(jsonDecode(response.body));
    } on FormatException {
      throw const FormatException('The server returned invalid profile data.');
    }
  }

  Future<http.Response> _get(String token) => _client
      .get(
        Uri.parse('$_baseUrl/mobile/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
      .timeout(const Duration(seconds: 15));

  Future<String?> _refreshToken() {
    final refreshing = _refreshingToken;
    if (refreshing != null) return refreshing;

    late final Future<String?> refresh;
    refresh = _tokenProvider.getIdToken(forceRefresh: true).whenComplete(() {
      if (identical(_refreshingToken, refresh)) _refreshingToken = null;
    });
    _refreshingToken = refresh;
    return refresh;
  }
}

class StudentProfileRepository extends ChangeNotifier {
  StudentProfileRepository({
    required this.dataSource,
    required String? Function() userIdProvider,
    Stream<String?>? accountChanges,
    this.refreshInterval = const Duration(minutes: 5),
    DateTime Function()? clock,
  }) : _userIdProvider = userIdProvider,
       _clock = clock ?? DateTime.now,
       _activeUserId = userIdProvider() {
    _accountSubscription = accountChanges?.listen(_synchronizeAccount);
  }

  static final StudentProfileRepository session = _createSessionRepository();

  static StudentProfileRepository _createSessionRepository() {
    FirebaseAuth? auth;
    try {
      auth = FirebaseAuth.instance;
    } on FirebaseException {
      auth = null;
    }
    return StudentProfileRepository(
      dataSource: FirebaseStudentProfileDataSource(),
      userIdProvider: _currentFirebaseUserId,
      accountChanges: auth?.authStateChanges().map((user) => user?.uid),
    );
  }

  final StudentProfileDataSource dataSource;
  final String? Function() _userIdProvider;
  final DateTime Function() _clock;
  final Duration refreshInterval;

  String? _activeUserId;
  StudentProfile? _cachedProfile;
  DateTime? _cachedAt;
  Future<StudentProfile>? _inFlight;
  String? _inFlightUserId;
  StreamSubscription<String?>? _accountSubscription;
  int _generation = 0;

  StudentProfile? get cachedProfile {
    _synchronizeAccount(_userIdProvider());
    return _cachedProfile;
  }

  String? get currentUserId => _userIdProvider();

  Future<StudentProfile> loadProfile({bool forceRefresh = false}) {
    final userId = _userIdProvider();
    _synchronizeAccount(userId);
    if (userId == null) return Future.error(const ProfileApiException(401));

    final cached = _cachedProfile;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        _clock().difference(cachedAt) < refreshInterval) {
      return Future.value(cached);
    }

    final activeRequest = _inFlight;
    if (activeRequest != null && _inFlightUserId == userId) {
      return activeRequest;
    }

    final generation = _generation;
    late final Future<StudentProfile> request;
    request = dataSource
        .loadProfile()
        .then((profile) {
          final currentUserId = _userIdProvider();
          if (currentUserId != userId ||
              _activeUserId != userId ||
              generation != _generation) {
            _synchronizeAccount(currentUserId);
            throw const ProfileApiException(401);
          }
          _cachedProfile = profile;
          _cachedAt = _clock();
          notifyListeners();
          return profile;
        })
        .whenComplete(() {
          if (identical(_inFlight, request)) {
            _inFlight = null;
            _inFlightUserId = null;
          }
        });

    _inFlight = request;
    _inFlightUserId = userId;
    return request;
  }

  void clear() {
    _generation++;
    _activeUserId = _userIdProvider();
    _cachedProfile = null;
    _cachedAt = null;
    _inFlight = null;
    _inFlightUserId = null;
    notifyListeners();
  }

  void _synchronizeAccount(String? userId) {
    if (_activeUserId == userId) return;
    _generation++;
    _activeUserId = userId;
    _cachedProfile = null;
    _cachedAt = null;
    _inFlight = null;
    _inFlightUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _accountSubscription?.cancel();
    dataSource.dispose();
    super.dispose();
  }
}

String? _currentFirebaseUserId() {
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } on FirebaseException {
    return null;
  }
}

String profileLoadErrorMessage(Object error) {
  if (error is ProfileApiException) {
    return switch (error.statusCode) {
      401 => 'Your sign-in has expired. Please sign in again.',
      403 => 'This student account is inactive or is not authorized.',
      404 => 'Your student profile is not available.',
      _ => 'Could not load your profile. Please try again.',
    };
  }
  if (error is ProfileConfigurationException) {
    return 'Mobile API URL is not configured. Rebuild with the Laravel API URL.';
  }
  if (error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return 'Could not connect to the server. Check your connection and retry.';
  }
  if (error is FormatException) {
    return 'The server returned an invalid profile response. Please retry.';
  }
  return 'Could not load your profile. Please try again.';
}
