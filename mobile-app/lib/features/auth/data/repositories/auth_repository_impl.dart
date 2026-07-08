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
  Future<void> requestOtp(String phoneNumber) async {
    await remoteDataSource.requestOtp(phoneNumber);
  }

  @override
  Future<String> verifyOtp(String phoneNumber, String otp) async {
    final token = await remoteDataSource.verifyOtp(phoneNumber, otp);
    await saveToken(token);
    return token;
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
}
