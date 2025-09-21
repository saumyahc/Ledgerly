# 💰 Ledgerly Account Funding Guide

## 🎯 How to Fund User Accounts on Truffle/Ganache

You now have **multiple ways** to fund user accounts in your Ledgerly app:

---

## 🚀 **Quick Start (Recommended)**

1. **Start Ganache** (port 8545, network ID 5777)
2. **Run development environment**:
   ```bash
   # Windows
   scripts\start-dev.cmd
   
   # Linux/Mac
   bash scripts/start-dev.sh
   ```
3. **Create wallet in Flutter app** (gets MetaMask-style seed phrase)
4. **Click "Get Test ETH" button** in wallet page
5. **Done!** 🎉

---

## 📱 **Option 1: Flutter App UI (Easiest)**

### ✅ **Built-in Funding Button**
- Open wallet page in Flutter app
- Click **"Get Test ETH"** button (green button under balance)
- Choose amount: 0.5, 1, or 5 ETH
- Funds transferred automatically from Ganache accounts

### 🔧 **How It Works:**
- Uses `WalletManager.requestFunding()`
- Calls local funding server API
- Transfers from pre-funded Ganache accounts
- Updates balance automatically

---

## 💻 **Option 2: Command Line (Manual)**

### 📤 **Fund Single Account:**
```bash
node scripts/fund-accounts.js 0x742d35cc6631c0532925a3b8d5c0b5d81c6a5b87 5
```

### 📤 **Fund Multiple Accounts:**
```bash
node scripts/fund-accounts.js --multiple 0xaddr1,0xaddr2,0xaddr3 2
```

### 📋 **List Ganache Accounts:**
```bash
node scripts/fund-accounts.js --list
```

---

## 🌐 **Option 3: HTTP API (Backend Integration)**

### 🚀 **Start Funding Server:**
```bash
npm run funding-server
# or
node scripts/funding-server.js
```

### 📡 **API Endpoints:**

#### **Fund Wallet:**
```bash
POST http://localhost:3000/api/fund-wallet
Content-Type: application/json

{
  "address": "0x742d35cc6631c0532925a3b8d5c0b5d81c6a5b87",
  "amount": 2.5
}
```

#### **Get Funding Info:**
```bash
GET http://localhost:3000/api/funding-info
```

#### **Health Check:**
```bash
GET http://localhost:3000/api/health
```

---

## 🏦 **Pre-funded Ganache Accounts**

Ganache creates **5 accounts** with **100 ETH each**:

```
Account 0: 0x627306090abaB3A6e1400e9345bC60c78a8BEf57 (100 ETH)
Account 1: 0xf17f52151EbEF6C7334FAD080c5704D77216b732 (100 ETH)
Account 2: 0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef (100 ETH)
Account 3: 0x821aEa9a577a9b44299B9c15c88cf3087F3b5544 (100 ETH)
Account 4: 0x0d1d4e623D10F9FBA5Db95830F7d3839406C6AF2 (100 ETH)
```

**Account 0** is used as the "funder" to transfer ETH to user wallets.

---

## 🔐 **Security Features**

### ✅ **Development Mode Only**
- Funding only works when `NETWORK_MODE=local`
- Prevents accidental funding on testnet/mainnet
- Safe for development environment

### ✅ **User Isolation**
- Each user gets their own wallet with unique userId
- No wallet sharing between accounts
- MetaMask-style wallet creation with seed phrases

### ✅ **Limits & Validation**
- Maximum 10 ETH per funding request
- Address validation before transfer
- Transaction confirmation and error handling

---

## 🎯 **Complete Development Workflow**

### 1. **Setup**
```bash
# Install dependencies
npm install

# Start Ganache GUI on port 8545
# or use: npm run start-ganache
```

### 2. **Deploy Contracts**
```bash
npm run deploy:local
```

### 3. **Start Development Environment**
```bash
# Windows
scripts\start-dev.cmd

# Linux/Mac  
bash scripts/start-dev.sh
```

### 4. **Run Flutter App**
```bash
flutter run
```

### 5. **Create & Fund Wallet**
- Register/login user in Flutter app
- Create wallet (gets 12-word seed phrase)
- Click "Get Test ETH" to fund wallet
- Start sending payments! 🚀

---

## 🛠️ **Troubleshooting**

### ❌ **"Ganache not running"**
- Start Ganache GUI on port 8545
- Check network ID is 5777
- Verify `.env` has `NETWORK_MODE=local`

### ❌ **"Funding failed"**
- Check funding server is running (`npm run funding-server`)
- Verify wallet address is valid
- Ensure funder account has sufficient balance

### ❌ **"No wallet found"**
- Create wallet first in Flutter app
- Initialize WalletManager with userId
- Check secure storage permissions

---

## 🎉 **Summary**

You now have **complete funding infrastructure**:

✅ **MetaMask-style wallet creation** with seed phrases  
✅ **User-specific wallet isolation** (no sharing bug)  
✅ **Multiple funding methods** (UI button, CLI, API)  
✅ **Development safety** (local mode only)  
✅ **Automated funding server** with HTTP API  
✅ **Easy startup scripts** for complete environment  

**Happy coding!** 🚀💰