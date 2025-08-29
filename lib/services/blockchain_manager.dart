import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'blockchain/wallet_service.dart';
import 'blockchain/blockchain_service.dart';
import 'blockchain/transaction_service.dart';
import '../models/transaction_model.dart';

/// Main blockchain manager that coordinates all blockchain services
class BlockchainManager {
  static BlockchainManager? _instance;
  static BlockchainManager get instance => _instance ??= BlockchainManager._internal();
  
  BlockchainManager._internal();
  
  late BlockchainService _blockchainService;
  late TransactionService _transactionService;
  
  bool _isInitialized = false;
  String _currentNetwork = 'ethereum_sepolia'; // Default to testnet for safety
  
  /// Initialize the blockchain manager
  Future<void> initialize({String? network}) async {
    if (_isInitialized) return;
    
    // Use environment variable or parameter, but default to testnet for safety
    final selectedNetwork = network ?? 
        (dotenv.env['ENABLE_MAINNET'] == 'true' ? 'ethereum_mainnet' : 'ethereum_sepolia');
    
    _blockchainService = BlockchainService();
    _blockchainService.setNetwork(selectedNetwork);
    _currentNetwork = selectedNetwork;
    
    _transactionService = TransactionService(_blockchainService);
    
    _isInitialized = true;
  }
  
  /// Check if the manager is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get the current network name
  String get currentNetwork => _currentNetwork;
  
  /// Get current network info
  dynamic get currentNetworkInfo {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return _blockchainService.currentNetwork;
  }
  
  /// Switch to a different network
  Future<void> switchNetwork(String networkKey) async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    
    _blockchainService.setNetwork(networkKey);
    _currentNetwork = networkKey;
  }
  
  /// Check if a wallet exists
  Future<bool> hasWallet() async {
    return await WalletService.hasWallet();
  }
  
  /// Create a new wallet and return the mnemonic
  Future<String> createWallet() async {
    final mnemonic = await WalletService.generateWallet();
    return mnemonic;
  }
  
  /// Import a wallet from mnemonic
  Future<bool> importWallet(String mnemonic) async {
    return await WalletService.importWallet(mnemonic);
  }
  
  /// Get wallet address
  Future<String?> getWalletAddress() async {
    return await WalletService.getWalletAddress();
  }
  
  /// Get wallet balance in the network's native currency
  Future<double> getBalance() async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    
    final address = await getWalletAddress();
    if (address == null) throw Exception('No wallet found');
    
    return await _blockchainService.getBalanceInEther(address);
  }
  
  /// Send a transaction
  Future<String> sendTransaction({
    required String toAddress,
    required double amount,
    String? memo,
    double? gasPrice,
  }) async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    
    return await _transactionService.sendTransaction(
      toAddress: toAddress,
      amount: amount,
      memo: memo,
      gasPrice: gasPrice,
    );
  }
  
  /// Get transaction history
  List<TransactionModel> getTransactionHistory() {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return _transactionService.transactions;
  }
  
  /// Stream of transaction updates
  Stream<List<TransactionModel>> get transactionStream {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return _transactionService.transactionStream;
  }
  
  /// Get pending transactions
  List<TransactionModel> get pendingTransactions {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return _transactionService.pendingTransactions;
  }
  
  /// Refresh transaction status
  Future<void> refreshTransactions() async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    await _transactionService.refreshTransactions();
  }
  
  /// Get current gas price
  Future<double> getGasPrice() async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return await _blockchainService.getGasPrice();
  }
  
  /// Estimate gas for a transaction
  Future<BigInt> estimateGas({
    required String toAddress,
    required double amount,
  }) async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return await _blockchainService.estimateGas(
      toAddress: toAddress,
      amount: amount,
    );
  }
  
  /// Check if connected to the network
  Future<bool> isConnected() async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return await _blockchainService.isConnected();
  }
  
  /// Validate an Ethereum address
  bool isValidAddress(String address) {
    return WalletService.isValidAddress(address);
  }
  
  /// Get available networks
  Map<String, dynamic> getAvailableNetworks() {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return _blockchainService.availableNetworks;
  }
  
  /// Get current network info
  dynamic getCurrentNetworkInfo() {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return _blockchainService.currentNetwork;
  }
  
  /// Get total spent amount
  Future<double> getTotalSpent({String? currency}) async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return await _transactionService.getTotalSpent(currency: currency);
  }
  
  /// Get total received amount
  Future<double> getTotalReceived({String? currency}) async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return await _transactionService.getTotalReceived(currency: currency);
  }
  
  /// Export transaction history
  String exportTransactionHistory() {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    return _transactionService.exportHistory();
  }
  
  /// Clear transaction history
  Future<void> clearTransactionHistory() async {
    if (!_isInitialized) throw Exception('BlockchainManager not initialized');
    await _transactionService.clearHistory();
  }
  
  /// Delete wallet (use with extreme caution)
  Future<void> deleteWallet() async {
    await WalletService.deleteWallet();
    if (_isInitialized) {
      await _transactionService.clearHistory();
    }
  }
  
  /// Dispose the manager and clean up resources
  void dispose() {
    if (_isInitialized) {
      _transactionService.dispose();
      _blockchainService.dispose();
      _isInitialized = false;
    }
    _instance = null;
  }
}
