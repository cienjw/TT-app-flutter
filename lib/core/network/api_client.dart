import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static const _baseUrl = 'http://192.168.0.7:3000';  // ← 미니PC IP로 교체

  static final Dio dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
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