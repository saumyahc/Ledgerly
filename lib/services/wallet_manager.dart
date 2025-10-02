import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class WalletManager {
  static const _storage = FlutterSecureStorage();

  String get backendBaseUrl => ApiConstants.middlewareBaseUrl;

  /// Create a new wallet via backend
  Future<Map<String, dynamic>> createWallet() async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/wallet/create'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      await _storage.write(key: 'wallet_private_key', value: data['privateKey']);
      await _storage.write(key: 'wallet_address', value: data['address']);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to create wallet');
    }
  }

  /// Import wallet from private key via backend
  Future<Map<String, dynamic>> importWallet(String privateKey) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/wallet/import'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'privateKey': privateKey}),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      await _storage.write(key: 'wallet_private_key', value: privateKey);
      await _storage.write(key: 'wallet_address', value: data['address']);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to import wallet');
    }
  }

  Future<bool> validateAddress(String address) async {
    final response = await http.get(
      Uri.parse('$backendBaseUrl/wallet/validate/$address'),
    );
    final data = jsonDecode(response.body);
    return data['success'] == true && data['isValid'] == true;
  }

  /// Export wallet info (address/privateKey) from local storage
  Future<Map<String, String?>> exportWallet() async {
    final privateKey = await _storage.read(key: 'wallet_private_key');
    final address = await _storage.read(key: 'wallet_address');
    return {'privateKey': privateKey, 'address': address};
  }

  /// Get wallet balance via backend
  Future<double> getBalance() async {
    final address = await _storage.read(key: 'wallet_address');
    if (address == null) throw Exception('No wallet found');
    final response = await http.get(
      Uri.parse('$backendBaseUrl/wallet/balance/$address'),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return double.parse(data['balance'].toString());
    } else {
      throw Exception(data['error'] ?? 'Failed to get balance');
    }
  }

  /// Send ETH payment via backend
  Future<String> sendTransaction({
    required String toAddress,
    required double amount,
    String? memo,
  }) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/payment/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'toWallet': toAddress,
        'amountEth': amount,
        'memo': memo,
      }),
    );
    final data = jsonDecode(response.body);
    if (data['txHash'] != null) {
      return data['txHash'];
    } else {
      throw Exception(data['error'] ?? 'Failed to send transaction');
    }
  }

  /// Send payment by email via backend
  Future<String> sendPaymentByEmail({
    required String fromEmail,
    required String toEmail,
    required double amount,
    String? memo,
  }) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/payment/email-to-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fromEmail': fromEmail,
        'toEmail': toEmail,
        'amountEth': amount,
        'memo': memo,
      }),
    );
    final data = jsonDecode(response.body);
    if (data['txHash'] != null) {
      return data['txHash'];
    } else {
      throw Exception(data['error'] ?? 'Failed to send payment by email');
    }
  }

  /// Request faucet funding via backend
  Future<Map<String, dynamic>> requestFunding(double amount) async {
  final address = await _storage.read(key: 'wallet_address');
  if (address == null) throw Exception('No wallet found');
  final response = await http.post(
    Uri.parse('$backendBaseUrl/payment/faucet'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'toWallet': address,
      'amountEth': amount,
    }),
  );
  final data = jsonDecode(response.body);
  return data;
  }
  /// Clear wallet (logout)
  Future<void> clearWallet() async {
    await _storage.delete(key: 'wallet_private_key');
    await _storage.delete(key: 'wallet_address');
  }

  /// Initialize wallet manager (loads keys from storage)
  Future<void> initialize({required int userId}) async {
    // This can be expanded to load user-specific keys if needed
    // For now, just ensure keys are loaded from secure storage
    // Optionally, you could check if keys exist and throw if not
    final address = await _storage.read(key: 'wallet_address');
    final privateKey = await _storage.read(key: 'wallet_private_key');
    // No-op if keys exist; could add logic for userId if multi-user support is needed
  }

  /// Check if wallet exists in secure storage
  Future<bool> hasWallet() async {
    final address = await _storage.read(key: 'wallet_address');
    return address != null && address.isNotEmpty;
  }

  /// Retrieve the wallet public address from secure storage
  Future<String?> getWalletAddress() async {
    return await _storage.read(key: 'wallet_address');
  }
}