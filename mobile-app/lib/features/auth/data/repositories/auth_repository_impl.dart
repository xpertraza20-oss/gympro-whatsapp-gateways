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

  @override
  Future<void> signup({required String name, required String email, required String phone}) async {
    await remoteDataSource.signup(name: name, email: email, phone: phone);
  }

  @override
  Future<void> login({required String email}) async {
    await remoteDataSource.login(email: email);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) async {
    final result = await remoteDataSource.verifyOtp(email: email, otp: otp);
    await saveToken(result['token'] as String);
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
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    await remoteDataSource.requestOtp(phoneNumber);
  }
}
