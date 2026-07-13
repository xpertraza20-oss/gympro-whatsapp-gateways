import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

class DioClient {
  final Dio dio;

  DioClient({String? baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'https://grocery-backend.xpertraza13.workers.dev',
            ),
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            responseType: ResponseType.json,
          ),
        ) {
    // Add interceptors
    dio.interceptors.addAll([
      AuthInterceptor(),
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  /// Dynamically updates the base URL at runtime
  void setBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }
}
