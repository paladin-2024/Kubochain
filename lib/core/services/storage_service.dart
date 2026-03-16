import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';
  static const _roleKey = 'user_role';
  static const _onboardedKey = 'onboarded';

  static Future<void> saveToken(String token) =>
      _prefs.setString(_tokenKey, token);

  static String? getToken() => _prefs.getString(_tokenKey);

  static Future<void> saveUser(String userJson) =>
      _prefs.setString(_userKey, userJson);

  static String? getUser() => _prefs.getString(_userKey);

  static Future<void> saveRole(String role) =>
      _prefs.setString(_roleKey, role);

  static String? getRole() => _prefs.getString(_roleKey);

  static Future<void> setOnboarded() => _prefs.setBool(_onboardedKey, true);

  static bool isOnboarded() => _prefs.getBool(_onboardedKey) ?? false;

  static Future<void> clearAll() => _prefs.clear();

  static bool isLoggedIn() => getToken() != null;
}
