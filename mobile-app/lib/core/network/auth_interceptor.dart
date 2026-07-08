import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Custom interceptor to handle dynamic JWT bearer token injections
/// and handle 401 Unauthorized exceptions (e.g. token refresh flows).
class AuthInterceptor extends Interceptor {
  final _secureStorage = const FlutterSecureStorage();

  Future<String?> _getAccessToken() async {
    return await _secureStorage.read(key: 'jwt_access_token');
  }

  Future<String?> _getRefreshToken() async {
    return await _secureStorage.read(key: 'jwt_refresh_token');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Inject dynamic JWT bearer auth token
    final token = await _getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Standard headers
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If request fails with 401 Unauthorized, attempt token refresh
    if (err.response?.statusCode == 401) {
      final refreshToken = await _getRefreshToken();
      if (refreshToken != null) {
        try {
          // Simulate Token Refresh API Request
          // final dio = Dio();
          // final refreshResponse = await dio.post('/api/auth/refresh', data: {'refresh': refreshToken});
          // final newToken = refreshResponse.data['access'];
          // saveNewToken(newToken);
          
          // Re-try the original request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer refreshed_mock_token_value';
          
          final cloneDio = Dio(BaseOptions(
            baseUrl: options.baseUrl,
            headers: options.headers,
          ));
          
          final response = await cloneDio.request(
            options.path,
            data: options.data,
            queryParameters: options.queryParameters,
            options: Options(method: options.method),
          );
          
          return handler.resolve(response);
        } catch (refreshErr) {
          // Token refresh failed, force logout/redirect to auth page
          return handler.next(err);
        }
      }
    }
    
    // Custom error format printing
    print("[Dio Error] Path: ${err.requestOptions.path} | Code: ${err.response?.statusCode} | Message: ${err.message}");
    return handler.next(err);
  }
}
