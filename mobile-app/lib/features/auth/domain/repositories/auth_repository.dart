abstract class AuthRepository {
  Future<void> requestOtp(String phoneNumber);
  Future<String> verifyOtp(String phoneNumber, String otp);
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
}
