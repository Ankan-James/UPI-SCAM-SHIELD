import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  AuthService({ApiService? api}) : _api = api ?? ApiService();

  static const _tokenKey = 'session_token';
  final ApiService _api;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<User> login(String email, String password) async {
    final response = await _api.login(email, password);
    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('The server did not return a session token.');
    }
    final user = User.fromJson(await _api.me(token));
    await _storage.write(key: _tokenKey, value: token);
    return user;
  }

  Future<User> register(String username, String email, String password) async {
    await _api.register(username, email, password);
    return login(email, password);
  }

  Future<User?> currentUser() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;
    try {
      return User.fromJson(await _api.me(token));
    } on ApiException catch (error) {
      if (error.statusCode == 401) await _storage.delete(key: _tokenKey);
      rethrow;
    }
  }

  Future<void> logout() async {
    final token = await _storage.read(key: _tokenKey);
    try {
      if (token != null) await _api.logout(token);
    } finally {
      await _storage.delete(key: _tokenKey);
    }
  }

  void close() => _api.close();
}
