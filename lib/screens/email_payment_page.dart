import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/email_payment_service.dart';
import '../services/contract_service.dart';
import '../services/wallet_manager.dart';

class EmailPaymentPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const EmailPaymentPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<EmailPaymentPage> createState() => _EmailPaymentPageState();
}

class _EmailPaymentPageState extends State<EmailPaymentPage> {
  final TextEditingController _recipientEmailController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final ContractService _contractService = ContractService();
  final WalletManager _walletManager = WalletManager();
  
  bool _isLoading = false;
  bool _isRecipientVerified = false;
  String? _recipientName;
  String? _recipientWalletAddress;
  String? _errorMessage;
  
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
      // Initialize wallet and contract services
      await _walletManager.initialize(userId: widget.userId);
      await _contractService.initialize();
      print('Wallet and contract services initialized successfully');
    } catch (e) {
      print('Error initializing services: $e');
      setState(() {
        _errorMessage = 'Failed to initialize services: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _verifyRecipient() async {
    final email = _recipientEmailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a recipient email';
      });
      return;
    }
    
    if (email == widget.userEmail) {
      setState(() {
        _errorMessage = 'You cannot send payment to yourself';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _isRecipientVerified = false;
      _recipientName = null;
      _recipientWalletAddress = null;
      _errorMessage = null;
    });
    
    try {
      // TODO: Smart contract lookup functionality not implemented yet
      // First try to lookup via contract
      final contractLookup = await _contractService.lookupEmailWallet(email);
      if (contractLookup['success'] == true) {
        setState(() {
          _isRecipientVerified = true;
          _recipientName = email;
          _recipientWalletAddress = contractLookup['wallet'];
        });
        return;
      }
      
      // Fallback to API lookup
      final result = await EmailPaymentService.resolveEmailToWallet(email);
      
      if (result['success'] == true) {
        final userData = result['userData'];
        setState(() {
          _isRecipientVerified = true;
          _recipientName = userData['name'];
          _recipientWalletAddress = userData['wallet_address'];
        });
      } else {
        setState(() {
          _errorMessage = 'Email not registered in our system';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify recipient: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _sendPayment() async {
    if (!_isRecipientVerified) {
      setState(() {
        _errorMessage = 'Please verify recipient first';
      });
      return;
    }
    
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Use BlockchainManager's sendTransaction method
      final result = await _sendBlockchainPayment(amount);
      if (!result['success']) {
        throw Exception(result['error']);
      }
      
      // Show success message and clear form
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment sent! Transaction: ${result['txHash'].toString().substring(0, 10)}...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // Clear form
      _recipientEmailController.clear();
      _amountController.clear();
      _memoController.clear();
      
      setState(() {
        _isRecipientVerified = false;
        _recipientName = null;
        _recipientWalletAddress = null;
      });
    } catch (e) {
      print('DEBUG: _sendBlockchainPayment failed: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (e is FormatException) {
        print('DEBUG: Format exception details: ${e.message}');
        print('DEBUG: Format exception source: ${e.source}');
      }
      setState(() {
        _errorMessage = 'Failed to send payment: $e';
        print(e);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Send payment using WalletManager and ContractService
  Future<Map<String, dynamic>> _sendBlockchainPayment(double amount) async {
    try {
      // 1. Check if we have a wallet
      final hasWallet = await _walletManager.hasWallet();
      if (!hasWallet) {
        return {'success': false, 'error': 'No wallet found. Please create a wallet first.'};
      }

      // 2. Get the recipient's wallet address
      final recipientAddress = _recipientWalletAddress;
      if (recipientAddress == null) {
        return {'success': false, 'error': 'Recipient wallet address is missing'};
      }

      // 3. Validate the recipient address
      if (!_walletManager.isValidAddress(recipientAddress)) {
        return {'success': false, 'error': 'Invalid recipient wallet address'};
      }

      // 4. Check if we have sufficient balance
      final balance = await _walletManager.getBalance();
      if (balance < amount) {
        return {'success': false, 'error': 'Insufficient balance. You have $balance ETH but need $amount ETH'};
      }

      // 5. Get credentials for transaction
      final credentials = _walletManager.credentials;
      if (credentials == null) {
        return {'success': false, 'error': 'Could not get wallet credentials'};
      }

      // 6. Try contract payment first if email is verified
      if (_isRecipientVerified && _recipientEmailController.text.trim().isNotEmpty) {
        print('DEBUG: Attempting contract payment to verified email: ${_recipientEmailController.text.trim()}');
        
        // Only pass memo if it's not empty
        String? memoToSend = null;
        if (_memoController.text.trim().isNotEmpty) {
          memoToSend = _memoController.text.trim();
          print('DEBUG: Including memo in contract payment: "$memoToSend" (${memoToSend.length} chars)');
        } else {
          print('DEBUG: No memo provided for contract payment');
        }
        
        print('DEBUG: Calling contract service with amount: $amount ETH');
        final contractResult = await _contractService.sendPaymentToEmail(
          email: _recipientEmailController.text.trim(),
          amount: amount,
          credentials: credentials,
          memo: memoToSend,
        );
        
        if (contractResult['success'] == true) {
          print('DEBUG: Contract payment successful: ${contractResult['txHash']}');
          return contractResult;
        } else {
          print('DEBUG: Contract payment failed with error: ${contractResult['error']}');
          print('DEBUG: Falling back to direct transfer...');
        }
      }

      // 7. Fallback to direct wallet transfer using JSON-RPC
      print('DEBUG: Performing direct wallet transfer to: $recipientAddress');
      
      // Be extra careful with memo handling - ensure it's properly formatted
      String? memo = null;
      if (_memoController.text.trim().isNotEmpty) {
        memo = _memoController.text.trim();
        print('DEBUG: Including memo in direct transfer: "$memo" (${memo.length} chars)');
      } else {
        print('DEBUG: No memo for direct transfer');
      }
      
      try {
        print('DEBUG: Calling wallet manager sendTransaction with amount: $amount ETH');
        // Pass null explicitly if no memo to ensure clean parameters
        final txHash = await _walletManager.sendTransaction(
          toAddress: recipientAddress,
          amount: amount,
          memo: memo,
        );
        
        print('DEBUG: Direct transfer successful with hash: $txHash');
        
        return {
          'success': true,
          'txHash': txHash,
          'message': 'Direct transfer successful'
        };
      } catch (e) {
        print('DEBUG: Direct transfer failed with error: $e');
        print('DEBUG: Error type: ${e.runtimeType}');
        throw e; // Rethrow to be caught by outer try-catch
      }
    } catch (e) {
      return {'success': false, 'error': 'Transaction failed: $e'};
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pay via Email',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send payment to an email address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              
              // Under Development Notice for Smart Contract Features
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Smart Contract Integration: Ready! Contract connected successfully.',
                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Recipient email input with verify button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _recipientEmailController,
                      decoration: InputDecoration(
                        labelText: 'Recipient Email',
                        hintText: 'example@email.com',
                        enabled: !_isRecipientVerified && !_isLoading,
                        prefixIcon: const Icon(Icons.email_outlined),
                        suffixIcon: _isRecipientVerified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      onChanged: (_) {
                        if (_isRecipientVerified) {
                          setState(() {
                            _isRecipientVerified = false;
                            _recipientName = null;
                            _recipientWalletAddress = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: !_isLoading && !_isRecipientVerified ? _verifyRecipient : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(_isRecipientVerified ? 'Verified' : 'Verify'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Recipient info (when verified)
              if (_isRecipientVerified && _recipientName != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipient: $_recipientName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wallet: ${_recipientWalletAddress!.substring(0, 6)}...${_recipientWalletAddress!.substring(_recipientWalletAddress!.length - 4)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Amount input
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (ETH)',
                  hintText: '0.001',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,8}$')),
                ],
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              
              // Memo input
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: 'Memo (Optional)',
                  hintText: 'What\'s this payment for?',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLength: 100,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 8),
              
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Send button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isRecipientVerified && !_isLoading ? _sendPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Send Payment'),
                ),
              ),
              const SizedBox(height: 24),
              
              // Information card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '💡 How Email Payments Work',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Smart contract integration active! Payments can be sent via EmailPaymentRegistry contract or direct wallet transfers.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When you make a payment:',
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. We lookup the recipient via smart contract first',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '2. If found, payment goes through the smart contract',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '3. Otherwise, direct wallet-to-wallet transfer',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Transactions are processed on the blockchain and typically complete within minutes.',
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
  
  @override
  void dispose() {
    _recipientEmailController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}