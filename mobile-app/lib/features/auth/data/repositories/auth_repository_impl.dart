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
    if (result['profile_status'] != null) {
      final pStatus = result['profile_status'] as Map<String, dynamic>;
      await secureStorage.write(key: 'profile_status', value: pStatus['status'] ?? 'complete');
    }
  }

  @override
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String password,
    String? role,
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
    if (role != null) {
      await secureStorage.write(key: 'user_role', value: role);
    }
    await secureStorage.write(key: 'user_password', value: password);
    await _saveUserLocal(result);
    return result;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,
  }) async {
    final result = await remoteDataSource.login(
      email: email,
      password: password,
    );
    if (result['token'] != null) {
      await saveToken(result['token'] as String);
    }
    if (role != null) {
      await secureStorage.write(key: 'user_role', value: role);
    }
    await secureStorage.write(key: 'user_password', value: password);
    await _saveUserLocal(result);
    return result;
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    String? role,
  }) async {
    final result = await remoteDataSource.verifyOtp(email: email, otp: otp);
    await saveToken(result['token'] as String);
    if (role != null) {
      await secureStorage.write(key: 'user_role', value: role);
    }
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
  Future<String?> getRole() async {
    return await secureStorage.read(key: 'user_role');
  }

  @override
  Future<String?> getProfileStatusString() async {
    return await secureStorage.read(key: 'profile_status') ?? 'incomplete';
  }

  @override
  Future<void> clearToken() async {
    await secureStorage.delete(key: _tokenKey);
    await secureStorage.delete(key: 'user_name');
    await secureStorage.delete(key: 'user_email');
    await secureStorage.delete(key: 'user_phone');
    await secureStorage.delete(key: 'user_location');
    await secureStorage.delete(key: 'user_password');
    await secureStorage.delete(key: 'user_role');
    await secureStorage.delete(key: 'profile_status');
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

  @override
  Future<Map<String, dynamic>> getProfileStatus() async {
    return await remoteDataSource.getProfileStatus();
  }

  @override
  Future<Map<String, dynamic>> registerShop({
    required String shopName,
    required String shopAddress,
    required String mapLocation,
    required String cnic,
    required String openingTime,
    required String closingTime,
    String? imageUrl,
  }) async {
    return await remoteDataSource.registerShop(
      shopName: shopName,
      shopAddress: shopAddress,
      mapLocation: mapLocation,
      cnic: cnic,
      openingTime: openingTime,
      closingTime: closingTime,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<Map<String, dynamic>> registerRider({
    required String vehicleType,
    required String vehicleNumber,
    required String cnic,
    required String currentLocation,
  }) async {
    return await remoteDataSource.registerRider(
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      cnic: cnic,
      currentLocation: currentLocation,
    );
  }
}
