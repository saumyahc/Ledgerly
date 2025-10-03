/// Central place for API endpoints and base URLs.

import 'package:flutter_dotenv/flutter_dotenv.dart';
class ApiConstants {
  // === BASE URLs ===
  /// PHP backend (user/profile, legacy APIs)
  static const String phpBaseUrl = 'https://ledgerly.hivizstudios.com/backend_example';
  /// Middleware endpoint (local/testnet blockchain node)
  static final String middlewareBaseUrl= dotenv.env['MIDDLEWARE_URL'] ?? 'http://10.0.2.2:3001'; // Change as needed for deployment
  /// Node.js blockchain API server (funding, ganache control, etc)

  // === PHP Backend Endpoints ===
    static const String testDb = '${phpBaseUrl}/test_db.php';
    static const String emailPayment = '${phpBaseUrl}/email_payment.php';
    static const String walletApi = '${phpBaseUrl}/wallet_api.php';

  // Auth / Registration
    static const String signup = '${phpBaseUrl}/signup.php';
    static const String sendOtp = '${phpBaseUrl}/send_otp.php';
    static const String verifyOtp = '${phpBaseUrl}/verify_otp.php';

  // User Profile
    static const String getProfile = '${phpBaseUrl}/get_profile.php';
    static const String saveProfile = '${phpBaseUrl}/save_profile.php';

  // Smart Contracts
    static const String saveContract = '${phpBaseUrl}/save_contract.php';
    static const String getContract = '${phpBaseUrl}/get_contract.php';

  // === Blockchain API Server Endpoints ===
    static final String ganacheInfo = '${middlewareBaseUrl}/ganache-info';
    static final String fundUser = '${middlewareBaseUrl}/fund-user';
    static final String startGanache = '${middlewareBaseUrl}/start-ganache';
    static final String stopGanache = '${middlewareBaseUrl}/stop-ganache';
  // ...add more as needed


}


class FinnhubConstants {
  // API key should be loaded from environment variable FINNHUB_API_KEY
  // For development, you can set a fallback key here temporarily
  static const String apiKey = const String.fromEnvironment('FINNHUB_API_KEY', 
      defaultValue: 'd383nk1r01qlbdj3p8vgd383nk1r01qlbdj3p900');
  
  static String quoteUrl(String symbol) =>
      'https://finnhub.io/api/v1/quote?symbol=$symbol&token=$apiKey';

  static String symbolsUrl(String exchange) =>
      'https://finnhub.io/api/v1/stock/symbol?exchange=$exchange&token=$apiKey';
  
  static String candleUrl(String symbol, String resolution, int from, int to) =>
    'https://finnhub.io/api/v1/stock/candle?symbol=$symbol&resolution=$resolution&from=$from&to=$to&token=$apiKey';
      
  static String searchUrl(String query) =>
      'https://finnhub.io/api/v1/search?q=$query&token=$apiKey';
      
  static String companyProfileUrl(String symbol) =>
      'https://finnhub.io/api/v1/stock/profile2?symbol=$symbol&token=$apiKey';
}