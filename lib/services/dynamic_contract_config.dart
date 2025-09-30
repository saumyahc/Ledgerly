import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ledgerly/constants.dart';
/// Dynamic contract configuration service that fetches from backend
class DynamicContractConfig {
  static DynamicContractConfig? _instance;
  Map<String, dynamic>? _cachedConfig;
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  DynamicContractConfig._();
  
  static DynamicContractConfig get instance {
    _instance ??= DynamicContractConfig._();
    return _instance!;
  }

  /// Fetch active contract configuration from backend (default: EmailPaymentRegistry)
  Future<Map<String, dynamic>> getContractConfig({
    String contractName = 'EmailPaymentRegistry',
    bool forceRefresh = false,
    int? chainId,
  }) async {
    // Use chainId from argument, env, or fallback
    int resolvedChainId = chainId ?? (() {
      if (dotenv.env['LOCAL_CHAIN_ID'] != null) {
        try {
          return int.parse(dotenv.env['LOCAL_CHAIN_ID']!.trim());
        } catch (e) {
          return dotenv.env['NETWORK_MODE'] == 'local' ? 1337 : 11155111;
        }
      } else {
        return dotenv.env['NETWORK_MODE'] == 'local' ? 1337 : 11155111;
      }
    })();

    // Use cache only if not forcing refresh, contractName matches, and chainId matches
    if (!forceRefresh && _cachedConfig != null && _lastFetch != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetch!);
      if (timeSinceLastFetch < _cacheTimeout &&
          _cachedConfig!['contractName'] == contractName &&
          _cachedConfig!['chainId'].toString() == resolvedChainId.toString()) {
        print('Using cached contract config for $contractName');
        return _cachedConfig!;
      }
    }

    try {
      print('Fetching contract config for $contractName from backend...');
      final url = '${ApiConstants.phpBaseUrl}/get_contract.php?contract_name=$contractName&chain_id=$resolvedChainId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['contract'] != null) {
          final contract = data['contract'];
          _cachedConfig = {
            'contractName': contract['name'],
            'contractAddress': contract['address'],
            'chainId': contract['chain_id'],
            'abi': contract['abi'],
            'deploymentTx': contract['deployment_tx'],
            'version': contract['version'],
            'networkMode': contract['network_mode'],
            'deployedAt': contract['deployed_at'],
            'isMainnet': contract['network_mode'] == 'mainnet',
            'isTestnet': contract['network_mode'] == 'testnet',
            'isLocal': contract['network_mode'] == 'local',
          };
          _lastFetch = DateTime.now();
          print('Contract config fetched: $contractName @ ${_cachedConfig!['contractAddress']}');
          return _cachedConfig!;
        } else {
          throw Exception('No active contract found');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
  print('Failed to fetch contract config: $e');
  print('Falling back to static configuration...');
      return _getStaticFallback();
    }
  }

  /// Fetch any contract by name and chainId (for multi-contract support)
  Future<Map<String, dynamic>> fetchContractByName(String contractName, int chainId, {bool forceRefresh = false}) async {
    return getContractConfig(contractName: contractName, chainId: chainId, forceRefresh: forceRefresh);
  }

  /// Get specific contract properties (default: EmailPaymentRegistry)
  Future<String> get contractName async {
    final config = await getContractConfig();
    return config['contractName'] as String;
  }

  Future<String> get contractAddress async {
    final config = await getContractConfig();
    return config['contractAddress'] as String;
  }

  Future<int> get chainId async {
    final config = await getContractConfig();
    return int.parse(config['chainId'].toString());
  }

  Future<String> get abi async {
    final config = await getContractConfig();
    return config['abi'] as String;
  }

  Future<String?> get deploymentTx async {
    final config = await getContractConfig();
    return config['deploymentTx'] as String?;
  }

  Future<String> get version async {
    final config = await getContractConfig();
    return config['version'] as String;
  }

  Future<String> get networkMode async {
    final config = await getContractConfig();
    return config['networkMode'] as String;
  }

  Future<bool> get isLocal async {
    final config = await getContractConfig();
    return config['isLocal'] as bool;
  }

  Future<bool> get isMainnet async {
    final config = await getContractConfig();
    return config['isMainnet'] as bool;
  }

  Future<bool> get isTestnet async {
    final config = await getContractConfig();
    return config['isTestnet'] as bool;
  }

  /// Clear cache to force refresh on next fetch
  void clearCache() {
    _cachedConfig = null;
    _lastFetch = null;
  print('Contract config cache cleared');
  }

  /// Get static fallback configuration
  Map<String, dynamic> _getStaticFallback() {
  print('Using static fallback configuration');
    
    // Import the static config as fallback
    return {
      'contractName': 'EmailPaymentRegistry',
      'contractAddress': '0xe78A0F7E598Cc8b0Bb87894B0F60dD2a88d6a8Ab', // From your static config
      'chainId': 5777,
      'abi': '''[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"emailHash","type":"bytes32"},{"indexed":true,"internalType":"address","name":"wallet","type":"address"}],"name":"EmailRegistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"fromEmailHash","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"toEmailHash","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"PaymentSent","type":"event"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"emailHash","type":"bytes32"},{"internalType":"address","name":"wallet","type":"address"}],"name":"registerEmail","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"emailHash","type":"bytes32"}],"name":"getWalletByEmail","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"bytes32","name":"emailHash","type":"bytes32"}],"name":"getUserProfile","outputs":[{"internalType":"address","name":"wallet","type":"address"},{"internalType":"uint256","name":"registeredAt","type":"uint256"},{"internalType":"uint256","name":"lastUpdatedAt","type":"uint256"},{"internalType":"uint256","name":"totalReceived","type":"uint256"},{"internalType":"uint256","name":"totalSent","type":"uint256"}],"stateMutability":"view","type":"function","constant":true},{"inputs":[{"internalType":"bytes32","name":"fromEmailHash","type":"bytes32"},{"internalType":"bytes32","name":"toEmailHash","type":"bytes32"}],"name":"sendPaymentByEmail","outputs":[],"stateMutability":"payable","type":"function","payable":true},{"inputs":[{"internalType":"bytes32","name":"toEmailHash","type":"bytes32"}],"name":"sendPaymentToEmail","outputs":[],"stateMutability":"payable","type":"function","payable":true},{"inputs":[{"internalType":"string","name":"email","type":"string"}],"name":"computeEmailHash","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function","constant":true},{"inputs":[],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"emailHash","type":"bytes32"},{"internalType":"address","name":"newWallet","type":"address"}],"name":"adminOverrideEmail","outputs":[],"stateMutability":"nonpayable","type":"function"}]''',
      'deploymentTx': '0x8b900f812af5c57ba696230687cfe6f623d0379b50f2a0b24d4943451c078663',
      'version': 'v1757784799936-80648a3',
      'networkMode': 'local',
      'deployedAt': '2025-09-13T17:33:19.935Z',
      'isMainnet': false,
      'isTestnet': false,
      'isLocal': true,
    };
  }

  /// Check if backend is available
  Future<bool> isBackendAvailable() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.saveContract),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get configuration info for debugging
  Future<Map<String, dynamic>> getConfigInfo() async {
    final isBackendUp = await isBackendAvailable();
    final hasCache = _cachedConfig != null;
    final cacheAge = _lastFetch != null 
        ? DateTime.now().difference(_lastFetch!).inMinutes 
        : null;

    return {
      'backendAvailable': isBackendUp,
      'hasCachedConfig': hasCache,
      'cacheAgeMinutes': cacheAge,
      'baseUrl': ApiConstants.phpBaseUrl,
      'lastFetch': _lastFetch?.toIso8601String(),
    };
  }
}