import 'package:flutter/material.dart';
import '../services/dynamic_contract_config.dart';
import '../services/contract_service.dart';
import '../theme.dart';

class ContractConfigPage extends StatefulWidget {
  const ContractConfigPage({super.key});

  @override
  State<ContractConfigPage> createState() => _ContractConfigPageState();
}

class _ContractConfigPageState extends State<ContractConfigPage> {
  final DynamicContractConfig _configService = DynamicContractConfig.instance;
  final ContractService _contractService = ContractService();
  
  Map<String, dynamic>? _currentConfig;
  Map<String, dynamic>? _configInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    
    try {
      final config = await _configService.getContractConfig();
      final info = await _configService.getConfigInfo();
      
      setState(() {
        _currentConfig = config;
        _configInfo = info;
      });
    } catch (e) {
      _showError('Failed to load config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshConfig() async {
    setState(() => _isLoading = true);
    
    try {
      _configService.clearCache();
      await _contractService.refreshConfig();
      await _loadConfig();
      _showSuccess('Configuration refreshed successfully');
    } catch (e) {
      _showError('Failed to refresh config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Configuration'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildConfigStatusCard(),
                  const SizedBox(height: 16),
                  _buildCurrentConfigCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildConfigStatusCard() {
    if (_configInfo == null) return const SizedBox.shrink();

    final isBackendUp = _configInfo!['backendAvailable'] == true;
    final hasCache = _configInfo!['hasCachedConfig'] == true;
    final cacheAge = _configInfo!['cacheAgeMinutes'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Backend Available', isBackendUp),
            _buildStatusRow('Has Cached Config', hasCache),
            if (cacheAge != null)
              _buildInfoRow('Cache Age', '$cacheAge minutes'),
            _buildInfoRow('Base URL', _configInfo!['baseUrl'] ?? 'Unknown'),
            if (_configInfo!['lastFetch'] != null)
              _buildInfoRow('Last Fetch', _configInfo!['lastFetch']),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentConfigCard() {
    if (_currentConfig == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Contract Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Contract Name', _currentConfig!['contractName']),
            _buildInfoRow('Address', _currentConfig!['contractAddress']),
            _buildInfoRow('Chain ID', _currentConfig!['chainId'].toString()),
            _buildInfoRow('Version', _currentConfig!['version'] ?? 'Unknown'),
            _buildInfoRow('Network Mode', _currentConfig!['networkMode'] ?? 'Unknown'),
            _buildStatusRow('Is Local', _currentConfig!['isLocal'] == true),
            _buildStatusRow('Is Testnet', _currentConfig!['isTestnet'] == true),
            _buildStatusRow('Is Mainnet', _currentConfig!['isMainnet'] == true),
            if (_currentConfig!['deployedAt'] != null)
              _buildInfoRow('Deployed At', _currentConfig!['deployedAt']),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _refreshConfig,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Configuration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                _configService.clearCache();
                _showSuccess('Cache cleared successfully');
                _loadConfig();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Cache'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final isAvailable = await _configService.isBackendAvailable();
                _showSuccess('Backend ${isAvailable ? "is" : "is not"} available');
              },
              icon: const Icon(Icons.network_check),
              label: const Text('Test Backend Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(status ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}