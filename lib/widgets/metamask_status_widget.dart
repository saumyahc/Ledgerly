import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/metamask_service.dart';

class MetaMaskStatusWidget extends StatefulWidget {
  const MetaMaskStatusWidget({Key? key}) : super(key: key);

  @override
  State<MetaMaskStatusWidget> createState() => _MetaMaskStatusWidgetState();
}

class _MetaMaskStatusWidgetState extends State<MetaMaskStatusWidget> {
  final MetaMaskService _metamask = MetaMaskService();
  Map<String, dynamic> _status = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkMetaMaskStatus();
  }

  Future<void> _checkMetaMaskStatus() async {
    setState(() {
      _isLoading = true;
    });

    final status = <String, dynamic>{};
    
    try {
      // Check MetaMask installation
      status['isInstalled'] = await _metamask.isMetaMaskInstalled();
      
      // Check connection status
      status['isConnected'] = _metamask.isConnected;
      status['connectedAddress'] = _metamask.connectedAddress;
      status['chainId'] = _metamask.chainId;
      
      // Check deep link capability
      status['canLaunchDeepLink'] = await canLaunchUrl(Uri.parse('metamask://'));
      
      // Test backend API for contract management
      try {
        // Test if we can reach the contract API
        final contractAddress = await _metamask.getContractAddress('EmailPaymentRegistry', 1337);
        status['backendAPIWorking'] = true;
        status['contractAddress'] = contractAddress;
      } catch (e) {
        status['backendAPIWorking'] = false;
        status['backendError'] = e.toString();
      }
      
      // Overall health check
      status['overallHealth'] = _calculateHealth(status);
      
    } catch (e) {
      status['error'] = e.toString();
      status['overallHealth'] = 'Error';
    }
    
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }

  String _calculateHealth(Map<String, dynamic> status) {
    if (status['isInstalled'] == true && status['backendAPIWorking'] == true) {
      return 'Healthy';
    } else if (status['isInstalled'] == true) {
      return 'Partial';
    } else {
      return 'Issues';
    }
  }

  Color _getHealthColor(String health) {
    switch (health) {
      case 'Healthy':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Issues':
      case 'Error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 28),
                const SizedBox(width: 12),
                Text(
                  'MetaMask API Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getHealthColor(_status['overallHealth'] ?? 'Unknown'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _status['overallHealth'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Text('Checking MetaMask status...'))
            else ...[
              _buildStatusRow('App Installed', _status['isInstalled']),
              _buildStatusRow('Connected', _status['isConnected']),
              if (_status['connectedAddress'] != null)
                _buildStatusRow('Address', _status['connectedAddress'], isAddress: true),
              _buildStatusRow('Chain ID', _status['chainId']),
              _buildStatusRow('Deep Link', _status['canLaunchDeepLink']),
              _buildStatusRow('Backend API', _status['backendAPIWorking']),
              if (_status['contractAddress'] != null)
                _buildStatusRow('Contract', _status['contractAddress'], isAddress: true),
              if (_status['error'] != null)
                _buildStatusRow('Error', _status['error'], isError: true),
              if (_status['backendError'] != null)
                _buildStatusRow('Backend Error', _status['backendError'], isError: true),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () async {
                      try {
                        final address = await _metamask.connect(context);
                        if (address != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Connected: ${address.substring(0, 8)}...')),
                          );
                          _checkMetaMaskStatus();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connection failed: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Test Connect'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _checkMetaMaskStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value, {bool isError = false, bool isAddress = false}) {
    String displayValue;
    Color color;
    IconData icon;

    if (value == null) {
      displayValue = 'Unknown';
      color = Colors.grey;
      icon = Icons.help_outline;
    } else if (value is bool) {
      displayValue = value ? 'Yes' : 'No';
      color = value ? Colors.green : Colors.red;
      icon = value ? Icons.check_circle : Icons.cancel;
    } else if (isAddress && value is String) {
      displayValue = '${value.substring(0, 8)}...${value.substring(value.length - 6)}';
      color = Colors.blue;
      icon = Icons.account_balance_wallet;
    } else {
      displayValue = value.toString();
      color = isError ? Colors.red : Colors.black87;
      icon = isError ? Icons.error : Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontFamily: isAddress ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Usage: Add this widget to any page to monitor MetaMask status
// Example: Add to your wallet page or debug screen
/*
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('My App')),
    body: Column(
      children: [
        MetaMaskStatusWidget(), // Add this widget
        // ... other widgets
      ],
    ),
  );
}
*/
