import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/session_manager.dart';

class HistoryPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const HistoryPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'tx001',
      'type': 'send',
      'icon': Icons.send_rounded,
      'title': 'Sent to Alice',
      'subtitle': 'To: alice@example.com',
      'amount': '-0.00125 BTC',
      'usdAmount': '-\$56.25',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
      'confirmations': 6,
    },
    {
      'id': 'tx002',
      'type': 'receive',
      'icon': Icons.call_received_rounded,
      'title': 'Received from Bob',
      'subtitle': 'From: bob@example.com',
      'amount': '+0.00200 BTC',
      'usdAmount': '+\$90.00',
      'time': DateTime.now().subtract(const Duration(hours: 8)),
      'status': 'completed',
      'confirmations': 15,
    },
    {
      'id': 'tx003',
      'type': 'exchange',
      'icon': Icons.swap_horiz_rounded,
      'title': 'Exchange BTC → ETH',
      'subtitle': 'Internal exchange',
      'amount': '0.00100 BTC',
      'usdAmount': '\$45.00',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'completed',
      'confirmations': 12,
    },
    {
      'id': 'tx004',
      'type': 'send',
      'icon': Icons.send_rounded,
      'title': 'Sent to Charlie',
      'subtitle': 'To: charlie@example.com',
      'amount': '-0.00075 BTC',
      'usdAmount': '-\$33.75',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'pending',
      'confirmations': 2,
    },
    {
      'id': 'tx005',
      'type': 'receive',
      'icon': Icons.call_received_rounded,
      'title': 'Received Mining Reward',
      'subtitle': 'Mining pool payout',
      'amount': '+0.00050 BTC',
      'usdAmount': '+\$22.50',
      'time': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'completed',
      'confirmations': 25,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    SessionManager.extendSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTransactions() async {
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return; // Check again after async operation
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Transactions')),
              const PopupMenuItem(value: 'Send', child: Text('Sent')),
              const PopupMenuItem(value: 'Receive', child: Text('Received')),
              const PopupMenuItem(value: 'Exchange', child: Text('Exchanges')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshTransactions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Sent'),
            Tab(text: 'Received'),
            Tab(text: 'Exchanges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionList('All'),
          _buildTransactionList('Send'),
          _buildTransactionList('Receive'),
          _buildTransactionList('Exchange'),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String filter) {
    final filteredTransactions = filter == 'All' 
        ? _transactions 
        : _transactions.where((tx) => tx['type'] == filter.toLowerCase()).toList();

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Loading transactions...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${filter.toLowerCase()} transactions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTransactions,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTransactions.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryCard();
          }
          return _buildTransactionCard(filteredTransactions[index - 1]);
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalSent = _transactions
        .where((tx) => tx['type'] == 'send')
        .length;
    final totalReceived = _transactions
        .where((tx) => tx['type'] == 'receive')
        .length;
    final totalExchanges = _transactions
        .where((tx) => tx['type'] == 'exchange')
        .length;

    return Glass3DCard(
      child: Column(
        children: [
          Text(
            'Transaction Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem(
                icon: Icons.send_rounded,
                count: totalSent,
                label: 'Sent',
                color: Colors.red,
              ),
              _buildSummaryItem(
                icon: Icons.call_received_rounded,
                count: totalReceived,
                label: 'Received',
                color: Colors.green,
              ),
              _buildSummaryItem(
                icon: Icons.swap_horiz_rounded,
                count: totalExchanges,
                label: 'Exchanges',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isOutgoing = transaction['type'] == 'send';
    final isPending = transaction['status'] == 'pending';
    
    Color iconColor = Colors.blue;
    if (isOutgoing) iconColor = Colors.red;
    if (transaction['type'] == 'receive') iconColor = Colors.green;

    return Glass3DCard(
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      transaction['icon'],
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                transaction['title'],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isPending)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Pending',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transaction['subtitle'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        transaction['amount'],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      Text(
                        transaction['usdAmount'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(transaction['time']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: isPending ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${transaction['confirmations']} confirmations',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isPending ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Transaction Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Transaction ID', transaction['id']),
              _buildDetailRow('Type', transaction['title']),
              _buildDetailRow('Amount', transaction['amount']),
              _buildDetailRow('USD Value', transaction['usdAmount']),
              _buildDetailRow('Status', transaction['status']),
              _buildDetailRow('Confirmations', '${transaction['confirmations']}'),
              _buildDetailRow('Date', _formatDateTime(transaction['time'])),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
