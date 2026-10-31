import '../config/api_config.dart';
import 'api_service.dart';
import 'session_service.dart';

class AuthService {
  AuthService({ApiService? api}) : _api = api ?? ApiService();

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