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
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String location,
    String? password,
  });
  Future<Map<String, dynamic>> getProfileStatus();
  Future<Map<String, dynamic>> registerShop({
    required String shopName,
    required String shopAddress,
    required String mapLocation,
    required String cnic,
    required String openingTime,
    required String closingTime,
    String? imageUrl,
  });
  Future<Map<String, dynamic>> registerRider({
    required String vehicleType,
    required String vehicleNumber,
    required String cnic,
    required String currentLocation,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl({required this.dio});

  String _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return 'Connection Error: Cannot resolve server address. Please verify your internet connection or backend URL in settings.';
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout ||
               e.type == DioExceptionType.sendTimeout) {
      return 'Timeout Error: Server took too long to respond. Please try again.';
    } else if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
    }
    return e.message ?? 'An unexpected network error occurred';
  }

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
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception(response.data?['message'] ?? 'Signup failed');
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
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
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception(response.data?['message'] ?? 'Login failed');
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
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
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    try {
      await dio.post('/api/v1/auth/request-otp', data: {'phoneNumber': phoneNumber});
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String location,
    String? password,
  }) async {
    try {
      final response = await dio.put('/api/v1/auth/profile', data: {
        'name': name,
        'phone': phone,
        'location': location,
        if (password != null && password.isNotEmpty) 'password': password,
      });
      if (response.data?['success'] == true) {
        return response.data;
      }
      throw Exception(response.data?['message'] ?? 'Profile update failed');
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> getProfileStatus() async {
    try {
      final response = await dio.get('/api/v1/auth/profile-status');
      if (response.data?['success'] == true) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception(response.data?['message'] ?? 'Failed to get profile status');
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
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
    try {
      final response = await dio.post('/api/v1/shops', data: {
        'shop_name': shopName,
        'shop_address': shopAddress,
        'map_location': mapLocation,
        'cnic': cnic,
        'opening_time': openingTime,
        'closing_time': closingTime,
        if (imageUrl != null) 'image_url': imageUrl,
      });
      if (response.data?['success'] == true) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception(response.data?['message'] ?? 'Shop registration failed');
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> registerRider({
    required String vehicleType,
    required String vehicleNumber,
    required String cnic,
    required String currentLocation,
  }) async {
    try {
      final response = await dio.post('/api/v1/riders', data: {
        'vehicle_type': vehicleType,
        'vehicle_number': vehicleNumber,
        'cnic': cnic,
        'current_location': currentLocation,
      });
      if (response.data?['success'] == true) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception(response.data?['message'] ?? 'Rider registration failed');
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }
}
