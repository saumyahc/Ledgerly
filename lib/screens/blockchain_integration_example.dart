import 'package:flutter/material.dart';
import '../services/blockchain_manager.dart';
import '../models/transaction_model.dart';

/// Example screen showing how to integrate blockchain functionality
class BlockchainIntegrationExample extends StatefulWidget {
  const BlockchainIntegrationExample({super.key});

  @override
  State<BlockchainIntegrationExample> createState() => _BlockchainIntegrationExampleState();
}

class _BlockchainIntegrationExampleState extends State<BlockchainIntegrationExample> {
  final BlockchainManager _blockchainManager = BlockchainManager.instance;
  bool _isInitialized = false;
  bool _hasWallet = false;
  String? _walletAddress;
  double _balance = 0.0;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeBlockchain();
  }

  Future<void> _initializeBlockchain() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing blockchain...';
    });

    try {
      // Initialize blockchain manager
      await _blockchainManager.initialize(network: 'ethereum_sepolia');
      _isInitialized = true;
      
      // Check if wallet exists
      _hasWallet = await _blockchainManager.hasWallet();
      
      if (_hasWallet) {
        await _loadWalletData();
      }
      
      // Listen to transaction updates
      _blockchainManager.transactionStream.listen((transactions) {
        if (mounted) {
          setState(() {
            _transactions = transactions;
          });
        }
      });
      
      setState(() {
        _statusMessage = _hasWallet ? 'Wallet loaded successfully' : 'No wallet found';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing blockchain: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWalletData() async {
    try {
      _walletAddress = await _blockchainManager.getWalletAddress();
      _balance = await _blockchainManager.getBalance();
      _transactions = _blockchainManager.getTransactionHistory();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading wallet data: $e';
      });
    }
  }

  Future<void> _createWallet() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating wallet...';
    });

    try {
      final mnemonic = await _blockchainManager.createWallet();
      
      // Show mnemonic to user (in production, ensure they save it securely)
      if (mounted) {
        await _showMnemonicDialog(mnemonic);
        
        _hasWallet = true;
        await _loadWalletData();
        setState(() {
          _statusMessage = 'Wallet created successfully';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating wallet: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTransaction() async {
    // Example transaction - replace with your UI
    const recipientAddress = '0x742d35Cc6634C0532925a3b8D88f91b5b57e5A81';
    const amount = 0.001; // 0.001 ETH

    setState(() {
      _isLoading = true;
      _statusMessage = 'Sending transaction...';
    });

    try {
      final txHash = await _blockchainManager.sendTransaction(
        toAddress: recipientAddress,
        amount: amount,
        memo: 'Test payment from Ledgerly',
      );

      setState(() {
        _statusMessage = 'Transaction sent: ${txHash.substring(0, 10)}...';
      });

      // Refresh balance after transaction
      await Future.delayed(const Duration(seconds: 2));
      await _refreshData();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error sending transaction: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_hasWallet) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Refreshing data...';
      });

      try {
        await _loadWalletData();
        await _blockchainManager.refreshTransactions();
        setState(() {
          _statusMessage = 'Data refreshed';
        });
      } catch (e) {
        setState(() {
          _statusMessage = 'Error refreshing data: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showMnemonicDialog(String mnemonic) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('IMPORTANT: Save Your Recovery Phrase'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write down this 12-word recovery phrase and store it safely. This is the only way to recover your wallet:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    mnemonic,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '• Never share this phrase with anyone\n'
                  '• Store it in a safe place\n'
                  '• Anyone with this phrase can access your funds',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('I have saved it safely'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockchain Integration'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Network: ${_isInitialized ? _blockchainManager.currentNetwork : 'Not initialized'}'),
                    Text('Wallet: ${_hasWallet ? 'Connected' : 'Not found'}'),
                    if (_walletAddress != null) 
                      Text('Address: ${_walletAddress!.substring(0, 10)}...${_walletAddress!.substring(_walletAddress!.length - 8)}'),
                    Text('Balance: ${_balance.toStringAsFixed(6)} ETH'),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const LinearProgressIndicator()
                    else
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains('Error') ? Colors.red : Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              spacing: 8,
              children: [
                if (!_hasWallet)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createWallet,
                    child: const Text('Create Wallet'),
                  ),
                if (_hasWallet) ...[
                  ElevatedButton(
                    onPressed: _isLoading ? null : _refreshData,
                    child: const Text('Refresh'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendTransaction,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Send Test TX'),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Transaction History
            if (_hasWallet) ...[
              Text(
                'Transaction History (${_transactions.length})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _transactions.isEmpty
                    ? const Center(child: Text('No transactions yet'))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                tx.from.toLowerCase() == _walletAddress?.toLowerCase()
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: tx.from.toLowerCase() == _walletAddress?.toLowerCase()
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              title: Text('${tx.amount.toStringAsFixed(6)} ${tx.currency}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('To: ${tx.shortTo}'),
                                  Text('Status: ${tx.status.displayName}'),
                                  if (tx.memo != null) Text('Memo: ${tx.memo}'),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${tx.confirmations} conf.'),
                                  Text(
                                    tx.timestamp.toString().substring(0, 16),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Integration instructions for your existing app:
/// 
/// 1. Add to main_navigation.dart:
/// ```dart
/// import 'blockchain_integration_example.dart';
/// 
/// // Add as a new tab or screen in your navigation
/// ```
/// 
/// 2. Initialize blockchain manager in main.dart or app startup:
/// ```dart
/// await BlockchainManager.instance.initialize();
/// ```
/// 
/// 3. Use in your wallet_page.dart:
/// ```dart
/// final blockchainManager = BlockchainManager.instance;
/// 
/// // Get balance
/// final balance = await blockchainManager.getBalance();
/// 
/// // Send transaction
/// final txHash = await blockchainManager.sendTransaction(
///   toAddress: recipientAddress,
///   amount: amount,
/// );
/// 
/// // Listen to transactions
/// blockchainManager.transactionStream.listen((transactions) {
///   // Update UI with new transactions
/// });
/// ```
