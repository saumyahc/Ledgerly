# 🔑 API Key Setup Instructions

## ✅ You're almost ready!

Since you have a **mainnet.infura.io** URL, follow these steps:

### 1. **Add Your API Credentials**

Open the `.env` file in your project root and replace the placeholder values:

```env
# Replace with your actual mainnet URL from MetaMask/Infura:
ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR_ACTUAL_PROJECT_ID
ETHEREUM_API_KEY=YOUR_ACTUAL_API_KEY

# IMPORTANT: Keep this FALSE for development/testing
ENABLE_MAINNET=false
```

### 2. **Example Setup**
If your MetaMask/Infura gave you something like:
- **HTTPS URL**: `https://mainnet.infura.io/v3/abc123def456ghi789`  
- **API Key**: `abc123def456ghi789`

Your `.env` should look like:
```env
ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/abc123def456ghi789
ETHEREUM_API_KEY=abc123def456ghi789
ENABLE_MAINNET=false
```

### 3. **🚨 IMPORTANT: Development vs Production**

**For Development/Testing (Recommended):**
- Keep `ENABLE_MAINNET=false` 
- App will automatically use Sepolia testnet (converts your mainnet URL)
- Use free test ETH from: https://sepoliafaucet.com/
- ✅ **Safe to experiment - no real money involved**

**For Production (Real Money):**
- Set `ENABLE_MAINNET=true`
- App will use your mainnet URL with real ETH
- ⚠️ **BE CAREFUL - uses real money!**

### 4. **Test Your Setup**

1. **Start with testnet (safe):**
   ```bash
   flutter run
   ```

2. **Get test ETH:**
   - Visit: https://sepoliafaucet.com/
   - Enter your wallet address
   - Get free test ETH

3. **Test blockchain functionality:**
   - Create or import a wallet
   - Try sending a small test transaction
   - Everything works with fake money first!

### 5. **Security Notes**
- ✅ `.env` is gitignored - your keys are safe
- ✅ Defaults to testnet for safety
- ✅ Easy to switch to mainnet when ready

Your crypto payments app is configured and ready to test safely! 🚀
