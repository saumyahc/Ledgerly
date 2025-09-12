# MetaMask Contract Deployment Guide

This guide will walk you through deploying smart contracts for Ledgerly using MetaMask.

## Prerequisites

Before you begin, make sure you have:

1. MetaMask installed (browser extension or mobile app)
2. Enough ETH on your test network (e.g., Sepolia)
3. Node.js and npm installed
4. Truffle installed: `npm install -g truffle`
5. Basic knowledge of Ethereum and smart contracts

## Option 1: In-App Deployment (Recommended)

The Ledgerly app includes a contract deployment interface for easy deployment:

1. **Compile the contracts**
   ```bash
   truffle compile
   ```

2. **Extract contract artifacts**
   ```bash
   node extract-contract-data.js
   ```

3. **Launch the Ledgerly app**

4. **Navigate to the Contract Deployment page**
   - Go to Wallet page
   - Tap on the "Deploy" quick action button

5. **Connect your MetaMask wallet**
   - Tap "Connect MetaMask"
   - Approve the connection in MetaMask

6. **Deploy the contract**
   - Tap "Deploy Contract"
   - Confirm the transaction in MetaMask
   - Wait for confirmation
   - Contract address will be displayed and saved automatically

## Option 2: Using Remix IDE

For a more manual approach:

1. Visit [Remix IDE](https://remix.ethereum.org/)

2. Create a new file named `EmailPaymentRegistry.sol` and paste the contract code:
   ```solidity
   // SPDX-License-Identifier: MIT
   pragma solidity ^0.8.0;
   
   contract EmailPaymentRegistry {
       // ... contract code from contracts/EmailPaymentRegistry.sol
   }
   ```

3. Compile the contract:
   - Select Solidity Compiler tab
   - Choose compiler version 0.8.0 or later
   - Click "Compile"

4. Deploy the contract:
   - Select Deploy & Run Transactions tab
   - Set Environment to "Injected Web3" (connects to MetaMask)
   - Click "Deploy"
   - Confirm transaction in MetaMask

5. Save the deployed contract address

6. Update the app's configuration:
   - Add the contract address to `lib/constants.dart`

## Option 3: Using Truffle CLI

For a more developer-friendly approach:

1. **Install HDWalletProvider**
   ```bash
   npm install @truffle/hdwallet-provider dotenv
   ```

2. **Create a `.env` file**
   ```
   MNEMONIC="your twelve word mnemonic phrase here"
   INFURA_API_KEY=your_infura_api_key_here
   ```

3. **Configure truffle-config.js**
   ```javascript
   require('dotenv').config();
   const HDWalletProvider = require('@truffle/hdwallet-provider');
   
   module.exports = {
     networks: {
       sepolia: {
         provider: () => new HDWalletProvider(
           process.env.MNEMONIC,
           `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`
         ),
         network_id: 11155111,
         gas: 5500000,
         confirmations: 2,
         timeoutBlocks: 200,
         skipDryRun: true
       }
     },
     compilers: {
       solc: {
         version: "0.8.17",
       }
     }
   };
   ```

4. **Deploy the contract**
   ```bash
   truffle migrate --network sepolia
   ```

5. **Extract contract artifacts**
   ```bash
   node extract-contract-data.js
   ```

6. **Update the app's configuration**
   - Copy the deployed contract address from migration output
   - Add the contract address to `lib/constants.dart`

## Testing the Deployment

After deployment, test that your contract works correctly:

1. Go to the Wallet page in the app
2. Use the email payment feature to register an email address
3. Try sending a payment to an email address
4. Verify the transaction appears in your history

## Troubleshooting

- **Transaction failing**: Ensure you have enough ETH for gas fees
- **Contract not found**: Double-check the contract address is correct in the app
- **MetaMask connection issues**: Try disconnecting and reconnecting MetaMask
- **Deployment errors**: Check compiler version and contract code for issues
