import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

/// Service for email-based payments
class EmailPaymentService {
  /// Resolve an email address to a wallet address
  static Future<Map<String, dynamic>> resolveEmailToWallet(String email) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.emailPayment}?email=$email'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'userData': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Failed to resolve email address',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  /// Send payment via email using Node.js middleware
  static Future<Map<String, dynamic>> sendPaymentToEmail({
    required String fromEmail,
    required String toEmail,
    required double amount,
    String? memo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.middlewareBaseUrl}/payment/email-to-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fromEmail': fromEmail,
          'toEmail': toEmail,
          'amountEth': amount.toString(),
          'memo': memo ?? '',
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'txHash': responseData['txHash'],
          'status': responseData['status'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to process payment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
