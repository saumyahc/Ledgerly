import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/wallet_manager.dart';
import '../services/wallet_api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      final address = await _walletManager.getAddress();
      final balance = await _walletManager.getBalance();
      
      setState(() {
        _walletAddress = address;
        _balance = balance;
        _hasWallet = address != null;
      });
    } catch (e) {
      _showError('Failed to load wallet data: $e');
    }
  }

  Future<void> _createWallet() async {
    setState(() => _isLoading = true);
    
    try {
      final walletData = await _walletManager.createWallet();
      final address = walletData['address']!;
      final mnemonic = walletData['mnemonic']!;
      
      // Link to backend
      await _linkWalletToBackend(address);
      
      await _loadWalletData();
      
      // Show success with mnemonic backup
      _showWalletCreatedSuccess(address, mnemonic);
    } catch (e) {
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Balance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_balance.toStringAsFixed(4)} ETH',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  // Add funding button for development
                  if (_walletManager.isFundingAvailable) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _requestFunding,
                      icon: const Icon(Icons.account_balance_wallet, size: 16),
                      label: const Text('Get Test ETH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Address Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wallet Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _walletAddress ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyAddress,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/send_payment',
                      arguments: {
                        'userId': widget.userId,
                        'userName': widget.userName,
                        'userEmail': widget.userEmail,
                      },
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/email_payment',
                      arguments: {
                        'userId': widget.userId,
                        'userName': widget.userName,
                        'userEmail': widget.userEmail,
                      },
                    );
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Pay via Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
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