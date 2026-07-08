import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  Future<void> requestOtp(String phoneNumber);
  Future<String> verifyOtp(String phoneNumber, String otp);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<void> requestOtp(String phoneNumber) async {
    try {
      final response = await dio.post(
        '/api/v1/auth/request-otp',
        data: {'phoneNumber': phoneNumber},
      );
      if (response.statusCode != 200 && response.data?['success'] != true) {
        throw Exception(response.data?['message'] ?? 'Failed to request OTP');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      throw Exception(msg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<String> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await dio.post(
        '/api/v1/auth/verify-otp',
        data: {'phoneNumber': phoneNumber, 'otp': otp},
      );
      if (response.statusCode == 200 && response.data?['success'] == true) {
        final token = response.data['token'];
        if (token != null) {
          return token;
        }
      }
      throw Exception(response.data?['message'] ?? 'Invalid OTP verification');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      throw Exception(msg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
