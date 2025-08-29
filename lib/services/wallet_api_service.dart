import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for communicating with the backend wallet API
class WalletApiService {
  static const String baseUrl = 'http://your-server.com/backend'; // Update with your actual server URL
  
  /// Link wallet address to user account
  static Future<Map<String, dynamic>> linkWalletToUser({
    required int userId,
    required String walletAddress,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/wallet_api.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'wallet_address': walletAddress,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Failed to link wallet',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  /// Get wallet information for a user
  static Future<Map<String, dynamic>> getUserWallet(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wallet_api.php?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Failed to get wallet info',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  /// Check if user has a linked wallet
  static Future<bool> userHasWallet(int userId) async {
    final result = await getUserWallet(userId);
    if (result['success'] == true) {
      final walletData = result['data']['wallet'];
      return walletData['has_wallet'] == true;
    }
    return false;
  }
  
  /// Get user's wallet address
  static Future<String?> getUserWalletAddress(int userId) async {
    final result = await getUserWallet(userId);
    if (result['success'] == true) {
      final walletData = result['data']['wallet'];
      return walletData['address'];
    }
    return null;
  }
}
