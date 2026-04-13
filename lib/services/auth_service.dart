import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static const String _adminIdKey = 'admin_id';
  static const String _adminPassKey = 'admin_pass';
  static const String _isSetupKey = 'is_setup';
  static const String _isLoggedInKey = 'is_logged_in';

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<bool> isSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSetupKey) ?? false;
  }

  static Future<void> setupAdmin({
    required String adminId,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminIdKey, adminId);
    await prefs.setString(_adminPassKey, _hashPassword(password));
    await prefs.setBool(_isSetupKey, true);
  }

  static Future<bool> login(String adminId, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_adminIdKey) ?? '';
    final storedPass = prefs.getString(_adminPassKey) ?? '';
    if (adminId == storedId && _hashPassword(password) == storedPass) {
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    }
    return false;
  }



  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
}
