import 'dart:async';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/transaction_model.dart';
import 'blockchain_service.dart';
import 'wallet_service.dart';

/// Service for managing transaction history and operations
class TransactionService {
  static const _storage = FlutterSecureStorage();
  static const String _transactionHistoryKey = 'ledgerly_transaction_history';
  
  final BlockchainService _blockchainService;
  final StreamController<List<TransactionModel>> _transactionController;
  
  List<TransactionModel> _transactions = [];
  Timer? _refreshTimer;
  
  TransactionService(this._blockchainService) 
      : _transactionController = StreamController<List<TransactionModel>>.broadcast() {
    _loadTransactionHistory();
    _startPeriodicRefresh();
  }
  
  /// Stream of transaction updates
  Stream<List<TransactionModel>> get transactionStream => _transactionController.stream;
  
  /// Current list of transactions
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  
  /// Loads transaction history from secure storage
  Future<void> _loadTransactionHistory() async {
    try {
      final historyJson = await _storage.read(key: _transactionHistoryKey);
      if (historyJson != null) {
        final List<dynamic> historyList = (historyJson as List);
        _transactions = historyList
            .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Sort by timestamp, newest first
        _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _transactionController.add(_transactions);
      }
    } catch (e) {
      print('Error loading transaction history: $e');
    }
  }
  
  /// Saves transaction history to secure storage
  Future<void> _saveTransactionHistory() async {
    try {
      final historyJson = _transactions.map((tx) => tx.toJson()).toList();
      await _storage.write(key: _transactionHistoryKey, value: historyJson.toString());
    } catch (e) {
      print('Error saving transaction history: $e');
    }
  }
  
  /// Sends a transaction and adds it to history
  Future<String> sendTransaction({
    required String toAddress,
    required double amount,
    String? memo,
    double? gasPrice,
    int? gasLimit,
  }) async {
    final walletAddress = await WalletService.getWalletAddress();
    if (walletAddress == null) {
      throw Exception('No wallet found');
    }
    
    // Send the transaction
    final txHash = await _blockchainService.sendEther(
      toAddress: toAddress,
      amount: amount,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
    );
    
    // Create transaction model
    final transaction = TransactionModel(
      hash: txHash,
      from: walletAddress,
      to: toAddress,
      amount: amount,
      currency: _blockchainService.currentNetwork.symbol,
      timestamp: DateTime.now(),
      confirmations: 0,
      gasUsed: gasLimit?.toDouble() ?? 21000.0,
      gasPrice: gasPrice ?? await _blockchainService.getGasPrice(),
      status: TransactionStatus.pending,
      memo: memo,
      network: _blockchainService.currentNetwork.name,
    );
    
    // Add to history
    await addTransaction(transaction);
    
    // Start monitoring for confirmation
    _monitorTransaction(txHash);
    
    return txHash;
  }
  
  /// Adds a transaction to the history
  Future<void> addTransaction(TransactionModel transaction) async {
    // Check if transaction already exists
    final existingIndex = _transactions.indexWhere((tx) => tx.hash == transaction.hash);
    
    if (existingIndex != -1) {
      // Update existing transaction
      _transactions[existingIndex] = transaction;
    } else {
      // Add new transaction
      _transactions.insert(0, transaction); // Add to beginning (newest first)
    }
    
    await _saveTransactionHistory();
    _transactionController.add(_transactions);
  }
  
  /// Monitors a transaction for confirmation
  void _monitorTransaction(String txHash) {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final receipt = await _blockchainService.getTransactionReceipt(txHash);
        if (receipt != null) {
          // Transaction is confirmed
          await _updateTransactionStatus(txHash, receipt);
          timer.cancel();
        }
      } catch (e) {
        print('Error monitoring transaction $txHash: $e');
        // Continue monitoring unless it's been too long
        if (timer.tick > 180) { // 30 minutes
          timer.cancel();
        }
      }
    });
  }
  
  /// Updates transaction status based on receipt
  Future<void> _updateTransactionStatus(String txHash, TransactionReceipt receipt) async {
    final txIndex = _transactions.indexWhere((tx) => tx.hash == txHash);
    if (txIndex == -1) return;
    
    final currentTx = _transactions[txIndex];
    final blockNumber = await _blockchainService.getBlockNumber();
    final confirmations = blockNumber - receipt.blockNumber.blockNum;
    
    final updatedTx = TransactionModel(
      hash: currentTx.hash,
      from: currentTx.from,
      to: currentTx.to,
      amount: currentTx.amount,
      currency: currentTx.currency,
      timestamp: currentTx.timestamp,
      confirmations: confirmations,
      gasUsed: receipt.gasUsed?.toDouble() ?? currentTx.gasUsed,
      gasPrice: currentTx.gasPrice,
      status: receipt.status == true ? TransactionStatus.confirmed : TransactionStatus.failed,
      memo: currentTx.memo,
      network: currentTx.network,
    );
    
    await addTransaction(updatedTx);
  }
  
  /// Refreshes transaction confirmations
  Future<void> refreshTransactions() async {
    for (int i = 0; i < _transactions.length; i++) {
      final tx = _transactions[i];
      if (tx.status == TransactionStatus.pending || tx.confirmations < 12) {
        try {
          final receipt = await _blockchainService.getTransactionReceipt(tx.hash);
          if (receipt != null) {
            await _updateTransactionStatus(tx.hash, receipt);
          }
        } catch (e) {
          print('Error refreshing transaction ${tx.hash}: $e');
        }
      }
    }
  }
  
  /// Gets transactions by status
  List<TransactionModel> getTransactionsByStatus(TransactionStatus status) {
    return _transactions.where((tx) => tx.status == status).toList();
  }
  
  /// Gets pending transactions
  List<TransactionModel> get pendingTransactions => getTransactionsByStatus(TransactionStatus.pending);
  
  /// Gets confirmed transactions
  List<TransactionModel> get confirmedTransactions => getTransactionsByStatus(TransactionStatus.confirmed);
  
  /// Gets failed transactions
  List<TransactionModel> get failedTransactions => getTransactionsByStatus(TransactionStatus.failed);
  
  /// Calculates total spent (outgoing transactions)
  Future<double> getTotalSpent({String? currency}) async {
    final walletAddress = await WalletService.getWalletAddress();
    if (walletAddress == null) return 0.0;
    
    double total = 0.0;
    for (final tx in _transactions) {
      if (tx.from.toLowerCase() == walletAddress.toLowerCase() &&
          tx.status == TransactionStatus.confirmed &&
          (currency == null || tx.currency == currency)) {
        total += tx.amount + tx.transactionFee;
      }
    }
    return total;
  }
  
  /// Calculates total received (incoming transactions)
  Future<double> getTotalReceived({String? currency}) async {
    final walletAddress = await WalletService.getWalletAddress();
    if (walletAddress == null) return 0.0;
    
    double total = 0.0;
    for (final tx in _transactions) {
      if (tx.to.toLowerCase() == walletAddress.toLowerCase() &&
          tx.status == TransactionStatus.confirmed &&
          (currency == null || tx.currency == currency)) {
        total += tx.amount;
      }
    }
    return total;
  }
  
  /// Starts periodic refresh of transactions
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      refreshTransactions();
    });
  }
  
  /// Clears all transaction history
  Future<void> clearHistory() async {
    _transactions.clear();
    await _storage.delete(key: _transactionHistoryKey);
    _transactionController.add(_transactions);
  }
  
  /// Exports transaction history as JSON string
  String exportHistory() {
    return _transactions.map((tx) => tx.toJson()).toList().toString();
  }
  
  /// Disposes the service
  void dispose() {
    _refreshTimer?.cancel();
    _transactionController.close();
  }
}
