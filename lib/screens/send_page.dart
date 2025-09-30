import 'package:flutter/material.dart';
import 'package:web3dart/crypto.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import '../theme.dart';
import '../services/wallet_manager.dart';
import '../constants.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

class SendPage extends StatefulWidget {
  final int userId;
  final String userEmail;
  final double currentBalance;

  const SendPage({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.currentBalance,
  });

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final WalletManager _walletManager = WalletManager();
  
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  // State
  bool _isLoading = false;
  int _selectedMethod = 0; // 0 = Email, 1 = Wallet Address
  bool _isValidEmail = false;
  bool _isValidAddress = false;
  bool _isValidAmount = false;
  
  // Web3 client
  late Web3Client _web3Client;
  
  @override
  void initState() {
    super.initState();
    _initializeWeb3();
    _initializeWallet();
  }

  void _initializeWeb3() {
    // Use platform-appropriate localhost URL
    String rpcUrl = ApiConstants.ganacheRpcUrl;
    if (!const bool.fromEnvironment('dart.library.js_util') && Platform.isAndroid) {
      rpcUrl = 'http://10.0.2.2:8545';
    }
    _web3Client = Web3Client(rpcUrl, http.Client());
  }

  Future<void> _initializeWallet() async {
    try {
      print('🔧 Initializing wallet manager for user ${widget.userId}...');
      await _walletManager.initialize(
        userId: widget.userId,
        networkMode: 'local', // Using local development network
      );
      print('✅ Wallet manager initialized successfully');
      
      // Check if wallet exists
      final hasWallet = await _walletManager.hasWallet();
      print('   Wallet exists: $hasWallet');
      
      if (hasWallet) {
        final address = await _walletManager.getWalletAddress();
        print('   Wallet address: $address');
        
        // Test credentials access
        final credentials = await _walletManager.getCredentials();
        print('   Credentials available: ${credentials != null}');
      } else {
        print('❌ No wallet found for user ${widget.userId}');
        print('   User needs to create or import a wallet first');
      }
    } catch (e) {
      print('❌ Failed to initialize wallet: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _web3Client.dispose();
    super.dispose();
  }

  void _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _isValidEmail = emailRegex.hasMatch(email) && email.isNotEmpty;
    });
  }

  void _validateAddress(String address) {
    setState(() {
      _isValidAddress = address.isNotEmpty && 
                       address.startsWith('0x') && 
                       address.length == 42;
    });
  }

  void _validateAmount(String amount) {
    try {
      final value = double.parse(amount);
      setState(() {
        _isValidAmount = value > 0 && value <= widget.currentBalance;
      });
    } catch (e) {
      setState(() {
        _isValidAmount = false;
      });
    }
  }

  bool get _canSend {
    if (_selectedMethod == 0) {
      return _isValidEmail && _isValidAmount;
    } else {
      return _isValidAddress && _isValidAmount;
    }
  }

  Future<void> _sendPayment() async {
    if (!_canSend) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedMethod == 0) {
        await _sendToEmail();
      } else {
        await _sendToAddress();
      }
      
      if (mounted) {
        _showSuccess('Payment sent successfully!');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to send payment: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendToEmail() async {
    final email = _emailController.text.trim();
    final amount = double.parse(_amountController.text);
    
    print('🚀 Starting sendToEmail function...');
    print('   Email: $email');
    print('   Amount: $amount ETH');
    
    try {
      // Step 1: Check if email is registered via backend API and get recipient wallet
      print('🔍 Step 1: Checking if email is registered via backend...');
      final emailCheckResponse = await _checkEmailRegistration(email);
      if (!emailCheckResponse['success']) {
        print('❌ FAILURE: ${emailCheckResponse['message']}');
        throw Exception(emailCheckResponse['message']);
      }
      final recipientWallet = emailCheckResponse['user']['wallet_address'];
      print('✅ Email is registered with wallet: $recipientWallet');
      
      // Step 2: Get wallet credentials for sender
      print('🔑 Step 2: Getting sender wallet credentials...');
      
      // First check if wallet exists
      final hasWallet = await _walletManager.hasWallet();
      print('   Wallet exists: $hasWallet');
      
      if (!hasWallet) {
        print('❌ FAILURE: No wallet found for user ${widget.userId}');
        throw Exception('No wallet found for this user. Please create or import a wallet first from the wallet page.');
      }
      
      final credentials = await _walletManager.getCredentials();
      if (credentials == null) {
        print('❌ FAILURE: Sender wallet credentials not available');
        print('   Wallet exists but credentials are null - possible initialization issue');
        throw Exception('Wallet credentials not available. Try refreshing or re-initializing the wallet.');
      }
      print('✅ Sender wallet credentials obtained');
      
      // Step 3: Send direct ETH transfer to recipient wallet
      print('💰 Step 3: Sending ETH transfer to recipient wallet...');
      final amountString = amount.toStringAsFixed(18);
      final amountInWei = BigInt.parse((double.parse(amountString) * 1e18).toStringAsFixed(0));
      print('   Amount in wei: $amountInWei');
      print('   Recipient address: $recipientWallet');
      
      final transaction = Transaction(
        to: EthereumAddress.fromHex(recipientWallet),
        value: EtherAmount.inWei(amountInWei),
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 Gwei
        maxGas: 21000, // Standard gas limit for ETH transfer
      );
      print('✅ Transaction built successfully');
      
      print('📤 Step 4: Sending transaction to blockchain...');
      final txHash = await _web3Client.sendTransaction(
        credentials,
        transaction,
        chainId: 1377, // Explicit Ganache chain ID
      );
      
      print('🎉 SUCCESS: ETH transfer sent successfully!');
      print('   Transaction hash: $txHash');
      
    } catch (e, stackTrace) {
      print('❌ CRITICAL FAILURE in _sendToEmail function: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow; // Re-throw to maintain original error handling
    }
  }

  Future<Map<String, dynamic>> _checkEmailRegistration(String email) async {
    try {
      final uri = Uri.parse('${ApiConstants.emailPayment}?email=${Uri.encodeComponent(email)}');
      print('   Checking email via: $uri');
      
      final response = await http.get(uri);
      final responseData = json.decode(response.body);
      
      print('   API response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Email not found or no wallet linked'
        };
      }
    } catch (e) {
      print('   Error checking email registration: $e');
      return {
        'success': false,
        'message': 'Failed to verify email registration: $e'
      };
    }
  }

  Future<void> _sendToAddress() async {
    final address = _addressController.text.trim();
    final amount = double.parse(_amountController.text);
    
    print('🚀 Starting sendToAddress function...');
    print('   Address: $address');
    print('   Amount: $amount ETH');
    
    try {
      // Get wallet credentials
      print('🔑 Step 1: Getting wallet credentials...');
      
      // First check if wallet manager is initialized
      final hasWallet = await _walletManager.hasWallet();
      print('   Wallet exists: $hasWallet');
      
      if (!hasWallet) {
        print('❌ FAILURE: No wallet found for user ${widget.userId}');
        throw Exception('No wallet found for this user. Please create or import a wallet first.');
      }
      
      final credentials = await _walletManager.getCredentials();
      if (credentials == null) {
        print('❌ FAILURE: Wallet credentials not available');
        print('   This could mean the wallet is not properly initialized or private key is missing');
        throw Exception('Wallet credentials not available. Please check wallet setup.');
      }
      print('✅ Wallet credentials obtained');
      
      // Convert double amount to wei (BigInt) properly
      print('🔧 Step 2: Converting amount to wei...');
      final amountString = amount.toStringAsFixed(18); // Ensure 18 decimal places
      final amountInWei = BigInt.parse((double.parse(amountString) * 1e18).toStringAsFixed(0));
      print('   Amount in wei: $amountInWei');
      
      // Build transaction manually to avoid eth_call issues
      print('📝 Step 3: Building ETH transfer transaction...');
      final transaction = Transaction(
        to: EthereumAddress.fromHex(address),
        value: EtherAmount.inWei(amountInWei),
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 Gwei
        maxGas: 21000, // Standard gas limit for ETH transfer
      );
      print('✅ Transaction built successfully');
      
      // Send direct ETH transaction
      print('📤 Step 4: Sending transaction to blockchain...');
      final txHash = await _web3Client.sendTransaction(
        credentials,
        transaction,
        chainId: 1377, // Explicit Ganache chain ID
      );
      
      print('🎉 SUCCESS: ETH transfer sent successfully!');
      print('   Transaction hash: $txHash');
      
    } catch (e, stackTrace) {
      print('❌ CRITICAL FAILURE in _sendToAddress function: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow; // Re-throw to maintain original error handling
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Send ETH'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF8B5FD9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.currentBalance.toStringAsFixed(4)} ETH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Send method selector
              const Text(
                'Send To',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMethod = 0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 0 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email,
                                color: _selectedMethod == 0 ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Email',
                                style: TextStyle(
                                  color: _selectedMethod == 0 ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMethod = 1),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 1 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: _selectedMethod == 1 ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Wallet',
                                style: TextStyle(
                                  color: _selectedMethod == 1 ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Input fields
              if (_selectedMethod == 0) ...[
                // Email input
                const Text(
                  'Recipient Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _validateEmail,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    prefixIcon: const Icon(Icons.email),
                    suffixIcon: _isValidEmail 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _emailController.text.isNotEmpty
                            ? (_isValidEmail ? Colors.green : Colors.red)
                            : Colors.grey[300]!,
                      ),
                    ),
                  ),
                ),
                if (_emailController.text.isNotEmpty && !_isValidEmail)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please enter a valid email address',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ] else ...[
                // Wallet address input
                const Text(
                  'Recipient Wallet Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  onChanged: _validateAddress,
                  decoration: InputDecoration(
                    hintText: '0x...',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isValidAddress)
                          const Icon(Icons.check_circle, color: Colors.green),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () {
                            // TODO: Implement QR code scanning
                            _showError('QR scanner coming soon!');
                          },
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _addressController.text.isNotEmpty
                            ? (_isValidAddress ? Colors.green : Colors.red)
                            : Colors.grey[300]!,
                      ),
                    ),
                  ),
                ),
                if (_addressController.text.isNotEmpty && !_isValidAddress)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please enter a valid wallet address (0x...)',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
              
              const SizedBox(height: 24),
              
              // Amount input
              const Text(
                'Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: _validateAmount,
                decoration: InputDecoration(
                  hintText: '0.0',
                  prefixIcon: const Icon(Icons.monetization_on),
                  suffixText: 'ETH',
                  suffixIcon: _isValidAmount 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _amountController.text.isNotEmpty
                          ? (_isValidAmount ? Colors.green : Colors.red)
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
              ),
              if (_amountController.text.isNotEmpty && !_isValidAmount)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _amountController.text.isNotEmpty && double.tryParse(_amountController.text) != null
                        ? 'Amount exceeds available balance'
                        : 'Please enter a valid amount',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              
              // Quick amount buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildQuickAmountButton('0.1'),
                  const SizedBox(width: 8),
                  _buildQuickAmountButton('0.5'),
                  const SizedBox(width: 8),
                  _buildQuickAmountButton('1.0'),
                  const SizedBox(width: 8),
                  _buildQuickAmountButton('Max'),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Send button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSend && !_isLoading ? _sendPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Send ${_selectedMethod == 0 ? 'to Email' : 'to Wallet'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedMethod == 0
                            ? 'Sending to email requires the recipient to be registered in the Ledgerly system.'
                            : 'Sending to wallet address will transfer ETH directly to the specified address.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(String amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          if (amount == 'Max') {
            _amountController.text = widget.currentBalance.toString();
          } else {
            _amountController.text = amount;
          }
          _validateAmount(_amountController.text);
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          amount,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}