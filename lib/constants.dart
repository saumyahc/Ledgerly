import 'package:flutter_dotenv/flutter_dotenv.dart';
/// Central place for API endpoints and base URLs.
class ApiConstants {
  // Change this to your production base URL (no trailing slash)
  static const String baseUrl = 'https://ledgerly.hivizstudios.com/backend_example';
  
  // Test endpoints
  static const String testDb = '$baseUrl/test_db.php';
  static const String emailPayment = '$baseUrl/email_payment.php';
  static const String walletApi = '$baseUrl/wallet_api.php';

  // Auth / Registration
  static const String signup = '$baseUrl/signup.php';
  static const String sendOtp = '$baseUrl/send_otp.php';
  static const String verifyOtp = '$baseUrl/verify_otp.php';

  // User Profile
  static const String getProfile = '$baseUrl/get_profile.php';
  static const String saveProfile = '$baseUrl/save_profile.php';
  
  // Smart Contracts
  static const String saveContract = '$baseUrl/save_contract.php';
  static const String getContract = '$baseUrl/get_contract.php';
  
  // Blockchain network details
  static const Map<int, String> networks = {
    1: 'Ethereum Mainnet',
    11155111: 'Sepolia Testnet',
    5: 'Goerli Testnet',
    137: 'Polygon Mainnet',
    80001: 'Polygon Mumbai Testnet',
  };

  // Contract details
  static const String emailPaymentRegistryAddress = '0x89580Ee54E4e618dbe9FC2FA7b48ADF51bd40400'; // Deployed on local development network
  static const int defaultChainId = 1337; // Local development network chain ID
}



class FinnhubConstants {
  static const String apiKey = 'YOUR_API_KEY_HERE';
  static String quoteUrl(String symbol) =>
      'https://finnhub.io/api/v1/quote?symbol=$symbol&token=$apiKey';

  static String symbolsUrl(String exchange) =>
      'https://finnhub.io/api/v1/stock/symbol?exchange=$exchange&token=$apiKey';
}