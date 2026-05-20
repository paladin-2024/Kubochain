import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // In-memory cache for sensitive values — populated at init, cleared on logout.
  // Allows synchronous reads after startup without blocking the UI thread.
  static String? _cachedToken;
  static String? _cachedRefreshToken;
  static String? _cachedUser;
  static String? _cachedRole;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _cachedToken        = await _secure.read(key: _accessTokenKey);
    _cachedRefreshToken = await _secure.read(key: _refreshTokenKey);
    _cachedUser         = await _secure.read(key: _userKey);
    _cachedRole         = await _secure.read(key: _roleKey);
  }

  // ── Non-sensitive (SharedPreferences) ─────────────────────────────────────
  static const _avatarColorIndexKey = 'avatar_color_index';
  static const _onboardedKey        = 'onboarded';

  static int getAvatarColorIndex() => _prefs.getInt(_avatarColorIndexKey) ?? 0;
  static Future<void> setAvatarColorIndex(int index) =>
      _prefs.setInt(_avatarColorIndexKey, index);

  static Future<void> setOnboarded() => _prefs.setBool(_onboardedKey, true);
  static bool isOnboarded() => _prefs.getBool(_onboardedKey) ?? false;

  // ── Sensitive (Keychain / Keystore via flutter_secure_storage) ─────────────
  static const _accessTokenKey  = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey         = 'user_data';
  static const _roleKey         = 'user_role';

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secure.write(key: _accessTokenKey, value: token);
  }

  static String? getToken() => _cachedToken;

  static Future<void> saveRefreshToken(String token) async {
    _cachedRefreshToken = token;
    await _secure.write(key: _refreshTokenKey, value: token);
  }

  static String? getRefreshToken() => _cachedRefreshToken;

  static Future<void> saveUser(String userJson) async {
    _cachedUser = userJson;
    await _secure.write(key: _userKey, value: userJson);
  }

  static String? getUser() => _cachedUser;

  static Future<void> saveRole(String role) async {
    _cachedRole = role;
    await _secure.write(key: _roleKey, value: role);
  }

  static String? getRole() => _cachedRole;

  static Future<void> clearAll() async {
    _cachedToken        = null;
    _cachedRefreshToken = null;
    _cachedUser         = null;
    _cachedRole         = null;
    await _secure.deleteAll();
    await _prefs.clear();
  }

  static bool isLoggedIn() => _cachedToken != null;
}
