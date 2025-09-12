# MetaMask API Status Guide 🦊

## 🔍 **What is MetaMask API in Your Context?**

Your Ledgerly app uses MetaMask in two ways:
1. **Direct MetaMask Mobile App Integration** - Deep linking to MetaMask app
2. **Backend API for Contract Management** - Your PHP backend stores contract addresses

## 📱 **Checking MetaMask Mobile Integration Status**

### **Method 1: Test in Your Flutter App**

Add this debug screen to test MetaMask connectivity:

```dart
// Create: lib/screens/metamask_debug_page.dart
import 'package:flutter/material.dart';
import '../services/metamask_service.dart';

class MetaMaskDebugPage extends StatefulWidget {
  @override
  _MetaMaskDebugPageState createState() => _MetaMaskDebugPageState();
}

class _MetaMaskDebugPageState extends State<MetaMaskDebugPage> {
  final MetaMaskService _metamask = MetaMaskService();
  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = <String, dynamic>{};
    
    try {
      // Check if MetaMask is installed
      status['isInstalled'] = await _metamask.isMetaMaskInstalled();
      
      // Check current connection status
      status['isConnected'] = _metamask.isConnected;
      status['connectedAddress'] = _metamask.connectedAddress;
      status['chainId'] = _metamask.chainId;
      
      // Test deep link capability
      status['canLaunchDeepLink'] = status['isInstalled'];
      
    } catch (e) {
      status['error'] = e.toString();
    }
    
    setState(() {
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MetaMask API Status')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusCard('MetaMask Installation', 
              _status['isInstalled'] == true ? '✅ Installed' : '❌ Not Installed'),
            
            _buildStatusCard('Connection Status', 
              _status['isConnected'] == true ? '✅ Connected' : '❌ Not Connected'),
            
            _buildStatusCard('Wallet Address', 
              _status['connectedAddress'] ?? 'None'),
            
            _buildStatusCard('Chain ID', 
              _status['chainId']?.toString() ?? 'Unknown'),
            
            _buildStatusCard('Deep Link Support', 
              _status['canLaunchDeepLink'] == true ? '✅ Available' : '❌ Unavailable'),
            
            if (_status['error'] != null)
              _buildStatusCard('Error', _status['error'], isError: true),
            
            SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final address = await _metamask.connect(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(address != null 
                            ? 'Connected: $address' 
                            : 'Connection failed')),
                        );
                        _checkStatus();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: Text('Test Connection'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkStatus,
                    child: Text('Refresh Status'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, {bool isError = false}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: TextStyle(
          color: isError ? Colors.red : 
                 value.contains('✅') ? Colors.green : Colors.orange,
        )),
      ),
    );
  }
}
```

### **Method 2: Check MetaMask Status via Deep Link**

```dart
// Add to your existing MetaMaskService
Future<Map<String, dynamic>> getDetailedStatus() async {
  final status = <String, dynamic>{};
  
  try {
    // Test installation
    status['metamask_installed'] = await isMetaMaskInstalled();
    
    // Test deep link
    status['deep_link_available'] = await canLaunchUrl(Uri.parse(_metaMaskDeepLink));
    
    // Connection status
    status['is_connected'] = isConnected;
    status['connected_address'] = connectedAddress;
    status['chain_id'] = chainId;
    
    // Platform info
    status['platform'] = Platform.isIOS ? 'iOS' : 'Android';
    
    return status;
    
  } catch (e) {
    status['error'] = e.toString();
    return status;
  }
}
```

## 🌐 **Checking MetaMask Backend API Status**

Your backend stores MetaMask contract deployment data. Here's how to test:

### **Contract Management API Endpoints:**

```
GET: https://ledgerly.hivizstudios.com/backend_example/get_contract.php?contract_name=EmailPaymentRegistry&chain_id=1337

POST: https://ledgerly.hivizstudios.com/backend_example/save_contract.php
Body: {
  "contract_name": "EmailPaymentRegistry",
  "contract_address": "0x123...",
  "chain_id": 1337,
  "abi": "[...]"
}
```

### **Test Backend Contract API:**

```dart
// Add to your MetaMaskService
Future<bool> testBackendAPI() async {
  try {
    // Test saving a contract
    final saveResult = await saveDeployedContract(
      contractName: 'TestContract',
      contractAddress: '0x1234567890123456789012345678901234567890',
      chainId: 1337,
      abi: '[]',
    );
    
    if (!saveResult) return false;
    
    // Test retrieving the contract
    final address = await getContractAddress('TestContract', 1337);
    
    return address != null;
    
  } catch (e) {
    print('Backend API test failed: $e');
    return false;
  }
}
```

## 🔧 **Complete MetaMask Status Checker**

Here's a comprehensive status checker for your app:

```dart
// lib/utils/metamask_status_checker.dart
import 'package:flutter/foundation.dart';
import '../services/metamask_service.dart';

class MetaMaskStatusChecker {
  static final MetaMaskService _metamask = MetaMaskService();
  
  static Future<Map<String, dynamic>> checkFullStatus() async {
    final results = <String, dynamic>{};
    
    // 1. Check MetaMask App Installation
    try {
      results['app_installed'] = await _metamask.isMetaMaskInstalled();
    } catch (e) {
      results['app_installed'] = false;
      results['app_install_error'] = e.toString();
    }
    
    // 2. Check Connection Status
    results['is_connected'] = _metamask.isConnected;
    results['connected_address'] = _metamask.connectedAddress;
    results['chain_id'] = _metamask.chainId;
    
    // 3. Check Backend API
    try {
      results['backend_api_working'] = await _metamask.testBackendAPI();
    } catch (e) {
      results['backend_api_working'] = false;
      results['backend_api_error'] = e.toString();
    }
    
    // 4. Overall Status
    results['overall_status'] = _calculateOverallStatus(results);
    
    return results;
  }
  
  static String _calculateOverallStatus(Map<String, dynamic> results) {
    if (results['app_installed'] == true && 
        results['backend_api_working'] == true) {
      return '✅ Fully Operational';
    } else if (results['app_installed'] == true) {
      return '⚠️ App OK, Backend Issues';
    } else if (results['backend_api_working'] == true) {
      return '⚠️ Backend OK, App Issues';
    } else {
      return '❌ Multiple Issues';
    }
  }
  
  static void printStatus(Map<String, dynamic> status) {
    if (kDebugMode) {
      print('🦊 MetaMask API Status Report:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      status.forEach((key, value) {
        print('$key: $value');
      });
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }
}
```

## 🎯 **Quick Status Check Commands**

### **In your Flutter app (debug mode):**

```dart
// Add this to any page for quick testing
FloatingActionButton(
  onPressed: () async {
    final status = await MetaMaskStatusChecker.checkFullStatus();
    MetaMaskStatusChecker.printStatus(status);
    
    // Show in UI
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('MetaMask Status'),
        content: Text(status['overall_status']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  },
  child: Icon(Icons.bug_report),
)
```

## 📱 **Testing on Different Platforms**

### **Android Emulator:**
- MetaMask detection may not work perfectly
- Deep linking requires MetaMask app installation
- Use physical device for best results

### **iOS Simulator:**
- Cannot install MetaMask app from App Store
- Deep linking will fail
- Use physical device for testing

### **Physical Devices:**
- Install MetaMask from App Store/Play Store
- Test deep linking functionality
- Best environment for full testing

## 🚨 **Common Issues & Solutions**

### **"MetaMask not detected"**
```dart
// Solution: Check installation and provide download link
if (!await _metamask.isMetaMaskInstalled()) {
  await _metamask.openMetaMaskDownload(context);
}
```

### **"Deep linking fails"**
```dart
// Solution: Fallback to manual instructions
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Manual Connection Required'),
    content: Text('Please open MetaMask manually and connect to your wallet.'),
  ),
);
```

### **"Backend API errors"**
- Check your backend URL in `constants.dart`
- Test backend endpoints directly in browser
- Verify database connection

This comprehensive approach will help you monitor all aspects of MetaMask integration in your Ledgerly app! 🚀
