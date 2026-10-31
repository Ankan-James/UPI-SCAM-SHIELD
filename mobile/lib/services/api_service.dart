import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session_service.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
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