import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../constants.dart';

/// Service for requesting test ETH funding for development
class FundingService {
  Web3Client? _client;
  DeployedContract? _contract;
  ContractFunction? _requestFaucetFunds;
  ContractFunction? _requestFaucetAmount;
  ContractFunction? _getFaucetInfo;
  ContractFunction? _canRequestFaucet;
  
  // New faucet funding queue functions
  ContractFunction? _joinFaucetFunding;
  ContractFunction? _addFaucetFunding;
  ContractFunction? _leaveFaucetFunding;
  ContractFunction? _getFaucetFundingInfo;
  ContractFunction? _getFunderInfo;
  ContractFunction? _getActiveFunders;
  
  // New queue-based request functions
  ContractFunction? _requestFromQueue;
  ContractFunction? _requestFromQueueDefault;
  
  // Welcome bonus functions
  ContractFunction? _requestWelcomeBonus;
  ContractFunction? _canRequestWelcomeBonus;
  
  bool _isContractInitialized = false;
  
  /// Initialize contract-based funding
  Future<void> _initializeContract() async {
    if (_isContractInitialized) return;
    
    try {
      // Get RPC URL based on network mode
      String rpcUrl;
      if (kDebugMode) {
        rpcUrl = dotenv.env['LOCAL_RPC_URL'] ?? 'http://10.0.2.2:8545';
      } else {
        rpcUrl = dotenv.env['ETHEREUM_RPC_URL'] ?? '';
      }
      
      if (rpcUrl.isEmpty) return;
      
      // Initialize Web3 client
      _client = Web3Client(rpcUrl, http.Client());
      
      // Get contract configuration
      final contractConfig = await _getContractConfig();
      if (contractConfig == null) return;
      
      if (kDebugMode) {
        print('Contract config fetched: ${contractConfig['address']}');
      }
      
      // Load contract ABI and create contract instance
      // The ABI from backend is already a JSON string, so we need to decode it
      final abiString = contractConfig['abi'] as String;
      final abiJson = jsonDecode(abiString);
      _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(abiJson), 'EmailPaymentRegistry'),
        EthereumAddress.fromHex(contractConfig['address']),
      );
      
      // Get contract functions (check if they exist first)
      try {
        _requestFaucetFunds = _contract!.function('requestFaucetFunds');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ requestFaucetFunds function not found in contract ABI');
        }
      }
      
      try {
        _requestFaucetAmount = _contract!.function('requestFaucetAmount');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ requestFaucetAmount function not found in contract ABI');
        }
      }
      
      try {
        _getFaucetInfo = _contract!.function('getFaucetInfo');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ getFaucetInfo function not found in contract ABI');
        }
      }
      
      try {
        _canRequestFaucet = _contract!.function('canRequestFaucet');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ canRequestFaucet function not found in contract ABI');
        }
      }
      
      // Initialize new faucet funding queue functions
      try {
        _joinFaucetFunding = _contract!.function('joinFaucetFunding');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ joinFaucetFunding function not found in contract ABI');
        }
      }
      
      try {
        _addFaucetFunding = _contract!.function('addFaucetFunding');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ addFaucetFunding function not found in contract ABI');
        }
      }
      
      try {
        _leaveFaucetFunding = _contract!.function('leaveFaucetFunding');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ leaveFaucetFunding function not found in contract ABI');
        }
      }
      
      try {
        _getFaucetFundingInfo = _contract!.function('getFaucetFundingInfo');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ getFaucetFundingInfo function not found in contract ABI');
        }
      }
      
      try {
        _getFunderInfo = _contract!.function('getFunderInfo');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ getFunderInfo function not found in contract ABI');
        }
      }
      
      try {
        _getActiveFunders = _contract!.function('getActiveFunders');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ getActiveFunders function not found in contract ABI');
        }
      }
      
      // Initialize queue-based request functions
      try {
        _requestFromQueue = _contract!.function('requestFromQueue');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ requestFromQueue function not found in contract ABI');
        }
      }
      
      try {
        _requestFromQueueDefault = _contract!.function('requestFromQueueDefault');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ requestFromQueueDefault function not found in contract ABI');
        }
      }
      
      // Initialize welcome bonus functions
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
      
      // Debug: List all available functions in the contract
      if (kDebugMode) {
        print('📋 Available contract functions:');
        for (var func in _contract!.functions) {
          print('  - ${func.name}');
        }
      }
      
      _isContractInitialized = true;
      
      if (kDebugMode) {
        print('Contract-based funding initialized successfully');
        print('Contract address: ${_contract!.address.hex}');
        print('RPC URL: $rpcUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Contract funding initialization failed: $e');
      }
    }
  }
  
  /// Get contract configuration from backend
  Future<Map<String, dynamic>?> _getContractConfig() async {
    try {
      // Use get_contract.php endpoint with required parameters
      final contractName = 'EmailPaymentRegistry';
      final chainId = 5777; // Ganache chain ID
      final url = '${ApiConstants.getContract}?contract_name=$contractName&chain_id=$chainId';
      
      if (kDebugMode) {
        print('🔥 Fetching contract config from: $url');
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (kDebugMode) {
        print('🔥 Backend response status: ${response.statusCode}');
        print('🔥 Backend response body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['contract'] != null) {
          // Return the contract data in the expected format
          final contract = data['contract'];
          return {
            'address': contract['address'],
            'abi': contract['abi'],
            'name': contract['name'],
            'chain_id': contract['chain_id'],
          };
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching contract config: $e');
      }
      return null;
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
  Future<bool> canReceiveWelcomeBonus(String userAddress) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) return false;
      
      if (_canRequestWelcomeBonus == null) return false;
      
      final address = EthereumAddress.fromHex(userAddress);
      final result = await _client!.call(
        contract: _contract!,
        function: _canRequestWelcomeBonus!,
        params: [address],
      );
      
      return result[0] as bool;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking welcome bonus eligibility: $e');
      }
      return false;
    }
  }

  /// Request funding for a wallet address from contract faucet
  Future<Map<String, dynamic>> requestFunding({
    required String walletAddress,
    double amount = 1.0,
  }) async {
    // Try queue-based funding first, then fall back to contract-based funding
    try {
      await _initializeContract();
      if (!_isContractInitialized) {
        return {'success': false, 'error': 'Contract faucet not available'};
      }
      
      // Try to find user credentials or use queue-based request
      // Since we don't have credentials here, suggest using requestFromQueue with credentials
      return {
        'success': false, 
        'error': 'Use requestFromQueue with credentials for queue-based funding, or requestContractFunding for direct contract interaction'
      };
    } catch (e) {
      return {'success': false, 'error': 'Contract funding failed: $e'};
    }
  }
  
  /// Request funds from the queue (prioritizes queue contributions over contract balance)
  Future<Map<String, dynamic>> requestFromQueue({
    required Credentials credentials,
    double amount = 1.0,
  }) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) {
        throw Exception('Contract not initialized');
      }
      
      if (_requestFromQueue == null) {
        // Fall back to regular contract funding if queue function not available
        return await requestContractFunding(credentials: credentials, amount: amount);
      }
      
      final amountWei = BigInt.from((amount * 1000000000000000000).round());
      
      // Check if user can request funding (cooldown check)
      if (_canRequestFaucet != null) {
        final userAddress = await credentials.extractAddress();
        final canRequest = await _client!.call(
          contract: _contract!,
          function: _canRequestFaucet!,
          params: [userAddress],
        );
        
        if (!(canRequest[0] as bool)) {
          final timeLeft = canRequest[1] as BigInt;
          throw Exception('Cooldown period not met. Wait ${timeLeft} seconds.');
        }
      }
      
      // Request funds from queue
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _requestFromQueue!,
        parameters: [amountWei],
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 Gwei
        maxGas: 150000,
      );
      
      final txHash = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: await _getChainId(),
      );
      
      return {
        'success': true,
        'transactionHash': txHash,
        'amount': amount,
        'method': 'requestFromQueue',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'method': 'requestFromQueue',
      };
    }
  }
  
  /// Request default faucet amount from queue
  Future<Map<String, dynamic>> requestFromQueueDefault({
    required Credentials credentials,
  }) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) {
        throw Exception('Contract not initialized');
      }
      
      if (_requestFromQueueDefault == null) {
        // Fall back to regular request if queue function not available
        return await requestFromQueue(credentials: credentials, amount: 1.0);
      }
      
      // Check if user can request funding (cooldown check)
      if (_canRequestFaucet != null) {
        final userAddress = await credentials.extractAddress();
        final canRequest = await _client!.call(
          contract: _contract!,
          function: _canRequestFaucet!,
          params: [userAddress],
        );
        
        if (!(canRequest[0] as bool)) {
          final timeLeft = canRequest[1] as BigInt;
          throw Exception('Cooldown period not met. Wait ${timeLeft} seconds.');
        }
      }
      
      // Request default amount from queue
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _requestFromQueueDefault!,
        parameters: [],
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 Gwei
        maxGas: 150000,
      );
      
      final txHash = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: await _getChainId(),
      );
      
      return {
        'success': true,
        'transactionHash': txHash,
        'method': 'requestFromQueueDefault',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'method': 'requestFromQueueDefault',
      };
    }
  }
  
  /// Request funding directly from contract (requires credentials)
  Future<Map<String, dynamic>> requestContractFunding({
    required Credentials credentials,
    double amount = 1.0,
  }) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) {
        throw Exception('Contract not initialized');
      }
      
      if (_canRequestFaucet == null || _requestFaucetAmount == null) {
        throw Exception('Contract does not support faucet functionality');
      }
      
      final amountWei = BigInt.from((amount * 1000000000000000000).round());
      
      // Check if user can request funding
      final userAddress = await credentials.extractAddress();
      final canRequest = await _client!.call(
        contract: _contract!,
        function: _canRequestFaucet!,
        params: [userAddress],
      );
      
      if (!(canRequest[0] as bool)) {
        final timeLeft = canRequest[1] as BigInt;
        throw Exception('Cooldown period not met. Wait ${timeLeft} seconds.');
      }
      
      // Request specific amount
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _requestFaucetAmount!,
        parameters: [amountWei],
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 Gwei
        maxGas: 100000,
      );
      
      final txHash = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: await _getChainId(),
      );
      
      return {
        'success': true,
        'transactionHash': txHash,
        'amount': amount,
        'method': 'contract',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'method': 'contract',
      };
    }
  }
  
  /// Get contract faucet information
  Future<Map<String, dynamic>?> getContractFaucetInfo() async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) return null;
      
      if (_getFaucetInfo == null) {
        if (kDebugMode) {
          print('getFaucetInfo function not available in contract');
        }
        return null;
      }
      
      final result = await _client!.call(
        contract: _contract!,
        function: _getFaucetInfo!,
        params: [],
      );
      
      return {
        'amount': (result[0] as BigInt).toDouble() / 1000000000000000000, // Convert wei to ETH
        'cooldown': (result[1] as BigInt).toInt(),
        'enabled': result[2] as bool,
        'balance': (result[3] as BigInt).toDouble() / 1000000000000000000, // Convert wei to ETH
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting contract faucet info: $e');
      }
      return null;
    }
  }
  
  /// Check if user can request contract funding
  Future<Map<String, dynamic>?> canRequestContractFunding(String walletAddress) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) return null;
      
      if (_canRequestFaucet == null) {
        if (kDebugMode) {
          print('canRequestFaucet function not available in contract');
        }
        return null;
      }
      
      final userAddress = EthereumAddress.fromHex(walletAddress);
      final result = await _client!.call(
        contract: _contract!,
        function: _canRequestFaucet!,
        params: [userAddress],
      );
      
      return {
        'canRequest': result[0] as bool,
        'timeLeft': (result[1] as BigInt).toInt(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error checking contract funding availability: $e');
      }
      return null;
    }
  }
  
  /// Join the faucet funding queue by contributing ETH
  Future<Map<String, dynamic>> joinFaucetFunding({
    required Credentials credentials,
    double contributionAmount = 0.5, // Default 0.5 ETH contribution
  }) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) {
        throw Exception('Contract not initialized');
      }
      
      if (_joinFaucetFunding == null) {
        throw Exception('Contract does not support faucet funding queue');
      }
      
      final contributionWei = BigInt.from((contributionAmount * 1000000000000000000).round());
      
      // Create transaction to join faucet funding
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _joinFaucetFunding!,
        parameters: [],
        value: EtherAmount.inWei(contributionWei),
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 Gwei
        maxGas: 150000,
      );
      
      final txHash = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: await _getChainId(),
      );
      
      return {
        'success': true,
        'transactionHash': txHash,
        'contributionAmount': contributionAmount,
        'method': 'joinFaucetFunding',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'method': 'joinFaucetFunding',
      };
    }
  }
  
  /// Add more funding to existing faucet contribution
  Future<Map<String, dynamic>> addFaucetFunding({
    required Credentials credentials,
    double additionalAmount = 0.1, // Default 0.1 ETH additional
  }) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) {
        throw Exception('Contract not initialized');
      }
      
      if (_addFaucetFunding == null) {
        throw Exception('Contract does not support adding faucet funding');
      }
      
      final amountWei = BigInt.from((additionalAmount * 1000000000000000000).round());
      
      // Create transaction to add faucet funding
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _addFaucetFunding!,
        parameters: [],
        value: EtherAmount.inWei(amountWei),
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 Gwei
        maxGas: 100000,
      );
      
      final txHash = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: await _getChainId(),
      );
      
      return {
        'success': true,
        'transactionHash': txHash,
        'additionalAmount': additionalAmount,
        'method': 'addFaucetFunding',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'method': 'addFaucetFunding',
      };
    }
  }
  
  /// Leave faucet funding queue and withdraw contribution
  Future<Map<String, dynamic>> leaveFaucetFunding({
    required Credentials credentials,
  }) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) {
        throw Exception('Contract not initialized');
      }
      
      if (_leaveFaucetFunding == null) {
        throw Exception('Contract does not support leaving faucet funding');
      }
      
      // Create transaction to leave faucet funding
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _leaveFaucetFunding!,
        parameters: [],
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 Gwei
        maxGas: 150000,
      );
      
      final txHash = await _client!.sendTransaction(
        credentials,
        transaction,
        chainId: await _getChainId(),
      );
      
      return {
        'success': true,
        'transactionHash': txHash,
        'method': 'leaveFaucetFunding',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'method': 'leaveFaucetFunding',
      };
    }
  }
  
  /// Get faucet funding queue information
  Future<Map<String, dynamic>?> getFaucetFundingInfo() async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) return null;
      
      if (_getFaucetFundingInfo == null) {
        if (kDebugMode) {
          print('getFaucetFundingInfo function not available in contract');
        }
        return null;
      }
      
      final result = await _client!.call(
        contract: _contract!,
        function: _getFaucetFundingInfo!,
        params: [],
      );
      
      return {
        'totalFunders': (result[0] as BigInt).toInt(),
        'totalContributions': (result[1] as BigInt).toDouble() / 1000000000000000000, // Convert wei to ETH
        'contractBalance': (result[2] as BigInt).toDouble() / 1000000000000000000, // Convert wei to ETH
        'minimumContribution': (result[3] as BigInt).toDouble() / 1000000000000000000, // Convert wei to ETH
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting faucet funding info: $e');
      }
      return null;
    }
  }
  
  /// Get specific funder information
  Future<Map<String, dynamic>?> getFunderInfo(String funderAddress) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) return null;
      
      if (_getFunderInfo == null) {
        if (kDebugMode) {
          print('getFunderInfo function not available in contract');
        }
        return null;
      }
      
      final userAddress = EthereumAddress.fromHex(funderAddress);
      final result = await _client!.call(
        contract: _contract!,
        function: _getFunderInfo!,
        params: [userAddress],
      );
      
      return {
        'contributedAmount': (result[0] as BigInt).toDouble() / 1000000000000000000, // Convert wei to ETH
        'contributedAt': (result[1] as BigInt).toInt(),
        'isActive': result[2] as bool,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting funder info: $e');
      }
      return null;
    }
  }
  
  /// Get list of active funders
  Future<List<String>?> getActiveFunders() async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) return null;
      
      if (_getActiveFunders == null) {
        if (kDebugMode) {
          print('getActiveFunders function not available in contract');
        }
        return null;
      }
      
      final result = await _client!.call(
        contract: _contract!,
        function: _getActiveFunders!,
        params: [],
      );
      
      final addressList = result[0] as List<dynamic>;
      return addressList.map((addr) => (addr as EthereumAddress).hex).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active funders: $e');
      }
      return null;
    }
  }
  
  /// Get chain ID for transactions
  Future<int> _getChainId() async {
    try {
      // Use getChainId() for transaction signing, not getNetworkId()
      final chainId = await _client!.getChainId();
      return chainId.toInt();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chain ID: $e');
      }
      return 1337; // Default Ganache chain ID (correct value)
    }
  }
  
  /// Debug method to check contract and queue state
  Future<Map<String, dynamic>?> debugContractState() async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) return null;
      
      // Get contract ETH balance
      final contractAddress = _contract!.address;
      final contractBalance = await _client!.getBalance(contractAddress);
      
      // Get queue information
      final queueInfo = await getFaucetFundingInfo();
      
      // Get active funders
      final activeFunders = await getActiveFunders();
      
      return {
        'contractAddress': contractAddress.hex,
        'contractBalance': contractBalance.getValueInUnit(EtherUnit.ether),
        'queueInfo': queueInfo,
        'activeFunders': activeFunders,
        'totalFunders': activeFunders?.length ?? 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error debugging contract state: $e');
      }
      return null;
    }
  }
  
  /// Check cooldown status for a user
  Future<Map<String, dynamic>?> checkCooldownStatus(String userAddress) async {
    try {
      await _initializeContract();
      if (!_isContractInitialized) return null;
      
      if (_canRequestFaucet == null) return null;
      
      final address = EthereumAddress.fromHex(userAddress);
      final result = await _client!.call(
        contract: _contract!,
        function: _canRequestFaucet!,
        params: [address],
      );
      
      final canRequest = result[0] as bool;
      final timeLeft = (result[1] as BigInt).toInt();
      
      return {
        'canRequest': canRequest,
        'timeLeftSeconds': timeLeft,
        'timeLeftMinutes': (timeLeft / 60).round(),
        'timeLeftHours': (timeLeft / 3600).round(),
        'currentTimestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error checking cooldown status: $e');
      }
      return null;
    }
  }

  /// Check if funding is available (local development mode)
  bool get isFundingAvailable {
    return dotenv.env['NETWORK_MODE'] == 'local';
  }

  /// Get funding information
  Future<Map<String, dynamic>> getFundingInfo() async {
    final contractInfo = await getContractFaucetInfo();
    
    return {
      'available': isFundingAvailable,
      'networkMode': dotenv.env['NETWORK_MODE'],
      'maxAmount': 10.0, // Max 10 ETH per request
      'description': isFundingAvailable 
          ? 'Test ETH available from contract faucet (Ganache 8545)'
          : 'Funding only available in local development',
      'contractFaucet': contractInfo != null ? {
        'available': contractInfo['enabled'],
        'amount': contractInfo['amount'],
        'balance': contractInfo['balance'],
        'cooldown': contractInfo['cooldown'],
      } : null,
      'methods': ['contract'],
    };
  }
  
  /// Cleanup resources
  void dispose() {
    _client?.dispose();
    _isContractInitialized = false;
  }
}