/// Central place for API endpoints and base URLs.
class ApiConstants {
  // Change this to your production base URL (no trailing slash)
  static const String baseUrl = 'https://ledgerly.hivizstudios.com/backend_example';

  // Auth / Registration
  static const String signup = '$baseUrl/signup.php';
  static const String sendOtp = '$baseUrl/send_otp.php';
  static const String verifyOtp = '$baseUrl/verify_otp.php';

  // User Profile
  static const String getProfile = '$baseUrl/get_profile.php';
  static const String saveProfile = '$baseUrl/save_profile.php';
}
