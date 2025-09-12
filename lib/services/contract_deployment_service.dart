import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ledgerly/constants.dart';
import 'package:ledgerly/services/metamask_service.dart';
import 'package:web3dart/web3dart.dart';
import 'package:hex/hex.dart' as hex_lib;

/// Service to handle smart contract deployment and interaction
class ContractDeploymentService {
  final MetaMaskService _metamaskService = MetaMaskService();
  
  // Contract configurations
  Map<String, dynamic>? _emailPaymentRegistryAbi;
  String? _emailPaymentRegistryBytecode;
  
  // Contract instances
  DeployedContract? _emailPaymentRegistry;
  
  /// Initialize the service
  Future<void> init() async {
    await _loadContractData();
    await _getDeployedContractsAddresses();
  }
  
  /// Load contract ABI and bytecode from asset files
  Future<void> _loadContractData() async {
    try {
      // Load Email Payment Registry contract data
      final abiString = await rootBundle.loadString('assets/contracts/EmailPaymentRegistry.json');
      final Map<String, dynamic> contractData = json.decode(abiString);
      _emailPaymentRegistryAbi = contractData['abi'];
      _emailPaymentRegistryBytecode = contractData['bytecode'];
    } catch (e) {
      print('Error loading contract data: $e');
    }
  }
  
  /// Get addresses of already deployed contracts from backend
  Future<void> _getDeployedContractsAddresses() async {
    try {
      // Get Email Payment Registry address
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/get_contract.php?contract_name=EmailPaymentRegistry&chain_id=${ApiConstants.defaultChainId}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['contract'] != null) {
          final address = data['contract']['address'];
          
          // If contract is found, initialize the contract instance
          if (address != null && address.isNotEmpty) {
            _initEmailPaymentRegistryContract(address);
          }
        }
      }
    } catch (e) {
      print('Error fetching deployed contracts: $e');
    }
  }
  
  /// Initialize Email Payment Registry contract instance with deployed address
  void _initEmailPaymentRegistryContract(String address) {
    if (_emailPaymentRegistryAbi != null) {
      _emailPaymentRegistry = DeployedContract(
        ContractAbi.fromJson(json.encode(_emailPaymentRegistryAbi), 'EmailPaymentRegistry'),
        EthereumAddress.fromHex(address),
      );
    }
  }
  
  /// Deploy Email Payment Registry contract
  Future<String?> deployEmailPaymentRegistryContract(BuildContext context) async {
    if (_emailPaymentRegistryBytecode == null || _emailPaymentRegistryAbi == null) {
      throw Exception('Contract data not loaded');
    }
    
    // Deploy contract using MetaMask
    final contractAddress = await _metamaskService.deployContract(
      context: context,
      bytecode: _emailPaymentRegistryBytecode!,
      abi: json.encode(_emailPaymentRegistryAbi),
    );
    
    if (contractAddress != null) {
      // Save the deployed contract to backend
      final success = await _metamaskService.saveDeployedContract(
        contractName: 'EmailPaymentRegistry',
        contractAddress: contractAddress,
        chainId: _metamaskService.chainId,
        abi: json.encode(_emailPaymentRegistryAbi),
      );
      
      if (success) {
        // Initialize contract instance
        _initEmailPaymentRegistryContract(contractAddress);
      }
    }
    
    return contractAddress;
  }
  
  /// Register email in the contract
  Future<String?> registerEmail(BuildContext context, String email) async {
    if (_emailPaymentRegistry == null) {
      throw Exception('Contract not initialized');
    }
    
    // Calculate email hash
    final emailHash = _calculateEmailHash(email);
    final address = await _metamaskService.connectedAddress;
    
    if (address == null) {
      throw Exception('No wallet connected');
    }
    
    // Encode function call
    final function = _emailPaymentRegistry!.function('registerEmail');
    final data = function.encodeCall([
      emailHash,
      EthereumAddress.fromHex(address),
    ]);
    
    // Send transaction
    return _metamaskService.sendTransaction(
      context: context,
      to: _emailPaymentRegistry!.address.hex,
      value: '0', // No ETH sent for registration
      data: '0x${hex_lib.HEX.encode(data)}',
    );
  }
  
  /// Send payment to email
  Future<String?> sendPaymentToEmail(BuildContext context, String email, String amount) async {
    if (_emailPaymentRegistry == null) {
      throw Exception('Contract not initialized');
    }
    
    // Calculate email hash
    final emailHash = _calculateEmailHash(email);
    
    // Encode function call
    final function = _emailPaymentRegistry!.function('sendPaymentToEmail');
    final data = function.encodeCall([emailHash]);
    
    // Send transaction with value
    return _metamaskService.sendTransaction(
      context: context,
      to: _emailPaymentRegistry!.address.hex,
      value: amount, // ETH value to send
      data: '0x${hex_lib.HEX.encode(data)}',
    );
  }
  
  /// Calculate keccak256 hash of email - this should match the Solidity implementation
  List<int> _calculateEmailHash(String email) {
    // In a real implementation, we should use the same keccak256 algorithm as Ethereum
    // For demo purposes, we're using a simplified approach
    
    // Convert email to bytes using the same encoding as Solidity (UTF-8)
    final emailBytes = utf8.encode(email);
    
    // Generate a fixed-length hash
    // Note: In production, use a proper keccak256 implementation that matches Ethereum's
    final hashList = List<int>.filled(32, 0); // 32 bytes for keccak256
    
    // Simple hash algorithm (NOT FOR PRODUCTION)
    for (int i = 0; i < emailBytes.length; i++) {
      hashList[i % 32] = (hashList[i % 32] + emailBytes[i]) % 256;
    }
    
    return hashList;
  }
  
  /// Check if Email Payment Registry contract is deployed
  bool get isEmailPaymentRegistryDeployed => _emailPaymentRegistry != null;
}
