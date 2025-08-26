import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../constants.dart';
import 'account_info_page.dart';

class UserProfileView extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  _UserProfileViewState createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
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
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.getProfile}?user_id=${widget.userId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _profileData = data['profile'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load profile';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'User Profile',
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadUserProfile,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32,
                      ),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Header
                              Center(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: AppColors.primary,
                                      child: Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      widget.userName,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.userEmail,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Profile Information
                              Text(
                                'Profile Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Profile Details
                              _buildProfileItem(
                                'Preferred Currency',
                                _profileData?['preferred_currency'] ??
                                    'Not set',
                                Icons.currency_exchange,
                              ),
                              _buildProfileItem(
                                'Date of Birth',
                                _profileData?['date_of_birth'] ?? 'Not set',
                                Icons.cake,
                              ),
                              _buildProfileItem(
                                'Address',
                                _profileData?['address'] ?? 'Not set',
                                Icons.home,
                              ),
                              _buildProfileItem(
                                'City',
                                _profileData?['city'] ?? 'Not set',
                                Icons.location_city,
                              ),
                              _buildProfileItem(
                                'Country',
                                _profileData?['country'] ?? 'Not set',
                                Icons.public,
                              ),
                              _buildProfileItem(
                                'Postal Code',
                                _profileData?['postal_code'] ?? 'Not set',
                                Icons.markunread_mailbox,
                              ),

                              const SizedBox(height: 24),

                              // Profile Status
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      _profileData?['profile_completed'] == true
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        _profileData?['profile_completed'] ==
                                            true
                                        ? Colors.green
                                        : Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _profileData?['profile_completed'] == true
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color:
                                          _profileData?['profile_completed'] ==
                                              true
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Profile Status',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  _profileData?['profile_completed'] ==
                                                      true
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                          Text(
                                            _profileData?['profile_completed'] ==
                                                    true
                                                ? 'Complete'
                                                : 'Incomplete',
                                            style: TextStyle(
                                              color:
                                                  _profileData?['profile_completed'] ==
                                                      true
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Edit Profile Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
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
                                    ).then((_) {
                                      // Reload profile data when returning from edit
                                      _loadUserProfile();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Edit Profile',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
