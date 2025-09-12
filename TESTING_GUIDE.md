# Ledgerly Testing Guide

## 🧪 Complete End-to-End Testing

### Prerequisites Setup
1. ✅ Ganache running on port 7545
2. ✅ Contracts deployed with `truffle migrate`
3. ✅ Contract address updated in `lib/contract_config.dart`
4. ✅ PHP backend running (XAMPP/WAMP)
5. ✅ MySQL database configured with schema
6. ✅ MetaMask installed and connected to local network

---

## 🎯 Test Scenarios

### Test 1: User Registration & Wallet Connection

```
📱 Flutter App:
1. Open app → Sign up with email A (test1@example.com)
2. Complete OTP verification
3. Connect MetaMask wallet A (0x123...)
4. Verify wallet appears in app

🔍 Expected Results:
- User created in database
- Wallet address linked to email in database
- Balance shows in app
- "Wallet Connected" status
```

### Test 2: Email-to-Wallet Resolution

```
📱 Flutter App:
1. Go to Email Payment page
2. Enter email B (test2@example.com)
3. Check if wallet address is found

📊 Backend Check:
SELECT u.email, up.wallet_address 
FROM users u 
JOIN user_profiles up ON u.id = up.user_id 
WHERE u.email = 'test2@example.com';

🔍 Expected Results:
- Email resolves to correct wallet address
- User profile data shown in app
```

### Test 3: Email Payment Transaction

```
📱 Flutter App (Account A):
1. Go to Email Payment page
2. Enter recipient email: test2@example.com
3. Enter amount: 0.1 ETH
4. Add memo: "Test payment"
5. Click Send Payment
6. Confirm in MetaMask

🔍 Expected Results:
- Email resolves to wallet address B
- MetaMask shows transaction details
- Transaction confirms on blockchain
- Balance updates in both wallets
- Transaction appears in history
```

### Test 4: Direct Wallet-to-Wallet Transfer

```
📱 Flutter App (Account A):
1. Go to Wallet page
2. Click "Send"
3. Enter wallet address B directly
4. Enter amount: 0.05 ETH
5. Confirm transaction

🔍 Expected Results:
- Transaction processes successfully
- Balances update immediately
- Transaction hash generated
- History shows sent transaction
```

---

## 🔧 Testing Tools & Commands

### Ganache Console Commands
```bash
# Check accounts and balances
truffle console
> web3.eth.getAccounts()
> web3.eth.getBalance('0x...')

# Interact with deployed contract
> let registry = await EmailPaymentRegistry.deployed()
> registry.address
> registry.registerEmail("test@example.com")
```

### Database Testing Queries
```sql
-- Check user registration
SELECT * FROM users WHERE email = 'test1@example.com';

-- Check wallet linking
SELECT u.email, up.wallet_address, up.created_at 
FROM users u 
JOIN user_profiles up ON u.id = up.user_id;

-- Check contract addresses
SELECT * FROM smart_contracts WHERE contract_name = 'EmailPaymentRegistry';
```

### Backend API Testing
```bash
# Test email resolution
curl "http://localhost/ledgerly/backend_example/email_payment.php?email=test1@example.com"

# Test wallet linking
curl -X POST "http://localhost/ledgerly/backend_example/wallet_api.php" \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "wallet_address": "0x123..."}'
```

---

## 🐛 Common Issues & Solutions

### Issue 1: "Contract not deployed"
```
❌ Error: Contract not found at address
✅ Solution:
1. Run: truffle migrate --reset
2. Update contract address in contract_config.dart
3. Restart Flutter app
```

### Issue 2: "Network connection failed"
```
❌ Error: Failed to connect to local network
✅ Solution:
1. Check Ganache is running: curl http://127.0.0.1:7545
2. For Android emulator, use: http://10.0.2.2:7545
3. For iOS simulator, use: http://127.0.0.1:7545
```

### Issue 3: "Email not found"
```
❌ Error: Email address not registered
✅ Solution:
1. Check database: SELECT * FROM user_profiles WHERE user_id = (SELECT id FROM users WHERE email = '...')
2. Ensure wallet was linked: Check wallet_address field
3. Register email in smart contract if needed
```

### Issue 4: "Transaction failed"
```
❌ Error: Transaction reverted or failed
✅ Solution:
1. Check account has sufficient ETH balance
2. Verify recipient address is valid
3. Check gas limit and gas price
4. Ensure contract is deployed correctly
```

---

## 📊 Test Data Setup

### Create Test Accounts

```sql
-- Insert test users
INSERT INTO users (name, email, password, email_verified, created_at) VALUES
('Test User 1', 'test1@example.com', 'hashed_password_1', 1, NOW()),
('Test User 2', 'test2@example.com', 'hashed_password_2', 1, NOW());

-- Link test wallets (replace with actual addresses from Ganache)
INSERT INTO user_profiles (user_id, wallet_address, created_at) VALUES
(1, '0x627306090abaB3A6e1400e9345bC60c78a8BEf57', NOW()), -- First Ganache account
(2, '0xf17f52151EbEF6C7334FAD080c5704D77216b732', NOW()); -- Second Ganache account
```

### Fund Test Accounts

```bash
# In Ganache, accounts are pre-funded with 100 ETH each
# You can also send ETH between accounts for testing

# Using Truffle console:
truffle console
> accounts = await web3.eth.getAccounts()
> web3.eth.sendTransaction({from: accounts[0], to: accounts[1], value: web3.utils.toWei('1', 'ether')})
```

---

## ✅ Success Criteria

### Complete Flow Test Checklist:
- [ ] User can register and verify email
- [ ] User can connect MetaMask wallet
- [ ] Wallet address is linked to email in database
- [ ] Email resolves to correct wallet address
- [ ] Email payments work end-to-end
- [ ] Direct wallet transfers work
- [ ] Transaction history is accurate
- [ ] Balance updates are real-time
- [ ] Error handling works properly
- [ ] Network switching works (local ↔ testnet)

### Performance Benchmarks:
- [ ] Email resolution: < 2 seconds
- [ ] Transaction confirmation: < 30 seconds (local)
- [ ] Balance updates: < 5 seconds
- [ ] App startup: < 10 seconds

---

## 📝 Test Report Template

```
🧪 Ledgerly Test Report
Date: ___________
Tester: __________

✅ PASSED TESTS:
- [ ] User Registration
- [ ] Wallet Connection  
- [ ] Email Resolution
- [ ] Email Payments
- [ ] Direct Transfers
- [ ] Transaction History
- [ ] Balance Updates

❌ FAILED TESTS:
- Issue: ________________
  Solution: ______________

📊 PERFORMANCE:
- Email resolution time: ___s
- Transaction time: ___s
- Balance update time: ___s

💡 RECOMMENDATIONS:
- ________________________
- ________________________
```

Happy testing! 🚀
