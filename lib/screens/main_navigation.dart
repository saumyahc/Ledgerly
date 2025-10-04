import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/session_manager.dart';
import 'stock_info.dart';
import 'wallet_page.dart';
import 'history_page.dart';
import 'profile_info_page.dart';

class MainNavigation extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const MainNavigation({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Extend session when navigation is initialized
    SessionManager.extendSession();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // Extend session on navigation
      SessionManager.extendSession();
    }
  }

  List<Widget> _getPages() {
    return [
      StockInfoPage(),
      WalletPage(
        userId: widget.userId,
        
        userEmail: widget.userEmail,
      ),
      HistoryPage(
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.userEmail,
      ),
      ProfileInfoPage(
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.userEmail,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _getPages(),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80, // Fixed height for the navigation bar
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Glass3DCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Wallet',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.history_rounded,
              label: 'History',
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Flexible(
      child: Neumorphic3DButton(
        onTap: () => _onItemTapped(index),
        borderRadius: 16,
        color: isSelected 
          ? AppColors.primary.withOpacity(0.1)
          : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                  size: isSelected ? 28 : 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSelected ? 12 : 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
