# MetaMask Local Network Setup Guide 🦊

## 🎯 **The Key Concept**

When you set up MetaMask to connect to your local Ganache blockchain, **any wallet created or imported in MetaMask will automatically work with your local network**. Here's how:

---

## 🔧 **Step-by-Step Setup**

### **Step 1: Start Ganache with Consistent Accounts**

```bash
# Use deterministic flag for consistent accounts every restart
ganache-cli --accounts 10 --host 0.0.0.0 --port 7545 --deterministic
```

**This creates the same 10 accounts every time:**
```
Available Accounts
==================
(0) 0x627306090abaB3A6e1400e9345bC60c78a8BEf57 (100 ETH)
(1) 0xf17f52151EbEF6C7334FAD080c5704D77216b732 (100 ETH)
(2) 0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef (100 ETH)
...

Private Keys
==================
(0) 0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d
(1) 0x6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1
...
```

### **Step 2: Add Local Network to MetaMask**

**In MetaMask (browser extension or mobile):**

1. Click network dropdown → "Add Network"
2. Enter these details:

```
Network Name: Ledgerly Local
RPC URL: http://127.0.0.1:7545  (desktop/browser)
RPC URL: http://10.0.2.2:7545   (Android emulator)
Chain ID: 1337
Currency Symbol: ETH
Block Explorer: (leave empty)
```

### **Step 3: Import Test Accounts (Optional)**

**To use pre-funded Ganache accounts:**
1. In MetaMask: Account menu → "Import Account"
2. Select "Private Key"
3. Enter: `4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d` (without 0x)
4. You now have 100 ETH for testing!

---

## 🔄 **How User Wallets Work**

### **Scenario A: User Creates New Wallet**
```
1. User opens MetaMask
2. Creates new wallet → Gets address: 0xNewUser123...
3. Switches to "Ledgerly Local" network
4. Address 0xNewUser123... now exists on your local blockchain
5. Balance starts at 0 ETH (needs funding for testing)
```

### **Scenario B: User Imports Existing Wallet**
```
1. User imports wallet with seed phrase
2. Gets existing address: 0xExisting456...
3. Switches to "Ledgerly Local" network  
4. Same address, but balance is 0 ETH on local network
5. Needs funding from Ganache accounts for testing
```

---

## 💰 **Funding User Wallets for Testing**

### **Method 1: Via Truffle Console**
```bash
truffle console --network development

# Send 5 ETH to user's wallet
web3.eth.sendTransaction({
  from: accounts[0], // Pre-funded Ganache account
  to: "0xUserWalletAddress", // User's MetaMask address  
  value: web3.utils.toWei("5", "ether")
})
```

### **Method 2: Via MetaMask**
1. Import a Ganache account (with 100 ETH)
2. Send ETH to user's wallet address
3. User now has test ETH for development

### **Method 3: Add to Your Flutter App**
```dart
// Development helper function
Future<void> fundUserWallet(String userAddress) async {
  await _blockchain.sendTransaction(
    toAddress: userAddress,
    amount: 5.0, // 5 ETH for testing
    memo: "Development funding",
  );
}
```

---

## 🔗 **Complete Integration Flow**

### **1. User Registration**
```dart
// User signs up in your Flutter app
final user = await AuthService.signUp(email: "user@example.com");
```

### **2. MetaMask Connection**
```dart
// User connects their MetaMask wallet
final metamask = MetaMaskService();
final walletAddress = await metamask.connect(context);
// Returns: 0xUserWalletAddress123...
```

### **3. Link Email to Wallet**
```dart
// Store mapping in your backend
await WalletApiService.linkWalletToUser(
  userId: user.id,
  walletAddress: walletAddress,
);

// Store in database:
// user_profiles table: user_id=123, wallet_address=0xUserWallet...
```

### **4. Register in Smart Contract**
```dart
// Register on blockchain (optional, for decentralization)
await _contractService.registerEmail(
  email: "user@example.com",
  walletAddress: walletAddress,
);
```

### **5. Fund for Testing (Development Only)**
```dart
// Send test ETH to user's wallet
await fundUserWallet(walletAddress);
```

### **6. Ready for Email Payments!**
```
Now when someone sends to user@example.com:

1. 📧 Sender enters: "user@example.com" 
2. 🔍 Backend resolves: user@example.com → 0xUserWallet...
3. 📱 Flutter shows: "Send to John (0xUserWallet...)"
4. ✅ Sender confirms
5. 🦊 MetaMask signs transaction to 0xUserWallet...
6. 💰 User receives ETH in their MetaMask wallet!
```

---

## 🎯 **Key Points**

### **✅ What Works Automatically:**
- Any MetaMask wallet works on your local network
- Users can create wallets directly in MetaMask
- Balances and transactions sync in real-time
- Your Flutter app can interact with any MetaMask wallet

### **🔧 What You Need to Configure:**
- Add "Ledgerly Local" network to MetaMask
- Fund user wallets with test ETH for development
- Link email addresses to wallet addresses in your backend
- Deploy smart contracts to the local network

### **🚨 Important for Production:**
- Replace Ganache with a real testnet (Sepolia) or mainnet
- Remove wallet funding features
- Add proper error handling for insufficient balances
- Implement proper gas fee estimation

---

## 🐛 **Troubleshooting**

### **"Can't connect to network"**
- ✅ Check Ganache is running: `curl http://127.0.0.1:7545`
- ✅ For Android emulator, use: `http://10.0.2.2:7545`
- ✅ For iOS simulator, use: `http://127.0.0.1:7545`

### **"Account has 0 ETH"**  
- ✅ Send test ETH from a Ganache pre-funded account
- ✅ Import a Ganache account with 100 ETH for testing

### **"Nonce too high" errors**
- ✅ MetaMask → Settings → Advanced → Reset Account

### **"Transaction failed"**
- ✅ Check sufficient ETH balance
- ✅ Verify contract is deployed correctly
- ✅ Check gas limit settings

---

## 🎉 **Summary**

**The magic**: Once you configure MetaMask to connect to your local Ganache network, users can create wallets, receive ETH, and make transactions just like on the real Ethereum network - but locally for development!

**Your job**: 
1. Set up the local network configuration
2. Link user emails to their MetaMask addresses  
3. Enable email-based payments to those addresses
4. Fund wallets with test ETH for development

This gives users the familiar MetaMask experience while adding your email-based payment innovation! 🚀
