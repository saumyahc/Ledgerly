// Contract Configuration for Ledgerly
// Update these addresses after deploying contracts with 'truffle migrate'

class ContractConfig {
  // ✅ UPDATED AFTER DEPLOYMENT
  static const String emailPaymentRegistryAddress = "0x7c28a30fb917e6ab5990ef99f86cb90083fa2b99"; // Updated to deployed contract address
  
  // Local development network configuration
  static const String localRpcUrl = "http://10.0.2.2:7545"; // For Android Emulator
  static const String localRpcUrlIOS = "http://127.0.0.1:7545"; // For iOS Simulator
  static const String localRpcUrlDesktop = "http://127.0.0.1:7545"; // For Desktop/Web
  static const int localChainId = 1337; // Ganache default
  
  // Get the correct RPC URL based on platform
  static String getRpcUrl() {
    // You can add platform detection here if needed
    // For now, return the Android emulator URL as default
    return localRpcUrl;
  }
  
  // Network configurations
  static const Map<String, Map<String, dynamic>> networks = {
    'local': {
      'name': 'Local Development',
      'rpcUrl': localRpcUrl,
      'chainId': localChainId,
      'symbol': 'ETH',
      'blockExplorer': null,
      'contractAddress': emailPaymentRegistryAddress,
    },
    'sepolia': {
      'name': 'Sepolia Testnet',
      'rpcUrl': 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY',
      'chainId': 11155111,
      'symbol': 'ETH',
      'blockExplorer': 'https://sepolia.etherscan.io',
      'contractAddress': null, // Deploy to testnet later
    },
  };
  
  // Current active network
  static const String activeNetwork = 'local'; // Change to 'sepolia' for testnet
  
  // Get current network config
  static Map<String, dynamic> get currentNetwork => networks[activeNetwork]!;
  
  // Validation
  static bool get isConfigured => emailPaymentRegistryAddress != "0x...";
  
  // Instructions for setup
  static const String setupInstructions = '''
📋 Contract Setup Instructions:

1. Start Ganache: ganache-cli --accounts 10 --host 0.0.0.0 --port 7545 --deterministic
2. Deploy contracts: truffle migrate --network development
3. Copy the EmailPaymentRegistry address from the migration output
4. Update emailPaymentRegistryAddress in this file
5. Restart your Flutter app

Example migration output:
Deploying 'EmailPaymentRegistry'
   > transaction hash:    0x...
   > contract address:    0x1234567890123456789012345678901234567890  <-- Copy this address
   > block number:        2
   > account:             0x...
   > balance:             99.99 ETH
   > gas used:            1234567
   > gas price:           20 gwei
   > value sent:          0 ETH
   > total cost:          0.01 ETH
''';
}

// ABI for EmailPaymentRegistry contract
// This will be automatically generated after compilation
class ContractABI {
  static const String emailPaymentRegistry = '''
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
        "internalType": "string",
        "name": "email",
        "type": "string"
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
        "internalType": "string",
        "name": "toEmail",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "fromEmail",
        "type": "string"
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
        "internalType": "string",
        "name": "email",
        "type": "string"
      }
    ],
    "name": "getWalletFromEmail",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
''';
}
