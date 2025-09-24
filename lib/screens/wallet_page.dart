import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/wallet_manager.dart';
import '../services/wallet_api_service.dart';
import '../services/transaction_service.dart';
import 'send_page.dart';

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
  final WalletManager _walletManager = WalletManager();
  
  bool _isLoading = false;
  double _balance = 0.0;
  String? _walletAddress;
  bool _hasWallet = false;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = false;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    setState(() => _isLoading = true);
    
    try {
      await _walletManager.initialize(userId: widget.userId);
      final hasWallet = await _walletManager.hasWallet();
      
      if (hasWallet) {
        await _loadWalletData();
      } else {
        setState(() => _hasWallet = false);
      }
    } catch (e) {
      _showError('Failed to initialize wallet: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWalletData() async {
    try {
      final address = await _walletManager.getWalletAddress();
      final balance = await _walletManager.getBalance();
      
      setState(() {
        _walletAddress = address;
        _balance = balance;
        _hasWallet = address != null;
      });
      
      // Load transactions
      await _loadTransactions();
    } catch (e) {
      _showError('Failed to load wallet data: $e');
    }
  }

  Future<void> _loadTransactions() async {
    if (_walletAddress == null) return;
    
    setState(() => _isLoadingTransactions = true);
    
    try {
      final response = await TransactionService.getTransactionHistory(
        userId: widget.userId,
        limit: 10, // Load latest 10 transactions
      );
      
      final transactions = List<Map<String, dynamic>>.from(response['transactions'] ?? []);
      
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      print('Failed to load transactions: $e');
      // Don't show error for transactions as it's not critical
    } finally {
      setState(() => _isLoadingTransactions = false);
    }
  }

  Future<void> _createWallet() async {
    setState(() => _isLoading = true);
    
    try {
      final walletData = await _walletManager.createWalletWithMnemonic();
      final address = walletData['address'];
      final mnemonic = walletData['mnemonic'];
      
      // Link to backend
      await _linkWalletToBackend(address);
      
      await _loadWalletData();
      
      // Show success with mnemonic backup
      _showWalletCreatedSuccess(address, mnemonic);
    } catch (e) {
      print(e);
      _showError('Failed to create wallet: $e');
      
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importWallet() async {
    // Show import method selection
    final importMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Wallet'),
        content: const Text('How would you like to import your wallet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'mnemonic'),
            child: const Text('Seed Phrase'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'private_key'),
            child: const Text('Private Key'),
          ),
        ],
      ),
    );

    if (importMethod == null) return;

    if (importMethod == 'mnemonic') {
      await _importFromMnemonic();
    } else {
      await _importFromPrivateKey();
    }
  }

  Future<void> _importFromMnemonic() async {
    final controller = TextEditingController();
    
    final mnemonic = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Seed Phrase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your 12-word seed phrase:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Seed Phrase',
                hintText: 'word1 word2 word3 ...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (mnemonic == null || mnemonic.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final address = await _walletManager.importWalletFromMnemonic(mnemonic);
      
      // Link to backend
      await _linkWalletToBackend(address);
      
      await _loadWalletData();
      _showSuccess('Wallet imported from seed phrase successfully!');
    } catch (e) {
      _showError('Failed to import wallet: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importFromPrivateKey() async {
    final controller = TextEditingController();
    
    final privateKey = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Private Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Private Key',
            hintText: 'Enter your private key',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (privateKey == null || privateKey.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final address = await _walletManager.importWallet(privateKey);
      
      // Link to backend
      await _linkWalletToBackend(address);
      
      await _loadWalletData();
      _showSuccess('Wallet imported successfully!');
    } catch (e) {
      _showError('Failed to import wallet: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _linkWalletToBackend(String address) async {
    try {
      await WalletApiService.linkWalletToUser(
        userId: widget.userId,
        walletAddress: address,
      );
    } catch (e) {
      print('Warning: Failed to link wallet to backend: $e');
      // Don't throw - wallet creation should still work
    }
  }

  Future<void> _refreshBalance() async {
    setState(() => _isLoading = true);
    
    try {
      await _loadWalletData();
    } catch (e) {
      _showError('Failed to refresh balance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestFunding() async {
    // Show amount selection dialog
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _buildFundingDialog(),
    );

    if (amount == null) return;

    setState(() => _isLoading = true);

    try {
      print('🔥 Requesting funding for amount: $amount ETH');
      final result = await _walletManager.requestFunding(amount: amount);
      print('🔥 Funding result: $result');
      
      if (result['success'] == true) {
        await _loadWalletData(); // Refresh balance
        _showSuccess('Successfully received ${amount} ETH!\nTx: ${result['transactionHash']?.substring(0, 10)}...');
      } else {
        _showError('Funding failed: ${result['error']}');
      }
    } catch (e) {
      _showError('Failed to request funding: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFundingDialog() {
    return AlertDialog(
      title: const Text('🏦 Request Test ETH'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select amount of test ETH to receive:'),
          const SizedBox(height: 16),
          Text(
            '💡 Available in local development mode only',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, 0.5),
          child: const Text('0.5 ETH'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, 1.0),
          child: const Text('1 ETH'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, 5.0),
          child: const Text('5 ETH'),
        ),
      ],
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showWalletCreatedSuccess(String address, String mnemonic) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 Wallet Created Successfully!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your wallet has been created using MetaMask-style security!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ IMPORTANT: Save your seed phrase',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Write down these 12 words in order. This is the ONLY way to recover your wallet:',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    mnemonic,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Address: ${address.substring(0, 10)}...${address.substring(address.length - 8)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: mnemonic));
                _showSuccess('Seed phrase copied to clipboard');
              },
              child: const Text('Copy Seed Phrase'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccess('Wallet created successfully!');
              },
              child: const Text('I\'ve Saved It'),
            ),
          ],
        );
      },
    );
  }

  void _copyAddress() {
    if (_walletAddress != null) {
      Clipboard.setData(ClipboardData(text: _walletAddress!));
      _showSuccess('Address copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_hasWallet)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshBalance,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasWallet
              ? _buildWalletContent()
              : _buildCreateWalletContent(),
    );
  }

  Widget _buildWalletContent() {
    return RefreshIndicator(
      onRefresh: _refreshBalance,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main Balance Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF8B5FD9)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_balance.toStringAsFixed(6)} ETH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(_balance * 2500).toStringAsFixed(2)} USD', // Mock ETH price
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Address Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_walletAddress?.substring(0, 6)}...${_walletAddress?.substring(_walletAddress!.length - 4)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _copyAddress,
                            child: const Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.send_rounded,
                    label: 'Send',
                    onTap: _showSendDialog,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Receive',
                    onTap: _showReceiveDialog,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Swap',
                    onTap: _showSwapDialog,
                    color: const Color(0xFFFF9800),
                  ),
                ),
                if (_walletManager.isFundingAvailable) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Faucet',
                      onTap: _requestFunding,
                      color: const Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Transactions
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/history');
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _buildTransactionsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoadingTransactions) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        
        // Determine transaction display properties
        final isIncoming = tx['direction'] == 'incoming';
        final type = tx['transaction_type'] ?? 'unknown';
        final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
        final amountStr = '${isIncoming ? '+' : '-'}${amount.toStringAsFixed(4)} ETH';
        
        IconData icon;
        Color color;
        String subtitle;
        
        switch (type) {
          case 'faucet':
            icon = Icons.water_drop;
            color = Colors.blue;
            subtitle = 'Faucet funding';
            break;
          case 'send':
            icon = Icons.arrow_upward;
            color = Colors.red;
            subtitle = tx['to_address'] != null 
                ? 'To ${tx['to_address'].toString().substring(0, 10)}...'
                : 'Send transaction';
            break;
          case 'receive':
            icon = Icons.arrow_downward;
            color = Colors.green;
            subtitle = tx['from_address'] != null 
                ? 'From ${tx['from_address'].toString().substring(0, 10)}...'
                : 'Receive transaction';
            break;
          case 'betting':
            icon = Icons.casino;
            color = Colors.purple;
            subtitle = 'Betting - ${tx['bet_type'] ?? 'Unknown'}';
            break;
          default:
            icon = Icons.swap_horiz;
            color = Colors.grey;
            subtitle = type;
        }
        
        // Format timestamp
        String timeStr = 'Unknown time';
        if (tx['created_at'] != null) {
          try {
            final timestamp = DateTime.parse(tx['created_at']);
            final now = DateTime.now();
            final difference = now.difference(timestamp);
            
            if (difference.inMinutes < 60) {
              timeStr = '${difference.inMinutes} min ago';
            } else if (difference.inHours < 24) {
              timeStr = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
            } else {
              timeStr = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
            }
          } catch (e) {
            timeStr = tx['created_at'].toString();
          }
        }
        
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            subtitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            timeStr,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          trailing: Text(
            amountStr,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }

  void _showSendDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendPage(
          userId: widget.userId,
          userEmail: widget.userEmail,
          currentBalance: _balance,
        ),
      ),
    );
    
    // If payment was successful, refresh wallet data
    if (result == true) {
      _loadWalletData();
    }
  }

  void _showReceiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive ETH'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share your wallet address to receive ETH:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Placeholder for QR code
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('QR Code\nComing Soon'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _walletAddress ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _copyAddress,
            child: const Text('Copy Address'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSwapDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Swap Tokens'),
        content: const Text('Token swap feature coming soon!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateWalletContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'No Wallet Found',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create a new wallet or import an existing one to get started with Ledgerly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          
          // Create Wallet Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createWallet,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create New Wallet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Import Wallet Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _importWallet,
              icon: const Icon(Icons.download),
              label: const Text('Import Existing Wallet'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}