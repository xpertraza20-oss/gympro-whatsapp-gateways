abstract class AuthRepository {
  /// Signup: creates account + sends email OTP
  Future<void> signup({required String name, required String email, required String phone});

  /// Login: sends email OTP to existing account
  Future<void> login({required String email});

  /// Verify OTP + get JWT
  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp});

  /// Token management
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();

  // Legacy phone support (kept for backward compat)
  Future<void> requestOtp(String phoneNumber);
}
