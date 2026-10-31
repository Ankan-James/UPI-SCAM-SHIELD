<<<<<<< HEAD
import '../config/api_config.dart';
import 'api_service.dart';
import 'session_service.dart';
=======
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_service.dart';
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

class AuthService {
  AuthService({ApiService? api}) : _api = api ?? ApiService();

<<<<<<< HEAD
  final ApiService _api;

  Future<void> login({
    required String email,
    required String password,
    required AppMode mode,
  }) async {
    if (mode == AppMode.demo) {
      SessionService.instance.signIn();
      return;
    }
    final response = await _api.post('auth/login', body: {
      'email': email.trim(),
      'password': password,
    });
    final token = response['token'];
    if (response['success'] != true || token is! String || token.isEmpty) {
      throw const ApiException('The server returned an invalid login response.');
    }
    await _api.saveToken(token);
    SessionService.instance.signIn();
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required AppMode mode,
  }) async {
    if (mode == AppMode.demo) {
      SessionService.instance.signIn();
      return;
    }
    final response = await _api.post('auth/register', body: {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
    });
    if (response['success'] != true) {
      throw const ApiException('The server could not create the account.');
    }
    await login(email: email, password: password, mode: mode);
  }

  Future<void> logout({required AppMode mode}) async {
    if (mode == AppMode.live) {
      await _api.post('auth/logout');
      await _api.clearToken();
    }
    SessionService.instance.signOut();
  }
}
=======
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
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
