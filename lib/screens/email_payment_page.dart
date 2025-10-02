import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/email_payment_service.dart';
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

  bool _isLoading = false;
  bool _isRecipientVerified = false;
  String? _recipientName;
  String? _recipientWalletAddress;
  String? _errorMessage;

  // Replace with your actual backend URLs
  final String phpBackendBaseUrl = 'https://ledgerly.hivizstudios.com/backend_example';
  final String nodeMiddlewareBaseUrl = 'http://localhost:3001';

  Future<void> _verifyRecipient() async {
    final email = _recipientEmailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter a recipient email');
      return;
    }
    if (email == widget.userEmail) {
      setState(() => _errorMessage = 'You cannot send payment to yourself');
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
      // Lookup recipient via PHP backend
      final uri = Uri.parse('$phpBackendBaseUrl/email_payment.php?email=${Uri.encodeComponent(email)}');
      final response = await http.get(uri);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true && data['user'] != null) {
        setState(() {
          _isRecipientVerified = true;
          _recipientName = data['user']['name'] ?? email;
          _recipientWalletAddress = data['user']['wallet_address'];
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPayment() async {
    if (!_isRecipientVerified) {
      setState(() => _errorMessage = 'Please verify recipient first');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Send payment via Node.js middleware
      final uri = Uri.parse('$nodeMiddlewareBaseUrl/payment/email-to-email');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromEmail': widget.userEmail,
          'toEmail': _recipientEmailController.text.trim(),
          'amountEth': amount,
          'memo': _memoController.text.trim(),
        }),
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment sent! Transaction: ${data['txHash'].toString().substring(0, 10)}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        _recipientEmailController.clear();
        _amountController.clear();
        _memoController.clear();
        setState(() {
          _isRecipientVerified = false;
          _recipientName = null;
          _recipientWalletAddress = null;
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to send payment';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send payment: $e';
      });
    } finally {
      setState(() => _isLoading = false);
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
                      'Payments are sent via backend services. Recipient lookup and payment processing are handled securely by the server.',
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