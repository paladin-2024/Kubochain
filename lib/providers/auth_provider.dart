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
    // Refresh from server
    try {
      final res = await ApiService.getMe();
      _user = UserModel.fromJson(res.data['user']);
      await StorageService.saveUser(jsonEncode(_user!.toJson()));
      _status = AuthStatus.authenticated;
    } catch (_) {
      // Keep local user if refresh fails
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      final token = res.data['token'];
      _user = UserModel.fromJson(res.data['user']);
      await StorageService.saveToken(token);
      await StorageService.saveUser(jsonEncode(_user!.toJson()));
      await StorageService.saveRole(_user!.role);
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
      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'otpCode': otpCode,
      };
      if (vehicle != null) body['vehicle'] = vehicle;
      final res = await ApiService.register(body);
      final token = res.data['token'];
      _user = UserModel.fromJson(res.data['user']);
      await StorageService.saveToken(token);
      await StorageService.saveUser(jsonEncode(_user!.toJson()));
      await StorageService.saveRole(_user!.role);
      _status = AuthStatus.authenticated;
      SocketService.connect();
      notifyListeners();
      // Upload driver documents in the background after registration
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
      final imageUrl = res.data['imageUrl'] as String;
      _user = _user?.copyWith(profileImage: imageUrl);
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

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    try {
      final res = await ApiService.updateProfile({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
      });
      _user = _user?.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
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

  String _parseError(dynamic e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      final msg = e.response?.data?['message'];
      if (code == 401) return 'Invalid email or password';
      if (code == 409) return 'Email already in use';
      if (code == 400 && msg != null) return msg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Check your internet.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Cannot reach server. Make sure the backend is running.';
      }
      if (msg != null) return msg;
    }
    return 'Something went wrong. Please try again.';
  }
}
