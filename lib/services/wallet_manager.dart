import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class WalletManager {
  static const _storage = FlutterSecureStorage();

  String get backendBaseUrl => ApiConstants.middlewareBaseUrl;

  /// Create a new wallet via backend
  Future<Map<String, dynamic>> createWallet() async {
    print('[WalletManager] Sending wallet create request...');
    final response = await http.post(
      Uri.parse('$backendBaseUrl/wallet/create'),
      headers: {'Content-Type': 'application/json'},
    );
    print('[WalletManager] Received response: ${response.body}');
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      print('[WalletManager] Writing privateKey and address to secure storage...');
      await _storage.write(key: 'wallet_private_key', value: data['privateKey']);
      await _storage.write(key: 'wallet_address', value: data['address']);
      print('[WalletManager] Wallet saved: address=${data['address']}');
      return data;
    } else {
      print('[WalletManager] Wallet creation failed: ${data['error']}');
      throw Exception(data['error'] ?? 'Failed to create wallet');
    }
  }

  /// Import wallet from private key via backend
  Future<Map<String, dynamic>> importWallet(String privateKey) async {
    print('[WalletManager] Sending wallet import request...');
    final response = await http.post(
      Uri.parse('$backendBaseUrl/wallet/import'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'privateKey': privateKey}),
    );
    print('[WalletManager] Received response: ${response.body}');
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      print('[WalletManager] Writing imported privateKey and address to secure storage...');
      await _storage.write(key: 'wallet_private_key', value: privateKey);
      await _storage.write(key: 'wallet_address', value: data['address']);
      print('[WalletManager] Wallet imported: address=${data['address']}');
      return data;
    } else {
      print('[WalletManager] Wallet import failed: ${data['error']}');
      throw Exception(data['error'] ?? 'Failed to import wallet');
    }
  }

  Future<bool> validateAddress(String address) async {
    print('[WalletManager] Validating address: $address');
    final response = await http.get(
      Uri.parse('$backendBaseUrl/wallet/validate/$address'),
    );
    print('[WalletManager] Received response: ${response.body}');
    final data = jsonDecode(response.body);
    return data['success'] == true && data['isValid'] == true;
  }

  /// Export wallet info (address/privateKey) from local storage
  Future<Map<String, String?>> exportWallet() async {
    print('[WalletManager] Exporting wallet from secure storage...');
    final privateKey = await _storage.read(key: 'wallet_private_key');
    final address = await _storage.read(key: 'wallet_address');
    print('[WalletManager] Exported wallet: address=$address, privateKey=${privateKey != null ? "****" : "null"}');
    return {'privateKey': privateKey, 'address': address};
  }

  /// Get wallet balance via backend
  Future<double> getBalance() async {
    final address = await _storage.read(key: 'wallet_address');
    print('[WalletManager] Getting balance for address: $address');
    if (address == null) throw Exception('No wallet found');
    final response = await http.get(
      Uri.parse('$backendBaseUrl/wallet/balance/$address'),
    );
    print('[WalletManager] Received response: ${response.body}');
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      print('[WalletManager] Balance: ${data['balance']}');
      return double.parse(data['balance'].toString());
    } else {
      print('[WalletManager] Failed to get balance: ${data['error']}');
      throw Exception(data['error'] ?? 'Failed to get balance');
    }
  }

  /// Send ETH payment via backend
  Future<String> sendTransaction({
    required String toAddress,
    required double amount,
    String? memo,
  }) async {
    print('[WalletManager] Sending transaction to $toAddress for $amount ETH...');
    final response = await http.post(
      Uri.parse('$backendBaseUrl/payment/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'toWallet': toAddress,
        'amountEth': amount,
        'memo': memo,
      }),
    );
    print('[WalletManager] Received response: ${response.body}');
    final data = jsonDecode(response.body);
    if (data['txHash'] != null) {
      print('[WalletManager] Transaction sent: txHash=${data['txHash']}');
      return data['txHash'];
    } else {
      print('[WalletManager] Transaction failed: ${data['error']}');
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
    print('[WalletManager] Sending payment by email from $fromEmail to $toEmail for $amount ETH...');
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
    print('[WalletManager] Received response: ${response.body}');
    final data = jsonDecode(response.body);
    if (data['txHash'] != null) {
      print('[WalletManager] Email payment sent: txHash=${data['txHash']}');
      return data['txHash'];
    } else {
      print('[WalletManager] Email payment failed: ${data['error']}');
      throw Exception(data['error'] ?? 'Failed to send payment by email');
    }
  }

  /// Request faucet funding via backend
  Future<Map<String, dynamic>> requestFunding(double amount) async {
    final address = await _storage.read(key: 'wallet_address');
    print('[WalletManager] Requesting faucet funding for $amount ETH to address: $address');
    if (address == null) throw Exception('No wallet found');
    final response = await http.post(
      Uri.parse('$backendBaseUrl/payment/faucet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'toWallet': address,
        'amountEth': amount,
      }),
    );
    print('[WalletManager] Received response: ${response.body}');
    final data = jsonDecode(response.body);
    return data;
  }

  /// Clear wallet (logout)
  Future<void> clearWallet() async {
    print('[WalletManager] Clearing wallet from secure storage...');
    await _storage.delete(key: 'wallet_private_key');
    await _storage.delete(key: 'wallet_address');
    print('[WalletManager] Wallet cleared.');
  }

  /// Initialize wallet manager (loads keys from storage)
  Future<void> initialize({required int userId}) async {
    print('[WalletManager] Initializing wallet manager for userId: $userId');
    final address = await _storage.read(key: 'wallet_address');
    final privateKey = await _storage.read(key: 'wallet_private_key');
    print('[WalletManager] Loaded from storage: address=$address, privateKey=${privateKey != null ? "****" : "null"}');
    // No-op if keys exist; could add logic for userId if multi-user support is needed
  }

  /// Check if wallet exists in secure storage
  Future<bool> hasWallet() async {
    final address = await _storage.read(key: 'wallet_address');
    print('[WalletManager] hasWallet check: address=$address');
    return address != null && address.isNotEmpty;
  }

  /// Retrieve the wallet public address from secure storage
  Future<String?> getWalletAddress() async {
    final address = await _storage.read(key: 'wallet_address');
    print('[WalletManager] getWalletAddress: $address');
    return address;
  }
}