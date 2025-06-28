import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginInfo extends ChangeNotifier {
  /// The username of login.
  String? get token => _token;
  String? _token;

  /// Whether a user has logged in.
  bool get loggedIn => _token?.isNotEmpty == true;

  /// Logs in a user.
  Future<void> login(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    debugPrint("token saved to storage: $token");
    _token = token;
    notifyListeners();
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    _token = token ?? "";
    debugPrint("token loaded from storage: $_token");
    notifyListeners();
  }

  /// Logs out the current user.
  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('uid');
    _token = null;
    notifyListeners();
  }
}
