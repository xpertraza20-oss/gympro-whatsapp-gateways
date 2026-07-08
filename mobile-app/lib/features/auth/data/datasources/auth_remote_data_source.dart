import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String password,
  });
  
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });
  
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp});
  Future<void> requestOtp(String phoneNumber); // legacy
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String password,
  }) async {
    try {
      final response = await dio.post('/api/v1/auth/signup', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'password': password,
      });
      if (response.data?['success'] == true) {
        return {
          'token': response.data['token'],
          'user': response.data['user'],
        };
      }
      throw Exception(response.data?['message'] ?? 'Signup failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Network error');
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });
      if (response.data?['success'] == true) {
        return {
          'token': response.data['token'],
          'user': response.data['user'],
        };
      }
      throw Exception(response.data?['message'] ?? 'Login failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Network error');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await dio.post('/api/v1/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      if (response.data?['success'] == true) {
        return {
          'token': response.data['token'],
          'user': response.data['user'],
        };
      }
      throw Exception(response.data?['message'] ?? 'OTP verification failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Network error');
    }
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    try {
      await dio.post('/api/v1/auth/request-otp', data: {'phoneNumber': phoneNumber});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Network error');
    }
  }
}
