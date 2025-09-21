# Ledgerly Architecture Guide - For Everyone! 👥

## 🏗️ What is Ledgerly?

Ledgerly is a **cryptocurrency wallet app** that lets people send money to **email addresses** instead of complicated wallet addresses. Think of it like PayPal, but using cryptocurrency (Ethereum) instead of traditional bank accounts.

---

## 🧩 The Big Picture - How Everything Fits Together

```
📱 Your Phone App (Flutter)
         ↕️
🌐 Website Backend (PHP)  
         ↕️
💾 Database (MySQL)
         ↕️
🔗 Blockchain Network (Ethereum)
         ↕️
🦊 MetaMask Wallet
```

**Simple Explanation:**
- Your **phone app** talks to a **website** 
- The **website** stores user info in a **database**
- The **website** also talks to the **blockchain** (like Bitcoin's network)
- **MetaMask** handles your actual cryptocurrency

---

## 📱 Frontend (Flutter Mobile App) - "What You See"

### What It Does:
- **Beautiful interface** you touch and tap
- **Wallet management** - see your crypto balance
- **Send money** to email addresses or wallet addresses
- **Receive money** from others
- **Transaction history** - see all your payments
- **User account** - login, signup, profile

### Key Features You'll Use:
```
🏠 Home Screen
   - Your balance (how much crypto you have)
   - Quick actions (Send, Receive, Pay by Email)

💰 Wallet Page  
   - Full balance details
   - Send crypto to wallet addresses
   - Receive crypto (shows your address)
   - Recent transactions

📧 Email Payment Page
   - Send crypto to someone's email
   - App finds their wallet automatically
   - Like sending money via email!

📊 History Page
   - All your past transactions
   - Who you sent to/received from
   - When it happened

👤 Profile Page
   - Your account information
   - Settings and preferences
```

### Technologies Used:
- **Flutter** - Makes the app work on both iPhone and Android
- **Dart** - Programming language for the app logic

---

## 🌐 Backend (PHP Website) - "The Brain Behind the Scenes"

### What It Does:
- **Stores user accounts** - your email, name, password
- **Links emails to wallets** - connects "john@email.com" to "0x123abc..."
- **Handles login/signup** - OTP verification, security
- **Manages user profiles** - personal information, settings
- **API services** - lets the mobile app get/send data

### Key Services:

#### 1. **User Management** 📋
```php
Files: signup.php, verify_otp.php, get_profile.php
Purpose: 
- Create new accounts
- Send verification codes to email
- Store user information securely
- Handle login authentication
```

#### 2. **Email-to-Wallet Mapping** 📧→💳
```php
Files: email_payment.php, wallet_api.php  
Purpose:
- When you type "friend@gmail.com", finds their wallet "0x456def..."
- Stores the connection between email and crypto wallet
- Like a phonebook for crypto addresses
```

#### 3. **Smart Contract Management** 📄
```php
Files: save_contract.php, get_contract.php
Purpose:
- Remembers where smart contracts are deployed
- Helps the app talk to blockchain contracts
- Manages contract addresses and settings
```

### Real-World Example:
```
You: "I want to send $50 to sarah@email.com"
Backend: "Let me check... Sarah's wallet is 0x789ghi..."
Backend: "Here's her wallet address, now you can send!"
```

---

## 💾 Database (MySQL) - "The Memory Bank"

### What It Stores:

#### **Users Table** 👥
```sql
- id: Unique user number
- name: "John Smith" 
- email: "john@email.com"
- password: (encrypted for security)
- email_verified: Is email confirmed?
- created_at: When they signed up
```

#### **User Profiles Table** 👤
```sql
- user_id: Links to Users table
- wallet_address: "0x123abc..." (their crypto wallet)
- phone: Phone number
- bio: Personal description
- avatar: Profile picture
- settings: App preferences
```

#### **Smart Contracts Table** 📄
```sql
- contract_name: "EmailPaymentRegistry"
- contract_address: "0x456def..." (where it lives on blockchain)
- network: "ethereum" or "sepolia-testnet"
- deployed_at: When it was created
```

### Why We Need a Database:
- **Speed** - Finding emails is instant (blockchain is slow)
- **User Experience** - Store profiles, preferences, history
- **Backup** - Keep user data safe even if blockchain fails
- **Privacy** - Some info doesn't need to be on public blockchain

---

## 🔗 Blockchain (Ethereum Network) - "The Money System"

### What It Is:
- **Global computer network** that handles cryptocurrency
- **Immutable ledger** - transactions can't be changed or deleted
- **Decentralized** - no single company controls it
- **Smart contracts** - programs that run on the blockchain

### What Ledgerly Uses It For:

#### 1. **Storing/Sending Cryptocurrency** 💰
```
- Your ETH balance lives on Ethereum
- Transactions are recorded forever
- No bank needed - peer-to-peer transfers
```

#### 2. **Smart Contract: EmailPaymentRegistry** 📧
```solidity
Purpose: Links email addresses to wallet addresses ON the blockchain
Functions:
- registerEmail("john@email.com") → Links to your wallet
- sendPaymentToEmail("sarah@email.com", amount) → Sends money
- getWalletFromEmail("friend@email.com") → Returns their wallet
```

### Networks You Can Use:
- **Ethereum Mainnet** - Real money, real transactions
- **Sepolia Testnet** - Fake money for testing
- **Local Network** - Development and testing on your computer

---

## 🦊 MetaMask Integration - "Your Crypto Wallet"

### What MetaMask Is:
- **Browser extension** or **mobile app**
- **Cryptocurrency wallet** - holds your ETH and other tokens
- **Transaction signer** - approves payments securely
- **Network connector** - connects to different blockchains

### How Ledgerly Uses MetaMask:

#### 1. **Wallet Connection** 🔗
```
1. You click "Connect Wallet" in Ledgerly
2. MetaMask opens asking permission
3. You approve the connection
4. Ledgerly can now see your balance and address
```

#### 2. **Transaction Signing** ✍️
```
1. You want to send $20 to friend@email.com
2. Ledgerly finds friend's wallet: 0x789...
3. MetaMask popup asks: "Send 0.01 ETH to 0x789...?"
4. You click "Confirm" in MetaMask
5. Transaction goes to blockchain
```

#### 3. **Security** 🔒
```
- MetaMask holds your private keys (password to your money)
- Ledgerly NEVER sees your private keys
- Only you can approve transactions
- Your crypto stays in YOUR control
```

---

## 🔄 Complete User Journey - Step by Step

### **Scenario: Sarah wants to send $25 to her friend John**

#### Step 1: Account Setup 📝
```
📱 Sarah opens Ledgerly app
📱 Clicks "Sign Up"
🌐 Backend receives signup request
💾 Database stores: Sarah's name, email, encrypted password
📧 Backend sends OTP to Sarah's email
📱 Sarah enters OTP code
✅ Account verified and created
```

#### Step 2: Wallet Connection 💳
```
📱 Sarah clicks "Connect Wallet"
🦊 MetaMask opens asking permission
📱 Sarah approves in MetaMask
🌐 Backend receives Sarah's wallet address: 0x123abc...
💾 Database links: sarah@email.com ↔ 0x123abc...
🔗 Smart contract registers: hash(sarah@email.com) ↔ 0x123abc...
```

#### Step 3: Sending Money 💸
```
📱 Sarah goes to "Pay by Email"
📱 Types: john@email.com, $25
🌐 Backend checks: Does john@email.com have a wallet?
💾 Database returns: john@email.com ↔ 0x456def...
📱 App shows: "Send $25 to John Smith (0x456def...)"
📱 Sarah clicks "Send"
🦊 MetaMask popup: "Send 0.015 ETH to 0x456def...?"
📱 Sarah confirms in MetaMask
🔗 Transaction sent to Ethereum blockchain
⏱️ Wait ~30 seconds for confirmation
✅ Money transferred! John's balance increases
📱 Both Sarah and John see transaction in history
```

---

## 🛠️ Technical Components Breakdown

### **Frontend Stack** 📱
```
Flutter Framework
├── Screens (UI pages you see)
├── Services (background logic)
│   ├── BlockchainManager (coordinates everything)
│   ├── MetaMaskService (connects to MetaMask)
│   ├── EmailPaymentService (handles email payments)
│   └── WalletApiService (talks to backend)
├── Models (data structures)
└── Widgets (reusable UI components)
```

### **Backend Stack** 🌐
```
PHP + MySQL
├── Authentication (signup.php, verify_otp.php)
├── User Management (get_profile.php, save_profile.php)
├── Email Payments (email_payment.php)
├── Wallet API (wallet_api.php)
├── Contract Management (save_contract.php, get_contract.php)
└── Database Schema (users, profiles, contracts tables)
```

### **Blockchain Stack** 🔗
```
Ethereum Network
├── Smart Contracts
│   └── EmailPaymentRegistry.sol
├── Development Tools
│   ├── Truffle (deployment framework)
│   ├── Ganache (local blockchain)
│   └── Web3 (blockchain interaction)
└── Networks
    ├── Local (development)
    ├── Sepolia (testing)
    └── Mainnet (production)
```

---

## 🔐 Security & Privacy

### **What's Secure** ✅
- **Private keys** stay in MetaMask (you control your money)
- **Passwords** are encrypted in database
- **Email hashes** used in smart contracts (not plain emails)
- **API calls** are authenticated
- **Blockchain** transactions are immutable

### **What We Store** 📊
- **In Database**: Name, email, wallet address, profile info
- **On Blockchain**: Hashed emails, wallet addresses, transactions
- **NOT Stored**: Private keys, plain text passwords, sensitive data

### **User Privacy** 🔒
- Emails are **hashed** before storing on blockchain
- Personal data stays on **private backend**
- You can **delete account** anytime
- **Blockchain data** is permanent (nature of blockchain)

---

## 💡 Why This Architecture?

### **Benefits** ✅
1. **User Friendly** - Send to emails instead of 0x123abc...
2. **Secure** - Private keys stay with you
3. **Fast** - Database lookup is instant
4. **Reliable** - Blockchain provides permanent record
5. **Scalable** - Can handle many users
6. **Cross-platform** - Works on iPhone and Android

### **Trade-offs** ⚖️
1. **Complexity** - Multiple systems to manage
2. **Dependency** - Requires backend server
3. **Cost** - Server hosting and blockchain fees
4. **Privacy** - Some data stored centrally
5. **Single Point of Failure** - Backend downtime affects app

---

## 🚀 What Makes Ledgerly Special?

### **Traditional Crypto Wallets** 😕
```
❌ Send to: 0x742d35Cc6C2F4823891A5BC7C2C84...
❌ Hard to remember addresses
❌ One mistake = money lost forever
❌ Technical and intimidating
```

### **Ledgerly** 😊
```
✅ Send to: friend@gmail.com
✅ Easy to remember emails  
✅ Verify recipient before sending
✅ User-friendly like PayPal
✅ All the security of blockchain
```

---

## 🎯 Summary - The Magic Explained

**Ledgerly is like having a translator between the human world and the crypto world:**

1. **You speak human** - "Send $20 to sarah@email.com"
2. **Ledgerly translates** - "sarah@email.com = wallet 0x456def..."  
3. **Blockchain executes** - Transfers 0.012 ETH to 0x456def...
4. **Everyone's happy** - Simple for you, secure on blockchain

**The key innovation**: Making cryptocurrency as easy to use as regular email, while keeping all the benefits of decentralized money.

**Your app bridges three worlds:**
- 📱 **Mobile apps** (easy to use)
- 🌐 **Web services** (fast and reliable)  
- 🔗 **Blockchain** (secure and permanent)

That's the magic of Ledgerly! 🪄✨
