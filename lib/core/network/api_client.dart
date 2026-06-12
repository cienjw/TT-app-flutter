import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static const _baseUrl = 'http://211.201.115.13:3000';  // 외부 ip: 211.201.115.13 / 내부 ip : 192.168.0.7

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
      onError: (error, handler) {
        // 자동 토큰 갱신은 추후 구현. 지금은 401이어도 토큰 유지.
        handler.next(error);
      },
    ),
  );
}