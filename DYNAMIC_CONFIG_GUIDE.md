# Dynamic Configuration Guide for Ledgerly

This guide explains the new dynamic configuration system implemented in Ledgerly to handle unstable network environments and provide fallback mechanisms.

## Configuration System Overview

The Ledgerly wallet now uses a multi-layered configuration system with the following priorities:

1. **Runtime Configuration** - Highest priority, set during app execution
2. **Environment Variables** - From .env file
3. **Default Configuration** - Hardcoded fallback values

This layered approach ensures that the app can function even when environment configurations are missing or network conditions change.

## Key Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| `NETWORK_MODE` | Network environment (local, testnet, mainnet) | `local` |
| `LOCAL_RPC_URL` | RPC endpoint for Ethereum node | `http://127.0.0.1:8545` |
| `FUNDING_ACCOUNT` | Address used for gas pre-funding | `0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1` |
| `FUNDING_ACCOUNT_KEY` | Private key for funding account | `0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d` |
| `LOCAL_CHAIN_ID` | Chain ID for the Ethereum network | `1337` |
| `GAS_PRICE` | Gas price in wei | `20000000000` (20 Gwei) |
| `PREFUND_AMOUNT` | Amount to pre-fund wallets with (in wei) | `100000000000000000` (0.1 ETH) |

## Using the Configuration System

### Retrieving Configuration Values

```dart
// Get configuration with fallback chain
String? rpcUrl = walletManager.getConfig('LOCAL_RPC_URL');
```

The `getConfig()` method will:
1. First check runtime configuration
2. Then check environment variables
3. Finally fall back to default configuration
4. Return null if not found anywhere

### Setting Runtime Configuration

Runtime configuration allows you to dynamically adjust settings during app execution:

```dart
// Set or update a runtime configuration value
walletManager.setConfig('LOCAL_RPC_URL', 'http://localhost:8545');
```

This is particularly useful when:
- Network conditions change
- User wants to modify settings
- App needs to adapt to different environments

## Improved Error Handling

The new configuration system enables better error handling through fallback mechanisms:

1. **JSON-RPC Method** - Primary method for pre-funding with gas
2. **Web3Dart Method** - Fallback method if JSON-RPC fails

Both methods now use the unified configuration system, ensuring consistent values across different approaches.

## Implementation Details

### Default Configuration

Default values are defined as static constants:

```dart
static const Map<String, String> _defaultConfig = {
  'NETWORK_MODE': 'local',
  'LOCAL_RPC_URL': 'http://127.0.0.1:8545',
  'FUNDING_ACCOUNT': '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1',
  'FUNDING_ACCOUNT_KEY': '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d',
  'LOCAL_CHAIN_ID': '1337',
  'GAS_PRICE': '20000000000', // 20 Gwei
  'PREFUND_AMOUNT': '100000000000000000', // 0.1 ETH
};
```

### Runtime Configuration Storage

Runtime values are stored in a map that persists during app execution:

```dart
final Map<String, String> _runtimeConfig = {};
```

### Configuration Retrieval

The getConfig method implements the priority chain:

```dart
String? getConfig(String key) {
  // Check runtime config first (highest priority)
  if (_runtimeConfig.containsKey(key)) {
    return _runtimeConfig[key];
  }
  
  // Check environment variables (medium priority)
  final envValue = dotenv.env[key];
  if (envValue != null && envValue.isNotEmpty) {
    return envValue;
  }
  
  // Fall back to default config (lowest priority)
  if (_defaultConfig.containsKey(key)) {
    return _defaultConfig[key];
  }
  
  // Not found anywhere
  return null;
}
```

## Debugging

For debugging purposes, the wallet manager provides detailed logging when `kDebugMode` is enabled:

- Configuration values used
- Transaction details
- Error diagnostics
- Fallback mechanism activations

## Best Practices

1. **Development Environment**: Always ensure your Ganache instance is running on the correct port
2. **Custom Configuration**: Set critical values at runtime using `setConfig()` rather than relying on .env files
3. **Error Recovery**: Implement UI to allow users to retry with different configuration when operations fail

## Migration from Previous Version

If you're migrating from the previous hardcoded configuration:

1. Replace direct `dotenv.env[key]` calls with `getConfig(key)`
2. Use the configuration parameters table above for reference
3. Add appropriate fallback handling in your code
await contractService.initialize();
```

### **Option B: Manual Management**
Use the configuration management page:

```dart
// Navigate to configuration page
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const ContractConfigPage(),
));
```

### **Option C: Programmatic Control**
```dart
// Get configuration info
final configInfo = await contractService.getConfigInfo();

// Refresh configuration
await contractService.refreshConfig();

// Check backend availability
final isAvailable = await contractService.isBackendAvailable();
```

---

## 🔧 **Development Workflow**

### **1. Deploy New Contract:**
```bash
node scripts/deploy-and-save.js
```

### **2. Flutter Automatically Updates:**
- Next app startup fetches new contract
- Or manually refresh in ContractConfigPage
- Or call `contractService.refreshConfig()`

### **3. Test Configuration:**
- Use ContractConfigPage to verify
- Check backend connectivity
- View current contract details

---

## 🛡️ **Safety Features**

### **Fallback Protection:**
- If backend is down → Uses static config
- If network fails → Uses cached config  
- If config invalid → Clear error messages

### **Environment Safety:**
- Local development → Gets local contracts
- Testnet → Gets testnet contracts
- Mainnet → Gets mainnet contracts

### **Cache Management:**
- 5-minute cache timeout
- Manual cache clearing
- Smart cache invalidation

---

## 🎯 **Quick Commands**

### **Backend Status:**
```bash
# Test if backend is working
curl "http://localhost/ledgerly/backend_example/save_contract.php"
```

### **Deploy & Update:**
```bash
# Deploy new contract and auto-update backend
node scripts/deploy-and-save.js

# Flutter app will automatically use the new contract!
```

### **Debug Configuration:**
```dart
// Check what configuration is being used
final config = await DynamicContractConfig.instance.getContractConfig();
print('Using contract: ${config['contractAddress']}');

// Check backend status
final info = await DynamicContractConfig.instance.getConfigInfo();
print('Backend available: ${info['backendAvailable']}');
```

---

## 🎉 **Summary**

**You now have the best of both worlds:**

✅ **Dynamic backend configuration** - Always uses latest contracts  
✅ **Static fallback protection** - Works even if backend is down  
✅ **Zero manual updates** - Deploy once, use everywhere  
✅ **Environment-aware** - Automatic network detection  
✅ **Developer-friendly** - Easy testing and management  

Your Flutter app will now **automatically stay synchronized** with your latest deployed contracts! 🚀