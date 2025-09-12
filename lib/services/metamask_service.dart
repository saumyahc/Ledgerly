import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:http/http.dart' as http;
import '../constants.dart';

/// Service for interacting with MetaMask wallet
class MetaMaskService {
  static const String _metaMaskDeepLink = 'metamask://';
  static const String _metaMaskAppStoreUrl = 'https://apps.apple.com/us/app/metamask-blockchain-wallet/id1438144202';
  static const String _metaMaskPlayStoreUrl = 'https://play.google.com/store/apps/details?id=io.metamask';
  
  // Singleton instance
  static final MetaMaskService _instance = MetaMaskService._internal();
  factory MetaMaskService() => _instance;
  MetaMaskService._internal();
  
  // Store connected account
  String? _connectedAddress;
  int _chainId = 11155111; // Default to Sepolia testnet
  
  // Getters
  String? get connectedAddress => _connectedAddress;
  int get chainId => _chainId;
  bool get isConnected => _connectedAddress != null;
  
  /// Check if MetaMask is installed by attempting to launch the deep link
  Future<bool> isMetaMaskInstalled() async {
    try {
      return await launcher.canLaunchUrl(Uri.parse(_metaMaskDeepLink));
    } catch (e) {
      print('Error checking if MetaMask is installed: $e');
      return false;
    }
  }
  
  /// Open MetaMask app store page
  Future<void> openMetaMaskDownload(BuildContext context) async {
    final url = Theme.of(context).platform == TargetPlatform.iOS
        ? _metaMaskAppStoreUrl
        : _metaMaskPlayStoreUrl;
    
    try {
      await launcher.launchUrl(
        Uri.parse(url),
        mode: launcher.LaunchMode.externalApplication
      );
    } catch (e) {
      print('Error opening MetaMask download: $e');
    }
  }
  
  /// Connect to MetaMask via mobile app deep linking
  Future<String?> connect(BuildContext context) async {
    // First check if MetaMask app is installed
    final isInstalled = await isMetaMaskInstalled();
    if (!isInstalled) {
      // Show dialog to download MetaMask
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('MetaMask Required'),
          content: const Text('MetaMask mobile app is required to connect your wallet. Would you like to download it now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Download'),
            ),
          ],
        ),
      );
      
      if (shouldDownload == true) {
        await openMetaMaskDownload(context);
      }
      return null;
    }
    
    // For demo purposes, simulate a wallet connection
    // In a real implementation, you would use deep linking or WalletConnect
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const MetaMaskConnectDialog(),
    );
    
    if (result != null) {
      _connectedAddress = result;
    }
    
    return result;
  }
  
  /// Send a transaction via MetaMask
  Future<String?> sendTransaction({
    required BuildContext context,
    required String to,
    required String value, // in wei
    String? data,
  }) async {
    if (_connectedAddress == null) {
      await connect(context);
      if (_connectedAddress == null) return null;
    }
    
    // Build transaction
    final transactionParams = {
      'from': _connectedAddress,
      'to': to,
      'value': value,
      'chainId': '0x${_chainId.toRadixString(16)}',
    };
    
    if (data != null) {
      transactionParams['data'] = data;
    }
    
    // For a real implementation, you would use a deep link or WalletConnect to send the transaction
    // Here we're using a dialog to simulate the process
    final txHash = await showDialog<String>(
      context: context,
      builder: (context) => MetaMaskTransactionDialog(
        transactionParams: transactionParams,
      ),
    );
    
    return txHash;
  }
  
  /// Deploy a contract via MetaMask
  Future<String?> deployContract({
    required BuildContext context,
    required String bytecode,
    required String abi,
    List<dynamic>? constructorArgs,
  }) async {
    if (_connectedAddress == null) {
      await connect(context);
      if (_connectedAddress == null) return null;
    }
    
    // Encode constructor args if provided
    String data = bytecode;
    if (constructorArgs != null && constructorArgs.isNotEmpty) {
      // In a real implementation, you'd encode the ABI and constructor args
      // For now, we'll just use the bytecode as is
    }
    
    // In a real implementation, you would use deep linking or a library to deploy the contract
    // Here we're simulating the process with a dialog
    final contractAddress = await showDialog<String>(
      context: context,
      builder: (context) => MetaMaskDeployDialog(
        bytecode: data,
        chainId: _chainId,
        from: _connectedAddress!,
      ),
    );
    
    return contractAddress;
  }
  
  /// Save deployed contract to backend for reference
  Future<bool> saveDeployedContract({
    required String contractName,
    required String contractAddress,
    required int chainId,
    required String abi,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/save_contract.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contract_name': contractName,
          'contract_address': contractAddress,
          'chain_id': chainId,
          'abi': abi,
        }),
      );
      
      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Error saving contract: $e');
      return false;
    }
  }
  
  /// Get deployed contract address from backend
  Future<String?> getContractAddress(String contractName, int chainId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/get_contract.php?contract_name=$contractName&chain_id=$chainId'),
      );
      
      final data = json.decode(response.body);
      if (data['success'] == true && data['contract'] != null) {
        return data['contract']['address'];
      }
      return null;
    } catch (e) {
      print('Error getting contract address: $e');
      return null;
    }
  }
  
  /// Disconnect wallet
  void disconnect() {
    _connectedAddress = null;
  }
  
  /// Get explorer URL for address or transaction
  String getExplorerUrl(String hashOrAddress) {
    switch (_chainId) {
      case 1: // Ethereum Mainnet
        return 'https://etherscan.io/address/$hashOrAddress';
      case 11155111: // Sepolia
        return 'https://sepolia.etherscan.io/address/$hashOrAddress';
      case 5: // Goerli
        return 'https://goerli.etherscan.io/address/$hashOrAddress';
      case 137: // Polygon
        return 'https://polygonscan.com/address/$hashOrAddress';
      default:
        return '#';
    }
  }
  
  /// Static navigator key to use for dialogs when context is not available
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

/// Dialog for connecting to MetaMask
class MetaMaskConnectDialog extends StatefulWidget {
  const MetaMaskConnectDialog({Key? key}) : super(key: key);

  @override
  State<MetaMaskConnectDialog> createState() => _MetaMaskConnectDialogState();
}

class _MetaMaskConnectDialogState extends State<MetaMaskConnectDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect MetaMask'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const CircularProgressIndicator()
          else
            const Text('Click the button below to connect your MetaMask wallet'),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
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
          onPressed: _isLoading ? null : _connectToMetaMask,
          child: const Text('Connect Wallet'),
        ),
      ],
    );
  }
  
  Future<void> _connectToMetaMask() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // In a real implementation, you would:
      // 1. Use a deep link or WalletConnect to connect to MetaMask
      // 2. Get back the connected address
      
      // For demo, we'll simulate a successful connection after a delay
      await Future.delayed(const Duration(seconds: 2));
      final mockAddress = '0x71C7656EC7ab88b098defB751B7401B5f6d8976F';
      
      if (mounted) {
        Navigator.of(context).pop(mockAddress);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to connect: $e';
          _isLoading = false;
        });
      }
    }
  }
}

/// Dialog for sending transactions via MetaMask
class MetaMaskTransactionDialog extends StatefulWidget {
  final Map<String, dynamic> transactionParams;
  
  const MetaMaskTransactionDialog({
    Key? key,
    required this.transactionParams,
  }) : super(key: key);

  @override
  State<MetaMaskTransactionDialog> createState() => _MetaMaskTransactionDialogState();
}

class _MetaMaskTransactionDialogState extends State<MetaMaskTransactionDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Transaction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('To: ${widget.transactionParams['to']}'),
          Text('Value: ${widget.transactionParams['value']} wei'),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            const Text('Please confirm this transaction in your MetaMask wallet.'),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
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
          onPressed: _isLoading ? null : _sendTransaction,
          child: const Text('Send'),
        ),
      ],
    );
  }
  
  Future<void> _sendTransaction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // In a real implementation, you would:
      // 1. Use a deep link or WalletConnect to send the transaction to MetaMask
      // 2. Get back the transaction hash
      
      // For demo, we'll simulate a successful transaction after a delay
      await Future.delayed(const Duration(seconds: 2));
      final mockTxHash = '0x88df016429689c079f3b2f6ad39fa052532c56795b733da78a91ebe6a713944b';
      
      if (mounted) {
        Navigator.of(context).pop(mockTxHash);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send transaction: $e';
          _isLoading = false;
        });
      }
    }
  }
}

/// Dialog for deploying contracts via MetaMask
class MetaMaskDeployDialog extends StatefulWidget {
  final String bytecode;
  final int chainId;
  final String from;
  
  const MetaMaskDeployDialog({
    Key? key,
    required this.bytecode,
    required this.chainId,
    required this.from,
  }) : super(key: key);

  @override
  State<MetaMaskDeployDialog> createState() => _MetaMaskDeployDialogState();
}

class _MetaMaskDeployDialogState extends State<MetaMaskDeployDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Deploy Contract'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chain ID: ${widget.chainId}'),
          Text('From: ${widget.from}'),
          Text('Bytecode: ${widget.bytecode.substring(0, 10)}...'),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            const Text('Please confirm the contract deployment in your MetaMask wallet.'),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
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
          onPressed: _isLoading ? null : _deployContract,
          child: const Text('Deploy'),
        ),
      ],
    );
  }
  
  Future<void> _deployContract() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // In a real implementation, you would:
      // 1. Use a deep link or WalletConnect to deploy the contract via MetaMask
      // 2. Get back the deployed contract address
      
      // For demo, we'll simulate a successful deployment after a delay
      await Future.delayed(const Duration(seconds: 2));
      final mockContractAddress = '0x71C7656EC7ab88b098defB751B7401B5f6d8976F';
      
      if (mounted) {
        Navigator.of(context).pop(mockContractAddress);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to deploy contract: $e';
          _isLoading = false;
        });
      }
    }
  }
}
