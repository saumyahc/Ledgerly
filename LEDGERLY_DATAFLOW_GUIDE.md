# Ledgerly Data Flow Diagrams 📊

## 🔄 Complete System Flow - Visual Guide

### **1. User Registration Flow**
```
👤 User                📱 Flutter App           🌐 PHP Backend         💾 Database
  |                         |                        |                     |
  | 1. Enter email/name     |                        |                     |
  |------------------------>|                        |                     |
  |                         | 2. POST /signup.php    |                     |
  |                         |----------------------->|                     |
  |                         |                        | 3. Store user info  |
  |                         |                        |-------------------->|
  |                         |                        | 4. Send OTP email   |
  |                         |                        |---------------------|
  | 5. Check email for OTP  |                        |                     |
  |<------------------------|                        |                     |
  | 6. Enter OTP code       |                        |                     |
  |------------------------>|                        |                     |
  |                         | 7. POST /verify_otp.php|                     |
  |                         |----------------------->|                     |
  |                         |                        | 8. Verify & activate|
  |                         |                        |-------------------->|
  |                         | 9. "Account verified!" |                     |
  |                         |<-----------------------|                     |
  | 10. Welcome screen      |                        |                     |
  |<------------------------|                        |                     |
```

### **2. Wallet Connection Flow**
```
👤 User                📱 Flutter App           🦊 MetaMask            🌐 Backend         💾 Database
  |                         |                        |                     |                |
  | 1. Click "Connect"      |                        |                     |                |
  |------------------------>|                        |                     |                |
  |                         | 2. Request connection  |                     |                |
  |                         |----------------------->|                     |                |
  |                         |                        | 3. Show permission  |                |
  | 4. Approve connection   |                        |                     |                |
  |------------------------------------------------->|                     |                |
  |                         |                        | 5. Return address   |                |
  |                         |<-----------------------|                     |                |
  |                         | 6. POST /wallet_api.php|                     |                |
  |                         |----------------------------------------->|                |
  |                         |                        |                     | 7. Link email  |
  |                         |                        |                     |     to wallet  |
  |                         |                        |                     |--------------->|
  | 8. "Wallet connected!"  |                        |                     |                |
  |<------------------------|                        |                     |                |
```

### **3. Email Payment Flow**
```
👤 Sender              📱 Flutter App           🌐 Backend         💾 Database         🔗 Blockchain       🦊 MetaMask
  |                         |                        |                  |                    |                 |
  | 1. Enter email & amount |                        |                  |                    |                 |
  |------------------------>|                        |                  |                    |                 |
  |                         | 2. GET /email_payment  |                  |                    |                 |
  |                         |    .php?email=friend@  |                  |                    |                 |
  |                         |----------------------->|                  |                    |                 |
  |                         |                        | 3. Find wallet   |                    |                 |
  |                         |                        |   for email      |                    |                 |
  |                         |                        |----------------->|                    |                 |
  |                         |                        | 4. Return 0x456  |                    |                 |
  |                         |                        |<-----------------|                    |                 |
  |                         | 5. Show: "Send $20 to  |                  |                    |                 |
  |                         |    John (0x456...)"    |                  |                    |                 |
  |                         |<-----------------------|                  |                    |                 |
  | 6. Confirm send         |                        |                  |                    |                 |
  |------------------------>|                        |                  |                    |                 |
  |                         | 7. Request transaction |                  |                    |                 |
  |                         |--------------------------------------------------------->|                 |
  |                         |                        |                  |                    | 8. Show popup   |
  |                         |                        |                  |                    |---------------->|
  | 9. Approve in MetaMask  |                        |                  |                    |                 |
  |---------------------------------------------------------------------------->|
  |                         |                        |                  |                    | 10. Send to     |
  |                         |                        |                  |                    |    blockchain   |
  |                         |                        |                  |                    |<----------------|
  |                         |                        |                  |    11. Transaction |                 |
  |                         |                        |                  |        confirmed   |                 |
  |                         |                        |                  |<-------------------|                 |
  | 12. "Payment sent!"     |                        |                  |                    |                 |
  |<------------------------|                        |                  |                    |                 |
```

---

## 🏗️ System Architecture Layers

### **Layer 1: User Interface (What You Touch)**
```
📱 Flutter Mobile App
├── 🏠 Home Screen (balance, quick actions)
├── 💰 Wallet Page (send, receive, history)
├── 📧 Email Payment (send to email addresses)
├── 📊 History Page (transaction list)
├── 👤 Profile Page (account settings)
└── 🔐 Auth Pages (login, signup, OTP)
```

### **Layer 2: Business Logic (The App's Brain)**
```
📱 Flutter Services
├── 🔗 BlockchainManager (coordinates everything)
├── 🦊 MetaMaskService (wallet connection)
├── 📧 EmailPaymentService (email payments)
├── 💳 WalletApiService (backend communication)
├── 🔐 SessionManager (user sessions)
└── 📄 ContractService (smart contract calls)
```

### **Layer 3: Backend API (The Server)**
```
🌐 PHP Backend Services
├── 👤 User Management
│   ├── signup.php (create accounts)
│   ├── verify_otp.php (email verification)
│   └── get_profile.php (user data)
├── 💳 Wallet Services  
│   ├── wallet_api.php (link emails to wallets)
│   └── email_payment.php (resolve emails)
└── 📄 Contract Services
    ├── save_contract.php (store contract addresses)
    └── get_contract.php (retrieve contracts)
```

### **Layer 4: Data Storage (The Memory)**
```
💾 MySQL Database
├── 👥 users (accounts, emails, passwords)
├── 👤 user_profiles (wallets, personal info)
├── 📄 smart_contracts (contract addresses)
└── 📧 otp_verifications (email codes)
```

### **Layer 5: Blockchain (The Money Network)**
```
🔗 Ethereum Network
├── 💰 Native ETH (your cryptocurrency balance)
├── 📄 EmailPaymentRegistry (email-to-wallet mapping)
├── 📝 Transaction History (permanent record)
└── 🔐 Security (cryptographic proofs)
```

---

## 🔄 Data Types & What They Mean

### **In Your Phone App** 📱
```dart
// User sees this:
"Balance: 1.25 ETH"
"Send to: friend@gmail.com"  
"Amount: $50.00"

// App stores this:
double balance = 1.25;
String recipientEmail = "friend@gmail.com";
String walletAddress = "0x742d35Cc6C2F482389...";
```

### **In The Database** 💾
```sql
-- What gets saved:
users: id=123, name="John", email="john@gmail.com"
user_profiles: wallet_address="0x742d35...", user_id=123
smart_contracts: name="EmailRegistry", address="0x456def..."
```

### **On The Blockchain** 🔗
```solidity
// Smart contract stores:
mapping(bytes32 => address) emailToWallet;
// keccak256("john@gmail.com") => 0x742d35Cc6C2F482389...

// Transactions record:
from: 0x123abc..., to: 0x456def..., amount: 1250000000000000000 wei (1.25 ETH)
```

---

## 🔐 Security Flow - How Your Money Stays Safe

### **Multi-Layer Protection**
```
👤 User Level:
├── 🔒 Password for app account
├── 📧 Email verification required  
├── 🔐 MetaMask password/biometrics
└── ✍️  Manual transaction approval

🌐 Backend Level:
├── 🔐 Encrypted password storage
├── 🛡️  SQL injection protection
├── 🔒 HTTPS encrypted communication
└── 🚫 Rate limiting (prevents spam)

🔗 Blockchain Level:
├── 🔐 Private key cryptography
├── 📝 Immutable transaction records
├── 🌐 Decentralized network
└── ✅ Mathematical proof of ownership
```

### **What Happens When You Send Money**
```
1. 📱 You: "Send $20 to sarah@email.com"
2. 🔍 App: "Let me find Sarah's wallet address..."
3. 🌐 Backend: "Sarah's wallet is 0x456def..."
4. 📱 App: "Confirm: Send $20 to Sarah (0x456def...)?"
5. 👤 You: "Yes, confirm"
6. 🦊 MetaMask: "Sign this transaction with your private key?"
7. 👤 You: "Approve" (enter password/biometric)
8. 🔗 Blockchain: "Transaction verified and recorded"
9. ✅ Result: Money moved from your wallet to Sarah's wallet
```

---

## 💰 Money Flow - Where Your Crypto Actually Lives

### **Important: Your Money Never Leaves Your Control**
```
❌ WRONG: "Ledgerly holds my money"
✅ CORRECT: "My money is in MY MetaMask wallet"

❌ WRONG: "Backend can spend my money"  
✅ CORRECT: "Only I can approve transactions"

❌ WRONG: "If Ledgerly shuts down, I lose money"
✅ CORRECT: "My money stays in my MetaMask wallet"
```

### **What Each Component Controls**
```
📱 Ledgerly App:
├── ✅ Shows your balance (reads from blockchain)
├── ✅ Finds recipient wallets (reads from backend)
├── ✅ Creates transaction requests
├── ❌ CANNOT spend your money
└── ❌ CANNOT access your private keys

🌐 PHP Backend:
├── ✅ Stores email-to-wallet mappings
├── ✅ Manages user profiles
├── ✅ Provides lookup services
├── ❌ CANNOT spend your money  
└── ❌ CANNOT access your private keys

🦊 MetaMask:
├── ✅ Holds your private keys
├── ✅ Signs transactions
├── ✅ Controls your money
├── ✅ Can reject any transaction
└── ✅ YOU have full control

🔗 Blockchain:
├── ✅ Records all transactions permanently
├── ✅ Proves ownership mathematically
├── ✅ Processes transfers
└── ✅ No single point of control
```

---

## 🎯 Real-World Comparison

### **Ledgerly vs Traditional Banking**

| Feature | Traditional Bank | Ledgerly |
|---------|------------------|----------|
| **Account Setup** | Visit branch, paperwork | Download app, verify email |
| **Send Money** | Account numbers, routing | Email addresses |
| **Transaction Time** | Hours/days | Minutes |
| **Geographic Limits** | Country restrictions | Global |
| **Transaction Fees** | $15-50 international | $1-5 |
| **Control** | Bank controls your money | You control your money |
| **Privacy** | Bank sees everything | Pseudonymous |
| **Availability** | Business hours | 24/7/365 |

### **Ledgerly vs Other Crypto Wallets**

| Feature | Other Wallets | Ledgerly |
|---------|---------------|----------|
| **Send To** | 0x742d35Cc6C2F... | friend@gmail.com |
| **User Experience** | Technical | User-friendly |
| **Recipient Verification** | None | Shows name & email |
| **Mistake Prevention** | Easy to lose money | Verify before sending |
| **Learning Curve** | Steep | Gentle |

---

## 🚀 The Innovation - Why This Matters

### **The Problem Ledgerly Solves**
```
😰 Traditional Crypto Problems:
├── "Send to 0x742d35Cc6C2F482389..." - Impossible to remember
├── One typo = money lost forever
├── No way to verify recipient
├── Technical and intimidating
└── Mass adoption barrier

😊 Ledgerly's Solution:
├── "Send to friend@gmail.com" - Easy to remember  
├── Verify recipient before sending
├── Show human names, not just addresses
├── Familiar email-based interface
└── Crypto for everyone
```

### **The Magic Behind the Scenes**
```
🧙‍♂️ When you type "sarah@gmail.com":

1. 📱 App asks backend: "What's Sarah's wallet?"
2. 🌐 Backend checks database: "Sarah = 0x456def..."
3. 📱 App shows: "Send to Sarah Smith (0x456def...)"
4. 👤 You confirm: "Yes, that's the right Sarah"
5. 🦊 MetaMask signs transaction to 0x456def...
6. 🔗 Blockchain processes: Transfer complete
7. 📱 Both you and Sarah see the transaction

Result: Crypto transaction, email simplicity! 🎉
```

---

This architecture makes cryptocurrency as easy to use as email while keeping all the security and benefits of blockchain technology. That's the power of Ledgerly! 💪✨
