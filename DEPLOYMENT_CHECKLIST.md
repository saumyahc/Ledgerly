
# Ledgerly Development Setup

## Base URL: https://ledgerly.hivizstudios.com/

## 🔧 Ganache Blockchain Setup

### Prerequisites
- Node.js installed
- Truffle installed globally: `npm install -g truffle`
- Ganache CLI installed: `npm install -g ganache-cli`

### 1. Start Ganache Network

#### Option A: Using Ganache CLI (Recommended)
```bash
ganache-cli --port 8545 --networkId 1337 --chainId 1337 --accounts 10 --defaultBalanceEther 100
```

#### Option B: Using included scripts
```bash
# Windows
start-ganache-windows.js

# Linux/Mac
./start-ganache.js
```

### 2. Verify Ganache Setup
Check that Ganache is running properly:
```bash
node -e "const Web3 = require('web3'); const web3 = new Web3('http://localhost:8545'); web3.eth.getChainId().then(id => console.log('Chain ID:', id));"
```
Expected output: `Chain ID: 1337`

### 3. Account Information
Ganache provides 10 pre-funded accounts with 100 ETH each:

**Default Accounts:**
- Account 0: `0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1` (Used for contract deployment)
- Account 1: `0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0` (Available for testing)
- Account 2-9: Additional test accounts with 100 ETH each

**Private Keys (for development only):**
- Account 0: `0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d`
- Account 1: `0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1`

### 4. Deploy Smart Contracts
```bash
# Deploy contracts to Ganache
node scripts/deploy-and-save.js
```

This script will:
- ✅ Compile contracts
- ✅ Deploy EmailPaymentRegistry contract
- ✅ Save contract info to backend database
- ✅ Update Flutter configuration
- ✅ Fund contract with ETH for welcome bonuses

### 5. Contract Features

#### Welcome Bonus System
- New users automatically receive **0.5 ETH welcome bonus**
- One-time only per wallet address
- Contract pre-funded with ETH for bonuses

#### Gas Pre-funding
- New wallets automatically receive **0.1 ETH for gas fees**
- Uses Ganache Account 0 for funding
- Solves chicken-and-egg problem for new users

#### Queue-based Funding
- Community-driven funding pool
- Users can contribute to shared faucet
- Fallback system if welcome bonus exhausted

### 6. Network Configuration

#### Flutter App (.env file)
```env
NETWORK_MODE=local
LOCAL_RPC_URL=http://10.0.2.2:8545
ETHEREUM_RPC_URL=http://localhost:8545
```

#### Important Network Details
- **Chain ID**: 1337 (Critical for transaction signing)
- **Network ID**: 1337
- **RPC URL**: http://localhost:8545 (desktop) or http://10.0.2.2:8545 (Android emulator)
- **Gas Price**: 20 Gwei
- **Block Time**: ~2 seconds

### 7. Troubleshooting

#### Common Issues

**"Invalid signature v value" Error:**
- Cause: Wrong chain ID in transaction signing
- Solution: Ensure all transactions use chain ID 1337

**"Insufficient funds for gas" Error:**
- Cause: User wallet has no ETH for gas fees
- Solution: Gas pre-funding should handle this automatically

**Contract not found:**
- Cause: Contract not deployed or wrong address
- Solution: Run `node scripts/deploy-and-save.js` again

**RPC Connection Failed:**
- Cause: Ganache not running or wrong URL
- Solution: Restart Ganache and verify port 8545

#### Verification Commands
```bash
# Check Ganache accounts
node -e "const Web3 = require('web3'); const web3 = new Web3('http://localhost:8545'); web3.eth.getAccounts().then(accounts => console.log('Accounts:', accounts));"

# Check account balances
node -e "const Web3 = require('web3'); const web3 = new Web3('http://localhost:8545'); web3.eth.getAccounts().then(accounts => { accounts.forEach((acc, i) => { web3.eth.getBalance(acc).then(bal => console.log(\`Account \${i}: \${web3.utils.fromWei(bal, 'ether')} ETH\`)); }); });"

# Check contract balance
node -e "const Web3 = require('web3'); const web3 = new Web3('http://localhost:8545'); const config = require('./deployments/EmailPaymentRegistry-latest.json'); web3.eth.getBalance(config.contract_address).then(bal => console.log('Contract balance:', web3.utils.fromWei(bal, 'ether'), 'ETH'));"
```

### 8. Development Workflow

1. **Start Ganache** → `ganache-cli --port 8545 --networkId 1337 --chainId 1337`
2. **Deploy contracts** → `node scripts/deploy-and-save.js`
3. **Start Flutter app** → Connect to http://10.0.2.2:8545
4. **Create wallet** → Automatic gas pre-funding
5. **Request funding** → Automatic welcome bonus
6. **Make payments** → User has ETH to transact

### 9. Production Considerations

For production deployment:
- Use real Ethereum networks (Mainnet/Sepolia)
- Implement proper private key management
- Remove hardcoded Ganache private keys
- Set up proper gas estimation
- Implement rate limiting for faucet functions
