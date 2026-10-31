import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

class SessionService extends ChangeNotifier {
  SessionService._();

  static final SessionService instance = SessionService._();

  AppMode mode = AppMode.demo;
  bool isAuthenticated = false;
  bool emergencyLockEnabled = false;

  void signIn() {
    isAuthenticated = true;
    notifyListeners();
  }

  void signOut() {
    isAuthenticated = false;
    notifyListeners();
  }

  void setMode(AppMode value) {
    mode = value;
    notifyListeners();
  }

  void setEmergencyLock(bool value) {
    emergencyLockEnabled = value;
    notifyListeners();
  }
}
