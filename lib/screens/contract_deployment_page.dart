import 'package:flutter/material.dart';
import 'package:ledgerly/services/contract_deployment_service.dart';
import 'package:ledgerly/services/metamask_service.dart';
import 'package:ledgerly/constants.dart';

class ContractDeploymentPage extends StatefulWidget {
  const ContractDeploymentPage({Key? key}) : super(key: key);

  @override
  _ContractDeploymentPageState createState() => _ContractDeploymentPageState();
}

class _ContractDeploymentPageState extends State<ContractDeploymentPage> {
  final ContractDeploymentService _deploymentService = ContractDeploymentService();
  final MetaMaskService _metaMaskService = MetaMaskService();
  
  bool _isLoading = false;
  String? _deployedContractAddress;
  String? _walletAddress;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _deploymentService.init();
      setState(() {
        _isLoading = false;
        _walletAddress = _metaMaskService.connectedAddress;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing services: $e';
      });
    }
  }
  
  Future<void> _connectWallet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final address = await _metaMaskService.connect(context);
      setState(() {
        _isLoading = false;
        _walletAddress = address;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error connecting wallet: $e';
      });
    }
  }
  
  Future<void> _deployContract() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final address = await _deploymentService.deployEmailPaymentRegistryContract(context);
      setState(() {
        _isLoading = false;
        _deployedContractAddress = address;
      });
      
      if (address != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contract deployed successfully to $address'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error deploying contract: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to deploy contract: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deploy Smart Contract'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wallet Connection',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8.0),
                          if (_walletAddress != null)
                            Text('Connected Wallet: $_walletAddress')
                          else
                            const Text('No wallet connected'),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _walletAddress == null ? _connectWallet : null,
                            child: Text(_walletAddress == null ? 'Connect MetaMask' : 'Wallet Connected'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deploy Email Payment Registry',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Network: ${ApiConstants.networks[ApiConstants.defaultChainId] ?? 'Unknown'}',
                          ),
                          const SizedBox(height: 8.0),
                          if (_deployedContractAddress != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Contract deployed successfully!',
                                  style: TextStyle(color: Colors.green),
                                ),
                                const SizedBox(height: 4.0),
                                Text('Address: $_deployedContractAddress'),
                                const SizedBox(height: 8.0),
                                OutlinedButton(
                                  onPressed: () {
                                    // Open in explorer
                                    // In a real app, you would use url_launcher here
                                    // final url = _metaMaskService.getExplorerUrl(_deployedContractAddress!);
                                    // launchUrl(Uri.parse(url));
                                  },
                                  child: const Text('View on Explorer'),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'No contract deployed yet',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _walletAddress != null ? _deployContract : null,
                            child: const Text('Deploy Contract'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Card(
                      color: Colors.red.shade50,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Error',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contract Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'The Email Payment Registry contract maps email addresses to wallet addresses, '
                            'allowing users to send payments using just an email address. '
                            'The contract also tracks payment history and transaction stats.',
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'Key Features:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          const Text('• Register email address to wallet'),
                          const Text('• Send payments using email address'),
                          const Text('• Track payment history'),
                          const Text('• View transaction statistics'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
