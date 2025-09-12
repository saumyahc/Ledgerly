import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/email_payment_service.dart'; // Keeping as fallback for verification
import '../services/contract_service.dart'; // Our contract service for blockchain payments
import '../services/metamask_service.dart';

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
  final MetaMaskService _metamaskService = MetaMaskService();
  
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
      // Check if MetaMask is available
      final isMetaMaskAvailable = await _metamaskService.isMetaMaskInstalled();
      
      // Optionally connect to MetaMask if available
      if (isMetaMaskAvailable) {
        // We'll just check availability for now, not forcing connection
        print('MetaMask is available for blockchain transactions');
      }
    } catch (e) {
      // Silently handle initialization errors
      print('Error initializing blockchain: $e');
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
      // First try to lookup via contract
      final contractLookup = await _contractService.lookupEmailWallet(email);
      
      if (contractLookup['success'] == true) {
        setState(() {
          _isRecipientVerified = true;
          _recipientName = email; // Use email as name since contract doesn't store names
          _recipientWalletAddress = contractLookup['wallet'];
        });
        return;
      }
      
      // Fallback to API lookup if contract lookup fails
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
          _errorMessage = 'Email not registered on the blockchain or in our system';
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
      // Check if MetaMask is installed
      final isMetaMaskInstalled = await _metamaskService.isMetaMaskInstalled();
      
      if (!isMetaMaskInstalled) {
        throw Exception('MetaMask is not installed. Please install MetaMask to send payments.');
      }
      
      // Use smart contract for payment
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
      setState(() {
        _errorMessage = 'Failed to send payment: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Send payment via blockchain/smart contract
  Future<Map<String, dynamic>> _sendBlockchainPayment(double amount) async {
    try {
      // Connect wallet if not already connected
      if (_metamaskService.connectedAddress == null) {
        final address = await _metamaskService.connect(context);
        if (address == null) {
          return {'success': false, 'error': 'Failed to connect wallet'};
        }
      }
      
      // Send payment via contract
      return await _contractService.sendPaymentToEmail(
        context: context,
        toEmail: _recipientEmailController.text.trim(),
        amount: amount.toString(),
      );
    } catch (e) {
      return {'success': false, 'error': 'Contract error: $e'};
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
              
              // MetaMask status indicator
              FutureBuilder<bool>(
                future: _metamaskService.isMetaMaskInstalled(),
                builder: (context, snapshot) {
                  final isMetaMaskAvailable = snapshot.data == true;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          isMetaMaskAvailable ? Icons.check_circle : Icons.error,
                          color: isMetaMaskAvailable ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMetaMaskAvailable 
                              ? 'MetaMask detected (will open to confirm payment)' 
                              : 'MetaMask not detected. Please install MetaMask to send payments.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isMetaMaskAvailable ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                      '💡 How Blockchain Email Payments Work',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Email payments use our EmailPaymentRegistry smart contract to send cryptocurrency to any email address on the blockchain.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When you make a payment:',
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. Your app formats the transaction data',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '2. MetaMask opens for you to sign the transaction',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '3. The transaction executes on the blockchain',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Blockchain transactions are immutable, transparent, and typically complete within minutes depending on network conditions.',
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
