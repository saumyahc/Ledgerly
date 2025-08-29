# Blockchain Integration Documentation

## Overview
Ledgerly now includes comprehensive blockchain functionality for cryptocurrency payments, allowing users to create wallets, send/receive ETH, and manage their crypto assets directly within the app.

## Architecture

### Core Components

#### 1. Blockchain Services (`lib/services/blockchain/`)
- **WalletService**: Handles wallet creation, import, and key management
- **BlockchainService**: Manages Ethereum network interactions
- **TransactionService**: Handles transaction sending and monitoring
- **BlockchainManager**: Unified coordinator for all blockchain operations

#### 2. Backend Integration
- **wallet_api.php**: REST API for linking wallets to user accounts
- **wallet_api_service.dart**: Flutter service for backend communication
- **Database**: Updated user_profiles table with wallet_address field

#### 3. Security Features
- **Flutter Secure Storage**: Encrypted storage for private keys
- **BIP-39 Mnemonic**: Industry-standard seed phrase generation
- **Network Validation**: Smart mainnet-to-testnet conversion for safe testing

## Features

### Wallet Management
- ✅ Create new wallets with secure seed phrases
- ✅ Import existing wallets using mnemonic phrases
- ✅ Automatic wallet-to-user account linking
- ✅ Secure private key storage

### Transaction Capabilities
- ✅ Send ETH to any valid Ethereum address
- ✅ Receive ETH with QR code generation
- ✅ Real-time balance updates
- ✅ Transaction history tracking

### Network Support
- ✅ Ethereum Mainnet support
- ✅ Sepolia Testnet for development/testing
- ✅ Automatic network switching based on environment

## Configuration

### Environment Variables (.env)
```
# MetaMask/Infura Configuration
INFURA_PROJECT_ID=your_infura_project_id
ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/your_project_id
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id

# Network Configuration (mainnet/testnet)
NETWORK_MODE=testnet
```

### Dependencies (pubspec.yaml)
```yaml
dependencies:
  web3dart: ^2.7.3
  http: ^0.13.5
  bip39: ^1.0.6
  flutter_secure_storage: ^9.0.0
  flutter_dotenv: ^5.1.0
  qr_flutter: ^4.0.0
```

## Usage Guide

### For Users
1. **Create Wallet**: Tap "Create New Wallet" and securely backup the 12-word seed phrase
2. **Import Wallet**: Use "Import Wallet" with existing seed phrase
3. **Send ETH**: Enter recipient address and amount
4. **Receive ETH**: Share your wallet address or QR code

### For Developers

#### Initialize Blockchain Manager
```dart
final blockchain = BlockchainManager.instance;
await blockchain.initialize();
```

#### Create New Wallet
```dart
final mnemonic = await blockchain.createWallet();
final address = await blockchain.getWalletAddress();
```

#### Send Transaction
```dart
final txHash = await blockchain.sendTransaction(
  toAddress: recipientAddress,
  amount: amountInEther,
);
```

#### Check Balance
```dart
final balance = await blockchain.getBalance();
```

## API Endpoints

### Backend Wallet API (`backend_example/wallet_api.php`)

#### Link Wallet to User
```http
PUT /wallet_api.php
Content-Type: application/json

{
  "user_id": 123,
  "wallet_address": "0x742d35Cc6635C0532925a3b8D42C06E6C7b6E6b7"
}
```

#### Get User Wallet
```http
GET /wallet_api.php?user_id=123
```

## Database Schema

### Updated user_profiles Table
```sql
ALTER TABLE user_profiles 
ADD COLUMN wallet_address VARCHAR(42),
ADD COLUMN wallet_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

## Security Considerations

### Private Key Management
- Private keys are stored encrypted using Flutter Secure Storage
- Keys never leave the device unencrypted
- Mnemonic phrases shown only during wallet creation for backup

### Network Security
- All RPC calls use HTTPS
- Infura provides reliable and secure Ethereum node access
- Transaction validation before broadcasting

### User Data Protection
- Wallet addresses are public by design (blockchain requirement)
- Private keys and mnemonics are device-local only
- Backend only stores wallet addresses for account linking

## Testing

### Development Mode
- Set `NETWORK_MODE=testnet` in .env file
- Uses Sepolia testnet for safe testing with fake ETH
- Get free test ETH from Sepolia faucets

### Mainnet Deployment
- Set `NETWORK_MODE=mainnet` in .env file
- Ensure users understand they're using real ETH
- Implement additional confirmations for large transactions

## Troubleshooting

### Common Issues
1. **"Insufficient funds"**: Check ETH balance and gas fees
2. **"Invalid address"**: Verify recipient address is valid Ethereum address
3. **"Transaction failed"**: Check network connectivity and gas price

### Debug Mode
Enable debug logging in blockchain services for detailed error information.

## Future Enhancements

### Planned Features
- Multi-token support (ERC-20 tokens)
- Transaction fee estimation
- Address book functionality
- Transaction categorization
- Portfolio tracking

### Integration Possibilities
- DeFi protocol integrations
- NFT support
- Cross-chain functionality
- Hardware wallet support

## Support

For blockchain-related issues:
1. Check network connectivity
2. Verify environment variables are set correctly
3. Ensure sufficient balance for transactions
4. Review transaction details carefully

## Version History

### v1.0.0 - Initial Blockchain Integration
- Basic wallet creation and import
- ETH send/receive functionality
- Backend account linking
- Secure storage implementation
- Multi-network support (mainnet/testnet)

---

**Note**: This is a production-ready blockchain integration. Always use testnet for development and testing before deploying to mainnet.
