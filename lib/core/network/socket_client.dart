import 'package:socket_io_client/socket_io_client.dart' as io;
import '../storage/secure_storage.dart';

class SocketClient {
  static io.Socket? _socket;

  static const _baseUrl = 'http://192.168.0.7:3000';

  // 소켓 연결 (토큰 필요)
  static Future<io.Socket> connect() async {
    if (_socket != null && _socket!.connected) return _socket!;

    final token = await SecureStorage.getAccessToken();

    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])   // 웹소켓만 사용
          .disableAutoConnect()           // 수동 연결
          .setAuth({'token': token})      // JWT를 handshake.auth로 전달
          .build(),
    );

    _socket!.connect();
    return _socket!;
  }

  static io.Socket? get socket => _socket;

  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}