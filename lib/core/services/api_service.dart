import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  // Android emulator  → 10.0.2.2
  // Physical device   → your machine's LAN IP (run `ip a` / `ipconfig`)
  static const String _host   = 'http://192.168.1.10:8000';
  static const String baseUrl = '$_host/api';

  static String imageUrl(String path) => '$_host$path';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static bool _isRefreshing = false;

  static void init() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // ── Auto-refresh on 401 ──────────────────────────────────────────
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            final refreshToken = StorageService.getRefreshToken();
            if (refreshToken != null) {
              _isRefreshing = true;
              try {
                final res = await _dio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                  options: Options(extra: {'skipAuth': true}),
                );
                final newAccess  = res.data['access_token']  as String;
                final newRefresh = res.data['refresh_token'] as String;
                await StorageService.saveToken(newAccess);
                await StorageService.saveRefreshToken(newRefresh);
                _isRefreshing = false;

                // Retry original request with new token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccess';
                final retried = await _dio.fetch(opts);
                return handler.resolve(retried);
              } catch (_) {
                _isRefreshing = false;
                await StorageService.clearAll();
              }
            }
          }

          // ── Retry on connection / timeout errors (handles cold starts) ───
          final extra   = error.requestOptions.extra;
          final retries = (extra['retries'] as int?) ?? 0;
          final isRetryable = error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout;
          if (isRetryable && retries < 3) {
            await Future.delayed(Duration(seconds: retries + 1));
            final opts = error.requestOptions;
            opts.extra['retries'] = retries + 1;
            try {
              return handler.resolve(await _dio.fetch(opts));
            } catch (_) {}
          }

          handler.next(error);
        },
      ),
    );
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  static Future<Response> login(String phone, String password) =>
      _dio.post('/auth/login', data: {'phone': phone, 'password': password});

  // FastAPI RegisterIn uses snake_case field names.
  static Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  static Future<Response> refreshTokens(String refreshToken) =>
      _dio.post('/auth/refresh', data: {'refresh_token': refreshToken});

  static Future<Response> getMe() => _dio.get('/auth/me');

  // ── OTP ─────────────────────────────────────────────────────────────────────

  static Future<Response> sendOtp(String phone) =>
      _dio.post('/auth/send-otp', data: {'phone': phone});

  static Future<Response> verifyOtp(String phone, String code) =>
      _dio.post('/auth/verify-otp', data: {'phone': phone, 'code': code});

  // ── Profile ──────────────────────────────────────────────────────────────────

  static Future<Response> uploadProfileImage(String filePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath, filename: 'profile.jpg'),
    });
    return _dio.put('/auth/profile-image', data: formData);
  }

  static Future<Response> uploadDriverDocuments(List<String> paths) async {
    final formData = FormData();
    for (final p in paths) {
      formData.files.add(MapEntry(
        'documents',
        await MultipartFile.fromFile(p, filename: p.split('/').last),
      ));
    }
    return _dio.put('/auth/documents', data: formData);
  }

  static Future<Response> updateFcmToken(String token) =>
      _dio.put('/auth/fcm-token', data: {'fcm_token': token});

  // FastAPI UpdateProfileIn uses snake_case.
  static Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.put('/auth/profile', data: data);

  static Future<Response> updateVehicle(Map<String, String> data) =>
      _dio.put('/driver/vehicle', data: data);

  // ── Rides ─────────────────────────────────────────────────────────────────

  static Future<Response> createRide(Map<String, dynamic> data) =>
      _dio.post('/rides', data: data);

  static Future<Response> getMyRides() => _dio.get('/rides/my');

  static Future<Response> getRide(String rideId) =>
      _dio.get('/rides/$rideId');

  static Future<Response> cancelRide(String rideId, String reason) =>
      _dio.put('/rides/$rideId/cancel', data: {'reason': reason});

  static Future<Response> rateRide(
          String rideId, int rating, String comment,
          {List<String> tags = const []}) =>
      _dio.post('/rides/$rideId/rate',
          data: {'rating': rating, 'comment': comment, 'tags': tags});

  static Future<Response> passengerConfirmRide(String rideId) =>
      _dio.put('/rides/$rideId/passenger-confirm');

  static Future<Response> initiatePayment({
    required String rideId,
    required String phone,
    required String method,
  }) =>
      _dio.post('/payments/initiate', data: {
        'ride_id': rideId,
        'phone_number': phone,
        'payment_method': method,
      });

  static Future<Response> getPaymentStatus(String rideId) =>
      _dio.get('/payments/$rideId/status');

  static Future<Response> getPaymentHistory() =>
      _dio.get('/payments/history');

  static Future<Response> acceptRide(String rideId) =>
      _dio.put('/rides/$rideId/accept');

  static Future<Response> startRide(String rideId) =>
      _dio.put('/rides/$rideId/start');

  static Future<Response> completeRide(String rideId) =>
      _dio.put('/rides/$rideId/complete');

  // ── Drivers ───────────────────────────────────────────────────────────────

  static Future<Response> getTopRatedDrivers() =>
      _dio.get('/drivers/top-rated');

  static Future<Response> getNearbyDrivers({
    required double lat,
    required double lng,
  }) =>
      _dio.get('/drivers/nearby', queryParameters: {'lat': lat, 'lng': lng});

  static Future<Response> updateDriverLocation(double lat, double lng) =>
      _dio.put('/drivers/location', data: {'lat': lat, 'lng': lng});

  static Future<Response> toggleAvailability(bool isOnline) =>
      _dio.put('/drivers/availability', data: {'is_online': isOnline});

  static Future<Response> getDriverEarnings() =>
      _dio.get('/drivers/earnings');

  // ── Chat ─────────────────────────────────────────────────────────────────

  static Future<Response> getConversations() => _dio.get('/chat/conversations');

  static Future<Response> getMessages(String rideId) =>
      _dio.get('/chat/$rideId');

  static Future<Response> sendMessage(
          String rideId, String receiverId, String content) =>
      _dio.post('/chat/$rideId',
          data: {'receiver_id': receiverId, 'content': content});

  // ── Admin ─────────────────────────────────────────────────────────────────

  static Future<Response> getAdminStats() => _dio.get('/admin/stats');

  static Future<Response> getAllRides({Map<String, dynamic>? params}) =>
      _dio.get('/admin/rides', queryParameters: params);

  static Future<Response> getAllDrivers() => _dio.get('/admin/drivers');

  static Future<Response> getAllUsers() => _dio.get('/admin/users');
}
