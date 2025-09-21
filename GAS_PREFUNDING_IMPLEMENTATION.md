# Gas Pre-Funding Implementation Guide

This comprehensive guide outlines the updated gas pre-funding system in Ledgerly with improved configuration and fallback mechanisms.

## Overview

The gas pre-funding mechanism in Ledgerly is now more robust with:

1. **Configurable Parameters** - Customizable funding amounts, gas prices, and addresses
2. **Fallback Mechanisms** - Multiple pre-funding methods with automatic failover
3. **Detailed Logging** - Comprehensive logging for debugging and monitoring
4. **Error Handling** - Better error diagnosis and recovery options

## Implementation Details

### Configuration System

The pre-funding system uses a multi-layered configuration approach:

```dart
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
```

### Primary Pre-Funding Method: JSON-RPC

The primary method uses direct JSON-RPC calls for more reliable pre-funding:

```dart
Future<void> _preFundWithGas(String walletAddress) async {
  // Configuration
  final rpcUrl = getConfig('LOCAL_RPC_URL') ?? 'http://127.0.0.1:8545';
  final fundingAccount = getConfig('FUNDING_ACCOUNT') ?? '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1';
  final prefundAmountStr = getConfig('PREFUND_AMOUNT') ?? '100000000000000000'; // 0.1 ETH
  final prefundAmount = BigInt.parse(prefundAmountStr);
  final gasPriceStr = getConfig('GAS_PRICE') ?? '20000000000'; // 20 Gwei
  final gasPrice = BigInt.parse(gasPriceStr);
  
  // JSON-RPC transaction
  final body = jsonEncode({
    "jsonrpc": "2.0",
    "method": "eth_sendTransaction",
    "params": [
      {
        "from": fundingAccount,
        "to": walletAddress,
        "value": "0x${prefundAmount.toRadixString(16)}",
        "gas": "0x5208", // 21000 gas
        "gasPrice": "0x${gasPrice.toRadixString(16)}"
      }
    ],
    "id": 1
  });
  
  // Send the request and process response
  // [Implementation details omitted for brevity]
}
```

### Fallback Method: Web3Dart

If the primary method fails, the system automatically falls back to using the web3dart library:

```dart
Future<void> _tryWeb3DartPrefunding(String walletAddress) async {
  // Configuration (reusing the same config values)
  final gasPvtKey = getConfig('FUNDING_ACCOUNT_KEY') ?? 
                    '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d';
  final prefundAmountStr = getConfig('PREFUND_AMOUNT') ?? '100000000000000000';
  final prefundAmount = BigInt.parse(prefundAmountStr);
  final gasPriceStr = getConfig('GAS_PRICE') ?? '20000000000';
  final gasPrice = BigInt.parse(gasPriceStr);
  final chainIdStr = getConfig('LOCAL_CHAIN_ID') ?? '1337';
  final chainId = int.parse(chainIdStr);
  
  // Create and send transaction using web3dart
  final gasAccount = EthPrivateKey.fromHex(gasPvtKey);
  final gasAmount = EtherAmount.fromUnitAndValue(EtherUnit.wei, prefundAmount);
  
  final transaction = Transaction(
    to: EthereumAddress.fromHex(walletAddress),
    value: gasAmount,
    gasPrice: EtherAmount.inWei(gasPrice),
    maxGas: 21000,
  );
  
  final txHash = await _client.sendTransaction(
    gasAccount,
    transaction,
    chainId: chainId,
  );
}
```

### Error Handling

The system includes comprehensive error handling with diagnostics:

```dart
try {
  // Pre-funding implementation
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
    try {
      await _tryWeb3DartPrefunding(walletAddress);
      // Success with fallback
    } catch (fallbackError) {
      // Both methods failed
    }
  }
}
```

## Configuration Management

The configuration system provides three layers of priority:

1. **Runtime Configuration** (highest priority)
   ```dart
   walletManager.setConfig('PREFUND_AMOUNT', '200000000000000000'); // 0.2 ETH
   ```

2. **Environment Variables** (medium priority)
   ```
   # .env file
   FUNDING_ACCOUNT=0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1
   ```

3. **Default Configuration** (lowest priority)
   ```dart
   // Built-in defaults as shown above
   ```

## Retrieving Configuration

The `getConfig()` method provides the unified access point for all configuration values:

```dart
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
```

## Best Practices

1. **Development Setup**
   - Always ensure Ganache is running on the specified RPC URL
   - The funding account must have sufficient ETH balance

2. **Configuration Management**
   - Set critical values at runtime for maximum flexibility
   - Provide reasonable defaults for all parameters
   - Log configuration values for debugging purposes

3. **Error Recovery**
   - Implement UI to allow users to retry with different configuration
   - Consider automatic retry with increasing gas prices
   - Monitor pre-funding success rates in production

## Common Issues and Solutions

| Issue | Possible Cause | Solution |
|-------|----------------|----------|
| Connection Error | Ganache not running | Start Ganache with `node scripts/start-ganache.js` |
| Insufficient Funds | Funding account empty | Fund account 0 in Ganache |
| Transaction Underpriced | Gas price too low | Increase GAS_PRICE configuration |
| Invalid Chain ID | Wrong network configuration | Ensure LOCAL_CHAIN_ID matches Ganache |
| BigInt Conversion Error | String vs number type issue | Ensure all numeric values are parsed correctly |

## Summary

The improved gas pre-funding implementation provides:

1. **Reliability** - Multiple methods with automatic fallback
2. **Flexibility** - Configurable parameters at runtime
3. **Diagnosability** - Detailed logging and error diagnosis
4. **Resilience** - Graceful degradation in unstable networks
        require(bytes(email).length > 0, "Email cannot be empty");
        require(bytes(walletToEmail[msg.sender]).length == 0, "Wallet already registered");
        
        emailToWallet[email] = msg.sender;
        walletToEmail[msg.sender] = email;
    }
    
    // Welcome bonus functions
    function canRequestWelcomeBonus(address recipient) public view returns (bool) {
        // If already received, cannot request again
        if (hasReceivedWelcomeBonus[recipient]) {
            return false;
        }
        
        // Check cooldown period
        if (block.timestamp - lastWelcomeBonusRequest[recipient] < welcomeBonusCooldown) {
            return false;
        }
        
        // Check if contract has enough funds
        if (address(this).balance < welcomeBonusAmount) {
            return false;
        }
        
        return true;
    }
    
    function requestWelcomeBonus() public {
        require(canRequestWelcomeBonus(msg.sender), "Cannot request welcome bonus");
        
        // Mark as received and update timestamp
        hasReceivedWelcomeBonus[msg.sender] = true;
        lastWelcomeBonusRequest[msg.sender] = block.timestamp;
        
        // Send welcome bonus
        payable(msg.sender).transfer(welcomeBonusAmount);
    }
    
    // Other functions omitted for brevity
}
```

### Key Contract Functions

1. **`registerEmail`**: Associates an email with a wallet address
2. **`canRequestWelcomeBonus`**: Checks if a wallet can receive the welcome bonus
3. **`requestWelcomeBonus`**: Sends 0.5 ETH to the caller if eligible

## 2. Contract Deployment Process

The contract is deployed using the `deploy-and-save.js` script.

### Deployment Script

```javascript
// scripts/deploy-and-save.js
const Web3 = require('web3');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');
const axios = require('axios');

// Load environment variables
dotenv.config();

// Contract compilation artifacts
const contractJson = require('../build/contracts/EmailPaymentRegistry.json');

async function deployContract() {
  console.log('🚀 Starting contract deployment process...');
  
  // Initialize web3 with local Ganache
  const rpcUrl = process.env.ETHEREUM_RPC_URL || 'http://localhost:8545';
  const web3 = new Web3(rpcUrl);
  
  // Get network ID and accounts
  const networkId = await web3.eth.net.getId();
  const accounts = await web3.eth.getAccounts();
  
  console.log(`📡 Connected to network ID: ${networkId}`);
  console.log(`👤 Using deployer account: ${accounts[0]}`);
  
  // Deploy contract
  const EmailPaymentRegistry = new web3.eth.Contract(contractJson.abi);
  const deployTx = EmailPaymentRegistry.deploy({
    data: contractJson.bytecode,
    arguments: []
  });
  
  const gas = await deployTx.estimateGas();
  
  console.log('⛽ Estimated gas for deployment:', gas);
  console.log('📄 Deploying EmailPaymentRegistry contract...');
  
  const deployedContract = await deployTx.send({
    from: accounts[0],
    gas
  });
  
  const contractAddress = deployedContract.options.address;
  console.log(`✅ Contract deployed at: ${contractAddress}`);
  
  // Fund contract with ETH for welcome bonuses
  const fundingAmount = web3.utils.toWei('20', 'ether');
  console.log(`💰 Funding contract with 20 ETH for welcome bonuses...`);
  
  await web3.eth.sendTransaction({
    from: accounts[0],
    to: contractAddress,
    value: fundingAmount
  });
  
  // Save deployment info
  const timestamp = new Date().toISOString().replace(/:/g, '-');
  const deploymentPath = path.join(__dirname, '../deployments', `EmailPaymentRegistry-${timestamp}.json`);
  const latestPath = path.join(__dirname, '../deployments', 'EmailPaymentRegistry-latest.json');
  
  const deploymentInfo = {
    network_id: networkId,
    contract_address: contractAddress,
    deployer_address: accounts[0],
    abi: contractJson.abi,
    deployment_timestamp: new Date().toISOString(),
    chain_id: await web3.eth.getChainId()
  };
  
  fs.writeFileSync(deploymentPath, JSON.stringify(deploymentInfo, null, 2));
  fs.writeFileSync(latestPath, JSON.stringify(deploymentInfo, null, 2));
  
  console.log(`📝 Deployment info saved to: ${deploymentPath}`);
  
  // Save to backend (optional)
  try {
    await saveToBackend(deploymentInfo);
    console.log('🌐 Contract info saved to backend');
  } catch (error) {
    console.error('❌ Failed to save to backend:', error.message);
  }
  
  return deploymentInfo;
}

async function saveToBackend(deploymentInfo) {
  const backendUrl = process.env.BACKEND_URL || 'https://ledgerly.hivizstudios.com';
  const saveUrl = `${backendUrl}/save_contract.php`;
  
  await axios.post(saveUrl, {
    contract_address: deploymentInfo.contract_address,
    abi: JSON.stringify(deploymentInfo.abi),
    network_id: deploymentInfo.network_id,
    chain_id: deploymentInfo.chain_id
  });
}

// Execute deployment
deployContract()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Deployment failed:', error);
    process.exit(1);
  });
```

### Initial Contract Setup

When deployed, the contract:
1. Is initialized with the deployer as owner
2. Is funded with 20 ETH for welcome bonuses
3. Sets the welcome bonus amount to 0.5 ETH
4. Sets a cooldown period of 1 day between welcome bonus requests
5. Saves deployment information to both a timestamped file and a "latest" file
6. Optionally saves contract info to the backend server

## 3. Flutter .env Configuration

The Flutter app uses a `.env` file to configure its blockchain connectivity. This file determines whether to connect to a local Ganache instance or a remote blockchain network.

### .env File Structure

```
# Network mode: local or testnet
NETWORK_MODE=local

# RPC URLs
LOCAL_RPC_URL=http://10.0.2.2:8545
ETHEREUM_RPC_URL=http://localhost:8545

# Backend API
BACKEND_URL=https://ledgerly.hivizstudios.com

# Chain ID (must match Ganache configuration)
CHAIN_ID=1337
```

### Key Configuration Parameters

- **NETWORK_MODE**: Determines which blockchain to connect to
  - `local`: Uses Ganache (for development)
  - `testnet`: Uses a testnet like Sepolia (for testing)
  
- **LOCAL_RPC_URL**: Special URL for Android emulators (10.0.2.2 routes to host machine)
- **ETHEREUM_RPC_URL**: Standard URL for desktop access
- **CHAIN_ID**: Critical for transaction signing, must be 1337 for Ganache

## 4. Blockchain Connectivity Architecture

The Ledgerly app can connect to the blockchain in two ways:

### 1. Direct Connection

The app connects directly to the blockchain via Web3 RPC:

```
Flutter App → Web3Client → RPC URL → Blockchain
```

This is used for:
- Reading blockchain data
- Sending transactions
- Interacting with smart contracts

### 2. Backend-Mediated Connection

For some operations, the app connects via the backend:

```
Flutter App → HTTP Client → Backend API → Blockchain
```

This is used for:
- Retrieving contract details
- Storing user profiles
- Email verification
- Multi-device synchronization

### Contract Configuration Loading

```dart
// lib/services/contract_service.dart

Future<void> _loadContractConfig() async {
  try {
    // Try to load from cached file first
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/contract_config.json');
    
    if (await file.exists()) {
      final json = jsonDecode(await file.readAsString());
      _contractAddress = json['contract_address'];
      _contractAbi = json['abi'];
      _chainId = json['chain_id'];
      return;
    }
    
    // If not available locally, fetch from backend
    final backendUrl = dotenv.env['BACKEND_URL'] ?? 'https://ledgerly.hivizstudios.com';
    final response = await http.get(Uri.parse('$backendUrl/get_contract.php'));
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      _contractAddress = json['contract_address'];
      _contractAbi = jsonDecode(json['abi']);
      _chainId = json['chain_id'];
      
      // Cache for future use
      await file.writeAsString(jsonEncode({
        'contract_address': _contractAddress,
        'abi': _contractAbi,
        'chain_id': _chainId
      }));
    }
  } catch (e) {
    print('Error loading contract config: $e');
    throw Exception('Failed to load contract configuration');
  }
}
```

## 5. Gas Pre-Funding Implementation (0.1 ETH)

The gas pre-funding mechanism is implemented entirely on the client side, not in the smart contract. It automatically sends 0.1 ETH to newly created wallets to cover gas fees.

### WalletManager Implementation

```dart
// lib/services/wallet_manager.dart

import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'dart:typed_data';
import 'funding_service.dart';

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
  
  /// Create new wallet for current user
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
    if (dotenv.env['NETWORK_MODE'] != 'local') {
      throw Exception('Gas pre-funding only available in local development mode');
    }
    
    try {
      if (kDebugMode) {
        print('💰 Pre-funding wallet $walletAddress with gas...');
      }
      
      // Use a funded Ganache account to send gas money
      const gasPrivateKey = '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d'; // Ganache account 0
      final gasAccount = EthPrivateKey.fromHex(gasPrivateKey);
      
      final gasAmount = EtherAmount.fromUnitAndValue(EtherUnit.ether, 0.1); // 0.1 ETH for gas
      
      if (kDebugMode) {
        print('   From account: ${await gasAccount.extractAddress()}');
        print('   Amount: 0.1 ETH');
        print('   Chain ID: 1337');
      }
      
      final transaction = Transaction(
        to: EthereumAddress.fromHex(walletAddress),
        value: gasAmount,
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
        maxGas: 21000,
      );
      
      // Get chain ID from .env or default to 1337 for Ganache
      final chainId = int.tryParse(dotenv.env['CHAIN_ID'] ?? '') ?? 1337;
      
      final txHash = await _client.sendTransaction(
        gasAccount,
        transaction,
        chainId: chainId,
      );
      
      if (kDebugMode) {
        print('⛽ Pre-funded new wallet with 0.1 ETH for gas! TX: $txHash');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Gas pre-funding error details: $e');
      }
      throw Exception('Failed to pre-fund wallet with gas: $e');
    }
  }
}
```

### Key Features of Gas Pre-Funding

1. **Automatic Trigger**: Pre-funding happens automatically during wallet creation
2. **Funding Source**: Uses Ganache Account 0 with private key `0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d`
3. **Amount**: Exactly 0.1 ETH (enough for multiple transactions)
4. **Development Only**: Only runs when `NETWORK_MODE=local`
5. **Graceful Failure**: If pre-funding fails, wallet creation continues
6. **Chain ID**: Uses the chain ID from .env file or defaults to 1337
```

## 6. Welcome Bonus System (0.5 ETH)

The welcome bonus system is implemented in the smart contract and provides new users with 0.5 ETH. This requires gas to claim, which is why the gas pre-funding is necessary.

### FundingService Implementation

```dart
// lib/services/funding_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../constants.dart';

class FundingService {
  Web3Client? _client;
  DeployedContract? _contract;
  ContractFunction? _requestWelcomeBonus;
  ContractFunction? _canRequestWelcomeBonus;
  
  bool _isContractInitialized = false;
  
  /// Initialize contract-based funding
  Future<void> _initializeContract() async {
    if (_isContractInitialized) return;
    
    try {
      // Get RPC URL based on network mode
      String rpcUrl;
      if (dotenv.env['NETWORK_MODE'] == 'local') {
        rpcUrl = dotenv.env['LOCAL_RPC_URL'] ?? 'http://10.0.2.2:8545';
      } else {
        rpcUrl = dotenv.env['ETHEREUM_RPC_URL'] ?? '';
      }
      
      if (rpcUrl.isEmpty) return;
      
      // Initialize Web3 client
      _client = Web3Client(rpcUrl, http.Client());
      
      // Get contract from backend or local file
      String? contractAddress;
      List<dynamic>? contractAbi;
      
      try {
        // Try local file first
        final directory = await getApplicationDocumentsDirectory();
        final contractFile = File('${directory.path}/contract_config.json');
        if (await contractFile.exists()) {
          final contractConfig = jsonDecode(await contractFile.readAsString());
          contractAddress = contractConfig['contract_address'];
          contractAbi = contractConfig['abi'];
        } else {
          // Fall back to backend
          final backendUrl = dotenv.env['BACKEND_URL'] ?? 'https://ledgerly.hivizstudios.com';
          final response = await http.get(Uri.parse('$backendUrl/get_contract.php'));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            contractAddress = data['contract_address'];
            contractAbi = jsonDecode(data['abi']);
            
            // Cache for future use
            await contractFile.writeAsString(jsonEncode({
              'contract_address': contractAddress,
              'abi': contractAbi
            }));
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error loading contract info: $e');
        }
        // Continue with fallback ABI
      }
      
      // If we couldn't get contract info, use fallback (for development)
      if (contractAddress == null || contractAbi == null) {
        // Use latest deployment if available
        try {
          final deploymentFile = File('deployments/EmailPaymentRegistry-latest.json');
          if (await deploymentFile.exists()) {
            final deployment = jsonDecode(await deploymentFile.readAsString());
            contractAddress = deployment['contract_address'];
            contractAbi = deployment['abi'];
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error loading local deployment: $e');
          }
        }
        
        // If still not available, use hardcoded values for development
        if (contractAddress == null) {
          contractAddress = '0x5017A545b09ab9a30499DE7F431DF0855bCb7275'; // Example address
        }
        
        if (contractAbi == null) {
          // Use minimal ABI with just the functions we need
          contractAbi = [
            {
              "inputs": [],
              "name": "requestWelcomeBonus",
              "outputs": [],
              "stateMutability": "nonpayable",
              "type": "function"
            },
            {
              "inputs": [{"internalType": "address", "name": "recipient", "type": "address"}],
              "name": "canRequestWelcomeBonus",
              "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
              "stateMutability": "view",
              "type": "function"
            }
          ];
        }
      }
      
      // Create contract instance
      _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(contractAbi), 'EmailPaymentRegistry'),
        EthereumAddress.fromHex(contractAddress),
      );
      
      // Get contract functions
      try {
        _requestWelcomeBonus = _contract!.function('requestWelcomeBonus');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ requestWelcomeBonus function not found in contract ABI');
        }
      }
      
      try {
        _canRequestWelcomeBonus = _contract!.function('canRequestWelcomeBonus');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ canRequestWelcomeBonus function not found in contract ABI');
        }
      }
      
      _isContractInitialized = true;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize contract: $e');
      }
    }
  }
  
  /// Request welcome bonus for new users (one-time only)
  Future<Map<String, dynamic>> requestWelcomeBonus({
    required Credentials credentials,
  }) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) {
        throw Exception('Contract not initialized');
      }
      
      if (_requestWelcomeBonus == null) {
        throw Exception('Welcome bonus not supported by this contract');
      }
      
      // Check if user is eligible for welcome bonus
      final userAddress = await credentials.extractAddress();
      if (_canRequestWelcomeBonus != null) {
        final canRequest = await _client!.call(
          contract: _contract!,
          function: _canRequestWelcomeBonus!,
          params: [userAddress],
        );
        
        if (!(canRequest[0] as bool)) {
          throw Exception('Welcome bonus already claimed or not available');
        }
      }
      
      // Request welcome bonus
      final chainId = await _getChainId();
      
      if (kDebugMode) {
        print('🔧 Welcome bonus transaction details:');
        print('   Chain ID: $chainId');
        print('   User address: ${userAddress.hex}');
        print('   Contract: ${_contract!.address.hex}');
      }
      
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _requestWelcomeBonus!,
        parameters: [],
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 Gwei
        maxGas: 150000,
      );
      
      final txHash = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: chainId,
      );
      
      return {
        'success': true,
        'transactionHash': txHash,
        'welcomeBonus': 0.5, // Default welcome bonus amount
        'message': 'Welcome to Ledgerly! You received 0.5 ETH to get started.',
        'method': 'welcomeBonus',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'method': 'welcomeBonus',
      };
    }
  }
  
  /// Check if user can receive welcome bonus
  Future<bool> canReceiveWelcomeBonus(String walletAddress) async {
    await _initializeContract();
    if (!_isContractInitialized) return false;
    if (_canRequestWelcomeBonus == null) return false;
    
    try {
      final result = await _client!.call(
        contract: _contract!,
        function: _canRequestWelcomeBonus!,
        params: [EthereumAddress.fromHex(walletAddress)],
      );
      
      return result[0] as bool;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking welcome bonus eligibility: $e');
      }
      return false;
    }
  }
  
  /// Get the chain ID from the current network
  Future<int> _getChainId() async {
    try {
      // Try to get from .env first
      final envChainId = int.tryParse(dotenv.env['CHAIN_ID'] ?? '');
      if (envChainId != null) return envChainId;
      
      // Otherwise get from the network
      return await _client!.getChainId();
    } catch (e) {
      // Default to Ganache chain ID
      return 1337;
    }
  }
}
```

## 7. Complete System Workflow

The complete gas funding and welcome bonus workflow is:

1. **User Creates Wallet**:
   - `WalletManager.createWallet()` is called
   - New wallet address is generated
   - If in local mode, `_preFundWithGas()` sends 0.1 ETH from Ganache Account 0

2. **User Checks Balance**:
   - Shows 0.1 ETH for gas

3. **User Claims Welcome Bonus**:
   - App checks eligibility with `FundingService.canReceiveWelcomeBonus()`
   - If eligible, calls `FundingService.requestWelcomeBonus()`
   - Uses the 0.1 ETH gas to pay for the transaction
   - Receives 0.5 ETH welcome bonus from contract

4. **Final Balance**:
   - User has approximately 0.6 ETH (0.5 ETH welcome bonus + remaining gas ETH)

## 8. Recommended Setup for Testing

To ensure the gas pre-funding and welcome bonus systems work correctly:

### 1. Start Ganache with correct Chain ID

```bash
ganache-cli --port 8545 --networkId 1337 --chainId 1337 --accounts 10 --defaultBalanceEther 100
```

### 2. Deploy Contract and Fund Welcome Bonus

```bash
node scripts/deploy-and-save.js
```

### 3. Configure Flutter App .env File

```
NETWORK_MODE=local
LOCAL_RPC_URL=http://10.0.2.2:8545
ETHEREUM_RPC_URL=http://localhost:8545
CHAIN_ID=1337
```

### 4. Verify Account 0 Balance

Account 0 should have enough ETH to fund new wallets with gas:
```bash
node -e "const Web3 = require('web3'); const web3 = new Web3('http://localhost:8545'); web3.eth.getAccounts().then(accounts => web3.eth.getBalance(accounts[0]).then(balance => console.log('Account 0 balance:', web3.utils.fromWei(balance, 'ether'), 'ETH')));"
```

### 5. Verify Contract Balance

Contract should have enough ETH for welcome bonuses:
```bash
node -e "const Web3 = require('web3'); const web3 = new Web3('http://localhost:8545'); const fs = require('fs'); const config = JSON.parse(fs.readFileSync('./deployments/EmailPaymentRegistry-latest.json')); web3.eth.getBalance(config.contract_address).then(balance => console.log('Contract balance:', web3.utils.fromWei(balance, 'ether'), 'ETH'));"
```

## 9. Troubleshooting

### Common Issues and Solutions

1. **Signature Validation Error**:
   - Symptoms: "Invalid signature v value"
   - Cause: Chain ID mismatch
   - Solution: Ensure Ganache uses chain ID 1337 and .env CHAIN_ID=1337

2. **Gas Pre-funding Fails**:
   - Symptoms: "Failed to pre-fund wallet with gas"
   - Cause: Account 0 has insufficient balance or RPC connection issues
   - Solution: Check Account 0 balance and network connectivity

3. **Welcome Bonus Not Available**:
   - Symptoms: "Welcome bonus already claimed or not available"
   - Causes: Already claimed, contract out of funds, or cooldown period
   - Solution: Check contract balance and hasReceivedWelcomeBonus mapping

4. **Contract Not Initialized**:
   - Symptoms: "Contract not initialized" error
   - Cause: Failed to load contract configuration
   - Solution: Verify deployments folder has latest contract info