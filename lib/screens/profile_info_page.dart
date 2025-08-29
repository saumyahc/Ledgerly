import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../constants.dart';
import '../services/session_manager.dart';
import 'account_info_page.dart';

class ProfileInfoPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const ProfileInfoPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  _ProfileInfoPageState createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final url = '${ApiConstants.getProfile}?user_id=${widget.userId}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (!mounted) return; // Check if widget is still mounted
          setState(() {
            _profileData = data['profile'];
            _isLoading = false;
          });
        } else {
          if (!mounted) return; // Check if widget is still mounted
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load profile';
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return; // Check if widget is still mounted
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extend session when viewing profile
    SessionManager.extendSession();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountInfoPage(
                    userId: widget.userId,
                    userName: widget.userName,
                    userEmail: widget.userEmail,
                  ),
                ),
              ).then((_) => _loadUserProfile());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Profile',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadUserProfile,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profile Header Card
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          
                          // Personal Information
                          _buildPersonalInfo(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final bool isProfileComplete = _profileData?['preferred_currency'] != null &&
        _profileData?['date_of_birth'] != null &&
        _profileData?['address'] != null &&
        _profileData?['city'] != null &&
        _profileData?['country'] != null &&
        _profileData?['postal_code'] != null;

    return Glass3DCard(
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 47,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // User Name
          Text(
            widget.userName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Email Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              widget.userEmail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Profile Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isProfileComplete ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isProfileComplete ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isProfileComplete ? Icons.check_circle : Icons.pending,
                  size: 16,
                  color: isProfileComplete ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  isProfileComplete ? 'Profile Complete' : 'Profile Incomplete',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isProfileComplete ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Glass3DCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow(
            icon: Icons.currency_exchange,
            label: 'Preferred Currency',
            value: _profileData?['preferred_currency'] ?? 'Not set',
          ),
          
          _buildInfoRow(
            icon: Icons.cake,
            label: 'Date of Birth',
            value: _profileData?['date_of_birth'] ?? 'Not set',
          ),
          
          _buildInfoRow(
            icon: Icons.home,
            label: 'Address',
            value: _profileData?['address'] ?? 'Not set',
          ),
          
          _buildInfoRow(
            icon: Icons.location_city,
            label: 'City',
            value: _profileData?['city'] ?? 'Not set',
          ),
          
          _buildInfoRow(
            icon: Icons.public,
            label: 'Country',
            value: _profileData?['country'] ?? 'Not set',
          ),
          
          _buildInfoRow(
            icon: Icons.markunread_mailbox,
            label: 'Postal Code',
            value: _profileData?['postal_code'] ?? 'Not set',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    final bool isEmpty = value == 'Not set' || value.isEmpty;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isEmpty ? Colors.grey[500] : Colors.black87,
                    fontWeight: isEmpty ? FontWeight.normal : FontWeight.w600,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isEmpty)
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 20,
            ),
        ],
      ),
    );
  }
}
