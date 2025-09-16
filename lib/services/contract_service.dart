import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dynamic_contract_config.dart';

/// Simple service to interact with deployed EmailPaymentRegistry contract
class ContractService {
  late Web3Client _client;
  late DeployedContract _contract;
  late EthereumAddress _contractAddress;
  late DynamicContractConfig _contractConfig;
  
  bool _isInitialized = false;
  
  /// Initialize contract connection using dynamic configuration
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Load environment
    await dotenv.load();
    
    // Initialize dynamic contract config
    _contractConfig = DynamicContractConfig.instance;
    
    // Get RPC URL based on network mode
    String rpcUrl;
    if (dotenv.env['NETWORK_MODE'] == 'local') {
      rpcUrl = dotenv.env['LOCAL_RPC_URL'] ?? 'http://127.0.0.1:8545';
    } else {
      rpcUrl = dotenv.env['ETHEREUM_RPC_URL'] ?? '';
    }
    
    if (rpcUrl.isEmpty) {
      throw Exception('RPC URL not configured');
    }
    
    // Create Web3 client
    _client = Web3Client(rpcUrl, http.Client());
    
    // Load contract from dynamic config
    final contractAddress = await _contractConfig.contractAddress;
    final contractAbi = await _contractConfig.abi;
    final contractName = await _contractConfig.contractName;
    
    _contractAddress = EthereumAddress.fromHex(contractAddress);
    final abi = ContractAbi.fromJson(contractAbi, contractName);
    _contract = DeployedContract(abi, _contractAddress);
    
    _isInitialized = true;
    print('✅ Contract service initialized');
    print('   Address: $contractAddress');
    print('   Network: ${dotenv.env['NETWORK_MODE']}');
    print('   Config source: ${await _contractConfig.isBackendAvailable() ? "Backend" : "Fallback"}');
  }
  
  /// Send payment to email address via smart contract
  Future<Map<String, dynamic>> sendPaymentToEmail({
    required String email,
    required double amount,
    required Credentials credentials,
    String? memo,
  }) async {
    await initialize();
    
    try {
      // Convert email to bytes32 hash (simple approach)
      final emailBytes = email.toLowerCase().trim().codeUnits;
      final emailHash = emailBytes.take(32).toList();
      while (emailHash.length < 32) emailHash.add(0);
      
      // Convert amount to wei
      final amountWei = EtherAmount.fromUnitAndValue(EtherUnit.ether, amount);
      
      // Get contract function
      final function = _contract.function('sendPaymentToEmail');
      
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [emailHash],
        value: amountWei,
      );
      
      // Send transaction
      final chainId = await _contractConfig.chainId;
      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: chainId,
      );
      
      return {
        'success': true,
        'txHash': txHash,
        'message': 'Payment sent via smart contract'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
  
  /// Look up wallet address for email
  Future<Map<String, dynamic>> lookupEmailWallet(String email) async {
    await initialize();
    
    try {
      // Convert email to bytes32 hash
      final emailBytes = email.toLowerCase().trim().codeUnits;
      final emailHash = emailBytes.take(32).toList();
      while (emailHash.length < 32) emailHash.add(0);
      
      // Get contract function
      final function = _contract.function('getWalletByEmail');
      
      // Call contract
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [emailHash],
      );
      
      if (result.isNotEmpty) {
        final address = result.first as EthereumAddress;
        final addressHex = address.hex;
        
        // Check if it's a valid registered address (not zero address)
        if (addressHex != '0x0000000000000000000000000000000000000000') {
          return {
            'success': true,
            'wallet': addressHex
          };
        }
      }
      
      return {
        'success': false,
        'error': 'Email not registered on contract'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
  
  /// Register current wallet with email
  Future<Map<String, dynamic>> registerEmail({
    required String email,
    required Credentials credentials,
  }) async {
    await initialize();
    
    try {
      // Convert email to bytes32 hash
      final emailBytes = email.toLowerCase().trim().codeUnits;
      final emailHash = emailBytes.take(32).toList();
      while (emailHash.length < 32) emailHash.add(0);
      
      // Get wallet address
      final walletAddress = await credentials.extractAddress();
      
      // Get contract function
      final function = _contract.function('registerEmail');
      
      // Create transaction
      final transaction = Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [emailHash, walletAddress],
      );
      
      // Send transaction
      final chainId = await _contractConfig.chainId;
      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: chainId,
      );
      
      return {
        'success': true,
        'txHash': txHash,
        'message': 'Email registered successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
  
  /// Get contract events (payments, registrations)
  Future<List<Map<String, dynamic>>> getRecentEvents({int? fromBlock}) async {
    await initialize();
    
    try {
      final events = <Map<String, dynamic>>[];
      
      // Get payment events
      final paymentEvent = _contract.event('PaymentSent');
      final paymentLogs = await _client.getLogs(FilterOptions.events(
        contract: _contract,
        event: paymentEvent,
        fromBlock: fromBlock != null ? BlockNum.exact(fromBlock) : null,
      ));
      
      for (final log in paymentLogs) {
        final decoded = paymentEvent.decodeResults(log.topics!, log.data!);
        events.add({
          'type': 'payment',
          'txHash': log.transactionHash,
          'blockNumber': log.blockNum,
          'data': decoded,
        });
      }
      
      // Get registration events
      final registrationEvent = _contract.event('EmailRegistered');
      final registrationLogs = await _client.getLogs(FilterOptions.events(
        contract: _contract,
        event: registrationEvent,
        fromBlock: fromBlock != null ? BlockNum.exact(fromBlock) : null,
      ));
      
      for (final log in registrationLogs) {
        final decoded = registrationEvent.decodeResults(log.topics!, log.data!);
        events.add({
          'type': 'registration',
          'txHash': log.transactionHash,
          'blockNumber': log.blockNum,
          'data': decoded,
        });
      }
      
      // Sort by block number (newest first)
      events.sort((a, b) => b['blockNumber'].compareTo(a['blockNumber']));
      
      return events;
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }
  
  /// Refresh contract configuration from backend
  Future<void> refreshConfig() async {
    _contractConfig.clearCache();
    _isInitialized = false;
    await initialize();
  }
  
  /// Get contract configuration info for debugging
  Future<Map<String, dynamic>> getConfigInfo() async {
    return await _contractConfig.getConfigInfo();
  }
  
  /// Check if backend configuration is available
  Future<bool> isBackendAvailable() async {
    return await _contractConfig.isBackendAvailable();
  }
  
  /// Get current contract address
  String get contractAddress => _contractAddress.hex;
  
  void dispose() {
    _client.dispose();
  }
}