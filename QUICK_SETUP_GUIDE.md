# Quick Setup Guide for Ledgerly 🚀

## 📦 Installation Steps (Windows)

### Step 1: Install Node.js
1. Download Node.js from: https://nodejs.org/
2. Choose the LTS version (recommended)
3. Run the installer and follow the setup wizard
4. Restart your command prompt

### Step 2: Verify Installation
```bash
# Check if Node.js and npm are installed
node --version
npm --version
```

### Step 3: Install Project Dependencies
```bash
# Navigate to your Ledgerly project
cd "c:\Users\malan\OneDrive\Documents\GitHub\Ledgerly\Ledgerly"

# Install all required dependencies (Truffle, Ganache, Web3, etc.)
npm install

# Install global tools (optional, but recommended)
npm install -g truffle ganache-cli
```

### Step 4: Start Local Blockchain
```bash
# Option 1: Use npm script (recommended)
npm run ganache

# Option 2: Use ganache-cli directly (if installed globally)
ganache-cli --accounts 10 --host 0.0.0.0 --port 7545 --deterministic
```

### Step 5: Deploy Smart Contracts
```bash
# Compile contracts
npm run compile

# Deploy to local network
npm run migrate:development
```

### Step 6: Run the Setup Script (Alternative)
```bash
# Windows
setup_local_dev.bat

# Or if you have WSL/Git Bash
./setup_local_dev.sh
```

---

## 🛠 Available NPM Scripts

```bash
npm run compile           # Compile smart contracts
npm run migrate          # Deploy contracts (default network)
npm run migrate:development # Deploy to local Ganache
npm run migrate:sepolia  # Deploy to Sepolia testnet
npm run migrate:reset    # Reset and redeploy contracts
npm run console          # Open Truffle console
npm run test            # Run contract tests
npm run extract-contracts # Extract contract data for Flutter
npm run ganache         # Start local blockchain
npm run setup           # Install dependencies and compile
npm run deploy-local    # Start Ganache and deploy contracts
```

---

## 🔧 What's Included in package.json

### Development Dependencies:
- **truffle** - Smart contract compilation and deployment
- **ganache-cli** - Local Ethereum blockchain
- **@truffle/hdwallet-provider** - Wallet provider for deployments
- **web3** - Ethereum JavaScript API

### Dependencies:
- **dotenv** - Environment variable management

---

## 🚨 Common Issues & Solutions

### Issue: "npm: command not found"
**Solution:** Install Node.js from https://nodejs.org/

### Issue: "truffle: command not found"
**Solution:** 
```bash
# Install globally
npm install -g truffle

# Or use npm scripts
npm run compile
```

### Issue: "ganache-cli: command not found"
**Solution:**
```bash
# Install globally
npm install -g ganache-cli

# Or use npm script
npm run ganache
```

### Issue: Port 7545 already in use
**Solution:**
```bash
# Kill any existing Ganache process
taskkill /f /im node.exe
# Or use a different port
ganache-cli --port 8545
```

---

## 📁 Project Structure After Setup

```
Ledgerly/
├── package.json          ✅ NPM configuration
├── package-lock.json     ✅ Dependency lock file
├── truffle-config.js     ✅ Truffle configuration
├── contracts/            ✅ Smart contracts
├── migrations/           ✅ Deployment scripts
├── build/               🔄 Generated after compilation
│   └── contracts/       🔄 Contract artifacts (ABI, bytecode)
├── lib/                 ✅ Flutter app
├── backend_example/     ✅ PHP backend
└── node_modules/        🔄 Generated after npm install
```

---

## ✅ Verification Steps

After running the setup, verify everything works:

```bash
# 1. Check if dependencies are installed
npm list

# 2. Check if Truffle works
npx truffle version

# 3. Check if Ganache can start
npm run ganache
# (Stop with Ctrl+C)

# 4. Try compiling contracts
npm run compile

# 5. Check if build artifacts were created
dir build\contracts
```

---

## 🎯 Next Steps

1. ✅ Run `npm install` to get all dependencies
2. ✅ Start Ganache with `npm run ganache`
3. ✅ Deploy contracts with `npm run migrate:development`
4. ✅ Update `lib/contract_config.dart` with deployed addresses
5. ✅ Set up PHP backend and database
6. ✅ Test the complete flow

You're now ready to develop with Ledgerly! 🎉
