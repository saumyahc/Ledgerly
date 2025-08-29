# Ledgerly Blockchain Integration Documentation

## Overview

Ledgerly is a crypto-based payments application built with Flutter that integrates Ethereum blockchain functionality for secure cryptocurrency transactions. This document outlines the blockchain architecture, implementation details, and usage guidelines.

## Architecture

The blockchain functionality is organized into three main service layers:

### 1. Wallet Service (`wallet_service.dart`)
- **Purpose**: Manages wallet creation, import, and key operations
- **Key Features**:
  - Generate new HD wallets with BIP-39 mnemonic phrases
  - Import existing wallets from mnemonic phrases
  - Secure key storage using Flutter Secure Storage
  - Address validation and derivation
  - Private key management

### 2. Blockchain Service (`blockchain_service.dart`)
- **Purpose**: Handles blockchain network connections and operations
- **Key Features**:
  - Multi-network support (Ethereum Mainnet, Sepolia Testnet, Polygon, Local)
  - Balance queries and transaction sending
  - Gas estimation and price management
  - Transaction monitoring and confirmation tracking
  - Network switching capabilities

### 3. Transaction Service (`transaction_service.dart`)
- **Purpose**: Manages transaction history and monitoring
- **Key Features**:
  - Transaction history persistence
  - Real-time transaction monitoring
  - Status updates and confirmation tracking
  - Transaction categorization and filtering
  - Export functionality

## Dependencies

```yaml
dependencies:
  # Blockchain Dependencies
  web3dart: ^2.7.3
  web_socket_channel: ^3.0.3
  flutter_secure_storage: ^9.2.2
  bip39: ^1.0.6
  ed25519_hd_key: ^2.2.0
  hex: ^0.2.0
  crypto: ^3.0.5
```

## Network Configuration

### Supported Networks

1. **Ethereum Mainnet**
   - Chain ID: 1
   - Symbol: ETH
   - Explorer: https://etherscan.io

2. **Ethereum Sepolia Testnet** (Default for development)
   - Chain ID: 11155111
   - Symbol: SepoliaETH
   - Explorer: https://sepolia.etherscan.io

3. **Polygon Mainnet**
   - Chain ID: 137
   - Symbol: MATIC
   - Explorer: https://polygonscan.com

4. **Local Development Network**
   - Chain ID: 1337
   - Symbol: ETH
   - RPC: http://127.0.0.1:8545

### RPC Configuration

For production deployment, you'll need to:
1. Sign up for Infura or Alchemy
2. Replace `YOUR_PROJECT_ID` with your actual project ID
3. Update the RPC URLs in `blockchain_service.dart`

## Security Features

### Secure Storage
- Private keys stored using Flutter Secure Storage
- Mnemonic phrases encrypted at rest
- No sensitive data in application memory after use

### Key Generation
- BIP-39 compliant mnemonic generation
- HD wallet derivation (BIP-44 compatible)
- Cryptographically secure random number generation

### Transaction Security
- All transactions signed locally
- Private keys never transmitted
- Gas estimation to prevent overpayment

## Usage Examples

### Initialize Services

```dart
// Initialize blockchain service
final blockchainService = BlockchainService();

// Initialize transaction service
final transactionService = TransactionService(blockchainService);

// Switch to Sepolia testnet for development
blockchainService.setNetwork('ethereum_sepolia');
```

### Create or Import Wallet

```dart
// Generate new wallet
final mnemonic = await WalletService.generateWallet();
print('Save this mnemonic safely: $mnemonic');

// Or import existing wallet
final success = await WalletService.importWallet('your twelve word mnemonic phrase here');
if (success) {
  print('Wallet imported successfully');
}
```

### Check Wallet Balance

```dart
final walletAddress = await WalletService.getWalletAddress();
if (walletAddress != null) {
  final balanceInEther = await blockchainService.getBalanceInEther(walletAddress);
  print('Balance: $balanceInEther ETH');
}
```

### Send Transaction

```dart
try {
  final txHash = await transactionService.sendTransaction(
    toAddress: '0x742d35Cc6634C0532925a3b8D88f91b5b57e5A81',
    amount: 0.01, // Amount in Ether
    memo: 'Payment for services',
  );
  
  print('Transaction sent: $txHash');
} catch (e) {
  print('Transaction failed: $e');
}
```

### Monitor Transactions

```dart
// Listen to transaction updates
transactionService.transactionStream.listen((transactions) {
  print('Total transactions: ${transactions.length}');
  
  final pending = transactions.where((tx) => tx.isPending).length;
  print('Pending transactions: $pending');
});
```

## Error Handling

### Common Exceptions

- `BlockchainException`: Network or blockchain-related errors
- `Exception`: Wallet or validation errors
- Connection timeouts and network failures

### Error Categories

1. **Network Errors**: RPC connection issues, timeouts
2. **Validation Errors**: Invalid addresses, insufficient balance
3. **Transaction Errors**: Gas estimation failures, transaction rejection
4. **Storage Errors**: Secure storage access issues

## Testing

### Test Networks
- Use Sepolia testnet for development
- Get test ETH from faucets:
  - https://sepoliafaucet.com/
  - https://faucet.sepolia.dev/

### Local Development
```bash
# Install Ganache CLI for local blockchain
npm install -g ganache-cli

# Start local blockchain
ganache-cli -p 8545 -m "your test mnemonic phrase here"
```

## Performance Considerations

### Optimization Strategies
- Transaction batching for multiple operations
- Caching of frequently accessed data
- Efficient gas estimation
- Background transaction monitoring

### Memory Management
- Proper disposal of services and streams
- Secure deletion of sensitive data
- Efficient transaction history storage

## Integration Checklist

### Pre-Production
- [ ] Configure production RPC endpoints
- [ ] Test on mainnet with small amounts
- [ ] Implement proper error logging
- [ ] Set up transaction monitoring
- [ ] Configure backup and recovery procedures

### Security Audit
- [ ] Code review of key management
- [ ] Penetration testing
- [ ] Dependency vulnerability scan
- [ ] Secure storage validation

## Future Enhancements

### Planned Features
1. **Token Support**: ERC-20 token transactions
2. **DeFi Integration**: DEX interactions, yield farming
3. **NFT Support**: ERC-721/ERC-1155 token management
4. **Multi-Signature Wallets**: Enhanced security for business accounts
5. **Layer 2 Solutions**: Arbitrum, Optimism support

### Smart Contract Integration
- Custom payment contracts
- Escrow services
- Recurring payments
- Multi-party transactions

## Support and Troubleshooting

### Common Issues

1. **"Insufficient funds for gas"**
   - Ensure wallet has enough ETH for transaction fees
   - Check current gas prices and adjust accordingly

2. **"Transaction timeout"**
   - Network congestion may cause delays
   - Increase gas price for faster confirmation

3. **"Invalid address"**
   - Verify recipient address format
   - Ensure address belongs to correct network

### Getting Help

For technical support or questions:
1. Check the error logs and debug output
2. Verify network connectivity and RPC endpoints
3. Consult Ethereum documentation for protocol-specific issues
4. Review transaction details on block explorers

## Conclusion

This blockchain integration provides Ledgerly with robust cryptocurrency payment capabilities while maintaining security and user experience. The modular architecture allows for easy extension and maintenance as the platform evolves.

Remember to always test thoroughly on testnets before deploying to mainnet, and never expose private keys or mnemonic phrases in your code or logs.
