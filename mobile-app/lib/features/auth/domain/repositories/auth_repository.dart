abstract class AuthRepository {
  /// Signup with email/password and location
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String password,
  });

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  /// Verify OTP + get JWT
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp});

  /// Token management
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();

  // Legacy phone support
  Future<void> requestOtp(String phoneNumber);

  /// Update profile details in database
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String location,
    String? password,
  });
}
