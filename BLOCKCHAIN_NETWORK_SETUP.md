# Blockchain Network Setup Guide

## Overview
This guide explains how to set up and use the blockchain networks for wallet creation and contract interaction in Ledgerly.

## 🔧 Network Configuration

### 1. Environment Setup
Your `.env` file contains all network configurations:

```env
# Your Infura Project ID
ETHEREUM_API_KEY=c669c4a6004f44eebe61de67c401b7a5

# Network Selection
ENABLE_MAINNET=false           # Set to true for production
DEFAULT_NETWORK=ethereum_sepolia  # Default network to use

# Safety Settings
DEBUG_MODE=true                # Additional logging and checks
MAX_TRANSACTION_AMOUNT_ETH=1.0 # Transaction safety limit
```

### 2. Available Networks

| Network | Purpose | Real Money | Gas Costs |
|---------|---------|------------|-----------|
| `local_ganache` | Development | ❌ No | Free |
| `ethereum_sepolia` | Testing | ❌ No | Free (testnet ETH) |
| `ethereum_goerli` | Testing | ❌ No | Free (testnet ETH) |
| `ethereum_mainnet` | Production | ✅ Yes | Real ETH |
| `polygon` | Production | ✅ Yes | Real MATIC |

## 🚀 Quick Start

### Step 1: Choose Your Network
For development and testing:
```env
ENABLE_MAINNET=false
DEFAULT_NETWORK=ethereum_sepolia
```

For production:
```env
ENABLE_MAINNET=true
DEFAULT_NETWORK=ethereum_mainnet
```

### Step 2: Start the Service
The blockchain service automatically:
- Reads your `.env` configuration
- Connects to the appropriate network
- Provides wallet creation and contract interaction

```dart
// The service is already integrated in your app
final blockchainService = BlockchainService();
await blockchainService.initialize();

// Check network status
final status = await blockchainService.getNetworkStatus();
print('Connected to: ${status['network']}');
```

## 🔨 Development Workflow

### 1. Local Development (Ganache)
```bash
# Start Ganache (use Ganache GUI or CLI)
ganache-cli --port 7545 --deterministic

# Your app will automatically connect to local network
```

### 2. Testnet Development (Sepolia)
```env
DEFAULT_NETWORK=ethereum_sepolia
```
- Get free testnet ETH from [Sepolia Faucet](https://sepoliafaucet.com/)
- Test real blockchain interactions without cost

### 3. Production (Mainnet)
```env
ENABLE_MAINNET=true
DEFAULT_NETWORK=ethereum_mainnet
```
⚠️ **WARNING**: This uses real ETH. Double-check everything!

## 💰 Wallet Creation Process

### How It Works
1. **Network Selection**: App selects network based on `.env`
2. **Infura Connection**: Connects to Ethereum via your Infura endpoint
3. **Wallet Generation**: Creates wallet using secure random generation
4. **MetaMask Integration**: Syncs with MetaMask if available

### Network-Specific Behavior

#### Local Ganache
```dart
// Wallet created on local blockchain
// Address: 0x123... (only valid locally)
// Balance: 100 ETH (fake, for testing)
```

#### Sepolia Testnet
```dart
// Wallet created on Sepolia testnet
// Address: 0x456... (valid on testnet)
// Balance: 0 SepoliaETH (get from faucet)
```

#### Mainnet
```dart
// Wallet created on Ethereum mainnet
// Address: 0x789... (real Ethereum address)
// Balance: 0 ETH (real money required)
```

## 🔍 Network Status Checking

### In Your App
```dart
// Check current network
final status = await blockchainService.getNetworkStatus();
print('Network: ${status['network']}');
print('Connected: ${status['connected']}');
print('Block Number: ${status['blockNumber']}');
```

### Using the Status Checker
1. Open `api_status_checker.html` in browser
2. Check all API endpoints including MetaMask
3. Verify network connectivity

### Using PowerShell Script
```powershell
# Run the API status test
.\test_api_status.ps1
```

## ⚙️ Advanced Configuration

### Network Switching
```dart
// Switch to different network
await blockchainService.switchNetwork('ethereum_mainnet');

// Verify switch
final newStatus = await blockchainService.getNetworkStatus();
```

### Custom RPC Endpoints
```env
# Add custom endpoints to .env
CUSTOM_RPC_URL=https://your-custom-node.com
```

### Gas Price Management
```dart
// Set gas price for transactions
final gasPrice = await blockchainService.getGasPrice();
print('Current gas price: $gasPrice gwei');
```

## 🛡️ Security & Safety

### Development Safety
- `DEBUG_MODE=true` enables extra logging and validation
- `MAX_TRANSACTION_AMOUNT_ETH=1.0` limits transaction sizes
- Automatic network validation before transactions

### Production Safety
- Never commit `.env` to version control
- Use hardware wallets for large amounts
- Test thoroughly on testnet first
- Enable transaction confirmations

## 🔧 Troubleshooting

### Common Issues

#### "Network not available"
```bash
# Check internet connection
# Verify Infura API key in .env
# Check if network is down at https://status.infura.io/
```

#### "Insufficient funds"
```bash
# For testnet: Get ETH from faucet
# For mainnet: Add real ETH to wallet
# Check gas price isn't too high
```

#### "Contract deployment failed"
```bash
# Check contract compilation
# Verify network supports contract
# Ensure sufficient gas limit
```

### Getting Help
1. Check `LEDGERLY_IMPLEMENTATION_STATUS.md` for current status
2. Review `METAMASK_LOCAL_SETUP.md` for MetaMask issues
3. Test with `api_status_checker.html`
4. Enable `DEBUG_MODE=true` for detailed logs

## 📋 Network Setup Checklist

### Before Development
- [ ] Infura account created and API key added to `.env`
- [ ] Network selection configured (`ENABLE_MAINNET=false` for testing)
- [ ] Ganache installed and running (for local development)
- [ ] MetaMask configured with correct network

### Before Testing
- [ ] Switched to testnet (`ethereum_sepolia`)
- [ ] Obtained testnet ETH from faucet
- [ ] Contracts deployed to testnet
- [ ] API status checker shows all green

### Before Production
- [ ] Code thoroughly tested on testnet
- [ ] Security audit completed
- [ ] `ENABLE_MAINNET=true` configured
- [ ] Real ETH available for gas fees
- [ ] Monitoring and alerting set up

## 🎯 Next Steps
1. Start with local Ganache for initial development
2. Move to Sepolia testnet for realistic testing
3. Use mainnet only when ready for production
4. Monitor network status with provided tools
5. Follow security best practices throughout

Remember: The blockchain service handles network switching automatically based on your `.env` configuration. You just need to set the appropriate values for your use case!
