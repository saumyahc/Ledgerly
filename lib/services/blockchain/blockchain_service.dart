import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'wallet_service.dart';

/// Service for managing blockchain connections and operations
class BlockchainService {
  late Web3Client _client;
  
  // Network configurations
  static Map<String, NetworkConfig> get _networks => {
    'ethereum_mainnet': NetworkConfig(
      name: 'Ethereum Mainnet',
      rpcUrl: dotenv.env['ETHEREUM_RPC_URL'] ?? 'https://mainnet.infura.io/v3/YOUR_PROJECT_ID',
      chainId: 1,
      symbol: 'ETH',
      blockExplorer: 'https://etherscan.io',
    ),
    'ethereum_sepolia': NetworkConfig(
      name: 'Ethereum Sepolia Testnet',
      rpcUrl: dotenv.env['ETHEREUM_RPC_URL']?.replaceAll('mainnet', 'sepolia') ?? 'https://sepolia.infura.io/v3/YOUR_PROJECT_ID',
      chainId: 11155111,
      symbol: 'SepoliaETH',
      blockExplorer: 'https://sepolia.etherscan.io',
    ),
    'polygon': NetworkConfig(
      name: 'Polygon Mainnet',
      rpcUrl: 'https://polygon-rpc.com',
      chainId: 137,
      symbol: 'MATIC',
      blockExplorer: 'https://polygonscan.com',
    ),
    'local': NetworkConfig(
      name: 'Local Development',
      rpcUrl: 'http://127.0.0.1:8545',
      chainId: 1337,
      symbol: 'ETH',
      blockExplorer: 'http://localhost',
    ),
  };
  
  NetworkConfig _currentNetwork = _networks['ethereum_sepolia']!;
  
  /// Initializes the blockchain service with default network
  BlockchainService() {
    _initializeClient();
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
  final String blockExplorer;
  
  const NetworkConfig({
    required this.name,
    required this.rpcUrl,
    required this.chainId,
    required this.symbol,
    required this.blockExplorer,
  });
}

/// Custom exception for blockchain operations
class BlockchainException implements Exception {
  final String message;
  
  const BlockchainException(this.message);
  
  @override
  String toString() => 'BlockchainException: $message';
}
