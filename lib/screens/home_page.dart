// home_page.dart
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/session_manager.dart';
import '../services/wallet_manager.dart';

class HomePage extends StatelessWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const HomePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    // Extend session when user is on home page
    SessionManager.extendSession();
    
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Ledgerly',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            elevation: 0,
            automaticallyImplyLeading: false, // Explicitly disable back button
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  try {
                    // Clear wallet data first
                    final walletManager = WalletManager();
                    final userId = await SessionManager.getUserId();
                    if (userId != null) {
                      await walletManager.initialize(userId: userId);
                      await walletManager.clearWallet();
                    }
                    
                    // Then clear user session
                    await SessionManager.clearUserSession();
                    
                    // Navigate to initial screen
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  } catch (e) {
                    print('❌ Logout error: $e');
                    // Still try to navigate away even if there was an error
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  }
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
                              'Welcome back, $userName!',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    fontSize: 24,
                                    color: AppColors.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your cryptocurrency payment solution',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.black54),
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
                          leading: Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'My Wallet',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            'View your cryptocurrency balance',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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
                          title: Text(
                            'Send Payment',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            'Send cryptocurrency to others',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          onTap: () {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(minHeight: 110),
                      child: Glass3DCard(
                        child: ListTile(
                          leading: Icon(
                            Icons.receipt_long,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'Transaction History',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            'View your payment history',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          onTap: () {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(minHeight: 110),
                      child: Glass3DCard(
                        child: ListTile(
                          leading: Icon(Icons.person, color: AppColors.primary),
                          title: Text(
                            'My Profile',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            'View and edit your profile',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          onTap: () {
                            // Profile access is now handled by bottom navigation
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Use the Profile tab in the bottom navigation'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(minHeight: 110),
                      child: Glass3DCard(
                        child: ListTile(
                          leading: Icon(
                            Icons.settings,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'Settings',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            'Manage your account settings',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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
        ),
      ),
    );
  }
}
