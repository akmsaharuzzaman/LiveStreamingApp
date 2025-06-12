import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginInfo extends ChangeNotifier {
  /// The username of login.
  String? get token => _token;
  String? _token;

  /// Whether a user has logged in.
  bool get loggedIn => _token?.isNotEmpty == true;

  /// Logs in a user.
  Future<void> login(String token) async {
/*    const storage = FlutterSecureStorage();

    await storage.write(key: "token", value: token);
    Logger().d("token is $token");
    _token = token;*/
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    Logger().d("token is $token");

    _token = token;
    notifyListeners();
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');
    _token = token ?? "";
    Logger().d("token from storage is $_token");

    notifyListeners();
  }

  /// Logs out the current user.
  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('uid');
    _token = null;
    notifyListeners();
  }

  // void logout() async {
  //   const storage = FlutterSecureStorage();
  //   await storage.delete(key: "email");
  //   await storage.delete(key: "password");
  //   await storage.delete(key: "isRemembered");
  //   await storage.delete(key: "token");
  //   _token = null;
  //   notifyListeners();
  // }
}
