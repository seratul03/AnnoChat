import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  late IO.Socket socket;

  void connect(String username, String roomCode) {
    socket = IO.io(
      "https://annochat-87fl.onrender.com",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setTimeout(20000)
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('[Socket] Connected');
      socket.emit("join room", {"username": username, "roomId": roomCode});
    });

    socket.onDisconnect((_) => debugPrint('[Socket] Disconnected'));
    socket.onConnectError((e) => debugPrint('[Socket] connect_error: $e'));
    socket.onError((e) => debugPrint('[Socket] error: $e'));
    socket.onReconnect((_) => debugPrint('[Socket] Reconnected'));
    socket.onReconnectAttempt((_) => debugPrint('[Socket] Reconnecting...'));
    socket.onReconnectFailed((_) => debugPrint('[Socket] Reconnect failed'));

    socket.connect();
  }

  void createRoom(String username, {int maxUsers = 1}) {
    socket.emit("create room", {"username": username, "maxUsers": maxUsers});
  }

  void sendMessage(String text) {
    socket.emit("chat message", {"text": text});
  }

  /// Ask the server to broadcast the current room headcount/state.
  ///
  /// The server should respond with a `room state`/`room_state` event
  /// containing at least `count` or `user_count`.
  void requestRoomState(String roomCode) {
    socket.emit("room state", {"roomId": roomCode});
  }

  void disconnect() {
    socket.disconnect();
  }
}
