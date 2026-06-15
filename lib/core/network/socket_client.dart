import 'package:socket_io_client/socket_io_client.dart' as io;
import '../storage/secure_storage.dart';

class SocketClient {
  static io.Socket? _socket;

  static const _baseUrl = 'http://192.168.0.7:3000';

  // 소켓 연결 (토큰 필요)
  static Future<io.Socket> connect() async {
    // 살아있는 소켓은 재사용
    if (_socket != null && _socket!.connected) return _socket!;

    // 끊긴 소켓 잔재가 있으면 완전히 정리
    disconnect();

    final token = await SecureStorage.getAccessToken();
    if (token == null) {
      throw Exception('토큰이 없습니다. 다시 로그인해주세요.');
    }

    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableForceNew()              // ★ 핵심: 패키지 내부 캐시 무시, 항상 새 소켓 생성
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) => print('### 소켓 연결됨'));
    _socket!.onConnectError((e) => print('### 소켓 연결 에러: $e'));
    _socket!.onError((e) => print('### 소켓 에러: $e'));

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