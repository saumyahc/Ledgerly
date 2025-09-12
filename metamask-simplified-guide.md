# Ledgerly MetaMask Integration Guide

This guide explains how to use MetaMask with Ledgerly for contract deployment.

## Simplified Integration

We've simplified the MetaMask integration to work without the WalletConnect dependency. The current implementation:

1. Uses deep linking to open MetaMask when needed
2. Provides simulated interaction for development purposes
3. Offers a pathway to add full WalletConnect integration later

## Setup Instructions

### For Users

1. **Install MetaMask Mobile**
   - [iOS App Store](https://apps.apple.com/us/app/metamask-blockchain-wallet/id1438144202)
   - [Google Play Store](https://play.google.com/store/apps/details?id=io.metamask)

2. **Create or Import a Wallet**
   - Follow MetaMask's instructions to create a new wallet or import an existing one

3. **Add Test Network**
   - Go to Settings > Networks > Add Network
   - Add Sepolia Testnet:
     - Network Name: Sepolia
     - RPC URL: https://sepolia.infura.io/v3/
     - Chain ID: 11155111
     - Currency Symbol: ETH
     - Block Explorer URL: https://sepolia.etherscan.io/

4. **Get Test Ether**
   - Visit [Sepolia Faucet](https://sepoliafaucet.com/)
   - Enter your wallet address
   - Complete any verification steps
   - Wait for test ETH to arrive in your wallet

### For Developers

#### Contract Deployment Options

1. **Manual Contract Deployment (Recommended for Now)**
   - Use Remix IDE (https://remix.ethereum.org/)
   - Create the contract file and compile it
   - Use "Injected Web3" to connect to MetaMask
   - Deploy the contract
   - Copy the deployed contract address
   - Update the `constants.dart` file with the contract address

2. **In-App Contract Deployment (For Future Implementation)**
   - Enhance the current simplified implementation to use WalletConnect v2
   - Implement proper deep linking with transaction signing
   - Test with MetaMask mobile app

## Integration Enhancement Plan

To fully integrate MetaMask in the future:

1. Add WalletConnect v2 dependency when it becomes stable with newer web_socket_channel versions
2. Implement proper mobile deep linking scheme
3. Add QR code scanning support for desktop to mobile connections
4. Enhance contract deployment dialog with real-time status updates

## Testing the Current Implementation

The current implementation includes simulated dialogs that mimic MetaMask interactions:

1. **Connect Wallet**
   - Open the Contract Deployment page
   - Tap "Connect MetaMask"
   - A simulated connection dialog appears
   - After "connection", a mock address is displayed

2. **Deploy Contract**
   - After connecting, tap "Deploy Contract"
   - A simulated deployment dialog appears
   - After "deployment", a mock contract address is displayed

## Troubleshooting

- If you encounter dependency issues, check if any dependency uses incompatible versions of web_socket_channel
- For real MetaMask integration, check mobile app settings to ensure deep linking is enabled
- Make sure you have test ETH in your wallet before attempting deployments
