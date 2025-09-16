import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/wallet_manager.dart';

class FundingTestWidget extends StatefulWidget {
  final String userId;
  
  const FundingTestWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<FundingTestWidget> createState() => _FundingTestWidgetState();
}

class _FundingTestWidgetState extends State<FundingTestWidget> {
  final WalletManager _walletManager = WalletManager();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _walletAddress;
  double? _walletBalance;
  Map<String, dynamic>? _fundingInfo;
  Map<String, dynamic>? _contractEligibility;
  
  @override
  void initState() {
    super.initState();
    _loadWalletInfo();
  }

  Future<void> _loadWalletInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _walletManager.initialize(userId: int.parse(widget.userId));
      
      final hasWallet = await _walletManager.hasWallet();
      if (!hasWallet) {
        setState(() {
          _errorMessage = 'No wallet found. Please create a wallet first.';
        });
        return;
      }
      
      final address = await _walletManager.getAddress();
      final balance = await _walletManager.getBalance();
      final fundingInfo = _walletManager.getFundingInfo();
      
      setState(() {
        _walletAddress = address;
        _walletBalance = balance;
        _fundingInfo = fundingInfo;
      });
      
      // Check contract funding eligibility
      if (address != null) {
        final eligibility = await _walletManager.canRequestContractFunding();
        setState(() {
          _contractEligibility = eligibility;
        });
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load wallet info: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _requestContractFunding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final result = await _walletManager.requestContractFunding(amount: 1.0);
      
      if (result['success'] == true) {
        setState(() {
          _successMessage = 'Contract funding successful! Tx: ${result['transactionHash']?.substring(0, 10)}...';
        });
        
        // Refresh wallet info
        await _loadWalletInfo();
      } else {
        setState(() {
          _errorMessage = 'Contract funding failed: ${result['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to request contract funding: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _requestExternalFunding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final result = await _walletManager.requestFunding(amount: 1.0);
      
      if (result['success'] == true) {
        setState(() {
          _successMessage = 'External funding successful! Method: ${result['method']}';
        });
        
        // Refresh wallet info
        await _loadWalletInfo();
      } else {
        setState(() {
          _errorMessage = 'Funding failed: ${result['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to request funding: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(height: 8),
              Text(
                'Test funding is only available in development mode.',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Enhanced Funding Test',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              _buildErrorMessage()
            else ...[
              if (_successMessage != null) ...[
                _buildSuccessMessage(),
                SizedBox(height: 16),
              ],
              
              _buildWalletInfo(),
              SizedBox(height: 16),
              
              if (_fundingInfo != null) ...[
                _buildFundingInfo(),
                SizedBox(height: 16),
              ],
              
              if (_contractEligibility != null) ...[
                _buildContractEligibility(),
                SizedBox(height: 16),
              ],
              
              _buildActionButtons(),
            ],
            
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.refresh, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                TextButton(
                  onPressed: _loadWalletInfo,
                  child: Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessMessage() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _successMessage!,
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWalletInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem('Address', _walletAddress?.substring(0, 10) ?? 'N/A'),
            ),
            Expanded(
              child: _buildInfoItem('Balance', '${_walletBalance?.toStringAsFixed(4) ?? '0.0000'} ETH'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFundingInfo() {
    final info = _fundingInfo!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funding Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'Available',
                info['available'] == true ? 'Yes' : 'No',
              ),
            ),
            Expanded(
              child: _buildInfoItem(
                'Network',
                info['networkMode'] ?? 'unknown',
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildContractEligibility() {
    final eligibility = _contractEligibility!;
    final canRequest = eligibility['canRequest'] == true;
    final timeLeft = eligibility['timeLeft'] as int? ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contract Faucet Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(
              canRequest ? Icons.check_circle : Icons.access_time,
              color: canRequest ? Colors.green : Colors.orange,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              canRequest 
                ? 'Ready to request'
                : 'Next request in ${timeLeft}s',
              style: TextStyle(
                color: canRequest ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    final canRequestContract = _contractEligibility?['canRequest'] == true;
    final fundingAvailable = _fundingInfo?['available'] == true;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canRequestContract && fundingAvailable && !_isLoading
                ? _requestContractFunding
                : null,
            icon: Icon(Icons.water_drop),
            label: Text('Request Contract Funding (1 ETH)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: fundingAvailable && !_isLoading
                ? _requestExternalFunding
                : null,
            icon: Icon(Icons.cloud_download),
            label: Text('Request External Funding (1 ETH)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}