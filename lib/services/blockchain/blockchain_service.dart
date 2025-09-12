import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../contract_config.dart';
import 'wallet_service.dart';

/// Service for managing blockchain connections and operations
class BlockchainService {
  String? _emailPaymentRegistryAbi;

  /// Loads the EmailPaymentRegistry ABI from the JSON file in lib/
  Future<void> loadEmailPaymentRegistryAbi() async {
    if (_emailPaymentRegistryAbi != null) return;
    final abiString = await rootBundle.loadString('lib/EmailPaymentRegistry_compData.json');
    _emailPaymentRegistryAbi = abiString;
  }

  /// Gets the deployed EmailPaymentRegistry contract
  Future<DeployedContract> getEmailPaymentRegistryContract() async {
    await loadEmailPaymentRegistryAbi();
    final abi = jsonDecode(_emailPaymentRegistryAbi!);
    return DeployedContract(
      ContractAbi.fromJson(jsonEncode(abi), 'EmailPaymentRegistry'),
      EthereumAddress.fromHex(ContractConfig.emailPaymentRegistryAddress),
    );
  }
  late Web3Client _client;
  
  // Network configurations using your Infura setup
  static Map<String, NetworkConfig> get _networks {
    final infuraApiKey = dotenv.env['ETHEREUM_API_KEY'] ?? 'c669c4a6004f44eebe61de67c401b7a5';
    final enableMainnet = dotenv.env['ENABLE_MAINNET']?.toLowerCase() == 'true';
    
    return {
      'ethereum_mainnet': NetworkConfig(
        name: 'Ethereum Mainnet',
        rpcUrl: 'https://mainnet.infura.io/v3/$infuraApiKey',
        chainId: 1,
        symbol: 'ETH',
        blockExplorer: 'https://etherscan.io',
        isMainnet: true,
      ),
      'ethereum_sepolia': NetworkConfig(
        name: 'Ethereum Sepolia Testnet',
        rpcUrl: 'https://sepolia.infura.io/v3/$infuraApiKey',
        chainId: 11155111,
        symbol: 'SepoliaETH',
        blockExplorer: 'https://sepolia.etherscan.io',
        isMainnet: false,
      ),
      'ethereum_goerli': NetworkConfig(
        name: 'Ethereum Goerli Testnet',
        rpcUrl: 'https://goerli.infura.io/v3/$infuraApiKey',
        chainId: 5,
        symbol: 'GoerliETH',
        blockExplorer: 'https://goerli.etherscan.io',
        isMainnet: false,
      ),
      'polygon': NetworkConfig(
        name: 'Polygon Mainnet',
        rpcUrl: 'https://polygon-mainnet.infura.io/v3/$infuraApiKey',
        chainId: 137,
        symbol: 'MATIC',
        blockExplorer: 'https://polygonscan.com',
        isMainnet: true,
      ),
      'polygon_mumbai': NetworkConfig(
        name: 'Polygon Mumbai Testnet',
        rpcUrl: 'https://polygon-mumbai.infura.io/v3/$infuraApiKey',
        chainId: 80001,
        symbol: 'MATIC',
        blockExplorer: 'https://mumbai.polygonscan.com',
        isMainnet: false,
      ),
      'local_ganache': NetworkConfig(
        name: 'Local Ganache',
        rpcUrl: 'http://127.0.0.1:7545',
        chainId: 1337,
        symbol: 'ETH',
        blockExplorer: null,
        isMainnet: false,
      ),
      'local_hardhat': NetworkConfig(
        name: 'Local Hardhat',
        rpcUrl: 'http://127.0.0.1:8545',
        chainId: 31337,
        symbol: 'ETH',
        blockExplorer: null,
        isMainnet: false,
      ),
    };
  }
  
  late NetworkConfig _currentNetwork;
  
  /// Initializes the blockchain service with network based on environment
  BlockchainService() {
    _currentNetwork = _getDefaultNetwork();
    _initializeClient();
  }
  
  /// Get default network based on environment configuration
  NetworkConfig _getDefaultNetwork() {
    final enableMainnet = dotenv.env['ENABLE_MAINNET']?.toLowerCase() == 'true';
    final debugMode = dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
    
    if (debugMode) {
      // In debug mode, prefer local development if available, otherwise Sepolia
      return _networks['local_ganache'] ?? _networks['ethereum_sepolia']!;
    } else if (enableMainnet) {
      // Production mode with mainnet enabled
      return _networks['ethereum_mainnet']!;
    } else {
      // Production mode but using testnet (recommended for initial deployment)
      return _networks['ethereum_sepolia']!;
    }
  }
  
  void _initializeClient() {
    _client = Web3Client(_currentNetwork.rpcUrl, Client());
  }
  
  /// Changes the network
  void setNetwork(String networkKey) {
    if (_networks.containsKey(networkKey)) {
      _currentNetwork = _networks[networkKey]!;
      _initializeClient();
    }
  }
  
  /// Gets current network information
  NetworkConfig get currentNetwork => _currentNetwork;
  
  /// Gets available networks
  Map<String, NetworkConfig> get availableNetworks => _networks;
  
  /// Gets available testnet networks (safe for development)
  Map<String, NetworkConfig> get testNetworks => 
    Map.fromEntries(_networks.entries.where((entry) => !entry.value.isMainnet));
  
  /// Gets available mainnet networks (real money - use with caution)
  Map<String, NetworkConfig> get mainnetNetworks => 
    Map.fromEntries(_networks.entries.where((entry) => entry.value.isMainnet));
  
  /// Check if current network is safe for development
  bool get isCurrentNetworkSafe => _currentNetwork.isTestNetwork;
  
  /// Get network status and configuration info
  Map<String, dynamic> getNetworkStatus() {
    return {
      'current_network': _currentNetwork.name,
      'chain_id': _currentNetwork.chainId,
      'rpc_url': _currentNetwork.rpcUrl,
      'symbol': _currentNetwork.symbol,
      'is_mainnet': _currentNetwork.isMainnet,
      'is_safe': _currentNetwork.isTestNetwork,
      'block_explorer': _currentNetwork.blockExplorer,
      'debug_mode': dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true',
      'mainnet_enabled': dotenv.env['ENABLE_MAINNET']?.toLowerCase() == 'true',
    };
  }
  
  /// Gets the balance of an address in Wei
  Future<EtherAmount> getBalance(String address) async {
    try {
      final ethAddress = EthereumAddress.fromHex(address);
      return await _client.getBalance(ethAddress);
    } catch (e) {
      throw BlockchainException('Failed to get balance: $e');
    }
  }
  
  /// Gets the balance in Ether (human readable format)
  Future<double> getBalanceInEther(String address) async {
    final balance = await getBalance(address);
    return balance.getValueInUnit(EtherUnit.ether);
  }
  
  /// Sends Ether to another address
  Future<String> sendEther({
    required String toAddress,
    required double amount,
    double? gasPrice,
    int? gasLimit,
  }) async {
    try {
      final credentials = await WalletService.getCredentials();
      if (credentials == null) {
        throw BlockchainException('No wallet credentials found');
      }
      
      final toEthAddress = EthereumAddress.fromHex(toAddress);
      final etherAmount = EtherAmount.fromUnitAndValue(EtherUnit.ether, amount);
      
      // Get current gas price if not provided
      final currentGasPrice = gasPrice != null 
          ? EtherAmount.fromUnitAndValue(EtherUnit.gwei, gasPrice)
          : await _client.getGasPrice();
      
      // Create transaction
      final transaction = Transaction(
        to: toEthAddress,
        gasPrice: currentGasPrice,
        maxGas: gasLimit ?? 21000,
        value: etherAmount,
      );
      
      // Send transaction
      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: _currentNetwork.chainId,
      );
      
      return txHash;
    } catch (e) {
      throw BlockchainException('Failed to send transaction: $e');
    }
  }
  
  /// Gets transaction details by hash
  Future<TransactionInformation?> getTransaction(String txHash) async {
    try {
      return await _client.getTransactionByHash(txHash);
    } catch (e) {
      throw BlockchainException('Failed to get transaction: $e');
    }
  }
  
  /// Gets transaction receipt
  Future<TransactionReceipt?> getTransactionReceipt(String txHash) async {
    try {
      return await _client.getTransactionReceipt(txHash);
    } catch (e) {
      throw BlockchainException('Failed to get transaction receipt: $e');
    }
  }
  
  /// Estimates gas for a transaction
  Future<BigInt> estimateGas({
    required String toAddress,
    required double amount,
    String? data,
  }) async {
    try {
      final credentials = await WalletService.getCredentials();
      if (credentials == null) {
        throw BlockchainException('No wallet credentials found');
      }
      
      final from = await credentials.extractAddress();
      final to = EthereumAddress.fromHex(toAddress);
      final value = EtherAmount.fromUnitAndValue(EtherUnit.ether, amount);
      
      return await _client.estimateGas(
        sender: from,
        to: to,
        value: value,
      );
    } catch (e) {
      throw BlockchainException('Failed to estimate gas: $e');
    }
  }
  
  /// Gets the current gas price in Gwei
  Future<double> getGasPrice() async {
    try {
      final gasPrice = await _client.getGasPrice();
      return gasPrice.getValueInUnit(EtherUnit.gwei);
    } catch (e) {
      throw BlockchainException('Failed to get gas price: $e');
    }
  }
  
  /// Waits for transaction confirmation
  Future<TransactionReceipt> waitForConfirmation(String txHash, {int timeoutSeconds = 300}) async {
    final timeout = DateTime.now().add(Duration(seconds: timeoutSeconds));
    
    while (DateTime.now().isBefore(timeout)) {
      final receipt = await getTransactionReceipt(txHash);
      if (receipt != null) {
        return receipt;
      }
      
      await Future.delayed(const Duration(seconds: 2));
    }
    
    throw BlockchainException('Transaction confirmation timeout');
  }
  
  /// Checks if the service is connected to the network
  Future<bool> isConnected() async {
    try {
      await _client.getNetworkId();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Gets the current block number
  Future<int> getBlockNumber() async {
    try {
      return await _client.getBlockNumber();
    } catch (e) {
      throw BlockchainException('Failed to get block number: $e');
    }
  }
  
  /// Disposes the client
  void dispose() {
    _client.dispose();
  }
}

/// Network configuration model
class NetworkConfig {
  final String name;
  final String rpcUrl;
  final int chainId;
  final String symbol;
  final String? blockExplorer;
  final bool isMainnet;
  
  const NetworkConfig({
    required this.name,
    required this.rpcUrl,
    required this.chainId,
    required this.symbol,
    this.blockExplorer,
    this.isMainnet = false,
  });
  
  /// Returns true if this is a mainnet (real money) network
  bool get isProduction => isMainnet;
  
  /// Returns true if this is a testnet or local network
  bool get isTestNetwork => !isMainnet;
}

/// Custom exception for blockchain operations
class BlockchainException implements Exception {
  final String message;
  
  const BlockchainException(this.message);
  
  @override
  String toString() => 'BlockchainException: $message';
}
