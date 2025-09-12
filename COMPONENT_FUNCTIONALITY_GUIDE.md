# Ledgerly Component Functionality Guide 🔧

## 📱 Flutter Frontend - Detailed Functionality

### **1. Authentication & User Management**
```dart
Files: signup_page.dart, otp_verification_page.dart, profile_info_page.dart

🔐 What It Provides:
├── User Registration
│   ├── Email & password signup
│   ├── OTP verification via email
│   ├── Profile completion
│   └── Account activation
├── User Login  
│   ├── Email/password authentication
│   ├── Session management
│   ├── Auto-login with saved credentials
│   └── Logout functionality
└── Profile Management
    ├── View/edit personal information
    ├── Update profile picture
    ├── Change password
    └── Account settings
```

### **2. Wallet Management System**
```dart
Files: wallet_page.dart, blockchain_manager.dart, wallet_service.dart

💳 What It Provides:
├── Wallet Creation & Import
│   ├── Generate new cryptocurrency wallet
│   ├── Import existing wallet via seed phrase
│   ├── Secure key storage
│   └── Wallet backup options
├── Balance Management
│   ├── Real-time ETH balance display
│   ├── Multiple currency support
│   ├── Balance refresh functionality
│   └── Historical balance tracking
├── Transaction Operations
│   ├── Send ETH to wallet addresses
│   ├── Receive ETH (show QR code)
│   ├── Transaction history
│   └── Transaction status tracking
└── MetaMask Integration
    ├── Connect to MetaMask wallet
    ├── Import MetaMask accounts
    ├── Transaction signing via MetaMask
    └── Network switching
```

### **3. Email Payment System**
```dart
Files: email_payment_page.dart, email_payment_service.dart

📧 What It Provides:
├── Email-to-Wallet Resolution
│   ├── Enter recipient email address
│   ├── Automatic wallet lookup
│   ├── Recipient verification display
│   └── Invalid email handling
├── Payment Processing
│   ├── Amount input with validation
│   ├── Transaction preview
│   ├── Gas fee estimation
│   └── Payment confirmation
├── Smart Features
│   ├── Recent recipients list
│   ├── Payment memos/notes
│   ├── Amount presets ($10, $25, $50)
│   └── Currency conversion
└── Error Handling
    ├── Email not found errors
    ├── Insufficient balance warnings
    ├── Network failure recovery
    └── Transaction failure handling
```

### **4. Transaction History & Monitoring**
```dart
Files: history_page.dart, transaction_model.dart

📊 What It Provides:
├── Transaction Display
│   ├── Chronological transaction list
│   ├── Send/receive categorization
│   ├── Transaction amounts & fees
│   └── Timestamp formatting
├── Transaction Details
│   ├── Full transaction hash
│   ├── Block number & confirmations
│   ├── Gas used & gas price
│   └── Transaction status
├── Filtering & Search
│   ├── Filter by date range
│   ├── Filter by transaction type
│   ├── Search by recipient/amount
│   └── Export transaction data
└── Visual Features
    ├── Transaction status icons
    ├── Amount color coding (green/red)
    ├── Loading states
    └── Pull-to-refresh
```

### **5. Blockchain Integration Services**
```dart
Files: blockchain_service.dart, transaction_service.dart, contract_service.dart

🔗 What It Provides:
├── Network Management
│   ├── Multiple network support (Mainnet, Testnet, Local)
│   ├── Network switching
│   ├── RPC endpoint management
│   └── Network status monitoring
├── Smart Contract Interaction
│   ├── Contract deployment
│   ├── Contract method calls
│   ├── Event listening
│   └── ABI management
├── Transaction Handling
│   ├── Transaction creation
│   ├── Gas estimation
│   ├── Transaction broadcasting
│   └── Confirmation waiting
└── Wallet Operations
    ├── Address generation
    ├── Balance queries
    ├── Private key management
    └── Signature creation
```

---

## 🌐 PHP Backend - Detailed Functionality

### **1. User Authentication System**
```php
Files: signup.php, verify_otp.php, send_otp.php

🔐 What It Provides:
├── User Registration
│   ├── Email uniqueness validation
│   ├── Password encryption (bcrypt)
│   ├── OTP generation & sending
│   └── Account creation in database
├── OTP Verification System
│   ├── Generate 6-digit codes
│   ├── Send via email (SMTP)
│   ├── Code expiration (10 minutes)
│   └── Rate limiting (prevent spam)
├── Email Services
│   ├── SMTP email sending
│   ├── HTML email templates
│   ├── Email validation
│   └── Delivery failure handling
└── Security Features
    ├── SQL injection prevention
    ├── Input sanitization
    ├── CORS headers
    └── Rate limiting
```

### **2. User Profile Management**
```php
Files: get_profile.php, save_profile.php

👤 What It Provides:
├── Profile Data Retrieval
│   ├── User information lookup
│   ├── Wallet address retrieval
│   ├── Profile settings
│   └── Account statistics
├── Profile Updates
│   ├── Personal information updates
│   ├── Profile picture uploads
│   ├── Settings modifications
│   └── Data validation
├── Wallet Integration
│   ├── Link wallet addresses to users
│   ├── Multiple wallet support
│   ├── Wallet verification
│   └── Address format validation
└── Data Security
    ├── User authentication required
    ├── Data encryption at rest
    ├── Secure file uploads
    └── Access logging
```

### **3. Email-to-Wallet Mapping System**
```php
Files: email_payment.php, wallet_api.php

📧 What It Provides:
├── Email Resolution Service
│   ├── Email to wallet address lookup
│   ├── User profile retrieval
│   ├── Account verification status
│   └── Response caching
├── Wallet Registration
│   ├── Link user emails to wallet addresses
│   ├── Validate wallet addresses
│   ├── Update existing mappings
│   └── Audit trail logging
├── API Endpoints
│   ├── GET: Resolve email to wallet
│   ├── POST: Register new email-wallet pair
│   ├── PUT: Update existing mapping
│   └── DELETE: Remove mapping
└── Error Handling
    ├── Email not found responses
    ├── Invalid wallet address errors
    ├── Database connection failures
    └── Malformed request handling
```

### **4. Smart Contract Management**
```php
Files: save_contract.php, get_contract.php

📄 What It Provides:
├── Contract Registration
│   ├── Store deployed contract addresses
│   ├── Contract metadata storage
│   ├── Network-specific deployments
│   └── Version management
├── Contract Retrieval
│   ├── Get contract addresses by name
│   ├── Network-specific lookups
│   ├── Contract ABI storage
│   └── Deployment history
├── Multi-Network Support
│   ├── Ethereum Mainnet contracts
│   ├── Testnet contracts
│   ├── Local development contracts
│   └── Network switching
└── Integration Features
    ├── Frontend contract config generation
    ├── Automatic ABI updates
    ├── Contract verification status
    └── Gas usage tracking
```

### **5. Database Architecture**
```sql
Files: database_schema.sql, migrations/

💾 What It Provides:
├── User Management Tables
│   ├── users (accounts, emails, passwords)
│   ├── user_profiles (personal info, wallets)
│   ├── otp_verifications (email codes)
│   └── user_sessions (login tracking)
├── Blockchain Integration Tables
│   ├── smart_contracts (deployed contracts)
│   ├── wallet_addresses (user wallets)
│   ├── transactions (transaction cache)
│   └── network_configs (blockchain networks)
├── Security Features
│   ├── Encrypted password storage
│   ├── Indexed queries for performance
│   ├── Foreign key constraints
│   └── Audit trails
└── Maintenance Tools
    ├── Database migration scripts
    ├── Backup procedures
    ├── Performance monitoring
    └── Data cleanup routines
```

---

## 🔗 Smart Contracts - Detailed Functionality

### **EmailPaymentRegistry.sol**
```solidity
What It Provides:
├── Email Registration
│   ├── registerEmail(string email) - Maps email hash to wallet
│   ├── updateEmailRegistration() - Updates existing mapping
│   ├── deregisterEmail() - Removes mapping
│   └── Event emission for frontend tracking
├── Payment Processing
│   ├── sendPaymentToEmail() - Send ETH to email address
│   ├── Automatic email-to-wallet resolution
│   ├── Payment validation & verification
│   └── Transaction event logging
├── Lookup Services
│   ├── getWalletFromEmail() - Resolve email to wallet
│   ├── isEmailRegistered() - Check registration status
│   ├── getUserStats() - Get payment statistics
│   └── getRegistrationTime() - When email was registered
└── Security Features
    ├── Owner-only administrative functions
    ├── Email hashing for privacy
    ├── Reentrancy protection
    └── Access control modifiers
```

### **Deployment & Migration Scripts**
```javascript
Files: migrations/2_deploy_contracts.js, migrations/3_deploy_email_payment_registry.js

🚀 What It Provides:
├── Contract Deployment
│   ├── Automated deployment to multiple networks
│   ├── Constructor parameter configuration
│   ├── Gas optimization
│   └── Deployment verification
├── Network Configuration
│   ├── Local development (Ganache)
│   ├── Ethereum testnets (Sepolia, Goerli)
│   ├── Ethereum mainnet
│   └── Custom RPC endpoints
├── Post-Deployment Setup
│   ├── Contract verification on Etherscan
│   ├── Initial configuration calls
│   ├── Permission setup
│   └── Frontend config generation
└── Development Tools
    ├── Contract size optimization
    ├── Gas usage reporting
    ├── Deployment cost calculation
    └── Network health checks
```

---

## 🦊 MetaMask Integration - Detailed Functionality

### **MetaMaskService.dart**
```dart
What It Provides:
├── Wallet Connection
│   ├── Detect MetaMask installation
│   ├── Request wallet connection
│   ├── Handle connection approval/rejection
│   └── Store connection state
├── Account Management
│   ├── Get connected accounts
│   ├── Switch between accounts
│   ├── Monitor account changes
│   └── Handle disconnection
├── Network Operations
│   ├── Get current network
│   ├── Request network switching
│   ├── Add custom networks
│   └── Monitor network changes
├── Transaction Signing
│   ├── Request transaction signatures
│   ├── Personal message signing
│   ├── Typed data signing
│   └── Batch transaction support
└── Event Handling
    ├── Account change events
    ├── Network change events
    ├── Connection/disconnection events
    └── Error event handling
```

---

## 🔄 Integration Points - How Components Work Together

### **1. User Registration Flow**
```
📱 Flutter signup_page.dart
    ↓ (POST request)
🌐 PHP signup.php
    ↓ (stores data)
💾 MySQL users table
    ↓ (sends OTP)
📧 SMTP email service
    ↓ (user enters OTP)
📱 Flutter otp_verification_page.dart
    ↓ (POST verification)
🌐 PHP verify_otp.php
    ↓ (activates account)
💾 MySQL users table
```

### **2. Email Payment Flow**
```
📱 Flutter email_payment_page.dart
    ↓ (resolves email)
🌐 PHP email_payment.php
    ↓ (queries database)
💾 MySQL user_profiles table
    ↓ (returns wallet address)
📱 Flutter shows recipient info
    ↓ (user confirms)
🦊 MetaMask transaction signing
    ↓ (broadcasts transaction)
🔗 Ethereum blockchain
    ↓ (updates balance)
📱 Flutter wallet updates
```

### **3. Smart Contract Interaction Flow**
```
📱 Flutter contract_service.dart
    ↓ (calls contract method)
🦊 MetaMask signs transaction
    ↓ (sends to network)
🔗 EmailPaymentRegistry.sol
    ↓ (emits events)
📱 Flutter listens for events
    ↓ (updates UI)
🌐 PHP save_contract.php
    ↓ (caches contract data)
💾 MySQL smart_contracts table
```

---

## 🎯 Summary - What Each Component Is Responsible For

### **📱 Flutter Frontend: User Experience**
- Beautiful, intuitive interface
- Real-time balance and transaction updates
- MetaMask integration and wallet management
- Email-based payment interface
- Transaction history and monitoring

### **🌐 PHP Backend: Business Logic**
- User authentication and profile management
- Email-to-wallet address mapping
- API services for mobile app
- Smart contract address management
- Database operations and caching

### **💾 MySQL Database: Data Persistence**
- User accounts and profiles
- Email-to-wallet mappings
- Smart contract addresses
- OTP codes and verification
- Transaction caching and history

### **🔗 Smart Contracts: Blockchain Logic**
- Immutable email-to-wallet mappings
- Decentralized payment processing
- Transaction event logging
- Security and access control
- Trustless operation

### **🦊 MetaMask: Wallet & Security**
- Private key management
- Transaction signing
- Network connection
- User authorization
- Cryptocurrency storage

**The Result**: A complete ecosystem where users can send cryptocurrency as easily as sending an email, while maintaining the security and decentralization of blockchain technology! 🚀✨
