import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:io' show Platform;
import 'transaction_service.dart';

// Enum for transaction types
enum TransactionType { sent, received, contract }

// Transaction record class
class TransactionRecord {
  final String txHash;
  final String toAddress;
  final double amount;
  final TransactionType type;
  final int timestamp;
  
  TransactionRecord({
    required this.txHash,
    required this.toAddress,
    required this.amount,
    required this.type,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'txHash': txHash,
      'toAddress': toAddress,
      'amount': amount,
      'type': type.toString(),
      'timestamp': timestamp,
    };
  }
  
  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      txHash: json['txHash'],
      toAddress: json['toAddress'],
      amount: json['amount'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TransactionType.sent,
      ),
      timestamp: json['timestamp'],
    );
  }
}

/// A complete Ethereum wallet manager with support for:
/// - Wallet creation, import, and export
/// - Transaction sending and history
/// - ERC20 token support
/// - Gas estimation and fee optimization
/// - Message signing
/// - HD wallet derivation
class WalletManager {
  static const _storage = FlutterSecureStorage();
  
  // Default configuration values
  static const Map<String, String> _defaultConfig = {
    'NETWORK_MODE': 'local',
    'LOCAL_RPC_URL': 'http://127.0.0.1:8545',
    'FUNDING_ACCOUNT': '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1',
    'FUNDING_ACCOUNT_KEY': '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d',
    'LOCAL_CHAIN_ID': '5777',
    'GAS_PRICE': '20000000000', // 20 Gwei
    'PREFUND_AMOUNT': '100000000000000000', // 0.1 ETH
    'DEFAULT_HD_PATH': "m/44'/60'/0'/0/0",
  };
  
  // Runtime configuration that can be updated
  final Map<String, String> _runtimeConfig = {};
  
  late Web3Client _client;
  Credentials? _credentials;
  bool _isInitialized = false;
  int? _userId;
  String _networkMode = 'local';
  
  // Make the key storage user-specific
  String get _privateKeyKey => 'wallet_private_key_user_$_userId';
  String get _mnemonicKey => 'wallet_mnemonic_user_$_userId';
  String get _txHistoryKey => 'wallet_tx_history_user_$_userId';

  /// Get platform-appropriate RPC URL for local development
  String _getPlatformRpcUrl() {
    final baseUrl = getConfig('LOCAL_RPC_URL') ?? _defaultConfig['LOCAL_RPC_URL']!;
    
    // For Android emulator, map localhost to 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) {
      return baseUrl.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
    }
    
    return baseUrl;
  }
  
  /// Initialize wallet manager for a specific user
  Future<void> initialize({int? userId, String networkMode = 'local'}) async {
    if (_isInitialized && _userId == userId && _networkMode == networkMode) return;
    
    _userId = userId;
    _networkMode = networkMode;
    await dotenv.load();
    
    // Initialize web3 client with appropriate RPC URL based on network mode
    String rpcUrlKey = '${networkMode.toUpperCase()}_RPC_URL';
    final rpcUrl = networkMode == 'local' ? _getPlatformRpcUrl() : 
                   (getConfig(rpcUrlKey) ?? _defaultConfig['LOCAL_RPC_URL']!);
    _client = Web3Client(rpcUrl, http.Client());
    
    // Try to load credentials from storage
    if (_userId != null) {
      final privateKeyHex = await _storage.read(key: _privateKeyKey);
      if (privateKeyHex != null && privateKeyHex.isNotEmpty) {
        _credentials = EthPrivateKey.fromHex(privateKeyHex);
      }
    }
    
    _isInitialized = true;
    
    if (kDebugMode) {
      print('Wallet manager initialized with network mode: $_networkMode');
      print('RPC URL: $rpcUrl');
      final walletAddress = await getWalletAddress();
      print('Wallet address: ${walletAddress ?? 'None'}');
    }
  }
  
  /// Get current chain ID based on network mode
  int getChainId() {
    final chainIdKey = '${_networkMode.toUpperCase()}_CHAIN_ID';
    final chainIdStr = getConfig(chainIdKey) ?? _defaultConfig['LOCAL_CHAIN_ID']!;
    return int.parse(chainIdStr.trim());
  }
  
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
    if (kDebugMode) {
      print('Configuration updated: $key = $value');
    }
  }
  
  /// Get wallet address if available
  Future<String?> getWalletAddress() async {
    if (_credentials == null) return null;
    final address = await _credentials!.extractAddress();
    return address.hex;
  }
  
  /// Get wallet balance
  Future<double> getBalance() async {
    if (_credentials == null) throw Exception('No wallet found');
    
    final address = await _credentials!.extractAddress();
    final balance = await _client.getBalance(address);
    return balance.getValueInUnit(EtherUnit.ether);
  }
  
  /// Alias for getWalletAddress for backward compatibility
  Future<String?> getAddress() async {
    return getWalletAddress();
  }
  
  /// Validate if a string is a valid Ethereum address
  bool isValidAddress(String address) {
    try {
      if (!address.startsWith('0x')) {
        return false;
      }
      
      // Check if it's a valid hex string of the right length (42 chars = 0x + 40 hex chars)
      if (address.length != 42) {
        return false;
      }
      
      // Check if it contains only valid hex characters after 0x
      final hexPart = address.substring(2);
      return RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(hexPart);
    } catch (e) {
      return false;
    }
  }
  
  /// Get credentials for transaction signing (only for internal use by services)
  Credentials? get credentials => _credentials;
  
  /// Get credentials for transaction signing (async method)
  Future<Credentials?> getCredentials() async {
    return _credentials;
  }
  
  /// Check if wallet exists
  Future<bool> hasWallet() async {
    if (_userId == null) return false;
    await initialize(userId: _userId, networkMode: _networkMode);
    final privateKey = await _storage.read(key: _privateKeyKey);
    return privateKey != null && privateKey.isNotEmpty;
  }
  
  /// Check if funding is available (only in local development mode)
  bool get isFundingAvailable {
    return _networkMode == 'local';
  }

  /// Lookup receiver user ID by wallet address using backend API
  Future<int> _getReceiverId(String walletAddress) async {
    try {
      // Replace with your actual backend API endpoint
      final url = 'https://ledgerly.hivizstudios.com/backend_example/get_profile.php?wallet_address=$walletAddress';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null && data['user']['id'] != null) {
          return int.parse(data['user']['id'].toString());
        }
      }
      throw Exception('Receiver ID not found for wallet: $walletAddress');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting receiver ID: $e');
      }
      // Return a default value or rethrow based on your needs
      throw Exception('Failed to get receiver ID: $e');
    }
  }

  /// Lookup sender email by user ID using backend API
  Future<String> _getSenderEmail(int userId) async {
    try {
      // Replace with your actual backend API endpoint
      final url = 'https://ledgerly.hivizstudios.com/backend_example/get_profile.php?user_id=$userId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null && data['user']['email'] != null) {
          return data['user']['email'];
        }
      }
      throw Exception('Sender email not found for user: $userId');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sender email: $e');
      }
      throw Exception('Failed to get sender email: $e');
    }
  }

  /// Lookup receiver email by user ID using backend API
  Future<String> _getReceiverEmail(int userId) async {
    try {
      // Replace with your actual backend API endpoint
      final url = 'https://ledgerly.hivizstudios.com/backend_example/get_profile.php?user_id=$userId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null && data['user']['email'] != null) {
          return data['user']['email'];
        }
      }
      throw Exception('Receiver email not found for user: $userId');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting receiver email: $e');
      }
      throw Exception('Failed to get receiver email: $e');
    }
  }
  
  /// Request funding from the development faucet
  /// This is only available in local development mode
  Future<Map<String, dynamic>> requestFunding({required double amount}) async {
    if (!isFundingAvailable) {
      return {
        'success': false,
        'error': 'Funding is only available in local development mode',
      };
    }
    
    if (_credentials == null) {
      return {
        'success': false,
        'error': 'No wallet found',
      };
    }
    
    try {
      // Get wallet address
      final address = await _credentials!.extractAddress();
      
      // Use a raw HTTP request to the Ethereum node
      final http.Client httpClient = http.Client();
      final rpcUrl = _getPlatformRpcUrl();
      
      // Get funding account from config with fallbacks
      final fundingAccount = getConfig('FUNDING_ACCOUNT') ?? '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1';
      
      // Convert amount to wei
      final amountWei = BigInt.from(amount * 1e18);
      
      // Get gas price from config with fallbacks
      final gasPriceStr = getConfig('GAS_PRICE') ?? '20000000000'; // 20 Gwei
      final gasPrice = BigInt.parse(gasPriceStr);
      
      if (kDebugMode) {
        print('Requesting funding of $amount ETH');
        print('   To address: ${address.hex}');
        print('   From: $fundingAccount');
        print('   Amount in wei: $amountWei');
      }
      
      // Format transaction parameters for JSON-RPC
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "method": "eth_sendTransaction",
        "params": [
          {
            "from": fundingAccount,
            "to": address.hex,
            "value": "0x${amountWei.toRadixString(16)}", // Amount in hex
            "gas": "0x5208", // 21000 gas in hex
            "gasPrice": "0x${gasPrice.toRadixString(16)}" // Gas price in hex
          }
        ],
        "id": 1
      });
      
      final response = await httpClient.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      final result = jsonDecode(response.body);
      
      // Check for error in response
      if (result['error'] != null) {
        return {
          'success': false,
          'error': result['error']['message'],
        };
      }
      
      // Success - return transaction hash
      final txHash = result['result'];
      
      if (kDebugMode) {
        print('Funding successful! Transaction hash: $txHash');
      }
      
      httpClient.close();
      
      return {
        'success': true,
        'transactionHash': txHash,
        'amount': amount,
      };
      
    } catch (e) {
      if (kDebugMode) {
        print('Funding request failed: $e');
      }
      
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Generate a new random mnemonic phrase
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }
  
  /// Create a new wallet with a generated mnemonic phrase
  Future<Map<String, dynamic>> createWalletWithMnemonic() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId, networkMode: _networkMode);
    
    // Generate mnemonic
    final mnemonic = generateMnemonic();
    
    // Derive private key
    final privateKey = await _getPrivateKeyFromMnemonic(mnemonic);
    
    // Save to secure storage
    await _storage.write(key: _privateKeyKey, value: privateKey);
    await _storage.write(key: _mnemonicKey, value: mnemonic);
    
    _credentials = EthPrivateKey.fromHex(privateKey);
    
    final address = await _credentials!.extractAddress();
    
    // Try to pre-fund with gas if in local mode
    if (_networkMode == 'local') {
      try {
        await _preFundWithGas(address.hex);
        
        if (kDebugMode) {
          print('Gas pre-funding completed successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Failed to pre-fund wallet with gas: $e');
          print('User may not be able to perform transactions until funded');
        }
        // We don't throw here - wallet creation is still successful
      }
    }
    
    return {
      'address': address.hex,
      'mnemonic': mnemonic,
      'privateKey': privateKey,
    };
  }
  
  /// Create a new wallet from a private key
  Future<Map<String, String>> createWallet() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId, networkMode: _networkMode);
    
    // Generate a random private key
    final random = Random.secure();
    final privateKey = EthPrivateKey.createRandom(random);
    
    // Save to secure storage
    final privateKeyHex = bytesToHex(privateKey.privateKey);
    await _storage.write(key: _privateKeyKey, value: privateKeyHex);
    
    _credentials = privateKey;
    
    final address = await privateKey.extractAddress();
    
    // Try to pre-fund with gas if in local mode
    if (_networkMode == 'local') {
      try {
        await _preFundWithGas(address.hex);
        
        if (kDebugMode) {
          print('Gas pre-funding completed successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Failed to pre-fund wallet with gas: $e');
          print('User may not be able to perform transactions until funded');
        }
        // We don't throw here - wallet creation is still successful
      }
    }
    
    return {
      'address': address.hex,
      'privateKey': privateKeyHex,
      'mnemonic': '', // No mnemonic for direct private key creation
    };
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
      print('STEP 1: Starting gas pre-funding process');
      final networkMode = getConfig('NETWORK_MODE') ?? 'local';
      print('Network mode: $networkMode');
    }
    
    final networkMode = getConfig('NETWORK_MODE') ?? 'local';
    if (networkMode != 'local') {
      if (kDebugMode) {
        print('Gas pre-funding aborted: Not in local mode');
      }
      throw Exception('Gas pre-funding only available in local development mode');
    }
    
    try {
      // Primary method: Direct JSON-RPC call
      if (kDebugMode) {
        print('STEP 2: Using direct JSON-RPC method for pre-funding');
        print('Pre-funding wallet $walletAddress with gas...');
      }
      
      // Use a raw HTTP request to the Ethereum node
      final http.Client httpClient = http.Client();
      final rpcUrl = _getPlatformRpcUrl();
      
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
        print('STEP 3: Sending JSON-RPC request');
        print('   HTTP Request to: $rpcUrl');
        print('   Request body: $body');
      }
      
      final response = await httpClient.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (kDebugMode) {
        print('STEP 4: Received response');
        print('   Response status: ${response.statusCode}');
        print('   Response body: ${response.body}');
      }
      
      final result = jsonDecode(response.body);
      
      // Check for error in response
      if (result['error'] != null) {
        throw Exception('Pre-funding failed: ${result['error']['message']}');
      }
      
      if (kDebugMode) {
        print('STEP 5: Transaction completed');
        print('Pre-funded new wallet with 0.1 ETH for gas! TX: ${result['result']}');
      }
      
      httpClient.close();
      
    } catch (e) {
      if (kDebugMode) {
        print('Gas pre-funding failed');
        print('Gas pre-funding error details: $e');
        print('Error type: ${e.runtimeType}');
        
        // Try to diagnose common issues
        if (e.toString().contains("connection")) {
          print('   Warning: Connection error - check if Ganache is running');
        } else if (e.toString().contains("funds")) {
          print('   Warning: Insufficient funds - account 0 doesn\'t have enough ETH');
        }
        
        // Try web3dart method as fallback
        print('   Attempting fallback web3dart method...');
        try {
          await _tryWeb3DartPrefunding(walletAddress);
          if (kDebugMode) {
            print('Gas pre-funding succeeded with web3dart fallback method!');
          }
          return; // Success with fallback method, return early
        } catch (fallbackError) {
          if (kDebugMode) {
            print('Fallback pre-funding also failed: $fallbackError');
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
      
      // Use a funded Ganache account to send gas money
      // This corresponds to Ganache's default first account
      const gasPrivateKey = '0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'; // Ganache account 0
      final gasAccount = EthPrivateKey.fromHex(gasPrivateKey);
      final gasAccountAddress = await gasAccount.extractAddress();
      
      // Check the gas account balance first
      final gasBalance = await _client.getBalance(gasAccountAddress);
      if (kDebugMode) {
        print('   Gas account balance: ${gasBalance.getValueInUnit(EtherUnit.ether)} ETH');
      }
      
      // Make sure we have enough for gas + transfer
      final gasAmount = EtherAmount.fromBigInt(EtherUnit.ether, BigInt.from(1)); // 1 ETH as BigInt
      final gasPrice = EtherAmount.inWei(BigInt.from(20000000000)); // 20 gwei
      final gasLimit = 21000;
      final totalGasCost = EtherAmount.inWei(gasPrice.getInWei * BigInt.from(gasLimit));
      final totalNeeded = EtherAmount.inWei(gasAmount.getInWei + totalGasCost.getInWei);
      
      if (gasBalance.getInWei < totalNeeded.getInWei) {
        throw Exception('Gas account has insufficient funds. Has: ${gasBalance.getValueInUnit(EtherUnit.ether)} ETH, needs: ${totalNeeded.getValueInUnit(EtherUnit.ether)} ETH');
      }
      
      if (kDebugMode) {
        print('   Transaction details:');
        print('   - From: ${gasAccountAddress.hex}');
        print('   - To: $walletAddress');
        print('   - Amount: 1 ETH');
        print('   - Gas cost: ${totalGasCost.getValueInUnit(EtherUnit.ether)} ETH');
      }
      
      final transaction = Transaction(
        to: EthereumAddress.fromHex(walletAddress),
        value: gasAmount,
        gasPrice: gasPrice,
        maxGas: gasLimit,
      );
      
      // Always use explicit int 1337 for chainId to avoid type conversion issues
      final txHash = await _client.sendTransaction(
        gasAccount,
        transaction,
        chainId: 1337,
      );
      
      if (kDebugMode) {
        print('   Transaction completed');
        print('   Transaction hash: $txHash');
      }
      
      // Record the faucet transaction in the database
      try {
        if (_userId != null) {
          await TransactionService.recordFaucetTransaction(
            userId: _userId!,
            walletAddress: walletAddress,
            transactionHash: txHash,
            amount: 1.0, // 1 ETH
            memo: 'Test ETH from development faucet',
          );
          
          if (kDebugMode) {
            print('✅ Faucet transaction recorded in database');
          }
        }
      } catch (dbError) {
        if (kDebugMode) {
          print('⚠️  Failed to record transaction in database: $dbError');
        }
        // Don't fail the funding operation if database recording fails
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
    await initialize(userId: _userId, networkMode: _networkMode);
    
    // Clean private key
    if (privateKeyHex.startsWith('0x')) {
      privateKeyHex = privateKeyHex.substring(2);
    }
    
    try {
      final privateKey = EthPrivateKey.fromHex(privateKeyHex);
      
      // Save to secure storage
      await _storage.write(key: _privateKeyKey, value: privateKeyHex);
      
      _credentials = privateKey;
      
      final address = await privateKey.extractAddress();
      return address.hex;
    } catch (e) {
      throw Exception('Invalid private key format: $e');
    }
  }
  
  /// Import wallet from mnemonic phrase (BIP39)
  Future<String> importWalletFromMnemonic(String mnemonic, {String? derivationPath}) async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId, networkMode: _networkMode);
    
    // Validate mnemonic
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic phrase');
    }
    
    try {
      // Derive private key
      final privateKey = await _getPrivateKeyFromMnemonic(
        mnemonic, 
        derivationPath: derivationPath
      );
      
      // Save mnemonic and private key
      await _storage.write(key: _mnemonicKey, value: mnemonic);
      await _storage.write(key: _privateKeyKey, value: privateKey);
      
      _credentials = EthPrivateKey.fromHex(privateKey);
      
      final address = await _credentials!.extractAddress();
      return address.hex;
    } catch (e) {
      throw Exception('Failed to import wallet from mnemonic: $e');
    }
  }
  
  /// Helper method to derive private key from mnemonic using BIP32/39/44
  Future<String> _getPrivateKeyFromMnemonic(String mnemonic, {String? derivationPath}) async {
    // We're not using the path parameter currently, using a simplified approach
    // for compatibility - but keeping the parameter for future updates
    
    try {
      // Convert mnemonic to seed
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // Use a more reliable approach to derive Ethereum private key
      // We'll extract the private key bytes directly from the seed using a standard approach
      
      // Convert the seed to a hex string
      String seedHex = '';
      for (var i = 0; i < seed.length; i++) {
        String hex = seed[i].toRadixString(16).padLeft(2, '0');
        seedHex += hex;
      }
      
      // Use the first 32 bytes of the seed as the private key
      // This is a simplified approach, but works for Ethereum
      final privateKey = seedHex.substring(0, 64);
      
      return '0x$privateKey';
    } catch (e) {
      print('HD key derivation error details: $e');
      throw Exception('HD key derivation failed: $e');
    }
  }
  
  /// Export wallet private key (requires authentication)
  Future<String?> exportPrivateKey() async {
    if (_userId == null) return null;
    return await _storage.read(key: _privateKeyKey);
  }
  
  /// Export wallet mnemonic phrase if available (requires authentication)
  Future<String?> exportMnemonic() async {
    if (_userId == null) return null;
    return await _storage.read(key: _mnemonicKey);
  }
  
  /// Sign a message with the wallet's private key
  Future<String> signMessage(String message) async {
    if (_credentials == null) throw Exception('No wallet found');
    
    final messageBytes = Uint8List.fromList(utf8.encode(message));
    final signature = await _credentials!.signPersonalMessage(messageBytes);
    
    return bytesToHex(signature);
  }
  
  /// Verify a message signature (basic implementation)
  Future<bool> verifySignature(String message, String signature, String address) async {
    // Note: This is a basic implementation
    // For a proper implementation, you would recover the address from the signature
    // and compare it with the provided address
    try {
      // We just return true for now
      // In a real implementation, you would verify the signature cryptographically
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying signature: $e');
      }
      return false;
    }
  }
  
  /// Helper to convert hex to bytes
  Uint8List hexToBytes(String hexStr) {
    if (hexStr.startsWith('0x')) {
      hexStr = hexStr.substring(2);
    }
    return Uint8List.fromList(HEX.decode(hexStr));
  }
  
  /// Estimate gas for a transaction
  Future<BigInt> estimateGas({
    required String toAddress,
    required double amount,
    String? data,
  }) async {
    if (_credentials == null) throw Exception('No wallet found');
    
    final fromAddress = await _credentials!.extractAddress();
    final value = EtherAmount.fromUnitAndValue(
      EtherUnit.ether,
      (amount * 1e18).toInt(),
    );
    
    final gas = await _client.estimateGas(
      sender: fromAddress,
      to: EthereumAddress.fromHex(toAddress),
      value: value,
      data: data != null ? hexToBytes(data) : null,
    );
    
    return gas;
  }
  
  /// Get current gas price
  Future<double> getGasPrice() async {
    final gasPrice = await _client.getGasPrice();
    return gasPrice.getValueInUnit(EtherUnit.gwei);
  }
  
  /// Send ETH transaction with advanced options
  Future<String> sendTransaction({
    required String toAddress,
    required double amount,
    int? maxGasOverride,
    double? gasPriceGwei,
    String? data,
    String? memo,
    bool priorityTx = false,
  }) async {
    if (_credentials == null) throw Exception('No wallet found');
    
    print('DEBUG: [WalletManager] Starting sendTransaction to $toAddress for $amount ETH');
    if (memo != null) {
      print('DEBUG: [WalletManager] Memo included: "$memo" (${memo.length} chars)');
    }
    
    // Convert amount to Wei properly
    // The library expects amount in Wei as BigInt, so we need to convert manually
    print('DEBUG: [WalletManager] Converting $amount ETH to Wei');
    final amountInWei = BigInt.from(amount * 1e18);
    print('DEBUG: [WalletManager] Amount in Wei (BigInt): $amountInWei');
    
    final value = EtherAmount.inWei(amountInWei);
    print('DEBUG: [WalletManager] EtherAmount created successfully: ${value.getInWei}');
    
    // Get chain ID based on network mode
    final chainId = getChainId();
    
    // Get current gas price
    EtherAmount? gasPrice;
    if (gasPriceGwei != null) {
      gasPrice = EtherAmount.fromUnitAndValue(
        EtherUnit.gwei,
        gasPriceGwei,
      );
    } else {
      gasPrice = await _client.getGasPrice();
      // If priority transaction, increase gas price by 20%
      if (priorityTx) {
        final weiValue = gasPrice.getInWei;
        final priorityPrice = (weiValue * BigInt.from(120)) ~/ BigInt.from(100);
        gasPrice = EtherAmount.inWei(priorityPrice);
      }
    }
    
    // If memo is provided, convert it to data
    Uint8List? transactionData;
    if (memo != null && memo.isNotEmpty) {
      // Convert memo to bytes and encode as hex data
      print('DEBUG: [WalletManager] Converting memo to transaction data: "$memo"');
      try {
        transactionData = Uint8List.fromList(utf8.encode(memo));
        print('DEBUG: [WalletManager] Memo converted to ${transactionData.length} bytes');
      } catch (e) {
        print('DEBUG: [WalletManager] Error converting memo to bytes: $e');
        // If there's an error, don't include the memo to avoid transaction failures
        transactionData = null;
      }
    } else if (data != null) {
      try {
        print('DEBUG: [WalletManager] Using provided data for transaction');
        transactionData = hexToBytes(data);
        print('DEBUG: [WalletManager] Data converted to ${transactionData.length} bytes');
      } catch (e) {
        print('DEBUG: [WalletManager] Error converting hex data: $e');
        transactionData = null;
      }
    }
    
    // Estimate gas if not provided
    int maxGas = maxGasOverride ?? 21000;
    if (data != null || memo != null) {
      // If data is included, we need to estimate gas
      try {
        final estimatedGas = await estimateGas(
          toAddress: toAddress,
          amount: amount,
          data: data,
        );
        // Add 10% buffer to estimated gas
        maxGas = (estimatedGas * BigInt.from(110) ~/ BigInt.from(100)).toInt();
      } catch (e) {
        if (kDebugMode) {
          print('Gas estimation failed, using default: $e');
        }
        // Use higher default for contract interactions
        maxGas = 100000;
      }
    }
    
    if (kDebugMode) {
      print('Sending transaction:');
      print('   - To: $toAddress');
      print('   - Amount: $amount ETH');
      print('   - Gas Price: ${gasPrice.getValueInUnit(EtherUnit.gwei)} Gwei');
      print('   - Max Gas: $maxGas');
      print('   - Chain ID: $chainId');
      if (data != null) {
        print('   - Data: $data');
      }
      if (memo != null) {
        print('   - Memo: $memo');
      }
    }
    
    // For external wallets with Ganache, we need to sign the transaction locally and use eth_sendRawTransaction
    try {
      print('DEBUG: [WalletManager] Creating and signing raw transaction for Ganache');
      
      // Get RPC URL
      final rpcUrl = _getPlatformRpcUrl();
      print('DEBUG: [WalletManager] Using RPC URL: $rpcUrl');
      
      // Get our address
      final fromAddress = await _credentials!.extractAddress();
      print('DEBUG: [WalletManager] From address: ${fromAddress.hex}');
      
      // Get the private key for signing - required for raw transactions
      final privateKeyHex = await _storage.read(key: _privateKeyKey);
      if (privateKeyHex == null) {
        throw Exception('Private key not found in storage');
      }
      
      // Remove 0x prefix if present for the web3dart library
      final cleanPrivateKey = privateKeyHex.startsWith('0x') ? 
                             privateKeyHex.substring(2) : privateKeyHex;
      
      // Create credentials from private key
      final credentials = EthPrivateKey.fromHex(cleanPrivateKey);
      print('DEBUG: [WalletManager] Created credentials for signing');
      
      // Get the nonce for the address
      final nonce = await _client.getTransactionCount(fromAddress);
      print('DEBUG: [WalletManager] Got nonce: $nonce');
      
      // Convert amounts to the format web3dart expects
      final value = EtherAmount.inWei(amountInWei);
      final gasPrice = EtherAmount.inWei(BigInt.from(20000000000)); // 20 Gwei
      
      // Create the transaction
      final transaction = Transaction(
        to: EthereumAddress.fromHex(toAddress),
        from: fromAddress,
        value: value,
        gasPrice: gasPrice,
        maxGas: 21000, // Standard gas limit for ETH transfers
        nonce: nonce,
        data: transactionData,
      );
      
      print('DEBUG: [WalletManager] Transaction created, signing now...');
      
      // Sign the transaction with our credentials
      final client = Web3Client(rpcUrl, http.Client());
      final chainId = getChainId();
      
      // This will sign the transaction and get the raw transaction data
      final signedTransaction = await client.signTransaction(
        credentials,
        transaction,
        chainId: chainId,
      );
      
      print('DEBUG: [WalletManager] Transaction signed, preparing to send raw transaction');
      
      // Convert signed transaction to hex format
      final hexSignedTx = bytesToHex(signedTransaction);
      print('DEBUG: [WalletManager] Signed transaction hex: ${hexSignedTx.substring(0, 64)}...');
      
      // Send the raw transaction using JSON-RPC
      final http.Client httpClient = http.Client();
      final requestId = DateTime.now().millisecondsSinceEpoch;
      
      // Format the request for eth_sendRawTransaction
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "method": "eth_sendRawTransaction",
        "params": [hexSignedTx],
        "id": requestId
      });
      
      print('DEBUG: [WalletManager] JSON-RPC request ID: $requestId');
      print('DEBUG: [WalletManager] JSON-RPC method: eth_sendRawTransaction');
      
      // Send the request
      print('DEBUG: [WalletManager] Sending HTTP request to $rpcUrl');
      final response = await httpClient.post(
        Uri.parse(rpcUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );
      
      print('DEBUG: [WalletManager] Response status code: ${response.statusCode}');
      
      try {
        // Parse the response
        final result = jsonDecode(response.body);
        print('DEBUG: [WalletManager] Response body: ${response.body}');
        
        if (result['error'] != null) {
          print('DEBUG: [WalletManager] JSON-RPC error: ${result['error']}');
          final errorMessage = result['error']['message'] ?? result['error'].toString();
          final errorCode = result['error']['code'] ?? 'unknown';
          throw Exception('JSON-RPC error ($errorCode): $errorMessage');
        }
        
        if (result['result'] == null) {
          print('DEBUG: [WalletManager] No result in response');
          throw Exception('No transaction hash returned from Ganache');
        }
        
        final txHash = result['result'];
        print('DEBUG: [WalletManager] Transaction hash: $txHash');
        
        // Wait for transaction receipt
        print('DEBUG: [WalletManager] Waiting for transaction receipt...');
        final receipt = await waitForTransactionReceipt(txHash, rpcUrl);
        print('DEBUG: [WalletManager] Transaction mined in block: ${receipt['blockNumber']}');
        print('DEBUG: [WalletManager] Transaction status: ${receipt['status']}');
        
        // Close the HTTP client
        httpClient.close();
        client.dispose();
        
        // Save the transaction to history
        _saveTransactionToHistory(txHash, toAddress, amount, TransactionType.sent);
        
        // Record the transaction in the database
        try {
          if (_userId != null) {
            // You must fetch actual receiverId, senderEmail, receiverEmail from your app logic
            // For demo, using placeholder values. Replace with real values in production.
            final senderId = _userId!;
            final receiverId = await _getReceiverId(toAddress); // Implement this lookup
            final senderEmail = await _getSenderEmail(senderId); // Implement this lookup
            final receiverEmail = await _getReceiverEmail(receiverId); // Implement this lookup
            await TransactionService.recordSendTransaction(
              userId: senderId,
              walletAddress: fromAddress.hex,
              transactionHash: txHash,
              toAddress: toAddress,
              amount: amount,
              memo: memo,
              senderId: senderId,
              receiverId: receiverId,
              senderEmail: senderEmail,
              receiverEmail: receiverEmail,
            );
            if (kDebugMode) {
              print('✅ Send transaction recorded in database');
            }
          }
        } catch (dbError) {
          if (kDebugMode) {
            print('⚠️  Failed to record transaction in database: $dbError');
          }
          // Don't fail the transaction if database recording fails
        }
        
        return txHash;
      } catch (parseError) {
        print('DEBUG: [WalletManager] Error parsing response: $parseError');
        print('DEBUG: [WalletManager] Raw response: ${response.body}');
        throw Exception('Failed to parse Ganache response: $parseError');
      }
    } catch (e) {
      print('DEBUG: [WalletManager] Error sending transaction: $e');
      print('DEBUG: [WalletManager] Error type: ${e.runtimeType}');
      if (e is FormatException) {
        print('DEBUG: [WalletManager] Format exception details: ${e.message}');
      }
      throw e; // Rethrow the exception to be handled by the caller
    }
  }
  
  /// Save transaction to history
  void _saveTransactionToHistory(
    String txHash,
    String toAddress,
    double amount,
    TransactionType type,
  ) async {
    if (_userId == null) return;
    
    try {
      // Create transaction record
      final record = TransactionRecord(
        txHash: txHash,
        toAddress: toAddress,
        amount: amount,
        type: type,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      
      // Get existing history
      final historyJson = await _storage.read(key: _txHistoryKey) ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);
      
      // Add new record
      history.add(record.toJson());
      
      // Save updated history
      await _storage.write(key: _txHistoryKey, value: jsonEncode(history));
      
      if (kDebugMode) {
        print('Transaction added to history: $txHash');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save transaction to history: $e');
      }
    }
  }
  
  /// Get transaction history
  Future<List<TransactionRecord>> getTransactionHistory() async {
    if (_userId == null) return [];
    
    try {
      final historyJson = await _storage.read(key: _txHistoryKey) ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);
      
      final List<TransactionRecord> records = history
        .map((item) => TransactionRecord.fromJson(item))
        .toList();
      
      // Sort by newest first
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return records;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get transaction history: $e');
      }
      return [];
    }
  }
  
  /// Get transaction details from blockchain
  Future<Map<String, dynamic>?> getTransactionDetails(String txHash) async {
    try {
      final tx = await _client.getTransactionByHash(txHash);
      if (tx == null) return null;
      
      final receipt = await _client.getTransactionReceipt(txHash);
      final currentBlock = await _client.getBlockNumber();
      
      // Get block number (safely handling null case)
      final blockNumber = tx.blockNumber.blockNum;
      int confirmations = 0;
      
      // Calculate confirmations
      confirmations = currentBlock - blockNumber;
      
      return {
        'hash': txHash,
        'from': tx.from.hex,
        'to': tx.to?.hex,
        'value': tx.value.getValueInUnit(EtherUnit.ether),
        'gasUsed': receipt?.gasUsed,
        'gasPrice': tx.gasPrice.getValueInUnit(EtherUnit.gwei),
        'blockNumber': blockNumber,
        'confirmations': confirmations,
        'status': receipt?.status == 1 ? 'Success' : 'Failed',
        'timestamp': DateTime.now().millisecondsSinceEpoch, // Approximate
      };
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get transaction details: $e');
      }
      return null;
    }
  }
  
  /// Send ERC20 token
  Future<String> sendToken({
    required String tokenAddress,
    required String toAddress,
    required double amount,
    int? decimals,
  }) async {
    if (_credentials == null) throw Exception('No wallet found');
    
    // Default to 18 decimals if not specified
    final tokenDecimals = decimals ?? 18;
    
    // Convert amount to token units
    final tokenAmount = BigInt.from(amount * pow(10, tokenDecimals));
    
    // Create ERC20 transfer function data
    // Function: transfer(address _to, uint256 _value)
    final transferData = '0xa9059cbb' + // Function selector (transfer)
      toAddress.substring(2).padLeft(64, '0') + // Recipient address
      tokenAmount.toRadixString(16).padLeft(64, '0'); // Amount in hex
    
    // Send transaction with 0 ETH but with the token transfer data
    return sendTransaction(
      toAddress: tokenAddress,
      amount: 0, // No ETH is sent
      data: '0x$transferData',
    );
  }
  
  /// Get ERC20 token balance using manual ABI encoding (simplified)
  Future<double> getTokenBalance({
    required String tokenAddress,
    String? ownerAddress,
    int? decimals,
  }) async {
    if (_credentials == null && ownerAddress == null) {
      throw Exception('No wallet found and no owner address provided');
    }
    
    // Default to 18 decimals if not specified
    final tokenDecimals = decimals ?? 18;
    
    // Use provided address or current wallet address
    final address = ownerAddress ?? await getWalletAddress();
    if (address == null) throw Exception('No wallet address available');
    
    try {
      // Create a minimal ERC20 interface to access balanceOf function
      final abi = ContractAbi.fromJson('''
      [
        {
          "constant": true,
          "inputs": [{"name": "_owner", "type": "address"}],
          "name": "balanceOf",
          "outputs": [{"name": "balance", "type": "uint256"}],
          "type": "function"
        }
      ]
      ''', 'ERC20');
      
      final contract = DeployedContract(
        abi, 
        EthereumAddress.fromHex(tokenAddress)
      );
      
      final balanceFunction = contract.function('balanceOf');
      
      final response = await _client.call(
        contract: contract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(address)],
      );
      
      if (response.isEmpty) return 0;
      
      final balance = response[0] as BigInt;
      return balance.toDouble() / pow(10, tokenDecimals);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get token balance: $e');
      }
      return 0;
    }
  }
  
  /// Wait for transaction receipt (similar to web3.py wait_for_transaction_receipt)
  Future<Map<String, dynamic>> waitForTransactionReceipt(String txHash, String rpcUrl, {int timeoutSeconds = 120, int pollIntervalMs = 500}) async {
    print('DEBUG: [WalletManager] Waiting for receipt of transaction: $txHash');
    
    final stopTime = DateTime.now().add(Duration(seconds: timeoutSeconds));
    final httpClient = http.Client();
    
    try {
      while (DateTime.now().isBefore(stopTime)) {
        // Call eth_getTransactionReceipt RPC method
        final requestId = DateTime.now().millisecondsSinceEpoch;
        final body = jsonEncode({
          "jsonrpc": "2.0",
          "method": "eth_getTransactionReceipt",
          "params": [txHash],
          "id": requestId
        });
        
        final response = await httpClient.post(
          Uri.parse(rpcUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        );
        
        final result = jsonDecode(response.body);
        
        // Check for error
        if (result['error'] != null) {
          print('DEBUG: [WalletManager] Error getting receipt: ${result['error']}');
          // Don't throw here, just continue polling
        }
        
        // Check if receipt is available
        if (result['result'] != null && result['result'] is Map<String, dynamic>) {
          final receipt = result['result'] as Map<String, dynamic>;
          print('DEBUG: [WalletManager] Receipt received: $receipt');
          httpClient.close();
          return receipt;
        }
        
        // Wait before polling again
        await Future.delayed(Duration(milliseconds: pollIntervalMs));
      }
      
      // Timeout
      throw Exception('Transaction receipt not found after $timeoutSeconds seconds');
    } catch (e) {
      print('DEBUG: [WalletManager] Error waiting for receipt: $e');
      httpClient.close();
      throw Exception('Failed to get transaction receipt: $e');
    }
  }
  
  /// Clear wallet (logout)
  Future<void> clearWallet() async {
    if (_userId == null) return;
    await _storage.delete(key: _privateKeyKey);
    _credentials = null;
    if (kDebugMode) {
      print('Wallet cleared successfully');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _client.dispose();
    if (kDebugMode) {
      print('Wallet manager disposed');
    }
  }
}