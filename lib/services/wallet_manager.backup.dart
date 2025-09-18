import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'dart:convert'; // Add this for jsonEncode/jsonDecode
import 'dart:typed_data';
import 'funding_service.dart';

/// Simple wallet manager for basic operations
class WalletManager {
  static const _storage = FlutterSecureStorage();
  
  late Web3Client _client;
  Credentials? _credentials;
  bool _isInitialized = false;
  int? _userId;
  
  // Make the private key storage user-specific
  String get _privateKeyKey => 'wallet_private_key_user_$_userId';
  
  /// Initialize wallet manager for a specific user
  Future<void> initialize({int? userId}) async {
    if (_isInitialized && _userId == userId) return;
    
    _userId = userId;
    await dotenv.load();
    
    // Get RPC URL
    String rpcUrl;
    if (dotenv.env['NETWORK_MODE'] == 'local') {
      rpcUrl = dotenv.env['LOCAL_RPC_URL'] ?? 'http://127.0.0.1:8545';
    } else {
      rpcUrl = dotenv.env['ETHEREUM_RPC_URL'] ?? '';
    }
    
    _client = Web3Client(rpcUrl, http.Client());
    
    // Try to load existing wallet
    await _loadWallet();
    
    _isInitialized = true;
  }
  
  /// Load wallet from secure storage for current user
  Future<void> _loadWallet() async {
    if (_userId == null) return;
    
    final privateKeyHex = await _storage.read(key: _privateKeyKey);
    if (privateKeyHex != null) {
      _credentials = EthPrivateKey.fromHex(privateKeyHex);
    }
  }
  
  /// Check if current user has a wallet
  Future<bool> hasWallet() async {
    if (_userId == null) return false;
    await initialize(userId: _userId);
    return _credentials != null;
  }
  
  /// Create new wallet for current user using MetaMask-style generation
  Future<Map<String, String>> createWallet() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    
    // Generate mnemonic phrase (MetaMask style)
    final mnemonic = bip39.generateMnemonic();
    
    // Derive private key from mnemonic using BIP39/BIP44 standard
    final seed = bip39.mnemonicToSeed(mnemonic);
    
    // Create private key from seed (using first 32 bytes)
    final privateKeyBytes = Uint8List.fromList(seed.take(32).toList());
    final privateKey = EthPrivateKey(privateKeyBytes);
    
    // Save both mnemonic and private key to secure storage
    await _storage.write(key: _privateKeyKey, value: privateKey.privateKeyInt.toRadixString(16));
    await _storage.write(key: '${_privateKeyKey}_mnemonic', value: mnemonic);
    
    _credentials = privateKey;
    
    final address = await privateKey.extractAddress();
    
    // Pre-fund with gas money for new users (development only)
    if (dotenv.env['NETWORK_MODE'] == 'local') {
      if (kDebugMode) {
        print('🔧 Attempting to pre-fund new wallet with gas...');
      }
      try {
        await _preFundWithGas(address.hex);
        if (kDebugMode) {
          print('✅ Gas pre-funding completed successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Pre-funding with gas failed: $e');
          print('   User will need to request gas funds manually');
        }
        // Don't rethrow - wallet creation should still succeed
      }
    } else {
      if (kDebugMode) {
        print('⚠️ Network mode is not local, skipping gas pre-funding');
      }
    }
    
    return {
      'address': address.hex,
      'mnemonic': mnemonic,
      'privateKey': privateKey.privateKeyInt.toRadixString(16),
    };
  }
  
  /// Pre-fund new wallet with gas money (development only)
  Future<void> _preFundWithGas(String walletAddress) async {
    if (kDebugMode) {
      print('🔍 STEP 1: Starting gas pre-funding process');
      print('🔍 Network mode: ${dotenv.env['NETWORK_MODE']}');
    }
    
    if (dotenv.env['NETWORK_MODE'] != 'local') {
      if (kDebugMode) {
        print('❌ Gas pre-funding aborted: Not in local mode');
      }
      throw Exception('Gas pre-funding only available in local development mode');
    }
    
    try {
      if (kDebugMode) {
        print('� STEP 2: Preparing transaction parameters');
        print('�💰 Pre-funding wallet $walletAddress with gas...');
      }
      
      // Use a funded Ganache account to send gas money
      const gasPrivateKey = '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d'; // Ganache account 0
      
      if (kDebugMode) {
        print('🔍 STEP 3: Creating private key from hex');
      }
      final gasAccount = EthPrivateKey.fromHex(gasPrivateKey);
      
      if (kDebugMode) {
        print('🔍 STEP 4: Creating ETH amount for gas');
      }
      final gasAmount = EtherAmount.fromUnitAndValue(EtherUnit.ether, 0.1); // 0.1 ETH for gas
      
      if (kDebugMode) {
        final fromAddress = await gasAccount.extractAddress();
        print('🔍 STEP 5: Transaction details prepared');
        print('   From account: ${fromAddress.hex}');
        print('   To account: $walletAddress');
        print('   Amount: 0.1 ETH (${gasAmount.getInWei} wei)');
        print('   Gas price: 20 gwei');
        print('   Max gas: 21000');
      }
      
      if (kDebugMode) {
        print('🔍 STEP 6: Creating transaction object');
      }
      final transaction = Transaction(
        to: EthereumAddress.fromHex(walletAddress),
        value: gasAmount,
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
        maxGas: 21000,
      );
      
      if (kDebugMode) {
        print('🔍 STEP 7: Getting chain ID');
      }
      
      // Get chain ID from .env or default to 1337 for Ganache
      int chainId;
      try {
        final chainIdStr = dotenv.env['LOCAL_CHAIN_ID'] ?? '1337';
        if (kDebugMode) {
          print('   Chain ID from .env: "$chainIdStr"');
        }
        
        // Try several conversion approaches
        if (chainIdStr.isEmpty) {
          if (kDebugMode) {
            print('   Chain ID string is empty, using default 1337');
          }
          chainId = 1337; // Default fallback
        } else {
          try {
            if (kDebugMode) {
              print('   Parsing chain ID string to int');
            }
            chainId = int.parse(chainIdStr.trim());
          } catch (e) {
            if (kDebugMode) {
              print('   Failed to parse chain ID: $e');
              print('   Using default 1337');
            }
            chainId = 1337; // Default if parsing fails
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('   Error getting chain ID: $e');
          print('   Using default 1337');
        }
        chainId = 1337; // Default if any error
      }
      
      if (kDebugMode) {
        print('🔍 STEP 8: Chain ID determined');
        print('   Using chain ID: $chainId (${chainId.runtimeType})');
        print('   Client status: initialized');
        print('   Client URL: ${dotenv.env['LOCAL_RPC_URL']}');
      }
      
      if (kDebugMode) {
        print('🔍 STEP 9: Sending transaction');
        print('   Transaction details:');
        print('   - To: ${transaction.to?.hex}');
        print('   - Value: ${transaction.value?.getInEther} ETH');
        print('   - Max gas: ${transaction.maxGas}');
      }
      
      // Use explicit int for chainId
      final txHash = await _client.sendTransaction(
        gasAccount,
        transaction,
        chainId: chainId,
      );
      
      if (kDebugMode) {
        print('🔍 STEP 10: Transaction completed');
        print('⛽ Pre-funded new wallet with 0.1 ETH for gas! TX: $txHash');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gas pre-funding failed');
        print('💥 Gas pre-funding error details: $e');
        print('💥 Error type: ${e.runtimeType}');
        
        // Try to diagnose common issues
        if (e.toString().contains("Invalid type")) {
          print('   ⚠️ Type error detected - might be chain ID format issue');
          print('   Debug info:');
          print('   - LOCAL_CHAIN_ID env var: "${dotenv.env['LOCAL_CHAIN_ID']}"');
          print('   - RPC URL: ${dotenv.env['LOCAL_RPC_URL']}');
          
          // Check if web3 client is initialized properly
          try {
            print('   - Client status: initialized');
            print('   - Client properties:');
            print('     - URL: ${_client.toString()}');
          } catch (clientError) {
            print('   - Error checking client: $clientError');
          }
          
          // Try alternative approach with hard-coded values
          print('   🔄 Attempting alternative pre-funding method...');
          try {
            await _tryAlternativePrefunding(walletAddress);
            if (kDebugMode) {
              print('✅ Gas pre-funding succeeded with alternative method!');
            }
            return; // Success with alternative method, return early
          } catch (altError) {
            if (kDebugMode) {
              print('❌ Alternative pre-funding also failed: $altError');
            }
            // Continue to throw the original exception
          }
        } else if (e.toString().contains("insufficient funds")) {
          print('   ⚠️ Insufficient funds - account 0 doesn\'t have enough ETH');
        } else if (e.toString().contains("connection")) {
          print('   ⚠️ Connection error - check if Ganache is running');
        }
      }
      throw Exception('Failed to pre-fund wallet with gas: $e');
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
    
    // Derive private key from mnemonic
    final seed = bip39.mnemonicToSeed(mnemonic);
    final privateKeyBytes = Uint8List.fromList(seed.take(32).toList());
    final privateKey = EthPrivateKey(privateKeyBytes);
    
    // Save both mnemonic and private key to secure storage
    await _storage.write(key: _privateKeyKey, value: privateKey.privateKeyInt.toRadixString(16));
    await _storage.write(key: '${_privateKeyKey}_mnemonic', value: mnemonic);
    
    _credentials = privateKey;
    
    final address = await privateKey.extractAddress();
    return address.hex;
  }
  
  /// Get wallet mnemonic phrase (if available)
  Future<String?> getMnemonic() async {
    if (_userId == null) throw Exception('User ID not set');
    return await _storage.read(key: '${_privateKeyKey}_mnemonic');
  }
  
  /// Get wallet address
  Future<String?> getAddress() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    if (_credentials == null) return null;
    
    final address = await _credentials!.extractAddress();
    return address.hex;
  }

  
  /// Get private key as hex string
  Future<String?> getPrivateKey() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    if (_credentials == null) return null;
    
    // Read directly from storage since we stored it as hex
    return await _storage.read(key: _privateKeyKey);
  }
  
  /// Get full wallet information
  Future<Map<String, String>?> getWalletInfo() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    if (_credentials == null) return null;
    
    final address = await getAddress();
    final privateKey = await getPrivateKey();
    final mnemonic = await getMnemonic();
    
    return {
      'address': address!,
      'privateKey': privateKey!,
      if (mnemonic != null) 'mnemonic': mnemonic,
    };
  }
  
  /// Get wallet balance
  Future<double> getBalance() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    if (_credentials == null) throw Exception('No wallet found');
    
    final address = await _credentials!.extractAddress();
    final balance = await _client.getBalance(address);
    
    return balance.getValueInUnit(EtherUnit.ether);
  }
  
  /// Get credentials for signing transactions
  Credentials? get credentials => _credentials;
  
  /// Send simple transaction
  Future<String> sendTransaction({
    required String toAddress,
    required double amount,
    String? memo,
  }) async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    if (_credentials == null) throw Exception('No wallet found');
    
    final to = EthereumAddress.fromHex(toAddress);
    final amountWei = EtherAmount.fromUnitAndValue(EtherUnit.ether, amount);
    
    final transaction = Transaction(
      to: to,
      value: amountWei,
      gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
      maxGas: 21000,
    );
    
    final chainId = dotenv.env['NETWORK_MODE'] == 'local' ? 1337 : 11155111;
    
    return await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: chainId,
    );
  }
  
  /// Validate Ethereum address
  bool isValidAddress(String address) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Request test ETH funding (development only)
  Future<Map<String, dynamic>> requestFunding({double amount = 1.0}) async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);

    if (dotenv.env['NETWORK_MODE'] != 'local') {
      throw Exception('Funding only available in local development mode');
    }

    final address = await getAddress();
    if (address == null) {
      throw Exception('No wallet found. Create a wallet first.');
    }

    try {
      final fundingService = FundingService();
      
      // First check if user is eligible for welcome bonus
      if (_credentials != null) {
        if (kDebugMode) {
          print('🔍 Checking welcome bonus eligibility for: $address');
        }
        
        final canReceiveWelcome = await fundingService.canReceiveWelcomeBonus(address);
        
        if (kDebugMode) {
          print('💡 Welcome bonus eligible: $canReceiveWelcome');
        }
        
        if (canReceiveWelcome) {
          if (kDebugMode) {
            print('🎉 User eligible for welcome bonus!');
          }
          
          final welcomeResult = await fundingService.requestWelcomeBonus(
            credentials: _credentials!,
          );
          
          if (welcomeResult['success'] == true) {
            if (kDebugMode) {
              print('✅ Welcome bonus granted successfully!');
            }
            return welcomeResult;
          } else {
            if (kDebugMode) {
              print('❌ Welcome bonus failed: ${welcomeResult['error']}');
            }
          }
        } else {
          if (kDebugMode) {
            print('ℹ️ User not eligible for welcome bonus, trying other methods...');
          }
        }
      }
      
      // If no welcome bonus available, try queue-based funding
      if (_credentials != null) {
        final queueResult = await fundingService.requestFromQueue(
          credentials: _credentials!,
          amount: amount,
        );
        
        if (queueResult['success'] == true) {
          return queueResult;
        }
        
        // If queue funding fails, try direct contract funding
        final contractResult = await fundingService.requestContractFunding(
          credentials: _credentials!,
          amount: amount,
        );
        
        if (contractResult['success'] == true) {
          return contractResult;
        }
        
        // Return the queue result error (more informative)
        return queueResult;
      }
      
      // No credentials available
      return {
        'success': false,
        'error': 'Wallet credentials not available. Please recreate your wallet.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Request funding using contract faucet (preferred method)
  Future<Map<String, dynamic>> requestContractFunding({double amount = 1.0}) async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    
    if (_credentials == null) {
      throw Exception('No wallet found. Create a wallet first.');
    }
    
    try {
      final fundingService = FundingService();
      return await fundingService.requestContractFunding(
        credentials: _credentials!,
        amount: amount,
      );
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Check if contract funding is available
  Future<Map<String, dynamic>?> canRequestContractFunding() async {
    if (_userId == null) return null;
    await initialize(userId: _userId);
    
    final address = await getAddress();
    if (address == null) return null;
    
    final fundingService = FundingService();
    return await fundingService.canRequestContractFunding(address);
  }
  
  /// Request welcome bonus for new users
  Future<Map<String, dynamic>> requestWelcomeBonus() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);

    if (dotenv.env['NETWORK_MODE'] != 'local') {
      throw Exception('Welcome bonus only available in local development mode');
    }

    final address = await getAddress();
    if (address == null) {
      throw Exception('No wallet found. Create a wallet first.');
    }

    if (_credentials == null) {
      throw Exception('Wallet credentials not available. Please recreate your wallet.');
    }

    final fundingService = FundingService();
    return await fundingService.requestWelcomeBonus(credentials: _credentials!);
  }

  /// Check if user can request funding (checks cooldown)
  Future<Map<String, dynamic>?> canRequestFunding() async {
    if (_userId == null) throw Exception('User ID not set');
    await initialize(userId: _userId);
    
    final address = await getAddress();
    if (address == null) return null;
    
    final fundingService = FundingService();
    return await fundingService.checkCooldownStatus(address);
  }
  
  /// Get funding service information  
  Map<String, dynamic> getFundingInfo() {
    return {
      'available': dotenv.env['NETWORK_MODE'] == 'local',
      'networkMode': dotenv.env['NETWORK_MODE'],
      'description': dotenv.env['NETWORK_MODE'] == 'local'
          ? 'Test ETH available via contract faucet and external server'
          : 'Funding only available in local development',
      'methods': ['contract', 'external'],
    };
  }
  
  /// Check if funding is available
  bool get isFundingAvailable {
    return dotenv.env['NETWORK_MODE'] == 'local';
  }
  
  /// Fallback method using web3dart library 
  Future<void> _tryWeb3DartPrefunding(String walletAddress) async {
    try {
      if (kDebugMode) {
        print('🔄 FALLBACK: Using web3dart library for pre-funding');
      }
      
      // Use a funded Ganache account to send gas money
      const gasPrivateKey = '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d'; // Ganache account 0
      final gasAccount = EthPrivateKey.fromHex(gasPrivateKey);
      final gasAmount = EtherAmount.fromUnitAndValue(EtherUnit.ether, 0.1); // 0.1 ETH for gas
      
      if (kDebugMode) {
        final fromAddress = await gasAccount.extractAddress();
        print('   Transaction details:');
        print('   - From: ${fromAddress.hex}');
        print('   - To: $walletAddress');
        print('   - Amount: 0.1 ETH');
      }
      
      final transaction = Transaction(
        to: EthereumAddress.fromHex(walletAddress),
        value: gasAmount,
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
        maxGas: 21000,
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ FALLBACK: Web3dart pre-funding failed: $e');
      }
      throw Exception('Web3dart pre-funding failed: $e');
    }
  }
  
  /// Clear wallet (logout)
  Future<void> clearWallet() async {
    if (_userId == null) return;
    await _storage.delete(key: _privateKeyKey);
    _credentials = null;
    _userId = null;
  }
  
  void dispose() {
    _client.dispose();
  }
}