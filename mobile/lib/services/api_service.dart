import 'dart:async';
import 'dart:convert';
<<<<<<< HEAD

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session_service.dart';
=======
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/scan_result.dart';
import '../utils/constants.dart';
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
<<<<<<< HEAD
  ApiService({
    http.Client? client,
    FlutterSecureStorage? storage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(),
        _baseUrl = (baseUrl ?? ApiConfig.defaultBaseUrl)
            .replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String _baseUrl;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, Object?> body = const {},
  }) =>
      _send('POST', path, body: body);

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'numpe.auth.token', value: token);
    } on PlatformException {
      throw const ApiException('Could not securely save the sign-in session.');
    }
  }

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: 'numpe.auth.token');
    } on PlatformException {
      throw const ApiException('Secure session storage is unavailable.');
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'numpe.auth.token');
    } on PlatformException {
      throw const ApiException('Could not securely clear the sign-in session.');
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$path');
      final token = await readToken();
      final headers = <String, String>{'Accept': 'application/json'};
      if (body != null) headers['Content-Type'] = 'application/json';
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(
            const Duration(seconds: 12),
          );
      final response = await http.Response.fromStream(streamed);
      final decoded =
          response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('The server returned an invalid response.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401 && path != 'auth/login') {
          await clearToken();
          SessionService.instance.signOut();
          throw const ApiException(
            'Your session has expired. Sign in again.',
            statusCode: 401,
          );
        }
        final detail = decoded['detail'];
        throw ApiException(
          detail is String ? detail : 'Request failed. Please try again.',
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException(
        'The request timed out. Check your connection and retry.',
      );
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    } on http.ClientException {
      throw const ApiException(
        'Could not reach NUMPE. Check your connection and retry.',
      );
    }
  }
}
=======
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = (baseUrl ?? apiBaseUrl).replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';
    try {
      final request = http.Request(method, _uri(path))..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(requestTimeout);
      final response =
          await http.Response.fromStream(streamed).timeout(requestTimeout);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded is Map<String, dynamic>
            ? decoded['detail']?.toString()
            : null;
        throw ApiException(
          detail ?? 'Request failed (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('The server returned an unexpected response.');
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('The server returned invalid JSON.');
    } on http.ClientException catch (error) {
      throw ApiException('Could not reach the server: ${error.message}');
    } on SocketException catch (error) {
      throw ApiException('Could not reach the server: ${error.message}');
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on HttpException catch (error) {
      throw ApiException('The request failed: ${error.message}');
    }
  }

  Future<ScanResult> analyze(String type, String input) async {
    final response = await _request(
      'POST',
      '/analyze',
      body: {'type': type, 'input': input},
    );
    return ScanResult.fromJson(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) =>
      _request('POST', '/auth/login', body: {
        'email': email,
        'password': password,
      });

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) =>
      _request('POST', '/auth/register', body: {
        'username': username,
        'email': email,
        'password': password,
      });

  Future<Map<String, dynamic>> me(String token) =>
      _request('GET', '/auth/me', token: token);

  Future<void> logout(String token) async {
    await _request('POST', '/auth/logout', token: token);
  }

  Future<List<Map<String, dynamic>>> history() async {
    final response = await _request('GET', '/history');
    final items = response['items'];
    if (items is! List) {
      throw const ApiException('The server returned invalid scan history.');
    }
    return items.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> checkHealth() async {
    final baseUri = Uri.parse(baseUrl);
    final healthUri = baseUri.replace(
      path: baseUri.path.replaceFirst(RegExp(r'/api/?$'), '/health'),
    );
    final response = await _client.get(healthUri,
        headers: const {'Accept': 'application/json'}).timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Health check failed (${response.statusCode}).');
    }
  }

  Future<String> report(String description, {String type = 'other'}) async {
    final response = await _request(
      'POST',
      '/reports',
      body: {'report_type': type, 'description': description},
    );
    return response['status'] as String? ?? 'Submitted';
  }

  Future<String> voiceSummary(ScanResult result) async {
    final response = await _request(
      'POST',
      '/voice/summary',
      body: {
        'risk_level': result.level.toLowerCase(),
        'recommendation': result.recommendation,
      },
    );
    final summary = response['summary'];
    if (summary is! String || summary.isEmpty) {
      throw const ApiException('The server returned an invalid voice summary.');
    }
    return summary;
  }

  void close() => _client.close();
}
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
