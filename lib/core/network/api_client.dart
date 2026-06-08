import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  // 에뮬레이터에서 로컬 백엔드 접속 시 10.0.2.2 사용
  static const _baseUrl = 'http://10.0.2.2:3000'; 

  static final Dio dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
  ))..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // 토큰 만료 시 자동 갱신 (추후 구현)
          await SecureStorage.clearAll();
        }
        handler.next(error);
      },
    ),
  );
}