// otp_verification_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../theme.dart';
import 'account_info_page.dart';
import 'main_navigation.dart';
import '../services/session_manager.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  const OTPVerificationPage({super.key, required this.email});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<bool> _checkProfileComplete(int userId) async {
    try {
      final url = '${ApiConstants.getProfile}?user_id=$userId';
      print('🔍 Profile Check - Making request to: $url');
      print('🔍 Profile Check - User ID: $userId');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔍 Profile Check - Response Status: ${response.statusCode}');
      print('🔍 Profile Check - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 Profile Check - Parsed Data: $data');
        
        if (data['success'] == true && data['profile'] != null) {
          final profile = data['profile'];
          print('🔍 Profile Check - Profile Data: $profile');
          
          // Check if essential profile fields are present
          final preferredCurrency = profile['preferred_currency'];
          final address = profile['address'];
          final city = profile['city'];
          final country = profile['country'];
          
          print('🔍 Profile Check - preferred_currency: $preferredCurrency');
          print('🔍 Profile Check - address: $address');
          print('🔍 Profile Check - city: $city');
          print('🔍 Profile Check - country: $country');
          
          final bool hasRequiredFields = 
            preferredCurrency != null &&
            address != null && address.toString().isNotEmpty &&
            city != null && city.toString().isNotEmpty &&
            country != null && country.toString().isNotEmpty;
          
          print('🔍 Profile Check - Has Required Fields: $hasRequiredFields');
          return hasRequiredFields;
        } else {
          print('🔍 Profile Check - Success=false or profile is null');
          return false;
        }
      } else {
        print('🔍 Profile Check - HTTP Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('🔍 Profile Check - Exception: $e');
      return false;
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': _otpController.text.trim(),
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('📧 OTP Verification - Response Data: $data');
          
          if (data['success'] == true) {
            // Extract user data from response
            final userData = data['user'];
            print('📧 OTP Verification - User Data: $userData');
            
            final userId = userData['id'];
            final userName = userData['name'];
            final userEmail = userData['email'];
            
            print('📧 OTP Verification - Extracted: userId=$userId, userName=$userName, userEmail=$userEmail');

            // Check if profile is complete
            print('📧 OTP Verification - Checking profile completeness...');
            final bool profileComplete = await _checkProfileComplete(userId);
            print('📧 OTP Verification - Profile Complete: $profileComplete');

            // Save user session
            await SessionManager.saveUserSession(
              userId: userId,
              userName: userName,
              userEmail: userEmail,
              profileComplete: profileComplete,
            );

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Success'),
                content: Text('OTP verified successfully!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (profileComplete) {
                        print('🚀 Navigation - Going to MainNavigation (profile complete) and clearing navigation stack');
                        // Navigate to home page and clear entire navigation stack
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => MainNavigation(
                              userId: userId,
                              userName: userName,
                              userEmail: userEmail,
                            ),
                          ),
                          (route) => false, // Remove all previous routes
                        );
                      } else {
                        print('🚀 Navigation - Going to AccountInfoPage (profile incomplete)');
                        // Navigate to account info page if profile is incomplete
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => AccountInfoPage(
                              userId: userId,
                              userName: userName,
                              userEmail: userEmail,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Error'),
                content: Text(data['message'] ?? 'OTP verification failed'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          // JSON parsing failed
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text('Server error: Unexpected response format.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // HTTP error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Server error: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to verify OTP: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Verify OTP',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontSize: 26,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the OTP sent to your email',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _otpController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.lock,
                              color: AppColors.primary,
                            ),
                            labelText: 'OTP',
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    'Verify',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Didn't receive the OTP? Resend",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.primary),
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
}
