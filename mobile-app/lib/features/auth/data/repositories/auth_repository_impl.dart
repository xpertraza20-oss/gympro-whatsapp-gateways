import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage secureStorage;

  static const String _tokenKey = 'jwt_access_token';

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  Future<void> _saveUserLocal(Map<String, dynamic> result) async {
    if (result['user'] != null) {
      final user = result['user'] as Map<String, dynamic>;
      await secureStorage.write(key: 'user_name', value: user['name'] ?? '');
      await secureStorage.write(key: 'user_email', value: user['email'] ?? '');
      await secureStorage.write(key: 'user_phone', value: user['phone'] ?? '');
      await secureStorage.write(key: 'user_location', value: user['location'] ?? '');
    }
  }

  @override
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String password,
  }) async {
    final result = await remoteDataSource.signup(
      name: name,
      email: email,
      phone: phone,
      location: location,
      password: password,
    );
    if (result['token'] != null) {
      await saveToken(result['token'] as String);
    }
    await secureStorage.write(key: 'user_password', value: password);
    await _saveUserLocal(result);
    return result;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await remoteDataSource.login(
      email: email,
      password: password,
    );
    if (result['token'] != null) {
      await saveToken(result['token'] as String);
    }
    await secureStorage.write(key: 'user_password', value: password);
    await _saveUserLocal(result);
    return result;
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) async {
    final result = await remoteDataSource.verifyOtp(email: email, otp: otp);
    await saveToken(result['token'] as String);
    await _saveUserLocal(result);
    return result;
  }

  @override
  Future<void> saveToken(String token) async {
    await secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> clearToken() async {
    await secureStorage.delete(key: _tokenKey);
    await secureStorage.delete(key: 'user_name');
    await secureStorage.delete(key: 'user_email');
    await secureStorage.delete(key: 'user_phone');
    await secureStorage.delete(key: 'user_location');
    await secureStorage.delete(key: 'user_password');
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    await remoteDataSource.requestOtp(phoneNumber);
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String location,
    String? password,
  }) async {
    final result = await remoteDataSource.updateProfile(
      name: name,
      phone: phone,
      location: location,
      password: password,
    );
    if (password != null && password.isNotEmpty) {
      await secureStorage.write(key: 'user_password', value: password);
    }
    await _saveUserLocal(result);
    return result;
  }
}
