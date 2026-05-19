import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/socket_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isPassenger => _user?.role == 'passenger';
  bool get isRider => _user?.role == 'rider';
  bool get isAdmin => _user?.role == 'admin';

  Future<void> checkAuth() async {
    if (!StorageService.isLoggedIn()) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    final savedUser = StorageService.getUser();
    if (savedUser != null) {
      _user = UserModel.fromJson(jsonDecode(savedUser));
      _status = AuthStatus.authenticated;
      notifyListeners();
      SocketService.connect();
    }
    // Refresh user from server (FastAPI /me returns UserOut directly)
    try {
      final res = await ApiService.getMe();
      _user = UserModel.fromJson(res.data as Map<String, dynamic>);
      await StorageService.saveUser(jsonEncode(_user!.toJson()));
      _status = AuthStatus.authenticated;
    } catch (_) {
      // Keep the locally cached user if network call fails
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      final data = res.data as Map<String, dynamic>;
      await _saveSession(data);
      _status = AuthStatus.authenticated;
      SocketService.connect();
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required String otpCode,
    Map<String, String>? vehicle,
    List<String>? documentPaths,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      // FastAPI RegisterIn uses snake_case field names
      final body = <String, dynamic>{
        'first_name': firstName,
        'last_name':  lastName,
        'email':      email,
        'phone':      phone,
        'password':   password,
        'role':       role,
        'otp_code':   otpCode,
      };
      if (vehicle != null) {
        body['vehicle'] = {
          'make':         vehicle['make'] ?? 'Unknown',
          'model':        vehicle['model'] ?? 'Unknown',
          'color':        vehicle['color'] ?? 'Black',
          'plate_number': vehicle['plateNumber'] ?? vehicle['plate_number'] ?? '',
          'type':         vehicle['type'] ?? 'motorcycle',
        };
      }
      final res = await ApiService.register(body);
      final data = res.data as Map<String, dynamic>;
      await _saveSession(data);
      _status = AuthStatus.authenticated;
      SocketService.connect();
      notifyListeners();
      if (role == 'rider' && documentPaths != null && documentPaths.isNotEmpty) {
        ApiService.uploadDriverDocuments(documentPaths).catchError((_) {});
      }
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    SocketService.disconnect();
    await StorageService.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfileImage(String filePath) async {
    try {
      final res = await ApiService.uploadProfileImage(filePath);
      // FastAPI returns UserOut directly — profile_image field
      final data = res.data as Map<String, dynamic>;
      final imageUrl = data['profile_image'] as String?;
      if (imageUrl != null) {
        _user = _user?.copyWith(profileImage: imageUrl);
        if (_user != null) {
          await StorageService.saveUser(jsonEncode(_user!.toJson()));
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    try {
      // FastAPI UpdateProfileIn uses snake_case
      await ApiService.updateProfile({
        'first_name': firstName,
        'last_name':  lastName,
        'email':      email,
        'phone':      phone,
      });
      _user = _user?.copyWith(
        firstName: firstName,
        lastName:  lastName,
        email:     email,
        phone:     phone,
      );
      if (_user != null) {
        await StorageService.saveUser(jsonEncode(_user!.toJson()));
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVehicle(Map<String, String> vehicle) async {
    try {
      await ApiService.updateVehicle(vehicle);
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final accessToken  = data['access_token']  as String;
    final refreshToken = data['refresh_token'] as String;
    _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await StorageService.saveToken(accessToken);
    await StorageService.saveRefreshToken(refreshToken);
    await StorageService.saveUser(jsonEncode(_user!.toJson()));
    await StorageService.saveRole(_user!.role);
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      final msg = body is Map ? (body['detail'] ?? body['message']) : null;
      if (code == 401) return 'Invalid email or password';
      if (code == 409) return 'Email already in use';
      if (code == 400 && msg != null) return msg.toString();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Check your internet.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Cannot reach server. Make sure the backend is running.';
      }
      if (msg != null) return msg.toString();
    }
    return 'Something went wrong. Please try again.';
  }
}
