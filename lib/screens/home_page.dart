// home_page.dart
import 'package:flutter/material.dart';
import '../theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Ledgerly',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Section
                    Container(
                      constraints: BoxConstraints(minHeight: 180),
                      child: Glass3DCard(
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 60,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Welcome to Ledgerly!',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24, color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your cryptocurrency payment solution',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    // Action Cards
                    Container(
                      constraints: BoxConstraints(minHeight: 110),
                      child: Glass3DCard(
                        child: ListTile(
                          leading: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                          title: Text('My Wallet', style: Theme.of(context).textTheme.bodyLarge),
                          subtitle: Text('View your cryptocurrency balance', style: Theme.of(context).textTheme.bodyMedium),
                          onTap: () {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(minHeight: 110),
                      child: Glass3DCard(
                        child: ListTile(
                          leading: Icon(Icons.send, color: AppColors.primary),
                          title: Text('Send Payment', style: Theme.of(context).textTheme.bodyLarge),
                          subtitle: Text('Send cryptocurrency to others', style: Theme.of(context).textTheme.bodyMedium),
                          onTap: () {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(minHeight: 110),
                      child: Glass3DCard(
                        child: ListTile(
                          leading: Icon(Icons.receipt_long, color: AppColors.primary),
                          title: Text('Transaction History', style: Theme.of(context).textTheme.bodyLarge),
                          subtitle: Text('View your payment history', style: Theme.of(context).textTheme.bodyMedium),
                          onTap: () {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(minHeight: 110),
                      child: Glass3DCard(
                        child: ListTile(
                          leading: Icon(Icons.settings, color: AppColors.primary),
                          title: Text('Settings', style: Theme.of(context).textTheme.bodyLarge),
                          subtitle: Text('Manage your account settings', style: Theme.of(context).textTheme.bodyMedium),
                          onTap: () {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              constraints: BoxConstraints(minHeight: 80),
              child: Glass3DCard(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFooterItem(Icons.home, 'Home', true, context),
                    _buildFooterItem(Icons.account_balance_wallet, 'Wallet', false, context),
                    _buildFooterItem(Icons.history, 'History', false, context),
                    _buildFooterItem(Icons.person, 'Profile', false, context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String label, bool selected, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? AppColors.primary : Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.primary : Colors.grey,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}
