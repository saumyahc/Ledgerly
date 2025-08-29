import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../constants.dart';
import 'main_navigation.dart';
import '../services/session_manager.dart';

class AccountInfoPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const AccountInfoPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  _AccountInfoPageState createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form fields
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Cryptocurrency-specific fields
  String preferredCurrency = 'USD';
  String dateOfBirth = '';
  String address = '';
  String city = '';
  String country = '';
  String postalCode = '';

  // Validation state variables
  String? _addressError;
  String? _cityError;
  String? _countryError;

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
  ];

  final List<String> _countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'Singapore',
    'India',
    'Brazil',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _dateOfBirthController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final url = '${ApiConstants.getProfile}?user_id=${widget.userId}';
      print('👤 Account Info - Loading profile from: $url');
      print('👤 Account Info - User ID: ${widget.userId}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('👤 Account Info - Response Status: ${response.statusCode}');
      print('👤 Account Info - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('👤 Account Info - Parsed Data: $data');
        
        if (data['success'] == true && data['profile'] != null) {
          final profile = data['profile'];
          print('👤 Account Info - Profile Data: $profile');
          
          setState(() {
            preferredCurrency = profile['preferred_currency'] ?? 'USD';
            dateOfBirth = profile['date_of_birth'] ?? '';
            address = profile['address'] ?? '';
            city = profile['city'] ?? '';
            country = profile['country'] ?? '';
            postalCode = profile['postal_code'] ?? '';
            
            print('👤 Account Info - Setting controllers with loaded data');
            // Update controllers with loaded data
            _dateOfBirthController.text = dateOfBirth;
            _addressController.text = address;
            _cityController.text = city;
            _postalCodeController.text = postalCode;
          });
          
          print('👤 Account Info - Profile loaded successfully');
        } else {
          print('👤 Account Info - Success=false or profile is null');
        }
      } else {
        print('👤 Account Info - HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      print('👤 Account Info - Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extend session when user is on account info page
    SessionManager.extendSession();
    
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
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 64,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Complete Your Profile',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    fontSize: 26,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Set up your crypto payment profile',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            // User info display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    widget.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.userEmail,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Preferred Currency Dropdown
                            DropdownButtonFormField<String>(
                              value: preferredCurrency,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.currency_exchange,
                                  color: AppColors.primary,
                                ),
                                labelText: 'Preferred Currency',
                              ),
                              items: _currencies.map((String currency) {
                                return DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  preferredCurrency = newValue!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Date of Birth Field
                            TextField(
                              controller: _dateOfBirthController,
                              onChanged: (val) =>
                                  setState(() => dateOfBirth = val),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.cake,
                                  color: AppColors.primary,
                                ),
                                labelText: 'Date of Birth (DD/MM/YYYY)',
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Address Field
                            TextField(
                              controller: _addressController,
                              onChanged: (val) => setState(() => address = val),
                              maxLines: 2,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.home,
                                  color: AppColors.primary,
                                ),
                                labelText: 'Address',
                                errorText: _addressError,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // City Field
                            TextField(
                              controller: _cityController,
                              onChanged: (val) => setState(() => city = val),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.location_city,
                                  color: AppColors.primary,
                                ),
                                labelText: 'City',
                                errorText: _cityError,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Country Dropdown
                            DropdownButtonFormField<String>(
                              value: country.isEmpty ? null : country,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.public,
                                  color: AppColors.primary,
                                ),
                                labelText: 'Country',
                                errorText: _countryError,
                              ),
                              items: _countries.map((String country) {
                                return DropdownMenuItem<String>(
                                  value: country,
                                  child: Text(country),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  country = newValue ?? '';
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Postal Code Field
                            TextField(
                              controller: _postalCodeController,
                              onChanged: (val) =>
                                  setState(() => postalCode = val),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.markunread_mailbox,
                                  color: AppColors.primary,
                                ),
                                labelText: 'Postal Code',
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Save Profile',
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
        ),
      ),
    );
  }

  bool _isLoading = false;

  Future<void> _handleSave() async {
    if (_validateForm()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse(ApiConstants.saveProfile),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': widget.userId,
            'preferred_currency': preferredCurrency,
            'date_of_birth': dateOfBirth,
            'address': address,
            'city': city,
            'country': country,
            'postal_code': postalCode,
          }),
        );

        setState(() => _isLoading = false);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profile saved successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // Update session to mark profile as complete
            await SessionManager.updateProfileComplete(true);

            // Navigate to home page after successful save and clear navigation stack
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigation(
                  userId: widget.userId,
                  userName: widget.userName,
                  userEmail: widget.userEmail,
                ),
              ),
              (route) => false, // Remove all previous routes
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Failed to save profile'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _validateForm() {
    bool isValid = true;

    // Reset all errors
    setState(() {
      _addressError = null;
      _cityError = null;
      _countryError = null;
    });

    // Address validation
    if (address.isEmpty) {
      setState(() => _addressError = 'Address is required');
      isValid = false;
    }

    // City validation
    if (city.isEmpty) {
      setState(() => _cityError = 'City is required');
      isValid = false;
    }

    // Country validation
    if (country.isEmpty) {
      setState(() => _countryError = 'Country is required');
      isValid = false;
    }

    return isValid;
  }
}
