import 'package:flutter/material.dart';
import '../services/contract_service.dart';
import '../services/metamask_service.dart';

class MetaMaskEmailPaymentPage extends StatefulWidget {
  const MetaMaskEmailPaymentPage({super.key});

  @override
  State<MetaMaskEmailPaymentPage> createState() => _MetaMaskEmailPaymentPageState();
}

class _MetaMaskEmailPaymentPageState extends State<MetaMaskEmailPaymentPage> {
  final TextEditingController _recipientEmailController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _yourEmailController = TextEditingController();
  final ContractService _contractService = ContractService();
  final MetaMaskService _metamaskService = MetaMaskService();
  
  bool _isLoading = false;
  bool _isMetaMaskConnected = false;
  String? _connectedWallet;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _checkMetaMaskStatus();
  }

  @override
  void dispose() {
    _recipientEmailController.dispose();
    _amountController.dispose();
    _yourEmailController.dispose();
    super.dispose();
  }

  Future<void> _checkMetaMaskStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final isInstalled = await _metamaskService.isMetaMaskInstalled();
      if (isInstalled) {
        _connectedWallet = _metamaskService.connectedAddress;
        _isMetaMaskConnected = _connectedWallet != null;
      } else {
        setState(() {
          _statusMessage = 'MetaMask is not installed. Please install MetaMask to use this feature.';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking MetaMask status: $e';
        _isSuccess = false;
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _connectMetaMask() async {
    setState(() => _isLoading = true);
    
    try {
      final address = await _metamaskService.connect(context);
      if (address != null) {
        setState(() {
          _connectedWallet = address;
          _isMetaMaskConnected = true;
          _statusMessage = 'Connected to MetaMask!';
          _isSuccess = true;
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to connect to MetaMask.';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error connecting to MetaMask: $e';
        _isSuccess = false;
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _registerEmail() async {
    if (_yourEmailController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter your email address';
        _isSuccess = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final result = await _contractService.registerEmail(
        context: context,
        email: _yourEmailController.text.trim(),
      );
      
      setState(() {
        _statusMessage = result['success'] 
          ? 'Email registered successfully! Transaction: ${result['txHash']}'
          : 'Failed to register email: ${result['error']}';
        _isSuccess = result['success'];
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error registering email: $e';
        _isSuccess = false;
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _sendPayment() async {
    if (_recipientEmailController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter recipient email';
        _isSuccess = false;
      });
      return;
    }

    if (_amountController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter amount';
        _isSuccess = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final result = await _contractService.sendPaymentToEmail(
        context: context,
        toEmail: _recipientEmailController.text.trim(),
        amount: _amountController.text.trim(),
      );
      
      setState(() {
        _statusMessage = result['success'] 
          ? 'Payment sent successfully! Transaction: ${result['txHash']}'
          : 'Failed to send payment: ${result['error']}';
        _isSuccess = result['success'];
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error sending payment: $e';
        _isSuccess = false;
      });
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MetaMask Email Payments'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // MetaMask Status Section
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MetaMask Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Icon(
                              _isMetaMaskConnected
                                ? Icons.check_circle
                                : Icons.cancel,
                              color: _isMetaMaskConnected
                                ? Colors.green
                                : Colors.red,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                _isMetaMaskConnected
                                  ? 'Connected: ${_connectedWallet?.substring(0, 8)}...${_connectedWallet?.substring(_connectedWallet!.length - 6)}'
                                  : 'Not Connected',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _isMetaMaskConnected ? null : _connectMetaMask,
                          child: const Text('Connect MetaMask'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Register Email Section
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register Your Email',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: _yourEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Your Email',
                            hintText: 'Enter your email address',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _isMetaMaskConnected ? _registerEmail : null,
                          child: const Text('Register Email'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Send Payment Section
                Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send Payment',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: _recipientEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Recipient Email',
                            hintText: 'Enter recipient email address',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount (ETH)',
                            hintText: 'Enter amount in ETH',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _isMetaMaskConnected ? _sendPayment : null,
                          child: const Text('Send Payment'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Status Message
                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(top: 8.0),
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }
}
