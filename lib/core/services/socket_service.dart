import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'storage_service.dart';

// FastAPI WebSocket protocol:
//   Send:    {"event": "eventName", "data": {...}}
//   Receive: {"event": "eventName", "data": {...}}

class SocketService {
  // Android emulator  → ws://10.0.2.2:8000

  // Physical device   → ws://192.168.x.x:8000
  static const String _wsHost = 'ws://192.168.1.10:8000';

  static WebSocket? _ws;
  static StreamSubscription? _sub;
  static bool _intentionalDisconnect = false;
  static int _reconnectDelay = 2;

  // Event listeners: event name → list of callbacks
  static final Map<String, List<Function(Map<String, dynamic>)>> _listeners = {};

  // ── Connect / disconnect ──────────────────────────────────────────────────

  static Future<void> connect() async {
    final token = StorageService.getToken();
    if (token == null) return;
    _intentionalDisconnect = false;
    await _doConnect(token);
  }

  static Future<void> _doConnect(String token) async {
    try {
      _ws = await WebSocket.connect('$_wsHost/ws?token=$token');
      _reconnectDelay = 2;

      _sub = _ws!.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  static void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final msg   = jsonDecode(raw) as Map<String, dynamic>;
      final event = msg['event'] as String?;
      final data  = (msg['data'] as Map<String, dynamic>?) ?? {};
      if (event == null) return;
      for (final cb in List.of(_listeners[event] ?? [])) {
        cb(data);
      }
    } catch (_) {}
  }

  static void _onDisconnected() {
    _ws = null;
    _sub?.cancel();
    _sub = null;
    if (!_intentionalDisconnect) _scheduleReconnect();
  }

  static void _scheduleReconnect() async {
    await Future.delayed(Duration(seconds: _reconnectDelay));
    _reconnectDelay = (_reconnectDelay * 2).clamp(2, 60);
    final token = StorageService.getToken();
    if (token != null && !_intentionalDisconnect) {
      await _doConnect(token);
    }
  }

  static void disconnect() {
    _intentionalDisconnect = true;
    _sub?.cancel();
    _sub = null;
    _ws?.close();
    _ws = null;
    _listeners.clear();
  }

  // ── Send helpers ──────────────────────────────────────────────────────────

  static void _emit(String event, Map<String, dynamic> data) {
    if (_ws == null || _ws!.readyState != WebSocket.open) return;
    _ws!.add(jsonEncode({'event': event, 'data': data}));
  }

  // ── Driver events (outgoing) ───────────────────────────────────────────────

  static void sendDriverLocation(double lat, double lng) =>
      _emit('driver:updateLocation', {'lat': lat, 'lng': lng});

  static void setDriverOnline(bool isOnline) =>
      _emit('driver:setOnline', {'isOnline': isOnline});

  static void notifyArrived(String rideId) =>
      _emit('ride:arrived', {'rideId': rideId});

  // ── Ride room membership ───────────────────────────────────────────────────

  static void joinRideRoom(String rideId) =>
      _emit('ride:join', {'rideId': rideId});

  static void leaveRideRoom(String rideId) =>
      _emit('ride:leave', {'rideId': rideId});

  // ── Chat events (outgoing) ─────────────────────────────────────────────────

  static void sendChatMessage(String rideId, String receiverId, String content) =>
      _emit('chat:send', {
        'rideId':     rideId,
        'receiverId': receiverId,
        'content':    content,
      });

  static void markChatRead(String rideId) =>
      _emit('chat:read', {'rideId': rideId});

  // ── Listener registration ──────────────────────────────────────────────────

  static void on(String event, Function(Map<String, dynamic>) callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  static void off(String event) {
    _listeners.remove(event);
  }

  // ── Typed convenience listeners ────────────────────────────────────────────

  static void onDriverLocation(Function(Map<String, dynamic>) cb) =>
      on('ride:driverLocation', cb);

  static void onRideAccepted(Function(Map<String, dynamic>) cb) =>
      on('ride:accepted', cb);

  static void onRideStarted(Function(Map<String, dynamic>) cb) =>
      on('ride:started', cb);

  static void onRideCompleted(Function(Map<String, dynamic>) cb) =>
      on('ride:completed', cb);

  static void onRideCancelled(Function(Map<String, dynamic>) cb) =>
      on('ride:cancelled', cb);

  static void onDriverArrived(Function(Map<String, dynamic>) cb) =>
      on('ride:driverArrived', cb);

  static void onNewRideRequest(Function(Map<String, dynamic>) cb) =>
      on('ride:newRequest', cb);

  static void onChatMessage(Function(Map<String, dynamic>) cb) =>
      on('chat:message', cb);

  static void onChatRead(Function(Map<String, dynamic>) cb) =>
      on('chat:read', cb);
}
