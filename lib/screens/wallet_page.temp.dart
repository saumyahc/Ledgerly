import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/session_manager.dart';
import '../services/blockchain_manager.dart';
import '../services/wallet_api_service.dart';
import '../models/transaction_model.dart';
import '../services/metamask_service.dart';

class WalletPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const WalletPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _isLoading = false;
  double _balance = 0.0;
  String? _walletAddress;
  bool _hasWallet = false;
  String _selectedCurrency = 'ETH';
  final BlockchainManager _blockchain = BlockchainManager.instance;
  List<TransactionModel> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _initializeBlockchain();
  }

  Future<void> _initializeBlockchain() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize blockchain manager
      await _blockchain.initialize();
      
      // Check if user has a wallet
      final hasWallet = await _blockchain.hasWallet();
      
      if (hasWallet) {
        await _loadWalletData();
      } else {
        // Show wallet creation dialog
        if (mounted) {
          _showWalletSetupDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Blockchain initialization failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWalletData() async {
    SessionManager.extendSession();
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get wallet address
      final address = await _blockchain.getWalletAddress();
      
      // Get balance
      final balance = await _blockchain.getBalance();
      
      // Get recent transactions
      final transactions = _blockchain.getTransactionHistory();
      
      if (!mounted) return;
      
      setState(() {
        _walletAddress = address;
        _balance = balance;
        _hasWallet = address != null;
        _recentTransactions = transactions.take(3).toList(); // Show latest 3
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load wallet data: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _navigateToEmailPayment() {
    if (!_hasWallet) {
      _showError('Please create a wallet first');
      return;
    }
    
    Navigator.of(context).pushNamed(
      '/email_payment',
      arguments: {
        'userId': widget.userId,
        'userName': widget.userName,
        'userEmail': widget.userEmail,
      },
    );
  }
  
  void _navigateToContractDeployment() {
    Navigator.of(context).pushNamed('/deploy_contract');
  }
  
  Future<void> _connectWithMetaMask() async {
    Navigator.of(context).pop(); // Close dialog
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Use MetaMask service to connect
      final metamaskService = MetaMaskService();
      final walletAddress = await metamaskService.connect(context);
      
      if (mounted && walletAddress != null) {
        // Link wallet address from MetaMask to user account in backend
        await _linkWalletToAccount(walletAddress);
        
        // Show success message
        _showSuccess('MetaMask wallet connected successfully!');
        
        // Refresh wallet data
        await _loadWalletData();
      } else {
        _showError('Failed to connect MetaMask wallet');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error connecting to MetaMask: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showWalletSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connect Your Wallet'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You need a cryptocurrency wallet to use Ledgerly. Ledgerly uses MetaMask for wallet management.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'What would you like to do?',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showImportInstructions();
              },
              child: const Text('Import Existing'),
            ),
            ElevatedButton(
              onPressed: () => _connectWithMetaMask(),
              child: const Text('Connect MetaMask'),
            ),
          ],
        );
      },
    );
  }
  
  void _showImportInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Import Wallet with MetaMask'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To import an existing wallet, you\'ll need to use the MetaMask app directly:',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                '1. Open MetaMask app',
                textAlign: TextAlign.left,
              ),
              Text(
                '2. Import your existing wallet with your seed phrase',
                textAlign: TextAlign.left,
              ),
              Text(
                '3. Return to Ledgerly and connect your MetaMask wallet',
                textAlign: TextAlign.left,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final metamaskService = MetaMaskService();
                metamaskService.openMetaMaskDownload(context);
              },
              child: const Text('Open MetaMask'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _linkWalletToAccount(String walletAddress) async {
    try {
      print('Linking wallet address to user account: ${widget.userId}, address: $walletAddress');
      final result = await WalletApiService.linkWalletToUser(
        userId: widget.userId,
        walletAddress: walletAddress,
      );
      
      if (result['success'] == true) {
        print('Wallet linked to account successfully: ${result['data']}');
        // Show success toast or notification here if desired
        _showSuccess('Wallet linked to your account');
      } else {
        print('Failed to link wallet to account: ${result['error']}');
        // Show a warning but don't block the user since wallet still works locally
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note: Wallet works locally but server sync failed. Your wallet will be re-synced later.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error linking wallet to account: $e');
      // Log the error for debugging but let the user continue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note: Your wallet works but backup to server failed. Will retry later.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'My Wallet',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWalletData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading wallet...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Balance Card
                      _buildBalanceCard(),
                      const SizedBox(height: 24),
                      
                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      
                      // Recent Transactions Preview
                      _buildRecentTransactions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Glass3DCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (_walletAddress != null)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _walletAddress!));
                    _showSuccess('Address copied to clipboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_walletAddress!.substring(0, 6)}...${_walletAddress!.substring(_walletAddress!.length - 4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.copy, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _balance.toStringAsFixed(6),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedCurrency,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: _hasWallet ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _hasWallet ? 'Wallet Connected' : 'No Wallet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _hasWallet ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.send_rounded,
                label: 'Send',
                onTap: () => _hasWallet ? _showSendDialog() : _showError('Please create a wallet first'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.call_received_rounded,
                label: 'Receive',
                onTap: () => _hasWallet ? _showReceiveDialog() : _showError('Please create a wallet first'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.email_outlined,
                label: 'Pay Email',
                onTap: () => _navigateToEmailPayment(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.settings_ethernet,
                label: 'Deploy',
                onTap: () => _navigateToContractDeployment(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Neumorphic3DButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendDialog() {
    final TextEditingController addressController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send ETH'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Address',
                  border: OutlineInputBorder(),
                  hintText: '0x...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (ETH)',
                  border: const OutlineInputBorder(),
                  hintText: '0.001',
                  suffix: Text('Balance: ${_balance.toStringAsFixed(6)} ETH'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: This will send on ${_blockchain.currentNetworkInfo.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _sendTransaction(
                addressController.text.trim(),
                amountController.text.trim(),
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendTransaction(String address, String amountStr) async {
    Navigator.of(context).pop(); // Close dialog

    if (address.isEmpty || amountStr.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (!_blockchain.isValidAddress(address)) {
      _showError('Invalid recipient address');
      return;
    }

    final double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      _showError('Invalid amount');
      return;
    }

    if (amount > _balance) {
      _showError('Insufficient balance');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final txHash = await _blockchain.sendTransaction(
        toAddress: address,
        amount: amount,
        memo: 'Sent via Ledgerly',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSuccess('Transaction sent! Hash: ${txHash.substring(0, 10)}...');
        await _loadWalletData(); // Refresh balance
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Transaction failed: $e');
      }
    }
  }

  void _showReceiveDialog() {
    if (_walletAddress == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Receive ETH'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your wallet address:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _walletAddress!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Network: ${_blockchain.currentNetworkInfo.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Only send ETH to this address on the correct network!',
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _walletAddress!));
                _showSuccess('Address copied to clipboard');
              },
              child: const Text('Copy Address'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to history page with user data
                Navigator.of(context).pushNamed(
                  '/history',
                  arguments: {
                    'userId': widget.userId,
                    'userName': widget.userName,
                    'userEmail': widget.userEmail,
                  },
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Glass3DCard(
          child: _recentTransactions.isEmpty 
            ? const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No transactions yet.\nStart by receiving some ETH!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : Column(
                children: _recentTransactions.map((tx) => _buildTransactionItem(tx)).toList(),
              ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final bool isOutgoing = transaction.from.toLowerCase() == _walletAddress?.toLowerCase();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOutgoing 
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOutgoing ? Icons.send_rounded : Icons.call_received_rounded,
              color: isOutgoing ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOutgoing ? 'Sent' : 'Received',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isOutgoing ? 'To: ${transaction.shortTo}' : 'From: ${transaction.shortFrom}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  transaction.status.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: transaction.status == TransactionStatus.confirmed 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isOutgoing ? "-" : "+"}${transaction.amount.toStringAsFixed(6)} ${transaction.currency}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOutgoing ? Colors.red : Colors.green,
                ),
              ),
              Text(
                _formatTimestamp(transaction.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
