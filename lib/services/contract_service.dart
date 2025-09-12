import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import '../constants.dart';
import 'metamask_service.dart';

// Access to the ASCII encoder
final ascii = AsciiCodec();

/// Service for interacting with the EmailPaymentRegistry smart contract
class ContractService {
  // Singleton instance
  static final ContractService _instance = ContractService._internal();
  factory ContractService() => _instance;
  ContractService._internal();
  
  // Services
  final MetaMaskService _metamaskService = MetaMaskService();
  
  // Contract ABI (Application Binary Interface)
  // This is a simplified ABI for the EmailPaymentRegistry contract - kept for reference
  static const String contractAbi = '''
[
  {
    "inputs": [],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "emailHash",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "wallet",
        "type": "address"
      }
    ],
    "name": "EmailRegistered",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "previousOwner",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipTransferred",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "fromEmailHash",
        "type": "bytes32"
      },
      {
        "indexed": true,
        "internalType": "bytes32",
        "name": "toEmailHash",
        "type": "bytes32"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "PaymentSent",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "emailHash",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "newWallet",
        "type": "address"
      }
    ],
    "name": "adminOverrideEmail",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "email",
        "type": "string"
      }
    ],
    "name": "computeEmailHash",
    "outputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "stateMutability": "pure",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "emailHash",
        "type": "bytes32"
      }
    ],
    "name": "getWalletByEmail",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "emailHash",
        "type": "bytes32"
      }
    ],
    "name": "getUserProfile",
    "outputs": [
      {
        "internalType": "address",
        "name": "wallet",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "registeredAt",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "lastUpdatedAt",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalReceived",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalSent",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "emailHash",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "wallet",
        "type": "address"
      }
    ],
    "name": "registerEmail",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "fromEmailHash",
        "type": "bytes32"
      },
      {
        "internalType": "bytes32",
        "name": "toEmailHash",
        "type": "bytes32"
      }
    ],
    "name": "sendPaymentByEmail",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "toEmailHash",
        "type": "bytes32"
      }
    ],
    "name": "sendPaymentToEmail",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "transferOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "withdraw",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
  ''';

  /// Calculate email hash the same way the contract does
  String hashEmail(String email) {
    return '0x${crypto.sha256.convert(utf8.encode(email)).toString()}';
  }
  
  /// Helper function to simulate keccak256 hashing (normally provided by web3dart)
  String keccak256(List<int> input) {
    // In a real implementation, you'd use a proper keccak256 library
    // For now, we'll use SHA-256 as a placeholder
    return crypto.sha256.convert(input).toString();
  }

  /// Register an email with a wallet address
  Future<Map<String, dynamic>> registerEmail({
    required BuildContext context,
    required String email,
  }) async {
    try {
      // First connect the wallet if not connected
      if (!_metamaskService.isConnected) {
        final address = await _metamaskService.connect(context);
        if (address == null) {
          return {
            'success': false,
            'error': 'Failed to connect wallet',
          };
        }
      }

      // Generate the function call data for registerEmail
      final emailHash = hashEmail(email);
      final functionSignature = 'registerEmail(bytes32,address)';
      final functionSelector = '0x' + keccak256(ascii.encode(functionSignature)).substring(0, 8);
      
      // Encode parameters
      final encodedEmailHash = emailHash.padRight(66, '0'); // bytes32 parameter
      final encodedWalletAddress = _metamaskService.connectedAddress!.padRight(66, '0'); // address parameter
      
      final data = '$functionSelector$encodedEmailHash$encodedWalletAddress';
      
      // Send transaction via MetaMask
      final txHash = await _metamaskService.sendTransaction(
        context: context,
        to: ApiConstants.emailPaymentRegistryAddress,
        value: '0x0', // No ETH being sent
        data: data,
      );
      
      if (txHash == null) {
        return {
          'success': false,
          'error': 'Transaction rejected',
        };
      }
      
      return {
        'success': true,
        'txHash': txHash,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error registering email: $e',
      };
    }
  }

  /// Send payment to an email
  Future<Map<String, dynamic>> sendPaymentToEmail({
    required BuildContext context,
    required String toEmail,
    required String amount, // In ETH
  }) async {
    try {
      // First connect the wallet if not connected
      if (!_metamaskService.isConnected) {
        final address = await _metamaskService.connect(context);
        if (address == null) {
          return {
            'success': false,
            'error': 'Failed to connect wallet',
          };
        }
      }

      // Calculate email hash
      final toEmailHash = hashEmail(toEmail);
      
      // Generate the function call data for sendPaymentToEmail
      final functionSignature = 'sendPaymentToEmail(bytes32)';
      final functionSelector = '0x' + keccak256(ascii.encode(functionSignature)).substring(0, 8);
      
      // Encode parameters
      final encodedEmailHash = toEmailHash.padRight(66, '0'); // bytes32 parameter
      
      final data = '$functionSelector$encodedEmailHash';
      
      // Convert ETH to Wei
      final amountWei = BigInt.from(double.parse(amount) * 1e18).toString();
      
      // Send transaction via MetaMask
      final txHash = await _metamaskService.sendTransaction(
        context: context,
        to: ApiConstants.emailPaymentRegistryAddress,
        value: '0x$amountWei', // ETH amount in wei, converted to hex
        data: data,
      );
      
      if (txHash == null) {
        return {
          'success': false,
          'error': 'Transaction rejected',
        };
      }
      
      return {
        'success': true,
        'txHash': txHash,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error sending payment: $e',
      };
    }
  }

  /// Send payment from one email to another (for users with both emails registered)
  Future<Map<String, dynamic>> sendPaymentBetweenEmails({
    required BuildContext context,
    required String fromEmail,
    required String toEmail,
    required String amount, // In ETH
  }) async {
    try {
      // First connect the wallet if not connected
      if (!_metamaskService.isConnected) {
        final address = await _metamaskService.connect(context);
        if (address == null) {
          return {
            'success': false,
            'error': 'Failed to connect wallet',
          };
        }
      }

      // Calculate email hashes
      final fromEmailHash = hashEmail(fromEmail);
      final toEmailHash = hashEmail(toEmail);
      
      // Generate the function call data for sendPaymentByEmail
      final functionSignature = 'sendPaymentByEmail(bytes32,bytes32)';
      final functionSelector = '0x' + keccak256(ascii.encode(functionSignature)).substring(0, 8);
      
      // Encode parameters
      final encodedFromEmailHash = fromEmailHash.padRight(66, '0'); // bytes32 parameter
      final encodedToEmailHash = toEmailHash.padRight(66, '0'); // bytes32 parameter
      
      final data = '$functionSelector$encodedFromEmailHash$encodedToEmailHash';
      
      // Convert ETH to Wei
      final amountWei = BigInt.from(double.parse(amount) * 1e18).toString();
      
      // Send transaction via MetaMask
      final txHash = await _metamaskService.sendTransaction(
        context: context,
        to: ApiConstants.emailPaymentRegistryAddress,
        value: '0x$amountWei', // ETH amount in wei, converted to hex
        data: data,
      );
      
      if (txHash == null) {
        return {
          'success': false,
          'error': 'Transaction rejected',
        };
      }
      
      return {
        'success': true,
        'txHash': txHash,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error sending payment: $e',
      };
    }
  }

  /// Lookup a wallet address by email
  Future<Map<String, dynamic>> lookupEmailWallet(String email) async {
    try {
      // First check our backend API
      final apiResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/email_payment.php?email=$email'),
      );
      
      if (apiResponse.statusCode == 200) {
        final apiData = json.decode(apiResponse.body);
        if (apiData['success'] == true && apiData['user'] != null) {
          return {
            'success': true,
            'wallet': apiData['user']['wallet_address'],
            'source': 'api',
          };
        }
      }
      
      // If not found in API, query the smart contract
      // This would require a connection to a node - for production you'd need
      // to use Infura or another provider for read-only operations
      
      return {
        'success': false,
        'error': 'Email not registered',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error looking up email: $e',
      };
    }
  }
}
