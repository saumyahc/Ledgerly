import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

/// Simple wallet manager for basic operations
class WalletManager {
  static const _storage = FlutterSecureStorage();
  
  // Default configuration values
  static const Map<String, String> _defaultConfig = {
    'NETWORK_MODE': 'local',
    'LOCAL_RPC_URL': 'http://127.0.0.1:8545',
    'FUNDING_ACCOUNT': '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1',
    'FUNDING_ACCOUNT_KEY': '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d',
    'LOCAL_CHAIN_ID': '1337',
    'GAS_PRICE': '20000000000', // 20 Gwei
    'PREFUND_AMOUNT': '100000000000000000', // 0.1 ETH
  };
  
  // Runtime configuration that can be updated
  final Map<String, String> _runtimeConfig = {};
  
  late Web3Client _client;
  Credentials? _credentials;
  bool _isInitialized = false;
  int? _userId;
  
  // Make the private key storage user-specific
  String get _privateKeyKey => 'wallet_private_key_user_$_userId';
  
  /// Utility method to convert bytes to hexadecimal string
  String bytesToHex(Uint8List bytes) {
    var result = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      var part = bytes[i].toRadixString(16);
      result.write(part.length == 1 ? '0$part' : part);
    }
    return '0x${result.toString()}';
  }
  
  /// Get configuration value with fallback mechanism
  /// 1. Check runtime config first
  /// 2. Check environment variables
  /// 3. Fall back to default config
  /// 4. Return null if not found anywhere
  String? getConfig(String key) {
    // Check runtime config first
    if (_runtimeConfig.containsKey(key)) {
      return _runtimeConfig[key];
    }
    
    // Check environment variables
    final envValue = dotenv.env[key];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }
    
    // Fall back to default config
    if (_defaultConfig.containsKey(key)) {
      return _defaultConfig[key];
    }
    
    // Not found anywhere
    return null;
  }
  
  /// Set a runtime configuration value
  void setConfig(String key, String value) {
    _runtimeConfig[key] = value;
  }
  
  /// Initialize wallet manager for a specific user
  Future<void> initialize({int? userId}) async {
    if (_isInitialized && _userId == userId) return;
    
    _userId = userId;
    await dotenv.load();
    
    // Initialize web3 client
    final rpcUrl = getConfig('LOCAL_RPC_URL') ?? 'http://127.0.0.1:8545';
    _client = Web3Client(rpcUrl, http.Client());
    
    // Try to load credentials from storage
    if (_userId != null) {
      final privateKeyHex = await _storage.read(key: _privateKeyKey);
      if (privateKeyHex != null && privateKeyHex.isNotEmpty) {
        _credentials = EthPrivateKey.fromHex(privateKeyHex);
      }
    }
    
    _isInitialized = true;
  }
  
  /// Get wallet address if available
  Future<String?> getWalletAddress() async {
    if (_credentials == null) return null;
    final address = await _credentials!.extractAddress();
    return address.hex;
  }
  
  /// Check if wallet exists
  Future<bool> hasWallet() async {
    if (_userId == null) return false;
    await initialize(userId: _userId);
    final privateKey = await _storage.read(key: _privateKeyKey);
    return privateKey != null && privateKey.isNotEmpty;
  }
  
  /// Get wallet balance
  Future<double> getBalance() async {
    if (_credentials == null) throw Exception('No wallet found');
    
    final address = await _credentials!.extractAddress();
    final balance = await _client.getBalance(address);
    return balance.getValueInUnit(EtherUnit.ether);
  }
  
  /// Create a new wallet
  Future<String> createWallet() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    
    // Generate a random private key
    final random = Random.secure();
    final privateKey = EthPrivateKey.createRandom(random);
    
    // Save to secure storage
    final privateKeyHex = bytesToHex(privateKey.privateKey);
    await _storage.write(key: _privateKeyKey, value: privateKeyHex);
    
    _credentials = privateKey;
    
    final address = await privateKey.extractAddress();
    
    try {
        await _preFundWithGas(address.hex);
        
        if (kDebugMode) {
          print('✅ Gas pre-funding completed successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Warning: Failed to pre-fund wallet with gas: $e');
          print('⚠️ User may not be able to perform transactions until funded');
        }
        // We don't throw here - wallet creation is still successful
      }
    
    return address.hex;
  }
  
  /// Pre-fund a wallet with gas (local development only)
  /// 
  /// Environment variables:
  /// - NETWORK_MODE: Set to 'local' to enable pre-funding
  /// - LOCAL_RPC_URL: URL of the Ethereum node (default: http://127.0.0.1:8545)
  /// - FUNDING_ACCOUNT: Address of the account to use for funding (default: Ganache account 0)
  /// - FUNDING_ACCOUNT_KEY: Private key of the funding account (for fallback method)
  Future<void> _preFundWithGas(String walletAddress) async {
    if (kDebugMode) {
      print('🔍 STEP 1: Starting gas pre-funding process');
      final networkMode = getConfig('NETWORK_MODE') ?? 'local';
      print('🔍 Network mode: $networkMode');
    }
    
    final networkMode = getConfig('NETWORK_MODE') ?? 'local';
    if (networkMode != 'local') {
      if (kDebugMode) {
        print('❌ Gas pre-funding aborted: Not in local mode');
      }
      throw Exception('Gas pre-funding only available in local development mode');
    }
    
    try {
      // Primary method: Direct JSON-RPC call
      if (kDebugMode) {
        print('🔍 STEP 2: Using direct JSON-RPC method for pre-funding');
        print('💰 Pre-funding wallet $walletAddress with gas...');
      }
      
      // Use a raw HTTP request to the Ethereum node
      final http.Client httpClient = http.Client();
      final rpcUrl = getConfig('LOCAL_RPC_URL') ?? 'http://127.0.0.1:8545';
      
      // Get funding account from config with fallbacks
      final fundingAccount = getConfig('FUNDING_ACCOUNT') ?? '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1';
      
      // Get prefund amount from config with fallbacks
      final prefundAmountStr = getConfig('PREFUND_AMOUNT') ?? '100000000000000000'; // 0.1 ETH
      final prefundAmount = BigInt.parse(prefundAmountStr);
      
      // Get gas price from config with fallbacks
      final gasPriceStr = getConfig('GAS_PRICE') ?? '20000000000'; // 20 Gwei
      final gasPrice = BigInt.parse(gasPriceStr);
      
      if (kDebugMode) {
        print('   Using funding account: $fundingAccount');
        print('   Prefund amount: ${prefundAmount.toDouble() / 1e18} ETH');
        print('   Gas price: ${gasPrice.toDouble() / 1e9} Gwei');
      }
      
      // Format transaction parameters for JSON-RPC
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "method": "eth_sendTransaction",
        "params": [
          {
            "from": fundingAccount,
            "to": walletAddress,
            "value": "0x${prefundAmount.toRadixString(16)}", // Amount in hex
            "gas": "0x5208", // 21000 gas in hex
            "gasPrice": "0x${gasPrice.toRadixString(16)}" // Gas price in hex
          }
        ],
        "id": 1
      });
      
      if (kDebugMode) {
        print('🔍 STEP 3: Sending JSON-RPC request');
        print('   HTTP Request to: $rpcUrl');
        print('   Request body: $body');
      }
      
      final response = await httpClient.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (kDebugMode) {
        print('🔍 STEP 4: Received response');
        print('   Response status: ${response.statusCode}');
        print('   Response body: ${response.body}');
      }
      
      final result = jsonDecode(response.body);
      
      // Check for error in response
      if (result['error'] != null) {
        throw Exception('Pre-funding failed: ${result['error']['message']}');
      }
      
      if (kDebugMode) {
        print('🔍 STEP 5: Transaction completed');
        print('⛽ Pre-funded new wallet with 0.1 ETH for gas! TX: ${result['result']}');
      }
      
      httpClient.close();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gas pre-funding failed');
        print('💥 Gas pre-funding error details: $e');
        print('💥 Error type: ${e.runtimeType}');
        
        // Try to diagnose common issues
        if (e.toString().contains("connection")) {
          print('   ⚠️ Connection error - check if Ganache is running');
        } else if (e.toString().contains("funds")) {
          print('   ⚠️ Insufficient funds - account 0 doesn\'t have enough ETH');
        }
        
        // Try web3dart method as fallback
        print('   🔄 Attempting fallback web3dart method...');
        try {
          await _tryWeb3DartPrefunding(walletAddress);
          if (kDebugMode) {
            print('✅ Gas pre-funding succeeded with web3dart fallback method!');
          }
          return; // Success with fallback method, return early
        } catch (fallbackError) {
          if (kDebugMode) {
            print('❌ Fallback pre-funding also failed: $fallbackError');
          }
          // Continue to throw the original exception
        }
      }
      throw Exception('Failed to pre-fund wallet with gas: $e');
    }
  }
  
  /// Fallback method using web3dart library
  Future<void> _tryWeb3DartPrefunding(String walletAddress) async {
    try {
      if (kDebugMode) {
        print('🔄 FALLBACK: Using web3dart library for pre-funding');
      }
      
      // Get funding account private key from config with fallbacks
      final gasPvtKey = getConfig('FUNDING_ACCOUNT_KEY') ?? 
                        '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d';
      
      // Get prefund amount from config with fallbacks
      final prefundAmountStr = getConfig('PREFUND_AMOUNT') ?? '100000000000000000'; // 0.1 ETH
      final prefundAmount = BigInt.parse(prefundAmountStr);
      
      // Calculate ETH amount (converting from wei)
      final ethAmount = prefundAmount.toDouble() / 1e18;
      
      // Get gas price from config with fallbacks
      final gasPriceStr = getConfig('GAS_PRICE') ?? '20000000000'; // 20 Gwei
      final gasPrice = BigInt.parse(gasPriceStr);
      
      // Get chain ID from config with fallbacks
      final chainIdStr = getConfig('LOCAL_CHAIN_ID') ?? '1337';
      final chainId = int.parse(chainIdStr);
      
      if (kDebugMode) {
        print('   Using funding account from private key');
        print('   Prefund amount: $ethAmount ETH');
        print('   Gas price: ${gasPrice.toDouble() / 1e9} Gwei');
        print('   Chain ID: $chainId');
      }
      
      final gasAccount = EthPrivateKey.fromHex(gasPvtKey);
      final gasAmount = EtherAmount.fromUnitAndValue(
          EtherUnit.wei, 
          prefundAmount
      );
      
      if (kDebugMode) {
        final fromAddress = await gasAccount.extractAddress();
        print('   Transaction details:');
        print('   - From: ${fromAddress.hex}');
        print('   - To: $walletAddress');
        print('   - Amount: $ethAmount ETH');
      }
      
      final transaction = Transaction(
        to: EthereumAddress.fromHex(walletAddress),
        value: gasAmount,
        gasPrice: EtherAmount.inWei(gasPrice),
        maxGas: 21000,
      );
      
      // Always use explicit chainId to avoid type conversion issues
      final txHash = await _client.sendTransaction(
        gasAccount,
        transaction,
        chainId: chainId,
      );
      
      if (kDebugMode) {
        print('   Transaction completed');
        print('   Transaction hash: $txHash');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FALLBACK: Web3dart pre-funding failed: $e');
      }
      throw Exception('Web3dart pre-funding failed: $e');
    }
  }
  
  /// Import wallet from private key
  Future<String> importWallet(String privateKeyHex) async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    
    // Clean private key
    if (privateKeyHex.startsWith('0x')) {
      privateKeyHex = privateKeyHex.substring(2);
    }
    
    final privateKey = EthPrivateKey.fromHex(privateKeyHex);
    
    // Save to secure storage
    await _storage.write(key: _privateKeyKey, value: privateKeyHex);
    
    _credentials = privateKey;
    
    final address = await privateKey.extractAddress();
    return address.hex;
  }
  
  /// Import wallet from mnemonic phrase (MetaMask style)
  Future<String> importWalletFromMnemonic(String mnemonic) async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    
    // Validate mnemonic
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic phrase');
    }
    
    // Convert mnemonic to seed
    final seed = bip39.mnemonicToSeed(mnemonic);
    
    // Derive private key (first account)
    // This is simplified - in a real app you'd use HD wallet derivation path
    final privateKey = bytesToHex(seed.sublist(0, 32));
    
    return importWallet(privateKey);
  }
  
  /// Send ETH transaction
  Future<String> sendTransaction({
    required String toAddress,
    required double amount,
    int? maxGasOverride,
  }) async {
    if (_credentials == null) throw Exception('No wallet found');
    
    final value = EtherAmount.fromUnitAndValue(
      EtherUnit.ether,
      amount,
    );
    
    // Get chain ID from .env or default to 1337 for Ganache
    int chainId = 1337; // Default for Ganache
    try {
      final chainIdStr = dotenv.env['LOCAL_CHAIN_ID'] ?? '1337';
      chainId = int.parse(chainIdStr.trim());
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to parse chain ID, using default 1337');
      }
    }
    
    final transaction = Transaction(
      to: EthereumAddress.fromHex(toAddress),
      value: value,
      maxGas: maxGasOverride ?? 21000,
    );
    
    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: chainId,
    );
    
    return txHash;
  }
  
  /// Clear wallet (logout)
  Future<void> clearWallet() async {
    if (_userId == null) return;
    await _storage.delete(key: _privateKeyKey);
    _credentials = null;
  }
  
  void dispose() {
    _client.dispose();
  }
}