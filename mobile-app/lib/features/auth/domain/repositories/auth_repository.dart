abstract class AuthRepository {
  /// Signup with email/password and location
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String password,
    String? role,
  });

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,
  });

  /// Verify OTP + get JWT
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    String? role,
  });

  /// Token management
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<String?> getRole();
  Future<String?> getProfileStatusString();

  // Legacy phone support
  Future<void> requestOtp(String phoneNumber);

  /// Update profile details in database
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String location,
    String? password,
  });

  /// Check profile status of the authenticated user
  Future<Map<String, dynamic>> getProfileStatus();

  /// Register shop details (for shopkeepers)
  Future<Map<String, dynamic>> registerShop({
    required String shopName,
    required String shopAddress,
    required String mapLocation,
    required String cnic,
    required String openingTime,
    required String closingTime,
    String? imageUrl,
  });

  /// Register rider details (for riders)
  Future<Map<String, dynamic>> registerRider({
    required String vehicleType,
    required String vehicleNumber,
    required String cnic,
    required String currentLocation,
  });
}
