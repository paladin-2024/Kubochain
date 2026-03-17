import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'storage_service.dart';

class SocketService {
  static const String socketUrl = 'http://172.20.10.5:5000';

  static IO.Socket? _socket;
  static IO.Socket? get socket => _socket;

  static void connect() {
    final token = StorageService.getToken();
    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );
    _socket!.connect();

    _socket!.onConnect((_) {
      // Connected to server
    });

    _socket!.onDisconnect((_) {
      // Disconnected from server
    });

    _socket!.onConnectError((data) {
      // Connection error
    });
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // Driver: send location update
  static void sendDriverLocation(double lat, double lng) {
    _socket?.emit('driver:updateLocation', {'lat': lat, 'lng': lng});
  }

  // Driver: toggle online/offline
  static void setDriverOnline(bool isOnline) {
    _socket?.emit('driver:setOnline', {'isOnline': isOnline});
  }

  // Passenger: listen for driver location
  static void onDriverLocation(Function(Map<String, dynamic>) callback) {
    _socket?.on('ride:driverLocation', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // Passenger: listen for driver accepted
  static void onRideAccepted(Function(Map<String, dynamic>) callback) {
    _socket?.on('ride:accepted', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // Passenger: listen for ride started
  static void onRideStarted(Function(Map<String, dynamic>) callback) {
    _socket?.on('ride:started', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // Passenger: listen for ride completed
  static void onRideCompleted(Function(Map<String, dynamic>) callback) {
    _socket?.on('ride:completed', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // Passenger: listen for ride cancelled by driver
  static void onRideCancelled(Function(Map<String, dynamic>) callback) {
    _socket?.on('ride:cancelled', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // Passenger: listen for driver arrived
  static void onDriverArrived(Function(Map<String, dynamic>) callback) {
    _socket?.on('ride:driverArrived', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // Driver: listen for new ride requests
  static void onNewRideRequest(Function(Map<String, dynamic>) callback) {
    _socket?.on('ride:newRequest', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // Driver: arrive at pickup
  static void notifyArrived(String rideId) {
    _socket?.emit('ride:arrived', {'rideId': rideId});
  }

  // Join a ride room
  static void joinRideRoom(String rideId) {
    _socket?.emit('ride:join', {'rideId': rideId});
  }

  // Leave ride room
  static void leaveRideRoom(String rideId) {
    _socket?.emit('ride:leave', {'rideId': rideId});
  }

  // Remove specific listener
  static void off(String event) {
    _socket?.off(event);
  }
}
