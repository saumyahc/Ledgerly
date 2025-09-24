import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants.dart';

/// Service for managing transaction recording and retrieval
class TransactionService {
  static const String _baseUrl = '${ApiConstants.baseUrl}/transaction_api.php';

  /// Record a new transaction
  static Future<Map<String, dynamic>> recordTransaction({
    required int userId,
    required String walletAddress,
    required String transactionHash,
    required String transactionType,
    required String direction,
    required String fromAddress,
    required String toAddress,
    required double amount,
    String currencySymbol = 'ETH',
    int? blockNumber,
    String? blockHash,
    int? transactionIndex,
    int? gasUsed,
    int? gasPrice,
    double? gasCost,
    String status = 'pending',
    int confirmations = 0,
    String? inputData,
    List<dynamic>? logs,
    String? errorMessage,
    String? memo,
    String? internalNotes,
    String? contractAddress,
    String? contractMethod,
    String? betId,
    String? betType,
    DateTime? blockchainTimestamp,
  }) async {
    try {
      final requestBody = {
        'user_id': userId,
        'wallet_address': walletAddress,
        'transaction_hash': transactionHash,
        'transaction_type': transactionType,
        'direction': direction,
        'from_address': fromAddress,
        'to_address': toAddress,
        'amount': amount.toString(),
        'currency_symbol': currencySymbol,
        'status': status,
        'confirmations': confirmations,
      };

      // Add optional fields
      if (blockNumber != null) requestBody['block_number'] = blockNumber.toString();
      if (blockHash != null) requestBody['block_hash'] = blockHash;
      if (transactionIndex != null) requestBody['transaction_index'] = transactionIndex.toString();
      if (gasUsed != null) requestBody['gas_used'] = gasUsed.toString();
      if (gasPrice != null) requestBody['gas_price'] = gasPrice.toString();
      if (gasCost != null) requestBody['gas_cost'] = gasCost.toString();
      if (inputData != null) requestBody['input_data'] = inputData;
      if (logs != null) requestBody['logs'] = logs;
      if (errorMessage != null) requestBody['error_message'] = errorMessage;
      if (memo != null) requestBody['memo'] = memo;
      if (internalNotes != null) requestBody['internal_notes'] = internalNotes;
      if (contractAddress != null) requestBody['contract_address'] = contractAddress;
      if (contractMethod != null) requestBody['contract_method'] = contractMethod;
      if (betId != null) requestBody['bet_id'] = betId;
      if (betType != null) requestBody['bet_type'] = betType;
      if (blockchainTimestamp != null) {
        requestBody['blockchain_timestamp'] = blockchainTimestamp.toIso8601String();
      }

      if (kDebugMode) {
        print('📝 Recording transaction: $transactionHash');
        print('   Type: $transactionType, Direction: $direction');
        print('   Amount: $amount $currencySymbol');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl?action=record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (kDebugMode) {
          print('✅ Transaction recorded successfully: ${responseData['transaction_id']}');
        }
        return responseData;
      } else {
        throw Exception(responseData['error'] ?? 'Failed to record transaction');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to record transaction: $e');
      }
      rethrow;
    }
  }

  /// Update transaction status (when confirmed/failed)
  static Future<Map<String, dynamic>> updateTransactionStatus({
    required String transactionHash,
    required String status,
    int? confirmations,
    int? blockNumber,
    String? blockHash,
    int? transactionIndex,
    int? gasUsed,
    double? gasCost,
    String? errorMessage,
    DateTime? blockchainTimestamp,
  }) async {
    try {
      final requestBody = {
        'transaction_hash': transactionHash,
        'status': status,
      };

      // Add optional fields
      if (confirmations != null) requestBody['confirmations'] = confirmations.toString();
      if (blockNumber != null) requestBody['block_number'] = blockNumber.toString();
      if (blockHash != null) requestBody['block_hash'] = blockHash;
      if (transactionIndex != null) requestBody['transaction_index'] = transactionIndex.toString();
      if (gasUsed != null) requestBody['gas_used'] = gasUsed.toString();
      if (gasCost != null) requestBody['gas_cost'] = gasCost.toString();
      if (errorMessage != null) requestBody['error_message'] = errorMessage;
      if (blockchainTimestamp != null) {
        requestBody['blockchain_timestamp'] = blockchainTimestamp.toIso8601String();
      }

      if (kDebugMode) {
        print('🔄 Updating transaction status: $transactionHash -> $status');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl?action=update_status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (kDebugMode) {
          print('✅ Transaction status updated successfully');
        }
        return responseData;
      } else {
        throw Exception(responseData['error'] ?? 'Failed to update transaction status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update transaction status: $e');
      }
      rethrow;
    }
  }

  /// Get transaction history for a user
  static Future<Map<String, dynamic>> getTransactionHistory({
    int? userId,
    String? walletAddress,
    int limit = 50,
    int offset = 0,
    String? type,
  }) async {
    try {
      final queryParams = <String, String>{
        'action': 'history',
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (userId != null) queryParams['user_id'] = userId.toString();
      if (walletAddress != null) queryParams['wallet_address'] = walletAddress;
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('📋 Fetching transaction history...');
      }

      final response = await http.get(uri);
      
      if (kDebugMode) {
        print('📋 Transaction API response status: ${response.statusCode}');
        print('📋 Transaction API response body: ${response.body}');
      }
      
      if (response.body.isEmpty) {
        if (kDebugMode) {
          print('⚠️ Empty response from transaction API');
        }
        return {'success': true, 'transactions': []};
      }
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (kDebugMode) {
          print('✅ Retrieved ${responseData['transactions'].length} transactions');
        }
        return responseData;
      } else {
        throw Exception(responseData['error'] ?? 'Failed to fetch transaction history');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch transaction history: $e');
      }
      rethrow;
    }
  }

  /// Get pending transactions
  static Future<List<Map<String, dynamic>>> getPendingTransactions({
    int? userId,
  }) async {
    try {
      final queryParams = <String, String>{
        'action': 'pending',
      };
      if (userId != null) queryParams['user_id'] = userId.toString();

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('⏳ Fetching pending transactions...');
      }

      final response = await http.get(uri);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (kDebugMode) {
          print('✅ Retrieved ${responseData['pending_transactions'].length} pending transactions');
        }
        return List<Map<String, dynamic>>.from(responseData['pending_transactions']);
      } else {
        throw Exception(responseData['error'] ?? 'Failed to fetch pending transactions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch pending transactions: $e');
      }
      rethrow;
    }
  }

  /// Get transaction summary for a user
  static Future<List<Map<String, dynamic>>> getTransactionSummary({
    required int userId,
    int days = 30,
  }) async {
    try {
      final queryParams = {
        'action': 'summary',
        'user_id': userId.toString(),
        'days': days.toString(),
      };

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('📊 Fetching transaction summary for $days days...');
      }

      final response = await http.get(uri);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (kDebugMode) {
          print('✅ Retrieved ${responseData['summaries'].length} summary records');
        }
        return List<Map<String, dynamic>>.from(responseData['summaries']);
      } else {
        throw Exception(responseData['error'] ?? 'Failed to fetch transaction summary');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch transaction summary: $e');
      }
      rethrow;
    }
  }

  /// Helper method to record a faucet transaction
  static Future<Map<String, dynamic>> recordFaucetTransaction({
    required int userId,
    required String walletAddress,
    required String transactionHash,
    required double amount,
    String? memo,
  }) async {
    return await recordTransaction(
      userId: userId,
      walletAddress: walletAddress,
      transactionHash: transactionHash,
      transactionType: 'faucet',
      direction: 'incoming',
      fromAddress: '0x0000000000000000000000000000000000000000', // Faucet address
      toAddress: walletAddress,
      amount: amount,
      memo: memo ?? 'Test ETH from faucet',
      internalNotes: 'Development faucet funding',
    );
  }

  /// Helper method to record a send transaction
  static Future<Map<String, dynamic>> recordSendTransaction({
    required int userId,
    required String walletAddress,
    required String transactionHash,
    required String toAddress,
    required double amount,
    double? gasCost,
    String? memo,
  }) async {
    return await recordTransaction(
      userId: userId,
      walletAddress: walletAddress,
      transactionHash: transactionHash,
      transactionType: 'send',
      direction: 'outgoing',
      fromAddress: walletAddress,
      toAddress: toAddress,
      amount: amount,
      gasCost: gasCost,
      memo: memo,
    );
  }

  /// Helper method to record a receive transaction
  static Future<Map<String, dynamic>> recordReceiveTransaction({
    required int userId,
    required String walletAddress,
    required String transactionHash,
    required String fromAddress,
    required double amount,
    String? memo,
  }) async {
    return await recordTransaction(
      userId: userId,
      walletAddress: walletAddress,
      transactionHash: transactionHash,
      transactionType: 'receive',
      direction: 'incoming',
      fromAddress: fromAddress,
      toAddress: walletAddress,
      amount: amount,
      memo: memo,
    );
  }

  /// Helper method to record a betting transaction
  static Future<Map<String, dynamic>> recordBettingTransaction({
    required int userId,
    required String walletAddress,
    required String transactionHash,
    required String betType, // 'create', 'join', 'resolve', 'claim'
    required String direction,
    required String fromAddress,
    required String toAddress,
    required double amount,
    required String betId,
    String? contractAddress,
    String? contractMethod,
    String? memo,
  }) async {
    return await recordTransaction(
      userId: userId,
      walletAddress: walletAddress,
      transactionHash: transactionHash,
      transactionType: 'betting',
      direction: direction,
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      betId: betId,
      betType: betType,
      contractAddress: contractAddress,
      contractMethod: contractMethod,
      memo: memo,
    );
  }
}